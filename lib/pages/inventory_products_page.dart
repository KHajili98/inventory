import 'package:flutter/material.dart';
import 'package:inventory/models/invoice_models.dart';
import 'package:inventory/models/product_models.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/core/utils/responsive.dart';

class InventoryProductsPage extends StatefulWidget {
  const InventoryProductsPage({super.key});

  @override
  State<InventoryProductsPage> createState() => _InventoryProductsPageState();
}

class _InventoryProductsPageState extends State<InventoryProductsPage> {
  final List<Product> _allProducts = List.from(mockProducts);
  List<Product> _filtered = List.from(mockProducts);
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  ProductStatus? _statusFilter;
  String _sortColumn = 'sku';
  bool _sortAscending = true;

  // Primary horizontal scroll controller (drives the body rows)
  final ScrollController _hScrollController = ScrollController();
  // Mirror controllers kept in sync via listener (header + bottom scrollbar)
  final ScrollController _hHeaderController = ScrollController();
  final ScrollController _hBarController = ScrollController();
  // Vertical scroll controller for rows
  final ScrollController _vScrollController = ScrollController();

  static const double _hScrollStep = 200.0;
  static const double _vScrollStep = 200.0;

  // ── Sync all horizontal controllers together ──────────────────────────────
  bool _hSyncing = false;
  void _onHScroll() {
    if (_hSyncing) return;
    _hSyncing = true;
    final offset = _hScrollController.offset;
    if (_hHeaderController.hasClients && _hHeaderController.offset != offset) {
      _hHeaderController.jumpTo(offset);
    }
    if (_hBarController.hasClients && _hBarController.offset != offset) {
      _hBarController.jumpTo(offset);
    }
    _hSyncing = false;
  }

  void _onHBarScroll() {
    if (_hSyncing) return;
    _hSyncing = true;
    final offset = _hBarController.offset;
    if (_hScrollController.hasClients && _hScrollController.offset != offset) {
      _hScrollController.jumpTo(offset);
    }
    if (_hHeaderController.hasClients && _hHeaderController.offset != offset) {
      _hHeaderController.jumpTo(offset);
    }
    _hSyncing = false;
  }

  // Total table width for horizontal scrolling
  static double get _tableWidth =>
      _colCheck +
      _colIdx +
      _colSku +
      _colName +
      _colColor +
      _colActQty +
      _colInvQty +
      _colUnit +
      _colInvTotal +
      _colActTotal +
      _colBarcode +
      _colCoord +
      _colSource +
      _colStatus +
      _colActions;

  // ── Column widths ────────────────────────────────────────────────────────────
  static const double _colCheck = 48;
  static const double _colIdx = 48;
  static const double _colSku = 150;
  static const double _colName = 100;
  static const double _colColor = 120;
  static const double _colActQty = 100;
  static const double _colInvQty = 100;
  static const double _colUnit = 110;
  static const double _colInvTotal = 120;
  static const double _colActTotal = 120;
  static const double _colBarcode = 150;
  static const double _colCoord = 120;
  static const double _colSource = 130;
  static const double _colStatus = 120;
  static const double _colActions = 80;

