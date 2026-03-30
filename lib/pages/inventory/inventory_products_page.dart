import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/barcode/data/repositories/barcode_repository.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_cubit.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_state.dart';
import 'package:inventory/features/inventory_products/data/models/create_inventory_product_request_model.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_repository.dart';
import 'package:inventory/features/invoice_detail/data/models/invoice_detail_model.dart';
import 'package:inventory/features/invoice_detail/data/repositories/invoice_detail_repository.dart';
import 'package:inventory/features/invoice_list/data/models/invoice_list_response_model.dart';
import 'package:inventory/features/invoice_list/data/repositories/invoice_list_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/product_models.dart';

class InventoryProductsPage extends StatelessWidget {
  const InventoryProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => InventoryProductsCubit()..fetchProducts(), child: const _InventoryProductsView());
  }
}

class _InventoryProductsView extends StatefulWidget {
  const _InventoryProductsView();

  @override
  State<_InventoryProductsView> createState() => _InventoryProductsViewState();
}

class _InventoryProductsViewState extends State<_InventoryProductsView> {
  final Set<String> _selectedIds = {};
  String? _activeStatusFilter; // 'in_stock' | 'low_stock' | 'out_of_stock' | null

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Primary horizontal scroll controller (drives both header and body rows)
  final ScrollController _hScrollController = ScrollController();
  // Mirror controller for header kept in sync via listener
  final ScrollController _hHeaderController = ScrollController();

  final ScrollController _vScrollController = ScrollController();

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

  // ── Sync header horizontal scroll with body ───────────────────────────────
  bool _hSyncing = false;
  void _onHScroll() {
    if (_hSyncing) return;
    _hSyncing = true;
    final offset = _hScrollController.offset;
    if (_hHeaderController.hasClients && _hHeaderController.offset != offset) {
      _hHeaderController.jumpTo(offset);
    }
    _hSyncing = false;
  }

  // Total table width for horizontal scrolling
  static double get _tableWidth =>
      _colCheck +
      _colIdx +
      _colProductCode +
      _colProductName +
      _colModelCode +
      _colColor +
      _colActQty +
      _colInvQty +
      _colUnitUsd +
      _colUnitAzn +
      _colInvTotal +
      _colActTotal +
      _colBarcode +
      _colCoord +
      _colSource +
      _colInventory +
      _colStatus +
      _colActions;

  // ── Column widths ────────────────────────────────────────────────────────────
  static const double _colCheck = 48;
  static const double _colIdx = 48;
  static const double _colProductCode = 120;
  static const double _colProductName = 160;
  static const double _colModelCode = 120;
  static const double _colColor = 120;
  static const double _colActQty = 100;
  static const double _colInvQty = 100;
  static const double _colUnitUsd = 120;
  static const double _colUnitAzn = 120;
  static const double _colInvTotal = 130;
  static const double _colActTotal = 130;
  static const double _colBarcode = 150;
  static const double _colCoord = 120;
  static const double _colSource = 130;
  static const double _colInventory = 150;
  static const double _colStatus = 120;
  static const double _colActions = 116;

