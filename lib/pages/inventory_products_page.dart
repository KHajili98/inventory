import 'package:flutter/material.dart';
import 'package:inventory/models/product_models.dart';

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

  // ── Column widths ────────────────────────────────────────────────────────────
  static const double _colCheck = 48;
  static const double _colIdx = 48;
  static const double _colSku = 150;
  static const double _colName = 100;
  static const double _colColor = 120;
  static const double _colQty = 90;
  static const double _colUnit = 110;
  static const double _colTotal = 120;
  static const double _colBarcode = 150;
  static const double _colCoord = 120;
  static const double _colStatus = 120;
  static const double _colActions = 80;

  // ── Filtering & Sorting ──────────────────────────────────────────────────────
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
            p.coordinate.label.toLowerCase().contains(q);
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

  // ── Summary stats ────────────────────────────────────────────────────────────
  int get _totalQty => _allProducts.fold(0, (s, p) => s + p.quantity);
  double get _totalValue => _allProducts.fold(0.0, (s, p) => s + p.totalPrice);
  int get _inStockCount => _allProducts.where((p) => p.status == ProductStatus.inStock).length;
  int get _lowStockCount => _allProducts.where((p) => p.status == ProductStatus.lowStock).length;
  int get _outCount => _allProducts.where((p) => p.status == ProductStatus.outOfStock).length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 2),
            Text('Track stock levels, locations and valuations', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        const Spacer(),
        if (_selectedIds.isNotEmpty) ...[
          Text(
            '${_selectedIds.length} selected',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: () => _showProductDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Product'),
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

  // ── Stats row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: 'Total SKUs', value: '${_allProducts.length}', icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        _StatCard(label: 'Total Units', value: '$_totalQty pcs', icon: Icons.layers_outlined, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 16),
        _StatCard(label: 'Total Value', value: '\$${_totalValue.toStringAsFixed(2)}', icon: Icons.payments_outlined, color: const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _StatCard(label: 'In Stock', value: '$_inStockCount', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _StatCard(label: 'Low Stock', value: '$_lowStockCount', icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 16),
        _StatCard(label: 'Out of Stock', value: '$_outCount', icon: Icons.remove_circle_outline_rounded, color: const Color(0xFFEF4444)),
      ],
    );
  }

  // ── Filter bar ───────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Search
        SizedBox(
          width: 300,
          height: 40,
          child: TextField(
            onChanged: (v) {
              _searchQuery = v;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: 'Search SKU, name, barcode, location…',
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
        const SizedBox(width: 12),
        // Status filter chips
        _FilterChip(
          label: 'All',
          selected: _statusFilter == null,
          onTap: () {
            _statusFilter = null;
            _applyFilter();
          },
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'In Stock',
          selected: _statusFilter == ProductStatus.inStock,
          color: const Color(0xFF22C55E),
          onTap: () {
            _statusFilter = ProductStatus.inStock;
            _applyFilter();
          },
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Low Stock',
          selected: _statusFilter == ProductStatus.lowStock,
          color: const Color(0xFFF59E0B),
          onTap: () {
            _statusFilter = ProductStatus.lowStock;
            _applyFilter();
          },
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Out of Stock',
          selected: _statusFilter == ProductStatus.outOfStock,
          color: const Color(0xFFEF4444),
          onTap: () {
            _statusFilter = ProductStatus.outOfStock;
            _applyFilter();
          },
        ),
        const Spacer(),
        Text('${_filtered.length} of ${_allProducts.length} products', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      ],
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────────
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
          _buildTableHeader(),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No products match your search.', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) => _buildProductRow(i, _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Select all checkbox
            SizedBox(
              width: _colCheck,
              height: 44,
              child: Checkbox(
                value: _selectedIds.length == _filtered.length && _filtered.isNotEmpty,
                tristate: _selectedIds.isNotEmpty && _selectedIds.length < _filtered.length,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedIds.addAll(_filtered.map((p) => p.id));
                  } else {
                    _selectedIds.clear();
                  }
                }),
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            _headerCell('#', _colIdx, null),
            _headerCell('SKU', _colSku, 'sku'),
            _headerCell('Model', _colName, null),
            _headerCell('Color', _colColor, 'color'),
            _headerCell('Qty', _colQty, 'qty'),
            _headerCell('Unit Price', _colUnit, 'unit'),
            _headerCell('Total Value', _colTotal, 'total'),
            _headerCell('Barcode', _colBarcode, 'barcode'),
            _headerCell('Location', _colCoord, 'coord'),
            _headerCell('Status', _colStatus, null),
            SizedBox(width: _colActions),
          ],
        ),
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
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF475569),
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
    final isSelected = _selectedIds.contains(product.id);
    final isOdd = index.isOdd;
    final rowBg = isSelected
        ? const Color(0xFFEEF2FF)
        : isOdd
        ? const Color(0xFFFAFAFA)
        : Colors.white;

    return InkWell(
      onTap: () => _showProductDialog(product: product),
      child: Container(
        color: rowBg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Checkbox
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
              // Index
              _cell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              // SKU
              _cell(
                product.sku,
                _colSku,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              // Model
              _cell(product.name, _colName, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              // Color
              SizedBox(
                width: _colColor,
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
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
                      Text(product.color, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              // Qty
              _cell(
                '${product.quantity}',
                _colQty,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: product.status == ProductStatus.outOfStock
                      ? const Color(0xFFEF4444)
                      : product.status == ProductStatus.lowStock
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF1E293B),
                ),
              ),
              // Unit price
              _cell('\$${product.unitPrice.toStringAsFixed(4)}', _colUnit, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              // Total
              _cell(
                '\$${product.totalPrice.toStringAsFixed(2)}',
                _colTotal,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              // Barcode
              SizedBox(
                width: _colBarcode,
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        product.barcode,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
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
                      tooltip: 'Edit',
                      onTap: () => _showProductDialog(product: product),
                    ),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
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
          child: Text(text, style: style ?? const TextStyle(fontSize: 13, color: Color(0xFF475569))),
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

  // ── Add / Edit Dialog ────────────────────────────────────────────────────────
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

// ── Add / Edit Product Dialog ─────────────────────────────────────────────────
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
    for (final c in [_sku, _name, _color, _qty, _price, _barcode, _zone, _row, _shelf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_qty.text) ?? 0;
    final product = Product(
      id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sku: _sku.text.trim(),
      name: _name.text.trim(),
      color: _color.text.trim().isEmpty ? '—' : _color.text.trim(),
      quantity: qty,
      unitPrice: double.tryParse(_price.text) ?? 0,
      barcode: _barcode.text.trim(),
      coordinate: WarehouseCoordinate(
        zone: _zone.text.trim().toUpperCase(),
        row: int.tryParse(_row.text) ?? 1,
        shelf: int.tryParse(_shelf.text) ?? 1,
      ),
      status: Product.statusFromQty(qty),
    );
    widget.onSave(product);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
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
                // Header
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
                      isEdit ? 'Edit Product' : 'Add New Product',
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

                // Row 1: SKU + Model
                Row(
                  children: [
                    Expanded(child: _field(_sku, 'SKU', 'e.g. X-1-500', required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_name, 'Model', 'e.g. X-1', required: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Color + Barcode
                Row(
                  children: [
                    Expanded(child: _field(_color, 'Color', 'e.g. GD Gold')),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_barcode, 'Barcode', 'e.g. 6901234500010', required: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 3: Qty + Unit Price
                Row(
                  children: [
                    Expanded(child: _field(_qty, 'Quantity', '0', isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field(_price, 'Unit Price (USD)', '0.0000', isDecimal: true, required: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Coordinate section
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
                      const Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6366F1)),
                          SizedBox(width: 6),
                          Text(
                            'Warehouse Location',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_zone, 'Zone', 'A', required: true, hint: 'Zone letter (A–Z)')),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_row, 'Row', '1', isNumber: true, required: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_shelf, 'Shelf', '1', isNumber: true, required: true)),
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
                                    'Location code: $z-$r-$s',
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
                // Buttons
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
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 16),
                        label: Text(isEdit ? 'Save Changes' : 'Add Product'),
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
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
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

// ── Small reusable widgets ─────────────────────────────────────────────────────

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
    final (label, bg, fg) = switch (status) {
      ProductStatus.inStock => ('In Stock', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      ProductStatus.lowStock => ('Low Stock', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      ProductStatus.outOfStock => ('Out of Stock', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
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
