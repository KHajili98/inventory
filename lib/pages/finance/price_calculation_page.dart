import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/price_calculation/cubit/price_calculation_cubit.dart';
import 'package:inventory/features/price_calculation/cubit/price_calculation_state.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/pages/finance/calculation_detail_page.dart';
import 'package:inventory/pages/finance/edit_product_price_by_stock_page.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class PriceCalculationPage extends StatefulWidget {
  const PriceCalculationPage({super.key});

  @override
  State<PriceCalculationPage> createState() => _PriceCalculationPageState();
}

class _PriceCalculationPageState extends State<PriceCalculationPage> {
  late final PriceCalculationCubit _cubit = PriceCalculationCubit();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  final ScrollController _hScrollController = ScrollController();
  final ScrollController _hHeaderController = ScrollController();
  final ScrollController _vScrollController = ScrollController();
  bool _hSyncing = false;

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

  static double get _tableWidth =>
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
      _colInvoicePrice +
      _colCostPrice +
      _colWholePrice +
      _colRetailPrice +
      50;

  @override
  void initState() {
    super.initState();
    _hScrollController.addListener(_onHScroll);
    _cubit.fetchItems();
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  void _fetch() {
    final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    _cubit.fetchItems(search: search);
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
                  // ── Title row ──────────────────────────────────────────
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.priceCalculation,
                            style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.priceRequestsSubtitle,
                            style: TextStyle(fontSize: isMobile ? 12 : 13, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProductPriceByStockPage())),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.adjustPrices),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Stats row ──────────────────────────────────────────
                  BlocBuilder<PriceCalculationCubit, PriceCalculationState>(
                    builder: (_, state) {
                      if (state is PriceCalculationLoaded) {
                        return _StatsRow(totalCount: state.totalCount, isMobile: isMobile, l10n: l10n);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  // ── Search ─────────────────────────────────────────────
                  _buildSearchBar(l10n),
                ],
              ),
            ),

            // ── Table ──────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<PriceCalculationCubit, PriceCalculationState>(
                builder: (_, state) {
                  if (state is PriceCalculationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is PriceCalculationError) {
                    return _ErrorView(message: state.message, onRetry: _fetch);
                  }
                  if (state is PriceCalculationLoaded) {
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.searchPlaceholder,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTable(PriceCalculationLoaded state, AppLocalizations l10n) {
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
              width: _tableWidth + 32,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _buildTableHeader(l10n),
            ),
          ),
          // Body
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
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
                      width: _tableWidth,
                      child: Column(
                        children: [
                          ...state.products.map((item) => _buildTableRow(item, l10n)),
                          if (state.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          if (!state.hasMore && state.products.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('${state.totalCount} items total', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFFF8FAFC),
      child: SizedBox(
        width: _tableWidth,
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
            _headerCell(l10n.invoicePriceAznLabel, _colInvoicePrice),
            _headerCell(l10n.costPrice, _colCostPrice),
            _headerCell(l10n.wholesalePrice, _colWholePrice),
            _headerCell(l10n.retailPrice, _colRetailPrice),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3),
        softWrap: true,
      ),
    );
  }

  Widget _buildTableRow(StockProductItemModel item, AppLocalizations l10n) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CalculationDetailPage(item: item, onSuccess: () => _cubit.removeItem(item.id)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: SizedBox(
          width: _tableWidth - 32,
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
              _cell(item.invoiceUnitPriceAzn != null ? '₼ ${item.invoiceUnitPriceAzn!.toStringAsFixed(2)}' : '—', _colInvoicePrice),
              _cell(item.costUnitPrice != null ? '₼ ${item.costUnitPrice!.toStringAsFixed(2)}' : '—', _colCostPrice),
              _cell(item.wholeUnitSalesPrice != null ? '₼ ${item.wholeUnitSalesPrice!.toStringAsFixed(2)}' : '—', _colWholePrice),
              _cell(item.retailUnitPrice != null ? '₼ ${item.retailUnitPrice!.toStringAsFixed(2)}' : '—', _colRetailPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, double width, {bool bold = false, bool muted = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: muted ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
        ),
        overflow: TextOverflow.ellipsis,
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
            child: Text(
              colorName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalCount;
  final bool isMobile;
  final AppLocalizations l10n;

  const _StatsRow({required this.totalCount, required this.isMobile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: l10n.totalRequests,
        value: '$totalCount',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        isMobile: isMobile,
      ),
      _StatCard(title: l10n.pricePending, value: '$totalCount', icon: Icons.pending_rounded, color: const Color(0xFFEF4444), isMobile: isMobile),
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
            child: const Text('Retry'),
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
          Icon(Icons.price_change_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noResultsFound, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
