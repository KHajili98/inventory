import 'package:flutter/material.dart';
import 'package:inventory/core/utils/responsive.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final List<_CartItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  double _totalAmount = 0.0;

  // Demo products
  final List<_Product> _products = [
    _Product(id: '1', name: 'Product 1', price: 10.50, barcode: '123456789'),
    _Product(id: '2', name: 'Product 2', price: 25.00, barcode: '987654321'),
    _Product(id: '3', name: 'Product 3', price: 15.75, barcode: '456789123'),
    _Product(id: '4', name: 'Product 4', price: 8.99, barcode: '789123456'),
    _Product(id: '5', name: 'Product 5', price: 32.50, barcode: '321654987'),
    _Product(id: '6', name: 'Product 6', price: 12.25, barcode: '654987321'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(_Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(_CartItem(product: product, quantity: 1));
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _updateQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _totalAmount = 0.0;
    });
  }

  void _completeSale() {
    if (_cartItems.isEmpty) return;

    // TODO: Implement actual sale completion logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Completed'),
        content: Text('Total: \$${_totalAmount.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(padding: EdgeInsets.all(context.responsivePadding), child: isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Products
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right side - Cart
        Expanded(flex: 1, child: _buildCart()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        Expanded(child: _buildProductGrid()),
        _buildMobileCartSummary(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products or scan barcode...',
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1)),
            onPressed: () {
              // TODO: Implement barcode scanner
            },
          ),
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
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isMobile ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(_Product product) {
    return InkWell(
      onTap: () => _addToCart(product),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Center(child: Icon(Icons.inventory_2_rounded, size: 48, color: Color(0xFF94A3B8))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const Spacer(),
                Text('${_cartItems.length} items', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 16),
                        Text('Cart is empty', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item, index);
                    },
                  ),
          ),

          // Cart Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '\$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cartItems.isEmpty ? null : _clearCart,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _cartItems.isEmpty ? null : _completeSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Complete Sale'),
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
  }

  Widget _buildCartItem(_CartItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text('\$${item.product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                onPressed: () => _updateQuantity(index, item.quantity - 1),
                color: const Color(0xFF64748B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                onPressed: () => _updateQuantity(index, item.quantity + 1),
                color: const Color(0xFF6366F1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: () => _removeFromCart(index),
            color: const Color(0xFFEF4444),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_cartItems.length} items', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                Text(
                  '\$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _cartItems.isEmpty
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.7,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder: (context, scrollController) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  child: _buildCart(),
                                );
                              },
                            ),
                          );
                        },
                  icon: const Icon(Icons.shopping_cart_rounded),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF6366F1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : _completeSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Complete Sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _Product {
  final String id;
  final String name;
  final double price;
  final String barcode;

  _Product({required this.id, required this.name, required this.price, required this.barcode});
}

class _CartItem {
  final _Product product;
  int quantity;

  _CartItem({required this.product, required this.quantity});
}