  // ── Filtering & Sorting ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _hScrollController.addListener(_onHScroll);
    _hBarController.addListener(_onHBarScroll);
  }

  @override
  void dispose() {
    _hScrollController.removeListener(_onHScroll);
    _hBarController.removeListener(_onHBarScroll);
    _hScrollController.dispose();
    _hHeaderController.dispose();
    _hBarController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allProducts.where((p) {
        final q = _searchQuery.toLowerCase();
        final matchSearch =
            q.isEmpty ||
            p.sku.toLowerCase().contains(q) ||
            p.name.toLowerCase().contains(q) ||
            p.barcode.contains(q) ||
            p.color.toLowerCase().contains(q) ||
            p.coordinate.label.toLowerCase().contains(q) ||
            (p.sourceInvoiceNo?.toLowerCase().contains(q) ?? false);
        final matchStatus = _statusFilter == null || p.status == _statusFilter;
        return matchSearch && matchStatus;
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    _filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'sku':
          cmp = a.sku.compareTo(b.sku);
          break;
        case 'color':
          cmp = a.color.compareTo(b.color);
          break;
        case 'qty':
          cmp = a.quantity.compareTo(b.quantity);
          break;
        case 'unit':
          cmp = a.unitPrice.compareTo(b.unitPrice);
          break;
        case 'total':
          cmp = a.totalPrice.compareTo(b.totalPrice);
          break;
        case 'barcode':
          cmp = a.barcode.compareTo(b.barcode);
          break;
        case 'coord':
          cmp = a.coordinate.label.compareTo(b.coordinate.label);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _applySort();
    });
  }

  void _deleteSelected() {
    setState(() {
      _allProducts.removeWhere((p) => _selectedIds.contains(p.id));
      _selectedIds.clear();
      _applyFilter();
    });
  }

  int get _totalQty => _allProducts.fold(0, (s, p) => s + p.quantity);
  double get _totalValue => _allProducts.fold(0.0, (s, p) => s + p.totalPrice);
  int get _inStockCount => _allProducts.where((p) => p.status == ProductStatus.inStock).length;
  int get _lowStockCount => _allProducts.where((p) => p.status == ProductStatus.lowStock).length;
  int get _outCount => _allProducts.where((p) => p.status == ProductStatus.outOfStock).length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          SizedBox(height: context.isMobile ? 16 : 20),
          _buildStatsRow(),
          SizedBox(height: context.isMobile ? 16 : 20),
          _buildFilterBar(),
          SizedBox(height: context.isMobile ? 12 : 16),
          Expanded(child: _buildTable()),
        ],
      ),
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
            style: const TextStyle(fontSize: 13, color: const Color(0xFF6366F1), fontWeight: FontWeight.w500),
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
        invoices: mockInvoices,
        onSelected: (invoice) {
          Navigator.of(context, rootNavigator: true).pop();
          _showInvoiceRowsDialog(invoice);
        },
      ),
    );
  }

  void _showInvoiceRowsDialog(InvoiceRecord invoice) {
    showDialog(
      context: context,
      builder: (_) => _InvoiceRowsDialog(
        invoice: invoice,
        onImport: (products) {
          setState(() {
            _allProducts.addAll(products);
            _applyFilter();
          });
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.nProductsImported(products.length, invoice.invoiceNo)),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    final stats = [
      _StatCard(label: l10n.totalSKUs, value: '${_allProducts.length}', icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1)),
      _StatCard(label: l10n.totalUnits, value: '$_totalQty ${l10n.pcs}', icon: Icons.layers_outlined, color: const Color(0xFF0EA5E9)),
      _StatCard(
        label: l10n.totalValue,
        value: '\$${_totalValue.toStringAsFixed(2)}',
        icon: Icons.payments_outlined,
        color: const Color(0xFF22C55E),
      ),
      _StatCard(label: l10n.inStock, value: '$_inStockCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E)),
      _StatCard(label: l10n.lowStock, value: '$_lowStockCount', icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
      _StatCard(label: l10n.outOfStock, value: '$_outCount', icon: Icons.remove_circle_outline_rounded, color: const Color(0xFFEF4444)),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(width: 140, child: stats[i]),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: stats[i]),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final searchWidth = isMobile ? MediaQuery.of(context).size.width - (context.responsivePadding * 2) : 300.0;

    return Column(
      children: [
        // Search field - full width on mobile
        SizedBox(
          width: isMobile ? double.infinity : searchWidth,
          height: 40,
          child: TextField(
            onChanged: (v) {
              _searchQuery = v;
              _applyFilter();
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
        // Filters - horizontal scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: l10n.all,
                selected: _statusFilter == null,
                onTap: () {
                  _statusFilter = null;
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.inStock,
                selected: _statusFilter == ProductStatus.inStock,
                color: const Color(0xFF22C55E),
                onTap: () {
                  _statusFilter = ProductStatus.inStock;
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.lowStock,
                selected: _statusFilter == ProductStatus.lowStock,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  _statusFilter = ProductStatus.lowStock;
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.outOfStock,
                selected: _statusFilter == ProductStatus.outOfStock,
                color: const Color(0xFFEF4444),
                onTap: () {
                  _statusFilter = ProductStatus.outOfStock;
                  _applyFilter();
                },
              ),
              const SizedBox(width: 16),
              Text(l10n.nOfMProducts(_filtered.length, _allProducts.length), style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }

  void _scrollH(double delta) {
    if (!_hScrollController.hasClients) return;
    final target = (_hScrollController.offset + delta).clamp(0.0, _hScrollController.position.maxScrollExtent);
    _hScrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _scrollV(double delta) {
    final target = (_vScrollController.offset + delta).clamp(0.0, _vScrollController.position.maxScrollExtent);
    _vScrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Top navigation bar (scroll left/right & jump to top/bottom) ──
          _buildHNavBar(),
          // ── Sticky header ─────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _hHeaderController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: _buildHeaderRow(),
          ),
          // ── Scrollable body + right vertical scrollbar ────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noProductsMatchSearch, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Table rows with horizontal scroll
                      Expanded(
                        child: SingleChildScrollView(
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
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (_, i) => _buildProductRow(i, _filtered[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── Right-side vertical nav buttons ─────────────────
                      _buildVNavBar(),
                    ],
                  ),
          ),
          // ── Bottom horizontal scrollbar + nav buttons ─────────────────────
          _buildHScrollBar(),
        ],
      ),
    );
  }

  /// Top bar: ← scroll left  |  → scroll right  |  spacer  |  ↑ top  |  ↓ bottom
  Widget _buildHNavBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.keyboard_double_arrow_left_rounded,
            tooltip: l10n.scrollToStart,
            onTap: () {
              if (_hScrollController.hasClients) {
                _hScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            },
          ),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_left_rounded, tooltip: l10n.scrollLeft, onTap: () => _scrollH(-_hScrollStep)),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_right_rounded, tooltip: l10n.scrollRight, onTap: () => _scrollH(_hScrollStep)),
          const SizedBox(width: 4),
          _NavBtn(
            icon: Icons.keyboard_double_arrow_right_rounded,
            tooltip: l10n.scrollToEnd,
            onTap: () {
              if (_hScrollController.hasClients) {
                _hScrollController.animateTo(
                  _hScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          const Spacer(),
          Text(l10n.horizontal, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          Text(l10n.vertical, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
          const SizedBox(width: 4),
          _NavBtn(
            icon: Icons.keyboard_double_arrow_up_rounded,
            tooltip: l10n.scrollToTop,
            onTap: () => _vScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
          ),
          const SizedBox(width: 4),
          _NavBtn(
            icon: Icons.keyboard_double_arrow_down_rounded,
            tooltip: l10n.scrollToBottom,
            onTap: () => _vScrollController.animateTo(
              _vScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  /// Right-side column with up/down step buttons
  Widget _buildVNavBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavBtn(icon: Icons.keyboard_arrow_up_rounded, tooltip: l10n.scrollUp, onTap: () => _scrollV(-_vScrollStep)),
          const SizedBox(height: 4),
          _NavBtn(icon: Icons.keyboard_arrow_down_rounded, tooltip: l10n.scrollDown, onTap: () => _scrollV(_vScrollStep)),
        ],
      ),
    );
  }

  /// Bottom area: draggable/clickable horizontal scrollbar + step buttons on either side
  Widget _buildHScrollBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded, tooltip: l10n.scrollLeft, onTap: () => _scrollH(-_hScrollStep)),
          Expanded(
            child: Scrollbar(
              controller: _hBarController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _hBarController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: _tableWidth, height: 1),
              ),
            ),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, tooltip: l10n.scrollRight, onTap: () => _scrollH(_hScrollStep)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colCheck,
            height: 44,
            child: Checkbox(
              value: _selectedIds.length == _filtered.length && _filtered.isNotEmpty,
              tristate: _selectedIds.isNotEmpty && _selectedIds.length < _filtered.length,
              onChanged: (v) => setState(() {
                if (v == true)
                  _selectedIds.addAll(_filtered.map((p) => p.id));
                else
                  _selectedIds.clear();
              }),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          _headerCell('#', _colIdx, null),
          _headerCell(l10n.sku, _colSku, 'sku'),
          _headerCell(l10n.model, _colName, null),
          _headerCell(l10n.color, _colColor, 'color'),
          _headerCell(l10n.actualQty, _colActQty, 'qty'),
          _headerCell(l10n.invoiceQty, _colInvQty, null),
          _headerCell(l10n.unitPrice, _colUnit, 'unit'),
          _headerCell(l10n.invoiceTotal, _colInvTotal, null),
          _headerCell(l10n.actualTotal, _colActTotal, 'total'),
          _headerCell(l10n.barcode, _colBarcode, 'barcode'),
          _headerCell(l10n.location, _colCoord, 'coord'),
          _headerCell(l10n.source, _colSource, null),
          _headerCell(l10n.status, _colStatus, null),
          SizedBox(width: _colActions),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, String? sortKey) {
    final isActive = sortKey != null && _sortColumn == sortKey;
    return GestureDetector(
      onTap: sortKey != null ? () => _onSort(sortKey) : null,
      child: Container(
        width: width,
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isActive ? const Color(0xFF6366F1) : const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (sortKey != null) ...[
              const SizedBox(width: 4),
              Icon(
                isActive ? (_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded) : Icons.unfold_more_rounded,
                size: 14,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(int index, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedIds.contains(product.id);
    final isOdd = index.isOdd;
    final rowBg = isSelected
        ? const Color(0xFFEEF2FF)
        : isOdd
        ? const Color(0xFFFAFAFA)
        : Colors.white;
    final hasDiscrepancy = product.qtyDiscrepancy != null && product.qtyDiscrepancy != 0;

    return InkWell(
      onTap: () => _showProductDialog(product: product),
      child: Container(
        color: rowBg,
        child: Row(
          children: [
            SizedBox(
              width: _colCheck,
              height: 52,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => setState(() {
                  if (v == true)
                    _selectedIds.add(product.id);
                  else
                    _selectedIds.remove(product.id);
                }),
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            _cell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            _cell(
              product.sku,
              _colSku,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            _cell(product.name, _colName, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            // Color
            SizedBox(
              width: _colColor,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.color != '—') ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorDot(product.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        product.color,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actual Qty
            SizedBox(
              width: _colActQty,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${product.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: product.status == ProductStatus.outOfStock
                              ? const Color(0xFFEF4444)
                              : product.status == ProductStatus.lowStock
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasDiscrepancy) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: l10n.discrepancyTooltip('${product.qtyDiscrepancy! > 0 ? '+' : ''}${product.qtyDiscrepancy}'),
                        child: Icon(
                          product.qtyDiscrepancy! > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: product.qtyDiscrepancy! > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Invoice Qty
            _cell(
              product.invoiceQty != null ? '${product.invoiceQty}' : '—',
              _colInvQty,
              style: TextStyle(fontSize: 13, color: product.invoiceQty != null ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
            // Unit price
            _cell('\$${product.unitPrice.toStringAsFixed(4)}', _colUnit, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            // Invoice Total
            _cell(
              product.invoiceTotalPrice != null ? '\$${product.invoiceTotalPrice!.toStringAsFixed(2)}' : '—',
              _colInvTotal,
              style: TextStyle(fontSize: 13, color: product.invoiceTotalPrice != null ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
            // Actual Total
            _cell(
              '\$${product.totalPrice.toStringAsFixed(2)}',
              _colActTotal,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            // Barcode
            SizedBox(
              width: _colBarcode,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        product.barcode,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Coordinate
            SizedBox(
              width: _colCoord,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text(
                        product.coordinate.label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Source
            SizedBox(
              width: _colSource,
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: product.sourceInvoiceNo != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.sourceInvoiceNo!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                                overflow: TextOverflow.ellipsis,
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
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _StatusBadge(status: product.status),
              ),
            ),
            // Actions
            SizedBox(
              width: _colActions,
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    tooltip: l10n.edit,
                    onTap: () => _showProductDialog(product: product),
                  ),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.delete,
                    color: const Color(0xFFEF4444),
                    onTap: () => setState(() {
                      _allProducts.removeWhere((p) => p.id == product.id);
                      _selectedIds.remove(product.id);
                      _applyFilter();
                    }),
                  ),
                ],
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
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: style ?? const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Color _colorDot(String color) {
    if (color.contains('Gold') || color.contains('GD')) return const Color(0xFFD97706);
    if (color.contains('Silver') || color.contains('SL')) return const Color(0xFF94A3B8);
    if (color.contains('White') || color.contains('WH')) return const Color(0xFFE2E8F0);
    return const Color(0xFF6366F1);
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(
        product: product,
        onSave: (p) {
          setState(() {
            if (product == null) {
              _allProducts.add(p);
            } else {
              final idx = _allProducts.indexWhere((x) => x.id == p.id);
              if (idx != -1) _allProducts[idx] = p;
            }
            _applyFilter();
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Picker Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _InvoicePickerDialog extends StatelessWidget {
  final List<InvoiceRecord> invoices;
  final ValueChanged<InvoiceRecord> onSelected;

  const _InvoicePickerDialog({required this.invoices, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 540,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (invoices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 8),
                        Text(l10n.noInvoicesAvailable, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 4),
                        Text(l10n.addInvoicesFirst, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                      ],
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = invoices[i];
                      final statusColor = inv.status == InvoiceStatus.confirmed
                          ? const Color(0xFF22C55E)
                          : inv.status == InvoiceStatus.pending
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444);
                      final statusLabel = inv.status == InvoiceStatus.confirmed
                          ? l10n.confirmed
                          : inv.status == InvoiceStatus.pending
                          ? l10n.pending
                          : l10n.cancelled;
                      return InkWell(
                        onTap: () => onSelected(inv),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.description_rounded, size: 20, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          inv.invoiceNo,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(inv.supplier, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${inv.totalItems} ${l10n.items.toLowerCase()}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  ),
                                  Text(inv.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                ],
                              ),
                              const SizedBox(width: 12),
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
// Invoice Rows Dialog — two-step: select SKUs → fill barcode/location/actual qty
// ═══════════════════════════════════════════════════════════════════════════════
class _InvoiceRowsDialog extends StatefulWidget {
  final InvoiceRecord invoice;
  final ValueChanged<List<Product>> onImport;

  const _InvoiceRowsDialog({required this.invoice, required this.onImport});

  @override
  State<_InvoiceRowsDialog> createState() => _InvoiceRowsDialogState();
}

class _InvoiceRowsDialogState extends State<_InvoiceRowsDialog> {
  late final List<_MergedRow> _mergedRows;
  final Set<int> _selected = {};
  int _step = 0;

  final Map<int, TextEditingController> _barcodeCtrl = {};
  final Map<int, TextEditingController> _zoneCtrl = {};
  final Map<int, TextEditingController> _rowCtrl = {};
  final Map<int, TextEditingController> _shelfCtrl = {};
  final Map<int, TextEditingController> _actualQtyCtrl = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _mergedRows = _mergeRows(widget.invoice.rows);
  }

  List<_MergedRow> _mergeRows(List<InvoiceRow> rows) {
    final map = <String, _MergedRow>{};
    for (final r in rows) {
      if (map.containsKey(r.productName)) {
        map[r.productName] = map[r.productName]!.copyWithAddedQty(r.qty);
      } else {
        map[r.productName] = _MergedRow(
          sku: r.productName,
          modelCode: r.modelCode,
          color: r.color,
          size: r.size,
          totalQty: r.qty,
          unitPrice: r.unitPrice,
        );
      }
    }
    return map.values.toList();
  }

  void _initControllersForSelected() {
    for (final idx in _selected) {
      final mr = _mergedRows[idx];
      _barcodeCtrl.putIfAbsent(idx, () => TextEditingController());
      _zoneCtrl.putIfAbsent(idx, () => TextEditingController());
      _rowCtrl.putIfAbsent(idx, () => TextEditingController(text: '1'));
      _shelfCtrl.putIfAbsent(idx, () => TextEditingController(text: '1'));
      _actualQtyCtrl.putIfAbsent(idx, () => TextEditingController(text: '${mr.totalQty}'));
    }
  }

  @override
  void dispose() {
    for (final c in [..._barcodeCtrl.values, ..._zoneCtrl.values, ..._rowCtrl.values, ..._shelfCtrl.values, ..._actualQtyCtrl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToStep2() {
    if (_selected.isEmpty) return;
    _initControllersForSelected();
    setState(() => _step = 1);
  }

  void _importProducts() {
    if (!_formKey.currentState!.validate()) return;
    final products = <Product>[];
    for (final idx in _selected) {
      final mr = _mergedRows[idx];
      final actualQty = int.tryParse(_actualQtyCtrl[idx]!.text) ?? mr.totalQty;
      products.add(
        Product(
          id: '${DateTime.now().millisecondsSinceEpoch}_$idx',
          sku: mr.sku,
          name: mr.modelCode,
          color: mr.color.isEmpty ? '—' : mr.color,
          quantity: actualQty,
          unitPrice: mr.unitPrice,
          barcode: _barcodeCtrl[idx]!.text.trim(),
          coordinate: WarehouseCoordinate(
            zone: _zoneCtrl[idx]!.text.trim().toUpperCase(),
            row: int.tryParse(_rowCtrl[idx]!.text) ?? 1,
            shelf: int.tryParse(_shelfCtrl[idx]!.text) ?? 1,
          ),
          status: Product.statusFromQty(actualQty),
          invoiceQty: mr.totalQty,
          invoiceTotalPrice: mr.totalQty * mr.unitPrice,
          actualTotalPrice: actualQty * mr.unitPrice,
          sourceInvoiceId: widget.invoice.id,
          sourceInvoiceNo: widget.invoice.invoiceNo,
        ),
      );
    }
    Navigator.of(context, rootNavigator: true).pop();
    widget.onImport(products);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 760,
        height: 620,
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(child: _step == 0 ? _buildStep1() : _buildStep2()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.importFromInvoiceNo(widget.invoice.invoiceNo),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(widget.invoice.supplier, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text(l10n.nUniqueSkusFromInvoice(_mergedRows.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  if (_selected.length == _mergedRows.length)
                    _selected.clear();
                  else
                    _selected.addAll(List.generate(_mergedRows.length, (i) => i));
                }),
                icon: Icon(_selected.length == _mergedRows.length ? Icons.deselect_rounded : Icons.select_all_rounded, size: 16),
                label: Text(_selected.length == _mergedRows.length ? l10n.deselectAll : l10n.selectAllLabel),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(flex: 3, child: _TH(l10n.sku)),
              Expanded(flex: 2, child: _TH(l10n.model)),
              Expanded(flex: 2, child: _TH(l10n.color)),
              Expanded(flex: 1, child: _TH(l10n.size)),
              Expanded(flex: 2, child: _TH(l10n.invQty)),
              Expanded(flex: 2, child: _TH(l10n.unitPrice)),
              Expanded(flex: 2, child: _TH(l10n.invTotal)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _mergedRows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final mr = _mergedRows[i];
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
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (v) => setState(() {
                            if (v == true)
                              _selected.add(i);
                            else
                              _selected.remove(i);
                          }),
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          mr.sku,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(mr.modelCode, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(mr.color.isEmpty ? '—' : mr.color, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(mr.size, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${mr.totalQty} ${l10n.pcs}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('\$${mr.unitPrice.toStringAsFixed(4)}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${(mr.totalQty * mr.unitPrice).toStringAsFixed(2)}',
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

  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context)!;
    final selectedList = _selected.map((i) => (i, _mergedRows[i])).toList();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(l10n.fillWarehouseDetails(selectedList.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              itemCount: selectedList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, listIdx) {
                final (idx, mr) = selectedList[listIdx];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            Text(
                              mr.sku,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 8),
                            Text(mr.modelCode, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            if (mr.color.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  mr.color,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                l10n.invoiceQtyLabel(mr.totalQty),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form fields
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _DetailField(
                                    ctrl: _barcodeCtrl[idx]!,
                                    label: l10n.barcodeField,
                                    hint: 'e.g. 6901234500010',
                                    required: true,
                                    icon: Icons.qr_code_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _DetailField(
                                    ctrl: _actualQtyCtrl[idx]!,
                                    label: l10n.actualQtyReceived,
                                    hint: '${mr.totalQty}',
                                    required: true,
                                    isNumber: true,
                                    icon: Icons.numbers_rounded,
                                    suffixWidget: ValueListenableBuilder(
                                      valueListenable: _actualQtyCtrl[idx]!,
                                      builder: (_, __, ___) {
                                        final actual = int.tryParse(_actualQtyCtrl[idx]!.text) ?? mr.totalQty;
                                        final diff = actual - mr.totalQty;
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
                            const SizedBox(height: 12),
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

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context)!;
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
              onPressed: () => setState(() => _step = 0),
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
            Text(l10n.nOfMSelected(_selected.length, _mergedRows.length), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
              onPressed: _importProducts,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(l10n.importNProducts(_selected.length)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────────
class _MergedRow {
  final String sku;
  final String modelCode;
  final String color;
  final String size;
  final int totalQty;
  final double unitPrice;

  const _MergedRow({
    required this.sku,
    required this.modelCode,
    required this.color,
    required this.size,
    required this.totalQty,
    required this.unitPrice,
  });

  _MergedRow copyWithAddedQty(int extra) =>
      _MergedRow(sku: sku, modelCode: modelCode, color: color, size: size, totalQty: totalQty + extra, unitPrice: unitPrice);
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
  final IconData? icon;
  final Widget? suffixWidget;

  const _DetailField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.isNumber = false,
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      ProductStatus.inStock => (l10n.inStock, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      ProductStatus.lowStock => (l10n.lowStock, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      ProductStatus.outOfStock => (l10n.outOfStock, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
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

/// Small compact button used in the table scroll nav bars.
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(child: Icon(icon, size: 18, color: const Color(0xFF94A3B8))),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Manual Add / Edit Product Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductDialog extends StatefulWidget {
  final Product? product;
  final ValueChanged<Product> onSave;

  const _ProductDialog({this.product, required this.onSave});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sku;
  late final TextEditingController _name;
  late final TextEditingController _color;
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _barcode;
  late final TextEditingController _zone;
  late final TextEditingController _row;
  late final TextEditingController _shelf;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _sku = TextEditingController(text: p?.sku ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _color = TextEditingController(text: p?.color ?? '');
    _qty = TextEditingController(text: p?.quantity.toString() ?? '');
    _price = TextEditingController(text: p?.unitPrice.toString() ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _zone = TextEditingController(text: p?.coordinate.zone ?? '');
    _row = TextEditingController(text: p?.coordinate.row.toString() ?? '');
    _shelf = TextEditingController(text: p?.coordinate.shelf.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_sku, _name, _color, _qty, _price, _barcode, _zone, _row, _shelf]) c.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_qty.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    final product = Product(
      id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sku: _sku.text.trim(),
      name: _name.text.trim(),
      color: _color.text.trim().isEmpty ? '—' : _color.text.trim(),
      quantity: qty,
      unitPrice: price,
      barcode: _barcode.text.trim(),
      coordinate: WarehouseCoordinate(
        zone: _zone.text.trim().toUpperCase(),
        row: int.tryParse(_row.text) ?? 1,
        shelf: int.tryParse(_shelf.text) ?? 1,
      ),
      status: Product.statusFromQty(qty),
      invoiceQty: widget.product?.invoiceQty,
      invoiceTotalPrice: widget.product?.invoiceTotalPrice,
      actualTotalPrice: qty * price,
      sourceInvoiceId: widget.product?.sourceInvoiceId,
      sourceInvoiceNo: widget.product?.sourceInvoiceNo,
    );
    widget.onSave(product);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isEdit ? Icons.edit_rounded : Icons.add_box_rounded, color: const Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? l10n.editProduct : l10n.addNewProduct,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _field(_sku, l10n.skuField, 'e.g. X-1-500', required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_name, l10n.modelField, 'e.g. X-1', required: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _field(_color, l10n.colorField, 'e.g. GD Gold')),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_barcode, l10n.barcodeField, 'e.g. 6901234500010', required: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _field(_qty, l10n.quantityField, '0', isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_price, l10n.unitPriceUSD, '0.0000', isDecimal: true, required: true)),
                  ],
                ),
                const SizedBox(height: 16),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
                        onPressed: _save,
                        icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 16),
                        label: Text(isEdit ? l10n.saveChanges : l10n.addProduct),
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
