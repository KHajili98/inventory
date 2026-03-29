import 'package:flutter/material.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/stock_models.dart';

class AddStockProductRequest extends StatefulWidget {
  final List<StockItem> availableStockItems;
  final List<String> inventories;

  const AddStockProductRequest({super.key, required this.availableStockItems, required this.inventories});

  @override
  State<AddStockProductRequest> createState() => _AddStockProductRequestState();
}

class _AddStockProductRequestState extends State<AddStockProductRequest> {
  String? _fromInventory;
  String? _toInventory;
  String _searchQuery = '';
  final List<RequestedItem> _requestedItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockItem> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return widget.availableStockItems.take(5).toList();
    }

    final results = widget.availableStockItems.where((item) {
      return item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.modelCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.productCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.barcode.contains(_searchQuery);
    }).toList();

    return results.take(5).toList();
  }

  void _addToRequest(StockItem item, int quantity) {
    setState(() {
      final existingIndex = _requestedItems.indexWhere((r) => r.stockItem.barcode == item.barcode);
      if (existingIndex != -1) {
        _requestedItems[existingIndex] = RequestedItem(
          stockItem: item,
          requestedQuantity: _requestedItems[existingIndex].requestedQuantity + quantity,
        );
      } else {
        _requestedItems.add(RequestedItem(stockItem: item, requestedQuantity: quantity));
      }
    });
  }

  void _removeFromRequest(int index) {
    setState(() {
      _requestedItems.removeAt(index);
    });
  }

  void _submitRequest() {
    final l10n = AppLocalizations.of(context)!;

    if (_fromInventory == null || _toInventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectFromAndTo), backgroundColor: Colors.orange));
      return;
    }

    if (_requestedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAddProducts), backgroundColor: Colors.orange));
      return;
    }

    // TODO: Implement actual request submission logic here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.stockRequestCreated), backgroundColor: Colors.green));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    l10n.createStockRequest,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From/To dropdowns
                    Row(
                      children: [
                        Expanded(child: _buildInventoryDropdown(l10n.from, _fromInventory, (value) => setState(() => _fromInventory = value))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInventoryDropdown(l10n.to, _toInventory, (value) => setState(() => _toInventory = value))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: l10n.searchProducts,
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product list
                    if (_filteredProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(l10n.noProductsFound, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                        ),
                      )
                    else
                      ..._filteredProducts.map((product) => _ProductListItem(product: product, onAddToRequest: _addToRequest)),

                    if (_requestedItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // Requested items section
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart_rounded, size: 18, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.requestedItems,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${_requestedItems.length}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._requestedItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _RequestedItemCard(item: item, onRemove: () => _removeFromRequest(index));
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // Footer with submit button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(l10n.submitRequest, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryDropdown(String label, String? value, Function(String?) onChanged) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(l10n.selectInventory, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              onChanged: onChanged,
              items: widget.inventories.map((inventory) {
                return DropdownMenuItem(
                  value: inventory,
                  child: Text(inventory, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductListItem extends StatefulWidget {
  final StockItem product;
  final Function(StockItem, int) onAddToRequest;

  const _ProductListItem({required this.product, required this.onAddToRequest});

  @override
  State<_ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<_ProductListItem> {
  bool _isExpanded = false;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isExpanded ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.productName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${l10n.productCode}: ${widget.product.productCode}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 12),
                            Text('${l10n.barcode}: ${widget.product.barcode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${widget.product.quantity} ${l10n.pcs}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.requestedQuantity,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final quantity = int.tryParse(_quantityController.text) ?? 0;
                      if (quantity > 0) {
                        widget.onAddToRequest(widget.product, quantity);
                        setState(() {
                          _isExpanded = false;
                          _quantityController.text = '1';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(l10n.addToRequest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestedItemCard extends StatelessWidget {
  final RequestedItem item;
  final VoidCallback onRemove;

  const _RequestedItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.stockItem.productName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text('${l10n.barcode}: ${item.stockItem.barcode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${item.requestedQuantity} ${l10n.pcs}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFFEF4444),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestedItem {
  final StockItem stockItem;
  final int requestedQuantity;

  RequestedItem({required this.stockItem, required this.requestedQuantity});
}