  @override
  void initState() {
    super.initState();
    _hScrollController.addListener(_onHScroll);
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    // Collect the product models for the selected IDs
    final loaded = context.read<InventoryProductsCubit>().state;
    if (loaded is! InventoryProductsLoaded) return;

    final toDelete = loaded.products.where((p) => _selectedIds.contains(p.id)).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete ${toDelete.length} Product${toDelete.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete the following products? This action cannot be undone.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: toDelete.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (_, i) {
                        final p = toDelete[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.productGeneratedName ?? p.productName ?? '—',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  softWrap: true,
                                ),
                              ),
                              if (p.barcode != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  p.barcode!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text('Delete ${toDelete.length}'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cubit = context.read<InventoryProductsCubit>();

    // Fire all delete requests in parallel
    final results = await Future.wait(toDelete.map((p) async => (product: p, result: await cubit.deleteProduct(p.id))));

    if (!mounted) return;

    final failed = results.where((r) => r.result is Failure).toList();
    final successCount = results.length - failed.length;

    if (successCount > 0) {
      setState(() => _selectedIds.removeWhere((id) => results.where((r) => r.result is Success).map((r) => r.product.id).contains(id)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount product${successCount == 1 ? '' : 's'} deleted successfully.'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (failed.isNotEmpty) {
      final errorLines = failed
          .map((r) {
            final name = r.product.productGeneratedName ?? r.product.productName ?? r.product.id;
            final msg = (r.result as Failure).message;
            return '• $name: $msg';
          })
          .join('\n');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${failed.length} deletion${failed.length == 1 ? '' : 's'} failed:\n$errorLines',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // ── Derived stats from filtered/all list ──────────────────────────────────
  List<InventoryProductItemModel> get _allProductsFromState {
    final s = context.read<InventoryProductsCubit>().state;
    return s is InventoryProductsLoaded ? s.products : [];
  }

  int get _totalQty => _allProductsFromState.fold(0, (s, p) => s + (p.actualQuantity ?? 0));
  double get _totalValue => _allProductsFromState.fold(0.0, (s, p) => s + (p.actualTotalPrice ?? 0.0));
  int get _inStockCount => _allProductsFromState.where((p) => _productStatus(p) == 'in_stock').length;
  int get _lowStockCount => _allProductsFromState.where((p) => _productStatus(p) == 'low_stock').length;
  int get _outCount => _allProductsFromState.where((p) => _productStatus(p) == 'out_of_stock').length;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _productStatus(InventoryProductItemModel p) {
    final qty = p.actualQuantity ?? 0;
    if (qty == 0) return 'out_of_stock';
    if (qty <= 10) return 'low_stock';
    return 'in_stock';
  }

  String _locationLabel(InventoryProductItemModel p) {
    final z = p.locationZone ?? '';
    final r = p.locationRow ?? '';
    final s = p.locationShelf ?? '';
    if (z.isEmpty && r.isEmpty && s.isEmpty) return '—';
    return '$z-$r-$s';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _hScrollController.removeListener(_onHScroll);
    _hScrollController.dispose();
    _hHeaderController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryProductsCubit, InventoryProductsState>(
      listener: (context, state) {
        // Clear selection when page data changes
        if (state is InventoryProductsLoaded) {
          setState(() {
            _selectedIds.removeWhere((id) => !state.products.any((p) => p.id == id));
          });
        }
      },
      builder: (context, state) {
        return Padding(
          padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: context.isMobile ? 16 : 20),
              _buildStatsRow(),
              SizedBox(height: context.isMobile ? 16 : 20),
              _buildFilterBar(state),
              SizedBox(height: context.isMobile ? 12 : 16),
              Expanded(child: _buildTable(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inventoryProducts,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(l10n.trackStockLevels, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_selectedIds.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text('${l10n.delete} (${_selectedIds.length})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: _selectedIds.isEmpty ? 1 : 0,
                child: FilledButton.icon(
                  onPressed: _showAddChoiceDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addProduct),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryProducts,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 2),
            Text(l10n.trackStockLevels, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        const Spacer(),
        if (_selectedIds.isNotEmpty) ...[
          Text(
            '${_selectedIds.length} ${l10n.selected}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text(l10n.delete),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: _showAddChoiceDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.addProduct),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ── Choice dialog ────────────────────────────────────────────────────────────
  void _showAddChoiceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 480,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_box_rounded, color: Color(0xFF6366F1), size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.addProduct,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.chooseHowToAddProduct,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _OptionCard(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF6366F1),
                        iconBg: const Color(0xFFEEF2FF),
                        title: l10n.manualEntry,
                        subtitle: l10n.fillProductDetails,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          _showProductDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _OptionCard(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        iconBg: const Color(0xFFE0F2FE),
                        title: l10n.fromInvoice,
                        subtitle: l10n.importFromInvoice,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          _showInvoicePickerDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF94A3B8))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvoicePickerDialog() {
    showDialog(
      context: context,
      builder: (_) => _InvoicePickerDialog(
        inventoryProductsCubit: context.read<InventoryProductsCubit>(),
        onDone: () {
          // List refreshed inside dialog after each successful import
        },
      ),
    );
  }

  // _showInvoiceRowsDialog is no longer needed — _InvoicePickerDialog navigates internally.

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final allCount = _allProductsFromState.length;

    final stats = [
      _StatCard(label: l10n.totalSKUs, value: '$allCount', icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1)),
      _StatCard(label: l10n.totalUnits, value: '$_totalQty ${l10n.pcs}', icon: Icons.layers_outlined, color: const Color(0xFF0EA5E9)),
      _StatCard(label: l10n.totalValue, value: '\$${_totalValue.toStringAsFixed(2)}', icon: Icons.payments_outlined, color: const Color(0xFF22C55E)),
      _StatCard(label: l10n.inStock, value: '$_inStockCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E)),
      _StatCard(label: l10n.lowStock, value: '$_lowStockCount', icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
      _StatCard(label: l10n.outOfStock, value: '$_outCount', icon: Icons.remove_circle_outline_rounded, color: const Color(0xFFEF4444)),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 12), SizedBox(width: 140, child: stats[i])],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: stats[i])],
      ],
    );
  }

  Widget _buildFilterBar(InventoryProductsState state) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final searchWidth = isMobile ? MediaQuery.of(context).size.width - (context.responsivePadding * 2) : 300.0;
    final totalCount = state is InventoryProductsLoaded ? state.totalCount : 0;
    final pageCount = state is InventoryProductsLoaded ? state.products.length : 0;

    return Column(
      children: [
        // Search field - full width on mobile
        SizedBox(
          width: isMobile ? double.infinity : searchWidth,
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                context.read<InventoryProductsCubit>().updateSearch(v);
              });
            },
            decoration: InputDecoration(
              hintText: l10n.searchSKUNameBarcode,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Stock status filter chips + result count
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: l10n.all,
                selected: _activeStatusFilter == null,
                onTap: () {
                  setState(() => _activeStatusFilter = null);
                  context.read<InventoryProductsCubit>().updateStatusFilter(null);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.inStock,
                selected: _activeStatusFilter == 'in_stock',
                color: const Color(0xFF22C55E),
                onTap: () {
                  setState(() => _activeStatusFilter = 'in_stock');
                  context.read<InventoryProductsCubit>().updateStatusFilter('in_stock');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.lowStock,
                selected: _activeStatusFilter == 'low_stock',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  setState(() => _activeStatusFilter = 'low_stock');
                  context.read<InventoryProductsCubit>().updateStatusFilter('low_stock');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.outOfStock,
                selected: _activeStatusFilter == 'out_of_stock',
                color: const Color(0xFFEF4444),
                onTap: () {
                  setState(() => _activeStatusFilter = 'out_of_stock');
                  context.read<InventoryProductsCubit>().updateStatusFilter('out_of_stock');
                },
              ),
              const SizedBox(width: 16),
              Text(l10n.nOfMProducts(pageCount, totalCount), style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTable(InventoryProductsState state) {
    final products = state is InventoryProductsLoaded ? state.products : <InventoryProductItemModel>[];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Sticky header ─────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _hHeaderController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(width: _tableWidth, child: _buildHeaderRow(products)),
          ),
          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: switch (state) {
              InventoryProductsLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              InventoryProductsError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<InventoryProductsCubit>().refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    ),
                  ],
                ),
              ),
              _ when products.isEmpty => Center(
                child: Text(AppLocalizations.of(context)!.noProductsMatchSearch, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              ),
              _ => Stack(
                children: [
                  SingleChildScrollView(
                    controller: _hScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _tableWidth,
                      child: Scrollbar(
                        controller: _vScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.separated(
                          controller: _vScrollController,
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (_, i) => _buildProductRow(i, products[i]),
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
            },
          ),
          // ── Pagination footer ─────────────────────────────────────────────
          if (state is InventoryProductsLoaded) _buildPaginationFooter(state),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(InventoryProductsLoaded state) {
    final cubit = context.read<InventoryProductsCubit>();
    final currentPage = state.currentPage;
    final totalPages = state.totalPages;
    final pageSize = state.pageSize;
    final totalCount = state.totalCount;
    final startItem = totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final endItem = ((currentPage * pageSize) < totalCount ? currentPage * pageSize : totalCount);

    // Build a compact list of page numbers with ellipsis
    List<int?> pageNumbers() {
      if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
      final pages = <int?>[];
      pages.add(1);
      if (currentPage > 3) pages.add(null); // ellipsis
      for (int p = (currentPage - 1).clamp(2, totalPages - 1); p <= (currentPage + 1).clamp(2, totalPages - 1); p++) {
        pages.add(p);
      }
      if (currentPage < totalPages - 2) pages.add(null); // ellipsis
      pages.add(totalPages);
      return pages;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text('Showing $startItem–$endItem of $totalCount', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          // Previous
          _PaginationBtn(icon: Icons.chevron_left_rounded, enabled: currentPage > 1, onTap: () => cubit.goToPage(currentPage - 1)),
          const SizedBox(width: 4),
          // Page number buttons
          ...pageNumbers().map((p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              );
            }
            final isActive = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: isActive ? null : () => cubit.goToPage(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Next
          _PaginationBtn(icon: Icons.chevron_right_rounded, enabled: currentPage < totalPages, onTap: () => cubit.goToPage(currentPage + 1)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(List<InventoryProductItemModel> products) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCell('#', _colIdx),
            _headerCell(l10n.productCode, _colProductCode),
            _headerCell(l10n.productName, _colProductName),
            _headerCell(l10n.model, _colModelCode),
            _headerCell(l10n.color, _colColor),
            _headerCell(l10n.actualQty, _colActQty),
            _headerCell(l10n.invoiceQty, _colInvQty),
            _headerCell('${l10n.unitPrice} (USD)', _colUnitUsd),
            _headerCell('${l10n.unitPrice} (AZN)', _colUnitAzn),
            _headerCell('${l10n.invoiceTotal} (USD)', _colInvTotal),
            _headerCell('${l10n.actualTotal} (AZN)', _colActTotal),
            _headerCell(l10n.barcode, _colBarcode),
            _headerCell(l10n.location, _colCoord),
            _headerCell(l10n.source, _colSource),
            _headerCell(l10n.sourceInventory, _colInventory),
            _headerCell(l10n.status, _colStatus),
            SizedBox(width: _colActions),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: Color(0xFF475569)),
        softWrap: true,
      ),
    );
  }

  Widget _buildProductRow(int index, InventoryProductItemModel product) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedIds.contains(product.id);
    final isOdd = index.isOdd;
    final rowBg = isSelected
        ? const Color(0xFFEEF2FF)
        : isOdd
        ? const Color(0xFFFAFAFA)
        : Colors.white;
    final status = _productStatus(product);
    final actualQty = product.actualQuantity ?? 0;
    final invoiceQty = product.invoiceQuantity;
    final qtyDiscrepancy = invoiceQty != null ? actualQty - invoiceQty : null;
    final hasDiscrepancy = qtyDiscrepancy != null && qtyDiscrepancy != 0;
    final colorStr = product.color ?? '—';
    final location = _locationLabel(product);

    return InkWell(
      onTap: () {},
      child: Container(
        color: rowBg,
        child: Row(
          children: [
            _cell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            // Product code
            _cell(
              product.productCode ?? '—',
              _colProductCode,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
            ),
            // Product name
            _cell(
              product.productName ?? '—',
              _colProductName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            // Model code
            _cell(product.modelCode ?? '—', _colModelCode, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            // Color
            SizedBox(
              width: _colColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(colorStr, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)), softWrap: true),
              ),
            ),
            // Actual Qty
            SizedBox(
              width: _colActQty,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '$actualQty',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status == 'out_of_stock'
                              ? const Color(0xFFEF4444)
                              : status == 'low_stock'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF1E293B),
                        ),
                        softWrap: true,
                      ),
                    ),
                    if (hasDiscrepancy) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: l10n.discrepancyTooltip('${qtyDiscrepancy > 0 ? '+' : ''}$qtyDiscrepancy'),
                        child: Icon(
                          qtyDiscrepancy > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: qtyDiscrepancy > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Invoice Qty
            _cell(
              invoiceQty != null ? '$invoiceQty' : '—',
              _colInvQty,
              style: TextStyle(fontSize: 13, color: invoiceQty != null ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
            // Unit price USD
            _cell(
              product.invoiceUnitPriceUsd != null ? '\$${product.invoiceUnitPriceUsd!.toStringAsFixed(4)}' : '—',
              _colUnitUsd,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            // Unit price AZN
            _cell(
              product.invoiceUnitPriceAzn != null ? '₼${product.invoiceUnitPriceAzn!.toStringAsFixed(4)}' : '—',
              _colUnitAzn,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            // Invoice Total (USD)
            _cell(
              product.invoiceTotalPrice != null ? '\$${product.invoiceTotalPrice!.toStringAsFixed(2)}' : '—',
              _colInvTotal,
              style: TextStyle(fontSize: 13, color: product.invoiceTotalPrice != null ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
            // Actual Total (AZN)
            _cell(
              product.actualTotalPrice != null ? '₼${product.actualTotalPrice!.toStringAsFixed(2)}' : '—',
              _colActTotal,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            // Barcode
            SizedBox(
              width: _colBarcode,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        product.barcode ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Location
            SizedBox(
              width: _colCoord,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                    softWrap: true,
                  ),
                ),
              ),
            ),
            // Source
            SizedBox(
              width: _colSource,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: product.source != null && product.source!.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.source!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
              ),
            ),
            // Inventory
            SizedBox(
              width: _colInventory,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: product.inventoryName != null && product.inventoryName!.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.warehouse_outlined, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.inventoryName!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
              ),
            ),
            // Status
            SizedBox(
              width: _colStatus,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _ApiStatusBadge(status: status),
              ),
            ),
            // Actions
            SizedBox(
              width: _colActions,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconBtn(icon: Icons.print_rounded, tooltip: 'Print', color: const Color(0xFF6366F1), onTap: () => _showPrintDialog(product)),
                    _IconBtn(icon: Icons.edit_outlined, tooltip: l10n.edit, color: const Color(0xFF8B5CF6), onTap: () => _showEditDialog(product)),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      tooltip: l10n.delete,
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDeleteProduct(product),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, {TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: style ?? const TextStyle(fontSize: 13, color: Color(0xFF475569)), softWrap: true),
        ),
      ),
    );
  }

  // ── Print barcode ────────────────────────────────────────────────────────────
  void _showPrintDialog(InventoryProductItemModel product) {
    final countCtrl = TextEditingController(text: '${product.actualQuantity ?? 1}');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.print_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Print Barcode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrintInfoRow(label: 'Barcode', value: product.barcode ?? '—'),
              const SizedBox(height: 6),
              _PrintInfoRow(label: 'Product', value: product.productGeneratedName ?? product.productName ?? '—'),
              const SizedBox(height: 16),
              const Text(
                'Count',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            FilledButton.icon(
              onPressed: () {
                final count = int.tryParse(countCtrl.text.trim()) ?? 1;
                Navigator.of(ctx).pop();
                _printProduct(product, count);
              },
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text('Print'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printProduct(InventoryProductItemModel product, int count) async {
    try {
      final Dio dio = DioClient.instance;
      await dio.post(
        'http://localhost:3000/print-barcode',
        data: {'barcode': product.barcode ?? '', 'productName': product.productGeneratedName ?? product.productName ?? '', 'count': count},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printed $count label${count == 1 ? '' : 's'} for ${product.productGeneratedName ?? product.productName ?? ''}'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?.toString() ?? e.message ?? 'Printer error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.print_disabled_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Print failed: $msg', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(
        product: product,
        cubit: context.read<InventoryProductsCubit>(),
        onCreated: () {
          // List is refreshed inside the cubit after creation
        },
      ),
    );
  }

  // ── Delete confirmation dialog ───────────────────────────────────────────────
  Future<void> _confirmDeleteProduct(InventoryProductItemModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this product? This action cannot be undone.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.productGeneratedName ?? product.productName ?? '—',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cubit = context.read<InventoryProductsCubit>();
    final result = await cubit.deleteProduct(product.id);

    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.productGeneratedName ?? product.productName ?? 'Product'} deleted successfully.'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Delete failed: $message', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  // ── Edit dialog dispatcher ────────────────────────────────────────────────────
  void _showEditDialog(InventoryProductItemModel product) {
    final isManual = (product.source ?? '').toLowerCase() == 'manual' || product.source == null || product.source!.isEmpty;
    if (isManual) {
      showDialog(
        context: context,
        builder: (_) => _EditManualProductDialog(product: product, cubit: context.read<InventoryProductsCubit>()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _EditInvoiceProductDialog(product: product, cubit: context.read<InventoryProductsCubit>()),
      );
    }
  }
}

// ── Shared price rounding helper (mirrors CreateInventoryProductRequestModel) ──
double _roundPrice(double value) => double.parse(value.toStringAsFixed(10));

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Manual Product Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _EditManualProductDialog extends StatefulWidget {
  final InventoryProductItemModel product;
  final InventoryProductsCubit cubit;

  const _EditManualProductDialog({required this.product, required this.cubit});

  @override
  State<_EditManualProductDialog> createState() => _EditManualProductDialogState();
}

class _EditManualProductDialogState extends State<_EditManualProductDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String _barcodeType = 'preprinted';

  // Selected inventory UUID (nullable = no inventory assigned)
  String? _selectedInventoryId;

  late final TextEditingController _productCode;
  late final TextEditingController _productName;
  late final TextEditingController _modelCode;
  late final TextEditingController _color;
  late final TextEditingController _colorCode;
  late final TextEditingController _size;
  late final TextEditingController _barcode;
  late final TextEditingController _actualQty;
  late final TextEditingController _unitPriceAzn;
  late final TextEditingController _actualPcsPerCarton;
  late final TextEditingController _actualCartonCount;
  late final TextEditingController _zone;
  late final TextEditingController _row;
  late final TextEditingController _shelf;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _selectedInventoryId = (p.inventory != null && p.inventory!.isNotEmpty) ? p.inventory : null;
    _productCode = TextEditingController(text: p.productCode ?? '');
    _productName = TextEditingController(text: p.productName ?? '');
    _modelCode = TextEditingController(text: p.modelCode ?? '');
    _color = TextEditingController(text: p.color ?? '');
    _colorCode = TextEditingController(text: p.colorCode ?? '');
    _size = TextEditingController(text: p.size ?? '');
    _barcode = TextEditingController(text: p.barcode ?? '');
    _barcodeType = p.barcodeType ?? 'preprinted';
    _barcode.addListener(() {
      if (_barcodeType != 'generated') _barcodeType = 'preprinted';
    });
    _actualQty = TextEditingController(text: p.actualQuantity != null ? '${p.actualQuantity}' : '');
    _unitPriceAzn = TextEditingController(text: p.invoiceUnitPriceAzn != null ? p.invoiceUnitPriceAzn!.toStringAsFixed(4) : '');
    _actualPcsPerCarton = TextEditingController(text: p.actualPiecesPerCarton != null ? '${p.actualPiecesPerCarton}' : '');
    _actualCartonCount = TextEditingController(text: p.actualCartonCount != null ? '${p.actualCartonCount}' : '');
    _zone = TextEditingController(text: p.locationZone ?? '');
    _row = TextEditingController(text: p.locationRow ?? '');
    _shelf = TextEditingController(text: p.locationShelf ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _productCode,
      _productName,
      _modelCode,
      _color,
      _colorCode,
      _size,
      _barcode,
      _actualQty,
      _unitPriceAzn,
      _actualPcsPerCarton,
      _actualCartonCount,
      _zone,
      _row,
      _shelf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final actualQty = int.tryParse(_actualQty.text.trim()) ?? 0;
    final actualPcs = int.tryParse(_actualPcsPerCarton.text.trim()) ?? 0;
    final actualCartons = int.tryParse(_actualCartonCount.text.trim()) ?? 0;
    final unitPriceAzn = double.tryParse(_unitPriceAzn.text.trim()) ?? 0.0;
    final actualTotalPrice = unitPriceAzn * actualQty;

    final data = <String, dynamic>{
      'product_code': _productCode.text.trim(),
      'model_code': _modelCode.text.trim(),
      'product_name': _productName.text.trim(),
      'size': _size.text.trim(),
      'color': _color.text.trim(),
      'color_code': _colorCode.text.trim(),
      'barcode': _barcode.text.trim(),
      'barcode_type': _barcodeType,
      'actual_quantity': actualQty,
      'actual_total_price': _roundPrice(actualTotalPrice),
      'invoice_unit_price_azn': _roundPrice(unitPriceAzn),
      'actual_pieces_per_carton': actualPcs,
      'actual_carton_count': actualCartons,
      'location_zone': _zone.text.trim().toUpperCase(),
      'location_row': _row.text.trim(),
      'location_shelf': _shelf.text.trim(),
      'inventory': _selectedInventoryId,
    };

    setState(() => _isSaving = true);
    final result = await widget.cubit.updateProduct(widget.product.id, data);
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSavedSuccess),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      case Failure(:final message):
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSaveFailed(message)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Product',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              widget.product.productGeneratedName ?? widget.product.productName ?? '—',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),

                  // ── Product Info ──────────────────────────────────────────────
                  _sectionHeader(Icons.inventory_2_outlined, l10n.productInfoSection),
                  const SizedBox(height: 12),
                  _field(_productCode, 'Product Code', 'e.g. PC-001', required: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_productName, l10n.productName, 'e.g. X-1-black', required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_modelCode, l10n.modelField, 'e.g. X-1', required: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_color, l10n.colorField, 'e.g. Black')),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_colorCode, l10n.colorCodeField, 'e.g. BL')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_size, l10n.sizeField, 'e.g. M / 42')),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field(_barcode, l10n.barcodeField, 'e.g. 1234500001', required: true),
                            const SizedBox(height: 4),
                            _GenerateBarcodeButton(ctrl: _barcode, onGenerated: (_) => setState(() => _barcodeType = 'generated')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_actualQty, l10n.actualQtyReceived, '0', isNumber: true, required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_unitPriceAzn, 'Unit Price (AZN)', '0.00', isDecimal: true)),
                    ],
                  ),
                  // Live total preview
                  ValueListenableBuilder(
                    valueListenable: _actualQty,
                    builder: (_, __, ___) => ValueListenableBuilder(
                      valueListenable: _unitPriceAzn,
                      builder: (_, __, ___) {
                        final qty = int.tryParse(_actualQty.text.trim());
                        final unitPrice = double.tryParse(_unitPriceAzn.text.trim());
                        final total = (qty != null && unitPrice != null) ? qty * unitPrice : null;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: total == null
                              ? const SizedBox.shrink()
                              : Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calculate_rounded, size: 14, color: Color(0xFF15803D)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Total Price: ₼${total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Inventory Selection ───────────────────────────────────────
                  _InventoryDropdown(
                    selectedId: _selectedInventoryId,
                    enabled: !_isSaving,
                    required: true,
                    onChanged: (id) => setState(() => _selectedInventoryId = id),
                  ),

                  const SizedBox(height: 20),

                  // ── Packaging ─────────────────────────────────────────────────
                  _sectionHeader(Icons.inventory_outlined, l10n.packagingSection),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_actualPcsPerCarton, l10n.actualPcsPerCarton, '0', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_actualCartonCount, l10n.actualCartonCount, '0', isNumber: true)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Warehouse Location ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.warehouseLocation,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _field(_zone, l10n.zone, 'A', required: true, hint: l10n.zoneLetter)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_row, l10n.row, '1', isNumber: true, required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_shelf, l10n.shelf, '1', isNumber: true, required: true)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder(
                          valueListenable: _zone,
                          builder: (_, __, ___) => ValueListenableBuilder(
                            valueListenable: _row,
                            builder: (_, __, ___) => ValueListenableBuilder(
                              valueListenable: _shelf,
                              builder: (_, __, ___) {
                                final z = _zone.text.toUpperCase();
                                final r = _row.text;
                                final s = _shelf.text;
                                if (z.isEmpty || r.isEmpty || s.isEmpty) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.locationCode('$z-$r-$s'),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ────────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 16),
                          label: Text(_isSaving ? l10n.savingProduct : 'Save Changes'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String placeholder, {
    bool required = false,
    bool isNumber = false,
    bool isDecimal = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            if (required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          enabled: !_isSaving,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.required : null : null,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint ?? placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Invoice Product Dialog (source != 'manual')
// Invoice fields are read-only; only actual qty, barcode, exchange rate,
// packaging and location can be edited.
// ═══════════════════════════════════════════════════════════════════════════════
class _EditInvoiceProductDialog extends StatefulWidget {
  final InventoryProductItemModel product;
  final InventoryProductsCubit cubit;

  const _EditInvoiceProductDialog({required this.product, required this.cubit});

  @override
  State<_EditInvoiceProductDialog> createState() => _EditInvoiceProductDialogState();
}

class _EditInvoiceProductDialogState extends State<_EditInvoiceProductDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String _barcodeType = 'preprinted';

  // Selected inventory UUID (nullable = no inventory assigned)
  String? _selectedInventoryId;

  late final TextEditingController _productCode;
  late final TextEditingController _barcode;
  late final TextEditingController _actualQty;
  late final TextEditingController _exchangeRate;
  late final TextEditingController _actualPcsPerCarton;
  late final TextEditingController _actualCartonCount;
  late final TextEditingController _zone;
  late final TextEditingController _row;
  late final TextEditingController _shelf;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _selectedInventoryId = (p.inventory != null && p.inventory!.isNotEmpty) ? p.inventory : null;
    _productCode = TextEditingController(text: p.productCode ?? '');
    _barcode = TextEditingController(text: p.barcode ?? '');
    _barcodeType = p.barcodeType ?? 'preprinted';
    _barcode.addListener(() {
      if (_barcodeType != 'generated') _barcodeType = 'preprinted';
    });
    _actualQty = TextEditingController(text: p.actualQuantity != null ? '${p.actualQuantity}' : '');
    // Derive exchange rate from stored prices if available, else default 1.70
    double initialRate = 1.70;
    if (p.invoiceUnitPriceUsd != null && p.invoiceUnitPriceAzn != null && p.invoiceUnitPriceUsd! > 0) {
      initialRate = p.invoiceUnitPriceAzn! / p.invoiceUnitPriceUsd!;
    }
    _exchangeRate = TextEditingController(text: initialRate.toStringAsFixed(2));
    _actualPcsPerCarton = TextEditingController(text: p.actualPiecesPerCarton != null ? '${p.actualPiecesPerCarton}' : '');
    _actualCartonCount = TextEditingController(text: p.actualCartonCount != null ? '${p.actualCartonCount}' : '');
    _zone = TextEditingController(text: p.locationZone ?? '');
    _row = TextEditingController(text: p.locationRow ?? '');
    _shelf = TextEditingController(text: p.locationShelf ?? '');
  }

  @override
  void dispose() {
    for (final c in [_productCode, _barcode, _actualQty, _exchangeRate, _actualPcsPerCarton, _actualCartonCount, _zone, _row, _shelf]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final actualQty = int.tryParse(_actualQty.text.trim()) ?? 0;
    final actualPcs = int.tryParse(_actualPcsPerCarton.text.trim()) ?? 0;
    final actualCartons = int.tryParse(_actualCartonCount.text.trim()) ?? 0;
    final exchangeRate = double.tryParse(_exchangeRate.text.trim()) ?? 1.70;
    final unitPriceUsd = widget.product.invoiceUnitPriceUsd ?? 0.0;
    final unitPriceAzn = unitPriceUsd * exchangeRate;
    final actualTotalPrice = unitPriceAzn * actualQty;

    final data = <String, dynamic>{
      'product_code': _productCode.text.trim(),
      'barcode': _barcode.text.trim(),
      'barcode_type': _barcodeType,
      'actual_quantity': actualQty,
      'invoice_unit_price_azn': _roundPrice(unitPriceAzn),
      'actual_total_price': _roundPrice(actualTotalPrice),
      'actual_pieces_per_carton': actualPcs,
      'actual_carton_count': actualCartons,
      'location_zone': _zone.text.trim().toUpperCase(),
      'location_row': _row.text.trim(),
      'location_shelf': _shelf.text.trim(),
      'inventory': _selectedInventoryId,
    };

    setState(() => _isSaving = true);
    final result = await widget.cubit.updateProduct(widget.product.id, data);
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSavedSuccess),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      case Failure(:final message):
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSaveFailed(message)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.product;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 640,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Invoice Product',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              p.productGeneratedName ?? p.productName ?? '—',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      if (p.source != null && p.source!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF0284C7)),
                              const SizedBox(width: 4),
                              Text(
                                p.source!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // ── Read-only product info banner ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            const Text(
                              'Invoice Details (read-only)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (p.productName != null) _InfoChip(label: 'Product', value: p.productName!),
                            if (p.modelCode != null) _InfoChip(label: 'Model', value: p.modelCode!),
                            if (p.color != null && p.color!.isNotEmpty) _InfoChip(label: 'Color', value: p.color!),
                            if (p.size != null && p.size!.isNotEmpty) _InfoChip(label: 'Size', value: p.size!),
                            if (p.invoiceQuantity != null) _InfoChip(label: 'Invoice Qty', value: '${p.invoiceQuantity}'),
                            if (p.invoiceUnitPriceUsd != null)
                              _InfoChip(label: 'Unit Price (USD)', value: '\$${p.invoiceUnitPriceUsd!.toStringAsFixed(4)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Product Code ──────────────────────────────────────────────
                  _detailField(_productCode, 'Product Code', 'e.g. PC-001', required: true, icon: Icons.tag_rounded),
                  const SizedBox(height: 16),

                  // ── Barcode + Actual Qty ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailField(_barcode, l10n.barcodeField, 'e.g. 6901234500010', required: true, icon: Icons.qr_code_rounded),
                            const SizedBox(height: 4),
                            _GenerateBarcodeButton(ctrl: _barcode, onGenerated: (_) => setState(() => _barcodeType = 'generated')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _detailField(
                          _actualQty,
                          l10n.actualQtyReceived,
                          '${p.invoiceQuantity ?? 0}',
                          required: true,
                          isNumber: true,
                          icon: Icons.numbers_rounded,
                          suffixWidget: ValueListenableBuilder(
                            valueListenable: _actualQty,
                            builder: (_, __, ___) {
                              final actual = int.tryParse(_actualQty.text);
                              if (actual == null) return const SizedBox.shrink();
                              final diff = actual - (p.invoiceQuantity ?? 0);
                              if (diff == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      size: 12,
                                      color: diff > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      l10n.vsInvoice('${diff > 0 ? '+' : ''}$diff'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: diff > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Price Calculation ─────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, size: 15, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 6),
                      const Text(
                        'Price Calculation',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Unit Price USD (locked)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unit Price (USD)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${(p.invoiceUnitPriceUsd ?? 0.0).toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 12),
                      // Exchange Rate
                      Expanded(
                        flex: 2,
                        child: _detailField(_exchangeRate, 'Exchange Rate', '1.70', isDecimal: true, icon: Icons.currency_exchange_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 12),
                      // Unit Price AZN (computed)
                      Expanded(
                        flex: 2,
                        child: ValueListenableBuilder(
                          valueListenable: _exchangeRate,
                          builder: (_, __, ___) {
                            final rate = double.tryParse(_exchangeRate.text.trim()) ?? 1.70;
                            final aznPrice = (p.invoiceUnitPriceUsd ?? 0.0) * rate;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unit Price (AZN)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF6366F1)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '₼${aznPrice.toStringAsFixed(4)}',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Live total preview
                  ValueListenableBuilder(
                    valueListenable: _actualQty,
                    builder: (_, __, ___) => ValueListenableBuilder(
                      valueListenable: _exchangeRate,
                      builder: (_, __, ___) {
                        final rate = double.tryParse(_exchangeRate.text.trim()) ?? 1.70;
                        final unitPriceAzn = (p.invoiceUnitPriceUsd ?? 0.0) * rate;
                        final qty = int.tryParse(_actualQty.text.trim());
                        final total = qty != null ? qty * unitPriceAzn : null;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: total == null
                              ? const SizedBox.shrink()
                              : Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calculate_rounded, size: 14, color: Color(0xFF15803D)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Total: ₼${total.toStringAsFixed(2)} ($qty × ₼${unitPriceAzn.toStringAsFixed(4)})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Inventory Selection ───────────────────────────────────────
                  _InventoryDropdown(
                    selectedId: _selectedInventoryId,
                    enabled: !_isSaving,
                    required: true,
                    onChanged: (id) => setState(() => _selectedInventoryId = id),
                  ),

                  const SizedBox(height: 20),

                  // ── Faktiki Əd/Karton & Faktiki Karton Sayı ───────────────────
                  Row(
                    children: [
                      const Icon(Icons.widgets_outlined, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.packagingSection,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _detailField(
                          _actualPcsPerCarton,
                          l10n.actualPcsPerCarton,
                          '${p.actualPiecesPerCarton ?? 0}',
                          isNumber: true,
                          icon: Icons.widgets_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailField(
                          _actualCartonCount,
                          l10n.actualCartonCount,
                          '${p.actualCartonCount ?? 0}',
                          isNumber: true,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Warehouse Location ────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.warehouseLocation,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _detailField(_zone, l10n.zone, 'A', required: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _detailField(_row, l10n.row, '1', isNumber: true, required: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _detailField(_shelf, l10n.shelf, '1', isNumber: true, required: true)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _zone,
                          builder: (_, __, ___) => ValueListenableBuilder(
                            valueListenable: _row,
                            builder: (_, __, ___) => ValueListenableBuilder(
                              valueListenable: _shelf,
                              builder: (_, __, ___) {
                                final z = _zone.text.toUpperCase();
                                final r = _row.text;
                                final s = _shelf.text;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.codeLabel,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 36,
                                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                      child: Center(
                                        child: Text(
                                          (z.isEmpty || r.isEmpty || s.isEmpty) ? '—' : '$z-$r-$s',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ────────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 16),
                          label: Text(_isSaving ? l10n.savingProduct : 'Save Changes'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailField(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool required = false,
    bool isNumber = false,
    bool isDecimal = false,
    IconData? icon,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: const Color(0xFF94A3B8)), const SizedBox(width: 4)],
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            if (required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          enabled: !_isSaving,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.required : null : null,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
        if (suffixWidget != null) suffixWidget,
      ],
    );
  }
}

// ── Small read-only info chip ─────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Picker Dialog — fetches real invoice list from API
// ═══════════════════════════════════════════════════════════════════════════════
class _InvoicePickerDialog extends StatefulWidget {
  final InventoryProductsCubit inventoryProductsCubit;
  final VoidCallback? onDone;

  const _InvoicePickerDialog({required this.inventoryProductsCubit, this.onDone});

  @override
  State<_InvoicePickerDialog> createState() => _InvoicePickerDialogState();
}

class _InvoicePickerDialogState extends State<_InvoicePickerDialog> {
  bool _loading = true;
  String? _error;
  List<InvoiceListItemModel> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await InvoiceListRepository.instance.fetchInvoices(page: 1, pageSize: 100);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _invoices = data.results;
          _loading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  void _onSelectInvoice(InvoiceListItemModel inv) {
    Navigator.of(context, rootNavigator: true).pop();
    showDialog(
      context: context,
      builder: (_) => _InvoiceRowsDialog(invoice: inv, inventoryProductsCubit: widget.inventoryProductsCubit, onDone: widget.onDone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectInvoice,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(l10n.chooseInvoiceToImport, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              // ── Body ──────────────────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400, minHeight: 120),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFEF4444)),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _fetchInvoices,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.retry),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                            ),
                          ],
                        ),
                      )
                    : _invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(l10n.noInvoicesAvailable, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Text(l10n.addInvoicesFirst, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final inv = _invoices[i];
                          return InkWell(
                            onTap: () => _onSelectInvoice(inv),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(Icons.description_rounded, size: 18, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inv.invoiceNumber ?? '—',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(inv.supplierName ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        l10n.nItemsInInvoice(inv.totalItemsCount),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                      if (inv.invoiceDate != null)
                                        Text(inv.invoiceDate!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Rows Dialog — fetches invoice detail, lets user pick rows,
// then posts each to POST /api/inventory-products/
// ═══════════════════════════════════════════════════════════════════════════════
class _InvoiceRowsDialog extends StatefulWidget {
  final InvoiceListItemModel invoice;
  final InventoryProductsCubit inventoryProductsCubit;
  final VoidCallback? onDone;

  const _InvoiceRowsDialog({required this.invoice, required this.inventoryProductsCubit, this.onDone});

  @override
  State<_InvoiceRowsDialog> createState() => _InvoiceRowsDialogState();
}

class _InvoiceRowsDialogState extends State<_InvoiceRowsDialog> {
  // ── Loading state for invoice detail ────────────────────────────────────────
  bool _loadingDetail = true;
  String? _detailError;
  InvoiceDetailModel? _detail;

  // ── Step & selection ─────────────────────────────────────────────────────────
  int _step = 0;
  final Set<int> _selected = {};

  // ── Inventory selection (shared for all imported rows) ───────────────────────
  String? _selectedInventoryId;

  // ── Per-row controllers (keyed by item index in _detail.items) ───────────────
  final Map<int, TextEditingController> _productCodeCtrl = {};
  final Map<int, TextEditingController> _barcodeCtrl = {};
  final Map<int, TextEditingController> _actualQtyCtrl = {};
  final Map<int, TextEditingController> _actPcsCtrl = {};
  final Map<int, TextEditingController> _actCartonsCtrl = {};
  final Map<int, TextEditingController> _zoneCtrl = {};
  final Map<int, TextEditingController> _rowCtrl = {};
  final Map<int, TextEditingController> _shelfCtrl = {};
  final Map<int, TextEditingController> _exchangeRateCtrl = {};
  // Tracks whether the barcode for each row was API-generated ('generated') or typed ('preprinted')
  final Map<int, String> _barcodeTypeMap = {};

  final _formKey = GlobalKey<FormState>();

  // ── Import progress ──────────────────────────────────────────────────────────
  bool _importing = false;
  int _importProgress = 0;
  // Maps item index → API error message for rows that failed to import.
  final Map<int, String> _rowErrors = {};

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    final result = await InvoiceDetailRepository.instance.fetchInvoiceDetail(widget.invoice.id);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _detail = data;
          _loadingDetail = false;
        });
      case Failure(:final message):
        setState(() {
          _detailError = message;
          _loadingDetail = false;
        });
    }
  }

  void _initControllersForSelected() {
    for (final idx in _selected) {
      // actual_* fields start EMPTY — user must fill them manually
      _barcodeCtrl.putIfAbsent(idx, () {
        final ctrl = TextEditingController();
        // Any manual edit → mark as 'preprinted'
        ctrl.addListener(() {
          if (_barcodeTypeMap[idx] != 'generated') {
            _barcodeTypeMap[idx] = 'preprinted';
          }
        });
        return ctrl;
      });
      _actualQtyCtrl.putIfAbsent(idx, () => TextEditingController());
      _actPcsCtrl.putIfAbsent(idx, () => TextEditingController());
      _actCartonsCtrl.putIfAbsent(idx, () => TextEditingController());
      _zoneCtrl.putIfAbsent(idx, () => TextEditingController());
      _rowCtrl.putIfAbsent(idx, () => TextEditingController());
      _shelfCtrl.putIfAbsent(idx, () => TextEditingController());
      _exchangeRateCtrl.putIfAbsent(idx, () => TextEditingController(text: '1.70')); // Default USD to AZN rate
      _productCodeCtrl.putIfAbsent(idx, () => TextEditingController());
      _barcodeTypeMap.putIfAbsent(idx, () => 'preprinted');
    }
  }

  @override
  void dispose() {
    for (final c in [
      ..._productCodeCtrl.values,
      ..._barcodeCtrl.values,
      ..._actualQtyCtrl.values,
      ..._actPcsCtrl.values,
      ..._actCartonsCtrl.values,
      ..._zoneCtrl.values,
      ..._rowCtrl.values,
      ..._shelfCtrl.values,
      ..._exchangeRateCtrl.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToStep2() {
    if (_selected.isEmpty) return;
    _initControllersForSelected();
    setState(() => _step = 1);
  }

  Future<void> _importProducts() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedInventoryId == null || _selectedInventoryId!.isEmpty) return;
    final items = _detail!.items;
    final selectedList = _selected.toList();

    setState(() {
      _importing = true;
      _importProgress = 0;
    });

    int successCount = 0;
    // Maps item index → error message for failed rows
    final Map<int, String> rowErrors = {};

    for (int i = 0; i < selectedList.length; i++) {
      final idx = selectedList[i];
      final item = items[idx];
      // actual_* fields come entirely from user input (form validates they're non-empty)
      final actualQty = int.tryParse(_actualQtyCtrl[idx]!.text.trim()) ?? 0;
      final actPcs = int.tryParse(_actPcsCtrl[idx]!.text.trim()) ?? 0;
      final actCartons = int.tryParse(_actCartonsCtrl[idx]!.text.trim()) ?? 0;
      // invoice_* fields come purely from the API response (item from _detail)
      final unitPriceUsd = item.unitPriceUsd ?? 0.0;
      final exchangeRate = double.tryParse(_exchangeRateCtrl[idx]!.text.trim()) ?? 1.70;
      // invoice_unit_price_azn = invoice_unit_price_usd × exchange_rate
      final unitPriceAzn = unitPriceUsd * exchangeRate;
      final invQty = item.quantity ?? 0;
      final invPcs = item.piecesPerCarton ?? 0;
      final invCartons = (item.cartonCount ?? 0).toInt();
      final invTotal = item.totalPrice ?? 0.0;
      // actual_total_price = invoice_unit_price_azn × actual_quantity
      final actualTotal = unitPriceAzn * actualQty;

      final request = CreateInventoryProductRequestModel(
        productCode: _productCodeCtrl[idx]!.text.trim(),
        productName: item.productName ?? '',
        modelCode: item.modelCode ?? '',
        color: item.color ?? '',
        colorCode: item.colorCode ?? '',
        size: item.size ?? '',
        barcode: _barcodeCtrl[idx]!.text.trim(),
        barcodeType: _barcodeTypeMap[idx] ?? 'preprinted',
        actualQuantity: actualQty,
        actualTotalPrice: actualTotal,
        actualPiecesPerCarton: actPcs,
        actualCartonCount: actCartons,
        locationZone: _zoneCtrl[idx]!.text.trim().toUpperCase(),
        locationRow: _rowCtrl[idx]!.text.trim(),
        locationShelf: _shelfCtrl[idx]!.text.trim(),
        // invoice-sourced fields — source is the invoice number (e.g. "INV-2024-001")
        source: widget.invoice.invoiceNumber ?? widget.invoice.id,
        invoice: widget.invoice.id,
        invoiceUnitPriceUsd: unitPriceUsd,
        invoiceUnitPriceAzn: unitPriceAzn,
        invoiceQuantity: invQty,
        invoiceTotalPrice: invTotal,
        invoicePiecesPerCarton: invPcs,
        invoiceCartonCount: invCartons,
        inventory: _selectedInventoryId,
      );

      // Post the product directly (no need to re-fetch invoice detail)
      final error = await _postProduct(request);

      if (!mounted) return;

      if (error == null) {
        successCount++;
      } else {
        rowErrors[idx] = error;
      }

      setState(() => _importProgress = i + 1);
    }

    if (!mounted) return;

    if (successCount > 0) widget.inventoryProductsCubit.refresh();

    Navigator.of(context, rootNavigator: true).pop();

    final messenger = ScaffoldMessenger.of(context);

    if (successCount > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.importSuccessN(successCount)),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (rowErrors.isNotEmpty) {
      // Show each failed product name + its error message
      final items = _detail!.items;
      final errorLines = rowErrors.entries
          .map((e) {
            final name = items[e.key].productName ?? 'Item ${e.key + 1}';
            return '$name: ${e.value}';
          })
          .join('\n');

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(errorLines, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    widget.onDone?.call();
  }

  /// Posts a single product and returns the error message on failure, or null on success.
  Future<String?> _postProduct(CreateInventoryProductRequestModel request) async {
    final result = await widget.inventoryProductsCubit.createProduct(request);
    return switch (result) {
      Success() => null,
      Failure(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800,
        height: 640,
        child: Column(
          children: [
            _buildHeader(l10n),
            if (!_loadingDetail && _detailError == null && _detail != null) _buildStepIndicator(l10n),
            Expanded(child: _buildBody(l10n)),
            if (!_loadingDetail && _detailError == null && _detail != null) _buildFooter(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importFromInvoiceNo(widget.invoice.invoiceNumber ?? widget.invoice.id),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(widget.invoice.supplierName ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            onPressed: _importing ? null : () => Navigator.of(context, rootNavigator: true).pop(),
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _StepBubble(number: 1, label: l10n.selectProducts, active: _step == 0, done: _step > 0),
          Expanded(child: Container(height: 2, color: _step > 0 ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0))),
          _StepBubble(number: 2, label: l10n.enterDetails, active: _step == 1, done: false),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadingDetail) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6366F1)),
            const SizedBox(height: 12),
            Text(l10n.loadingInvoiceDetail, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    if (_detailError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 8),
            Text(
              _detailError!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            ),
          ],
        ),
      );
    }
    if (_importing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF22C55E)),
            const SizedBox(height: 12),
            Text(l10n.importingProducts(_importProgress, _selected.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }
    return _step == 0 ? _buildStep1(l10n) : _buildStep2(l10n);
  }

  Widget _buildStep1(AppLocalizations l10n) {
    final items = _detail!.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: Row(
            children: [
              Text(l10n.nUniqueSkusFromInvoice(items.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  if (_selected.length == items.length)
                    _selected.clear();
                  else
                    _selected.addAll(List.generate(items.length, (i) => i));
                }),
                icon: Icon(_selected.length == items.length ? Icons.deselect_rounded : Icons.select_all_rounded, size: 16),
                label: Text(_selected.length == items.length ? l10n.deselectAll : l10n.selectAllLabel),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
        // Table header
        Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(flex: 3, child: _TH(l10n.productName)),
              Expanded(flex: 2, child: _TH(l10n.model)),
              Expanded(flex: 2, child: _TH(l10n.color)),
              Expanded(flex: 1, child: _TH(l10n.size)),
              Expanded(flex: 2, child: _TH(l10n.invQty)),
              Expanded(flex: 2, child: _TH(l10n.unitPrice)),
              Expanded(flex: 2, child: _TH(l10n.invTotal)),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final item = items[i];
              final isSelected = _selected.contains(i);
              return InkWell(
                onTap: () => setState(() {
                  if (isSelected)
                    _selected.remove(i);
                  else
                    _selected.add(i);
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.productName ?? '—',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(item.modelCode ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(item.color?.isEmpty ?? true ? '—' : item.color!, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(item.size?.isEmpty ?? true ? '—' : item.size!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.quantity ?? 0} ${l10n.pcs}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${(item.unitPriceUsd ?? 0).toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${(item.totalPrice ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    final items = _detail!.items;
    final selectedList = _selected.toList();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(l10n.fillWarehouseDetails(selectedList.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          // ── Inventory selection (applies to all imported rows) ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: _InventoryDropdown(
              selectedId: _selectedInventoryId,
              enabled: !_importing,
              required: true,
              onChanged: (id) => setState(() => _selectedInventoryId = id),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              itemCount: selectedList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, listIdx) {
                final idx = selectedList[listIdx];
                final item = items[idx];
                final rowError = _rowErrors[idx];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: rowError != null ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (item.modelCode?.isNotEmpty ?? false) ...[
                                        Text(item.modelCode!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        const SizedBox(width: 8),
                                      ],
                                      if (item.color?.isNotEmpty ?? false)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                                          child: Text(
                                            item.color!,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      if (item.colorCode?.isNotEmpty ?? false) ...[
                                        const SizedBox(width: 6),
                                        Text('(${item.colorCode})', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                l10n.invoiceQtyLabel(item.quantity ?? 0),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── API error banner (shown after a failed import attempt) ──
                      if (rowError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rowError,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Form fields
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // Product Code
                            _DetailField(
                              ctrl: _productCodeCtrl[idx]!,
                              label: 'Product Code',
                              hint: 'e.g. PC-001',
                              required: true,
                              icon: Icons.tag_rounded,
                            ),
                            const SizedBox(height: 10),
                            // Row 1: barcode + actual qty
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _DetailField(
                                        ctrl: _barcodeCtrl[idx]!,
                                        label: l10n.barcodeField,
                                        hint: 'e.g. 6901234500010',
                                        required: true,
                                        icon: Icons.qr_code_rounded,
                                      ),
                                      const SizedBox(height: 4),
                                      _GenerateBarcodeButton(
                                        ctrl: _barcodeCtrl[idx]!,
                                        onGenerated: (_) => setState(() => _barcodeTypeMap[idx] = 'generated'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _DetailField(
                                    ctrl: _actualQtyCtrl[idx]!,
                                    label: l10n.actualQtyReceived,
                                    hint: '${item.quantity ?? 0}',
                                    required: true,
                                    isNumber: true,
                                    icon: Icons.numbers_rounded,
                                    suffixWidget: ValueListenableBuilder(
                                      valueListenable: _actualQtyCtrl[idx]!,
                                      builder: (_, __, ___) {
                                        final actual = int.tryParse(_actualQtyCtrl[idx]!.text);
                                        if (actual == null) return const SizedBox.shrink();
                                        final diff = actual - (item.quantity ?? 0);
                                        if (diff == 0) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                                size: 12,
                                                color: diff > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                l10n.vsInvoice('${diff > 0 ? '+' : ''}$diff'),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: diff > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // ── Price calculation with exchange rate ──────────
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.attach_money_rounded, size: 15, color: Color(0xFF0EA5E9)),
                                const SizedBox(width: 6),
                                const Text(
                                  'Price Calculation',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Unit Price (USD)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 36,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 8),
                                            Text(
                                              '\$${(item.unitPriceUsd ?? 0.0).toStringAsFixed(4)}',
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _DetailField(
                                    ctrl: _exchangeRateCtrl[idx]!,
                                    label: 'Exchange Rate',
                                    hint: '1.70',
                                    isDecimal: true,
                                    icon: Icons.currency_exchange_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ValueListenableBuilder(
                                    valueListenable: _exchangeRateCtrl[idx]!,
                                    builder: (_, __, ___) {
                                      final unitPriceUsd = item.unitPriceUsd ?? 0.0;
                                      final exchangeRate = double.tryParse(_exchangeRateCtrl[idx]!.text.trim()) ?? 1.70;
                                      final unitPriceAzn = unitPriceUsd * exchangeRate;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Unit Price (AZN)',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF6366F1)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '₼${unitPriceAzn.toStringAsFixed(4)}',
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // ── Live actual_total_price preview ────────────────
                            ValueListenableBuilder(
                              valueListenable: _actualQtyCtrl[idx]!,
                              builder: (_, __, ___) => ValueListenableBuilder(
                                valueListenable: _exchangeRateCtrl[idx]!,
                                builder: (_, __, ___) {
                                  final unitPriceUsd = item.unitPriceUsd ?? 0.0;
                                  final exchangeRate = double.tryParse(_exchangeRateCtrl[idx]!.text.trim()) ?? 1.70;
                                  final unitPriceAzn = unitPriceUsd * exchangeRate;
                                  final qty = int.tryParse(_actualQtyCtrl[idx]!.text.trim());
                                  final total = qty != null ? qty * unitPriceAzn : null;
                                  return AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    child: total == null
                                        ? const SizedBox.shrink()
                                        : Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.calculate_rounded, size: 14, color: Color(0xFF15803D)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Total: ₼${total.toStringAsFixed(2)} ($qty × ₼${unitPriceAzn.toStringAsFixed(4)})',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Row 2: actual pcs/carton + actual carton count
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailField(
                                    ctrl: _actPcsCtrl[idx]!,
                                    label: l10n.actualPcsPerCarton,
                                    hint: '${item.piecesPerCarton ?? 0}',
                                    isNumber: true,
                                    icon: Icons.widgets_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DetailField(
                                    ctrl: _actCartonsCtrl[idx]!,
                                    label: l10n.actualCartonCount,
                                    hint: '${(item.cartonCount ?? 0).toInt()}',
                                    isNumber: true,
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Row 3: warehouse location
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF6366F1)),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.warehouseLocation,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _DetailField(ctrl: _zoneCtrl[idx]!, label: l10n.zone, hint: 'A', required: true),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DetailField(ctrl: _rowCtrl[idx]!, label: l10n.row, hint: '1', isNumber: true, required: true),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DetailField(ctrl: _shelfCtrl[idx]!, label: l10n.shelf, hint: '1', isNumber: true, required: true),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: _zoneCtrl[idx]!,
                                    builder: (_, __, ___) => ValueListenableBuilder(
                                      valueListenable: _rowCtrl[idx]!,
                                      builder: (_, __, ___) => ValueListenableBuilder(
                                        valueListenable: _shelfCtrl[idx]!,
                                        builder: (_, __, ___) {
                                          final z = _zoneCtrl[idx]!.text.toUpperCase();
                                          final r = _rowCtrl[idx]!.text;
                                          final s = _shelfCtrl[idx]!.text;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.codeLabel,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                height: 36,
                                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                                child: Center(
                                                  child: Text(
                                                    (z.isEmpty || r.isEmpty || s.isEmpty) ? '—' : '$z-$r-$s',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          if (_step == 1)
            OutlinedButton.icon(
              onPressed: _importing ? null : () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(l10n.back),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: const Color(0xFF475569),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF94A3B8))),
            ),
          const Spacer(),
          if (_step == 0) ...[
            Text(l10n.nOfMSelected(_selected.length, _detail!.items.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _goToStep2,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(l10n.nextEnterDetails),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: _importing ? null : _importProducts,
              icon: _importing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded, size: 16),
              label: Text(l10n.importNProducts(_selected.length)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step bubble ───────────────────────────────────────────────────────────────
class _StepBubble extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;

  const _StepBubble({required this.number, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final Color bg = done
        ? const Color(0xFF22C55E)
        : active
        ? const Color(0xFF6366F1)
        : const Color(0xFFE2E8F0);
    final Color fg = (done || active) ? Colors.white : const Color(0xFF94A3B8);
    final Color textColor = (done || active) ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
        ),
      ],
    );
  }
}

// ── Detail field for step-2 ───────────────────────────────────────────────────
class _DetailField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final bool isNumber;
  final bool isDecimal;
  final IconData? icon;
  final Widget? suffixWidget;

  const _DetailField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.isNumber = false,
    this.isDecimal = false,
    this.icon,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: const Color(0xFF94A3B8)), const SizedBox(width: 4)],
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            if (required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.required : null : null,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
        if (suffixWidget != null) suffixWidget!,
      ],
    );
  }
}

// ── Generate Barcode Button ───────────────────────────────────────────────────
/// A small button that calls POST /api/generate-barcode/ and fills [ctrl].
/// [onGenerated] is called with `true` after a successful API generation,
/// so the parent can set barcode_type = 'generated'.
class _GenerateBarcodeButton extends StatefulWidget {
  final TextEditingController ctrl;

  /// Called with `true` when the barcode was successfully generated via API.
  final ValueChanged<bool>? onGenerated;

  const _GenerateBarcodeButton({required this.ctrl, this.onGenerated});

  @override
  State<_GenerateBarcodeButton> createState() => _GenerateBarcodeButtonState();
}

class _GenerateBarcodeButtonState extends State<_GenerateBarcodeButton> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    final result = await BarcodeRepository.instance.generateBarcode();
    if (!mounted) return;
    setState(() => _loading = false);
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case Success(:final data):
        widget.ctrl.text = data;
        widget.onGenerated?.call(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.barcodeGeneratedSuccess),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.barcodeGenerateFailed(message)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: _loading ? null : _generate,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: _loading
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6366F1)))
            : const Icon(Icons.auto_awesome_rounded, size: 13),
        label: Text(_loading ? l10n.generatingBarcode : l10n.generateBarcode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Table header text ─────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3),
    );
  }
}

// ── Option card for choice dialog ─────────────────────────────────────────────
class _OptionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8FAFF) : Colors.white,
            border: Border.all(color: _hovered ? widget.iconColor.withOpacity(0.5) : const Color(0xFFE2E8F0), width: _hovered ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered ? [BoxShadow(color: widget.iconColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(widget.icon, color: widget.iconColor, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge backed by API string ────────────────────────────────────────
class _ApiStatusBadge extends StatelessWidget {
  /// 'in_stock' | 'low_stock' | 'out_of_stock'
  final String status;
  const _ApiStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      'in_stock' => (l10n.inStock, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'low_stock' => (l10n.lowStock, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      _ => (l10n.outOfStock, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, this.color = const Color(0xFF6366F1), required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? color : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap, this.color = const Color(0xFF64748B)});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
        ),
        child: Icon(icon, size: 16, color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Horizontal scroll button (auto-hides when at the boundary)
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// Reusable Inventory (Warehouse) Dropdown
// Fetches from GET /api/inventories/ and shows a searchable dropdown.
// ═══════════════════════════════════════════════════════════════════════════════
class _InventoryDropdown extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool required;

  const _InventoryDropdown({required this.selectedId, required this.onChanged, this.enabled = true, this.required = false});

  @override
  State<_InventoryDropdown> createState() => _InventoryDropdownState();
}

class _InventoryDropdownState extends State<_InventoryDropdown> {
  List<InventoryModel> _inventories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInventories();
  }

  Future<void> _fetchInventories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await InventoryRepository.instance.fetchInventories();
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _inventories = data.results.where((inv) => !inv.isStock).toList();
          _loading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warehouse_outlined, size: 13, color: Color(0xFF6366F1)),
            const SizedBox(width: 5),
            const Text(
              'Inventory (Warehouse)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            if (widget.required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 6),
        if (_loading)
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
            ),
          )
        else if (_error != null)
          GestureDetector(
            onTap: _fetchInventories,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Failed to load — tap to retry', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)), softWrap: true),
                  ),
                ],
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _inventories.any((inv) => inv.id == widget.selectedId) ? widget.selectedId : null,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: widget.enabled ? Colors.white : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
            hint: const Text('Select inventory…', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
            validator: widget.required ? (val) => (val == null || val.isEmpty) ? 'Please select an inventory' : null : null,
            items: [
              if (!widget.required)
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('— None —', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                ),
              ..._inventories.map(
                (inv) => DropdownMenuItem<String>(
                  value: inv.id,
                  child: Row(
                    children: [
                      Icon(
                        inv.isStock ? Icons.store_rounded : Icons.warehouse_outlined,
                        size: 14,
                        color: inv.isStock ? const Color(0xFF0EA5E9) : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(inv.name, softWrap: true, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: widget.enabled ? widget.onChanged : null,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Manual Add / Edit Product Dialog  (API-integrated)
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductDialog extends StatefulWidget {
  /// Pass an existing product to pre-fill the form (edit mode, local only).
  final Product? product;
  final InventoryProductsCubit cubit;
  final VoidCallback? onCreated;

  const _ProductDialog({this.product, required this.cubit, this.onCreated});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // 'preprinted' when user types the barcode, 'generated' when obtained via API
  String _barcodeType = 'preprinted';

  // Selected inventory UUID (nullable = no inventory assigned)
  String? _selectedInventoryId;

  // ── Product info ────────────────────────────────────────────────────────────
  late final TextEditingController _productCode; // product_code
  late final TextEditingController _productName; // product_name
  late final TextEditingController _modelCode; // model_code
  late final TextEditingController _color; // color
  late final TextEditingController _colorCode; // color_code
  late final TextEditingController _size; // size
  late final TextEditingController _barcode; // barcode
  late final TextEditingController _actualQty; // actual_quantity
  late final TextEditingController _unitPriceAzn; // invoice_unit_price_azn
  // ── Packaging ───────────────────────────────────────────────────────────────
  late final TextEditingController _actualPcsPerCarton; // actual_pieces_per_carton
  late final TextEditingController _actualCartonCount; // actual_carton_count
  // ── Location ─────────────────────────────────────────────────────────────────
  late final TextEditingController _zone;
  late final TextEditingController _row;
  late final TextEditingController _shelf;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _productCode = TextEditingController();
    _productName = TextEditingController(text: p?.sku ?? '');
    _modelCode = TextEditingController(text: p?.name ?? '');
    _color = TextEditingController(text: (p?.color == '—' ? '' : p?.color) ?? '');
    _colorCode = TextEditingController();
    _size = TextEditingController();
    _barcode = TextEditingController(text: p?.barcode ?? '');
    // Any manual keystroke marks the barcode as 'preprinted'
    _barcode.addListener(() {
      if (_barcodeType != 'generated') {
        _barcodeType = 'preprinted';
      }
    });
    _actualQty = TextEditingController(text: p != null ? '${p.quantity}' : '');
    _unitPriceAzn = TextEditingController();
    _actualPcsPerCarton = TextEditingController();
    _actualCartonCount = TextEditingController();
    _zone = TextEditingController(text: p?.coordinate.zone ?? '');
    _row = TextEditingController(text: p != null ? '${p.coordinate.row}' : '');
    _shelf = TextEditingController(text: p != null ? '${p.coordinate.shelf}' : '');
  }

  @override
  void dispose() {
    for (final c in [
      _productCode,
      _productName,
      _modelCode,
      _color,
      _colorCode,
      _size,
      _barcode,
      _actualQty,
      _unitPriceAzn,
      _actualPcsPerCarton,
      _actualCartonCount,
      _zone,
      _row,
      _shelf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final actualQty = int.tryParse(_actualQty.text.trim()) ?? 0;
    final actualPcs = int.tryParse(_actualPcsPerCarton.text.trim()) ?? 0;
    final actualCartons = int.tryParse(_actualCartonCount.text.trim()) ?? 0;
    final unitPriceAzn = double.tryParse(_unitPriceAzn.text.trim()) ?? 0.0;
    // actual_total_price = invoice_unit_price_azn × actual_quantity
    final actualTotalPrice = unitPriceAzn * actualQty;

    final request = CreateInventoryProductRequestModel(
      productCode: _productCode.text.trim(),
      productName: _productName.text.trim(),
      modelCode: _modelCode.text.trim(),
      color: _color.text.trim(),
      colorCode: _colorCode.text.trim(),
      size: _size.text.trim(),
      barcode: _barcode.text.trim(),
      barcodeType: _barcodeType,
      actualQuantity: actualQty,
      actualTotalPrice: actualTotalPrice,
      actualPiecesPerCarton: actualPcs,
      actualCartonCount: actualCartons,
      locationZone: _zone.text.trim().toUpperCase(),
      locationRow: _row.text.trim(),
      locationShelf: _shelf.text.trim(),
      // manual source defaults
      source: 'manual',
      invoice: '',
      invoiceUnitPriceUsd: 0,
      invoiceUnitPriceAzn: unitPriceAzn,
      invoiceQuantity: 0,
      invoiceTotalPrice: 0,
      invoicePiecesPerCarton: 0,
      invoiceCartonCount: 0,
      inventory: _selectedInventoryId,
    );

    setState(() => _isSaving = true);

    final result = await widget.cubit.createProduct(request);

    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSavedSuccess),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        widget.onCreated?.call();
      case Failure(:final message):
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productSaveFailed(message)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add_box_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.addNewProduct,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),

                  // ── Section: Product Info ─────────────────────────────────────
                  _sectionHeader(Icons.inventory_2_outlined, l10n.productInfoSection),
                  const SizedBox(height: 12),
                  _field(_productCode, 'Product Code', 'e.g. PC-001', required: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_productName, l10n.productName, 'e.g. X-1-black', required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_modelCode, l10n.modelField, 'e.g. X-1', required: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_color, l10n.colorField, 'e.g. Black')),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_colorCode, l10n.colorCodeField, 'e.g. BL')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_size, l10n.sizeField, 'e.g. M / 42')),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field(_barcode, l10n.barcodeField, 'e.g. 1234500001', required: true),
                            const SizedBox(height: 4),
                            _GenerateBarcodeButton(ctrl: _barcode, onGenerated: (_) => setState(() => _barcodeType = 'generated')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_actualQty, l10n.actualQtyReceived, '0', isNumber: true, required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_unitPriceAzn, 'Unit Price (AZN)', '0.00', isDecimal: true)),
                    ],
                  ),
                  // ── Live total price preview for manual entry ──
                  ValueListenableBuilder(
                    valueListenable: _actualQty,
                    builder: (_, __, ___) => ValueListenableBuilder(
                      valueListenable: _unitPriceAzn,
                      builder: (_, __, ___) {
                        final qty = int.tryParse(_actualQty.text.trim());
                        final unitPrice = double.tryParse(_unitPriceAzn.text.trim());
                        final total = (qty != null && unitPrice != null) ? qty * unitPrice : null;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: total == null
                              ? const SizedBox.shrink()
                              : Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calculate_rounded, size: 14, color: Color(0xFF15803D)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Total Price: ₼${total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Section: Inventory Selection ──────────────────────────────
                  _InventoryDropdown(
                    selectedId: _selectedInventoryId,
                    enabled: !_isSaving,
                    required: true,
                    onChanged: (id) => setState(() => _selectedInventoryId = id),
                  ),

                  const SizedBox(height: 20),

                  // ── Section: Packaging ────────────────────────────────────────
                  _sectionHeader(Icons.inventory_outlined, l10n.packagingSection),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_actualPcsPerCarton, l10n.actualPcsPerCarton, '0', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(_actualCartonCount, l10n.actualCartonCount, '0', isNumber: true)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Section: Warehouse Location ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.warehouseLocation,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _field(_zone, l10n.zone, 'A', required: true, hint: l10n.zoneLetter)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_row, l10n.row, '1', isNumber: true, required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_shelf, l10n.shelf, '1', isNumber: true, required: true)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder(
                          valueListenable: _zone,
                          builder: (_, __, ___) => ValueListenableBuilder(
                            valueListenable: _row,
                            builder: (_, __, ___) => ValueListenableBuilder(
                              valueListenable: _shelf,
                              builder: (_, __, ___) {
                                final z = _zone.text.toUpperCase();
                                final r = _row.text;
                                final s = _shelf.text;
                                if (z.isEmpty || r.isEmpty || s.isEmpty) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.locationCode('$z-$r-$s'),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer buttons ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add_rounded, size: 16),
                          label: Text(_isSaving ? l10n.savingProduct : l10n.addProduct),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String placeholder, {
    bool required = false,
    bool isNumber = false,
    bool isDecimal = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            if (required) const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          enabled: !_isSaving,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.required : null : null,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint ?? placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small label+value row used inside the print dialog ──────────────────────
class _PrintInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _PrintInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), softWrap: true),
        ),
      ],
    );
  }
}
