import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/auth/auth_cubit.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_repository.dart';
import 'package:inventory/features/stocks/cubit/stocks_cubit.dart';
import 'package:inventory/features/stocks/cubit/stocks_state.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/auth_models.dart';
import 'package:inventory/pages/stock/add_stock_item_dialog.dart';

// ── Stock status helper ───────────────────────────────────────────────────────

enum _StockStatus { active, lowStock, outOfStock, pricePending }

_StockStatus _resolveStatus(StockProductItemModel item) {
  if (!item.priced) return _StockStatus.pricePending;
  if (item.quantity == 0) return _StockStatus.outOfStock;
  if (item.quantity <= 10) return _StockStatus.lowStock;
  return _StockStatus.active;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  // ── cubit ────────────────────────────────────────────────────────────────
  late final StocksCubit _cubit = StocksCubit();

  // ── inventories ──────────────────────────────────────────────────────────
  List<InventoryModel> _inventories = [];
  InventoryModel? _selectedInventory; // null = all

  // ── search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ── scroll ───────────────────────────────────────────────────────────────
  final ScrollController _hScrollController = ScrollController();
  final ScrollController _hHeaderController = ScrollController();
  final ScrollController _vScrollController = ScrollController();
  bool _hSyncing = false;

  // ── Horizontal scroll step buttons ───────────────────────────────────────
  static const double _hScrollStep = 300.0;

  void _scrollLeft() {
    final target = (_hScrollController.offset - _hScrollStep).clamp(0.0, _hScrollController.position.maxScrollExtent);
    _hScrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _scrollRight() {
    final target = (_hScrollController.offset + _hScrollStep).clamp(0.0, _hScrollController.position.maxScrollExtent);
    _hScrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  // ── table column widths ───────────────────────────────────────────────────
  static const double _colModelCode = 140.0;
  static const double _colProductName = 180.0;
  static const double _colGeneratedName = 200.0;
  static const double _colProductCode = 130.0;
  static const double _colSize = 80.0;
  static const double _colColor = 110.0;
  static const double _colColorCode = 100.0;
  static const double _colQuantity = 90.0;
  static const double _colBarcode = 150.0;
  static const double _colInventory = 200.0;
  static const double _colInvoicePrice = 150.0;
  static const double _colCostPrice = 120.0;
  static const double _colWholePrice = 140.0;
  static const double _colRetailPrice = 130.0;
  static const double _colStatus = 140.0;
  static const double _colActions = 60.0;

  static double _tableWidth({bool showCostPrices = true}) =>
      _colModelCode +
      _colProductName +
      _colGeneratedName +
      _colProductCode +
      _colSize +
      _colColor +
      _colColorCode +
      _colQuantity +
      _colBarcode +
      _colInventory +
      (showCostPrices ? _colInvoicePrice + _colCostPrice : 0) +
      _colWholePrice +
      _colRetailPrice +
      _colStatus +
      _colActions +
      50;

  @override
  void initState() {
    super.initState();
    _hScrollController.addListener(_onHScroll);
    _loadInventories();
    _cubit.fetchStocks();
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _hHeaderController.dispose();
    _vScrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  void _onHScroll() {
    if (_hSyncing) return;
    _hSyncing = true;
    final offset = _hScrollController.offset;
    if (_hHeaderController.hasClients && _hHeaderController.offset != offset) {
      _hHeaderController.jumpTo(offset);
    }
    _hSyncing = false;
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadInventories() async {
    final result = await InventoryRepository.instance.fetchInventories(pageSize: 200);
    if (!mounted) return;
    if (result is Success<InventoryListResponse>) {
      setState(() => _inventories = result.data.results);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  void _onInventoryChanged(InventoryModel? inv) {
    setState(() => _selectedInventory = inv);
    _fetch();
  }

  void _fetch() {
    final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    _cubit.fetchStocks(search: search, inventoryId: _selectedInventory?.id);
  }

  // ── delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(StockProductItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 10),
            Text(l10n.deleteStockItem, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(l10n.deleteStockItemConfirm, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _cubit.deleteStock(item.id);
    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.stockItemDeleted), backgroundColor: const Color(0xFF10B981)));
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.stockItemDeleteFailed(message)), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  // ── add stock item ────────────────────────────────────────────────────────

  Future<void> _openAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;
    final loggedInInventoryId = authState is AuthAuthenticated ? authState.response.loggedInInventory?.id : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AddStockItemDialog(inventories: _inventories, defaultInventoryId: loggedInInventoryId, cubit: _cubit),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.stockItemCreated), backgroundColor: const Color(0xFF10B981)));
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ── Top controls ───────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ──────────────────────────────────────────
                  BlocBuilder<StocksCubit, StocksState>(
                    builder: (_, state) {
                      if (state is StocksLoaded) {
                        return _StatsRow(products: state.products, isMobile: isMobile, l10n: l10n);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  // ── Filters + Add button ───────────────────────────────
                  _buildFilterBar(l10n, isMobile),
                ],
              ),
            ),

            // ── Table ──────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<StocksCubit, StocksState>(
                builder: (_, state) {
                  if (state is StocksLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is StocksError) {
                    return _ErrorView(message: state.message, onRetry: _fetch);
                  }
                  if (state is StocksLoaded) {
                    if (state.products.isEmpty) {
                      return _EmptyView(l10n: l10n);
                    }
                    return _buildTable(state, l10n);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n, bool isMobile) {
    return Row(
      children: [
        // Inventory dropdown
        Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InventoryModel?>(
              value: _selectedInventory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              onChanged: _onInventoryChanged,
              items: [
                DropdownMenuItem<InventoryModel?>(value: null, child: Text(l10n.allInventories, style: const TextStyle(fontSize: 14))),
                ..._inventories.map(
                  (inv) => DropdownMenuItem<InventoryModel?>(
                    value: inv,
                    child: Text(inv.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Search
        if (!isMobile)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchStock,
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
        const Spacer(),
        // Add button
        ElevatedButton.icon(
          onPressed: _openAddDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.addStockItem, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTable(StocksLoaded state, AppLocalizations l10n) {
    final authState = context.read<AuthCubit>().state;
    final role = authState is AuthAuthenticated ? authState.response.user.role : UserRole.unknown;
    final showCostPrices = role.canSeeStockCostPrices;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Sticky header
          SingleChildScrollView(
            controller: _hHeaderController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              width: _tableWidth(showCostPrices: showCostPrices) + 32,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _buildTableHeader(l10n, showCostPrices: showCostPrices),
            ),
          ),
          // Body
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // Load more when near bottom
                    if (n is ScrollEndNotification && n.metrics.axis == Axis.vertical) {
                      final pixels = n.metrics.pixels;
                      final maxExtent = n.metrics.maxScrollExtent;
                      if (maxExtent > 0 && pixels >= maxExtent - 200) {
                        _cubit.loadMore();
                      }
                    }
                    return false;
                  },
                  child: Scrollbar(
                    controller: _vScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _vScrollController,
                      child: SingleChildScrollView(
                        controller: _hScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _tableWidth(showCostPrices: showCostPrices),
                          child: Column(
                            children: [
                              ...state.products.map((item) => _buildTableRow(item, l10n, showCostPrices: showCostPrices)),
                              if (state.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              if (!state.hasMore && state.products.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(l10n.itemsTotal(state.totalCount), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Left scroll button ──────────────────────────────────
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _HScrollButton(icon: Icons.chevron_left_rounded, onTap: _scrollLeft, controller: _hScrollController, isLeft: true),
                  ),
                ),
                // ── Right scroll button ─────────────────────────────────
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _HScrollButton(icon: Icons.chevron_right_rounded, onTap: _scrollRight, controller: _hScrollController, isLeft: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations l10n, {bool showCostPrices = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFFF8FAFC),
      child: SizedBox(
        width: _tableWidth(showCostPrices: showCostPrices),
        child: Row(
          children: [
            _headerCell(l10n.modelCode, _colModelCode),
            _headerCell(l10n.productName, _colProductName),
            _headerCell(l10n.generatedName, _colGeneratedName),
            _headerCell(l10n.productCode, _colProductCode),
            _headerCell(l10n.size, _colSize),
            _headerCell(l10n.color, _colColor),
            _headerCell(l10n.colorCode, _colColorCode),
            _headerCell(l10n.quantity, _colQuantity),
            _headerCell(l10n.barcode, _colBarcode),
            _headerCell(l10n.sourceInventory, _colInventory),
            if (showCostPrices) _headerCell(l10n.invoicePriceAznLabel, _colInvoicePrice),
            if (showCostPrices) _headerCell(l10n.costPrice, _colCostPrice),
            _headerCell(l10n.wholesalePrice, _colWholePrice),
            _headerCell(l10n.retailPrice, _colRetailPrice),
            _headerCell(l10n.status, _colStatus),
            _headerCell(l10n.actions, _colActions),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildTableRow(StockProductItemModel item, AppLocalizations l10n, {bool showCostPrices = true}) {
    final status = _resolveStatus(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SizedBox(
        width: _tableWidth(showCostPrices: showCostPrices) - 32,
        child: Row(
          children: [
            _cell(item.modelCode ?? '—', _colModelCode),
            _cell(item.productName ?? '—', _colProductName),
            _cell(item.productGeneratedName ?? '—', _colGeneratedName),
            _cell(item.productCode ?? '—', _colProductCode),
            _cell(item.size ?? '—', _colSize),
            _colorCell(item.color ?? '—', item.colorCode ?? '', _colColor),
            _cell(item.colorCode ?? '—', _colColorCode, muted: true),
            _cell('${item.quantity}', _colQuantity, bold: true),
            _cell(item.barcode ?? '—', _colBarcode),
            _cell(item.inventoryName, _colInventory),
            if (showCostPrices) _cell(item.invoiceUnitPriceAzn != null ? '₼ ${item.invoiceUnitPriceAzn!.toStringAsFixed(2)}' : '—', _colInvoicePrice),
            if (showCostPrices) _cell(item.costUnitPrice != null ? '₼ ${item.costUnitPrice!.toStringAsFixed(2)}' : '—', _colCostPrice),
            _cell(item.wholeUnitSalesPrice != null ? '₼ ${item.wholeUnitSalesPrice!.toStringAsFixed(2)}' : '—', _colWholePrice),
            _cell(item.retailUnitPrice != null ? '₼ ${item.retailUnitPrice!.toStringAsFixed(2)}' : '—', _colRetailPrice),
            _statusCell(status, l10n, _colStatus),
            SizedBox(
              width: _colActions,
              child: IconButton(
                onPressed: () => _confirmDelete(item),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: const Color(0xFFEF4444),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                tooltip: l10n.deleteStockItem,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, {bool bold = false, bool muted = false}) {
    return SizedBox(
      width: width,
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: muted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _colorCell(String colorName, String colorCode, double width) {
    Color? swatch;
    if (colorCode.startsWith('#') && colorCode.length == 7) {
      try {
        swatch = Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return SizedBox(
      width: width,
      child: Row(
        children: [
          if (swatch != null) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: SelectableText(colorName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  Widget _statusCell(_StockStatus status, AppLocalizations l10n, double width) {
    late Color bg;
    late Color fg;
    late String label;

    switch (status) {
      case _StockStatus.active:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = l10n.activeStatus;
      case _StockStatus.lowStock:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = l10n.lowStock;
      case _StockStatus.outOfStock:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = l10n.outOfStock;
      case _StockStatus.pricePending:
        bg = const Color(0xFFFED7AA);
        fg = const Color(0xFF9A3412);
        label = l10n.pricePending;
    }

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<StockProductItemModel> products;
  final bool isMobile;
  final AppLocalizations l10n;

  const _StatsRow({required this.products, required this.isMobile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    int active = 0, lowStock = 0, outOfStock = 0, pricePending = 0;
    for (final p in products) {
      switch (_resolveStatus(p)) {
        case _StockStatus.active:
          active++;
        case _StockStatus.lowStock:
          lowStock++;
        case _StockStatus.outOfStock:
          outOfStock++;
        case _StockStatus.pricePending:
          pricePending++;
      }
    }

    final cards = [
      _StatCard(title: l10n.activeProducts, value: '$active', icon: Icons.check_circle_rounded, color: const Color(0xFF10B981), isMobile: isMobile),
      _StatCard(title: l10n.lowStock, value: '$lowStock', icon: Icons.warning_rounded, color: const Color(0xFFF59E0B), isMobile: isMobile),
      _StatCard(title: l10n.outOfStock, value: '$outOfStock', icon: Icons.cancel_rounded, color: const Color(0xFF64748B), isMobile: isMobile),
      _StatCard(title: l10n.pricePending, value: '$pricePending', icon: Icons.pending_rounded, color: const Color(0xFFEF4444), isMobile: isMobile),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
      );
    }
    return Wrap(spacing: 14, runSpacing: 14, children: cards);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error / empty views ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noProducts, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ── Horizontal Scroll Button ──────────────────────────────────────────────────

class _HScrollButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ScrollController controller;
  final bool isLeft;

  const _HScrollButton({required this.icon, required this.onTap, required this.controller, required this.isLeft});

  @override
  State<_HScrollButton> createState() => _HScrollButtonState();
}

class _HScrollButtonState extends State<_HScrollButton> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    // Defer first check until layout is done
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted || !widget.controller.hasClients) return;
    final pos = widget.controller.position;
    final shouldShow = widget.isLeft ? pos.pixels > 4 : pos.pixels < pos.maxScrollExtent - 4;
    if (shouldShow != _visible) setState(() => _visible = shouldShow);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !_visible,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 18, color: const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
