import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum PriceType { retail, wholesale }

enum PaymentMethod { cash, card, transfer }

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final List<_CartItem> _cartItems = [];
  final List<_FrozenOrder> _frozenOrders = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _discountEnabled = false;
  double _globalDiscountPercent = 0.0;
  int? _selectedDiscountBadge;
  _Product? _selectedDropdownProduct;

  PriceType _priceType = PriceType.retail;
  _Customer? _selectedCustomer;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;

  final String _currentUser = 'Əhməd R.';
  final String _currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

  final List<_Product> _products = [
    _Product(id: '1', name: 'iPhone 15 Pro, Qara', retailPrice: 2350, wholesalePrice: 2200, barcode: '123456789'),
    _Product(id: '2', name: 'Nike Air Max, 43', retailPrice: 120, wholesalePrice: 100, barcode: '987654321'),
    _Product(id: '3', name: 'T-shirt, Ağ, M', retailPrice: 25, wholesalePrice: 20, barcode: '456789123'),
    _Product(id: '4', name: 'Samsung Galaxy S24', retailPrice: 1800, wholesalePrice: 1650, barcode: '111222333'),
    _Product(id: '5', name: 'Adidas Sneakers, 42', retailPrice: 150, wholesalePrice: 130, barcode: '444555666'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus search field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _onSearchSubmitted(String value) {
    if (value.isEmpty) return;

    // Try to find exact barcode match
    final product = _products.cast<_Product?>().firstWhere((p) => p?.barcode == value, orElse: () => null);

    if (product != null) {
      _addToCart(product);
      _searchController.clear();
      setState(() {
        _selectedDropdownProduct = null;
      });
      // Keep focus on search
      _searchFocusNode.requestFocus();
    }
  }

  void _onDropdownChanged(_Product? product) {
    if (product == null) return;
    _addToCart(product);
    _searchController.clear();
    setState(() {
      _selectedDropdownProduct = null;
    });
    // Keep focus on search for next scan
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  double _getCurrentPrice(_Product product) {
    return _priceType == PriceType.retail ? product.retailPrice : product.wholesalePrice;
  }

  void _addToCart(_Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(_CartItem(product: product, quantity: 1, discountPercent: _discountEnabled ? _globalDiscountPercent : 0.0));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    // Keep focus on search after removing item
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _updateQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
    });
    // Keep focus on search after quantity update
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _onDiscountEnabledChanged(bool? value) {
    setState(() {
      _discountEnabled = value ?? false;
      if (!_discountEnabled) {
        _globalDiscountPercent = 0.0;
        _selectedDiscountBadge = null;
        _discountController.clear();
        for (var item in _cartItems) {
          item.discountPercent = 0.0;
        }
      }
    });
  }

  void _onDiscountBadgeSelected(int percent) {
    setState(() {
      _selectedDiscountBadge = percent;
      _globalDiscountPercent = percent.toDouble();
      _discountController.text = percent.toString();
      for (var item in _cartItems) {
        item.discountPercent = _globalDiscountPercent;
      }
    });
  }

  void _onDiscountFieldChanged(String value) {
    final percent = double.tryParse(value) ?? 0.0;
    setState(() {
      _globalDiscountPercent = percent;
      _selectedDiscountBadge = null;
      for (var item in _cartItems) {
        item.discountPercent = _globalDiscountPercent;
      }
    });
  }

  double _calculateSubtotal() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = _getCurrentPrice(item.product);
      return sum + (price * item.quantity);
    });
  }

  double _calculateTotalDiscount() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = _getCurrentPrice(item.product);
      final itemTotal = price * item.quantity;
      return sum + (itemTotal * item.discountPercent / 100);
    });
  }

  double _calculateCustomerDiscount() {
    if (_selectedCustomer == null) return 0.0;
    final subtotal = _calculateSubtotal();
    final discount = _calculateTotalDiscount();
    final afterDiscount = subtotal - discount;
    return afterDiscount * _selectedCustomer!.discountPercent / 100;
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateTotalDiscount();
    final customerDiscount = _calculateCustomerDiscount();
    return subtotal - discount - customerDiscount;
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    // Keep focus on search after clearing cart
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _freezeOrder() {
    if (_cartItems.isEmpty) return;

    final order = _FrozenOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(_cartItems),
      priceType: _priceType,
      customer: _selectedCustomer,
      paymentMethod: _selectedPaymentMethod,
      timestamp: DateTime.now(),
    );

    setState(() {
      _frozenOrders.add(order);
      _cartItems.clear();
      _selectedCustomer = null;
      _discountEnabled = false;
      _globalDiscountPercent = 0.0;
      _selectedDiscountBadge = null;
      _discountController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sifariş donduruldu (#${_frozenOrders.length})'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );

    // Keep focus on search after freezing order
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _showFrozenOrdersDialog() {
    if (_frozenOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dondurulmuş sifariş yoxdur')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dondurulmuş Sifarişlər'),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _frozenOrders.length,
            itemBuilder: (context, index) {
              final order = _frozenOrders[index];
              final total = order.items.fold(0.0, (sum, item) {
                final price = order.priceType == PriceType.retail ? item.product.retailPrice : item.product.wholesalePrice;
                return sum + (price * item.quantity);
              });
              return Card(
                child: ListTile(
                  title: Text('Sifariş #${index + 1}'),
                  subtitle: Text('${order.items.length} məhsul - ${DateFormat('HH:mm').format(order.timestamp)}'),
                  trailing: Text('${total.toStringAsFixed(2)} ₼', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _restoreFrozenOrder(order);
                    setState(() {
                      _frozenOrders.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bağla'))],
      ),
    );
  }

  void _restoreFrozenOrder(_FrozenOrder order) {
    setState(() {
      _cartItems.clear();
      _cartItems.addAll(order.items.map((item) => _CartItem(product: item.product, quantity: item.quantity, discountPercent: item.discountPercent)));
      _priceType = order.priceType;
      _selectedCustomer = order.customer;
      _selectedPaymentMethod = order.paymentMethod;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sifariş bərpa edildi'), backgroundColor: Color(0xFF4CAF50)));

    // Keep focus on search after restoring order
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _completeSale() {
    if (_cartItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Satış Tamamlandı'),
        content: Text('Yekun: ${_calculateTotal().toStringAsFixed(2)} ₼'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
              setState(() {
                _selectedCustomer = null;
              });
              // Keep focus on search after completing sale
              Future.microtask(() => _searchFocusNode.requestFocus());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog() {
    final cardController = TextEditingController();
    _Customer? tempCustomer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Müştəri Seç'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: cardController,
                  decoration: const InputDecoration(labelText: 'Loayallıq Kartı Nömrəsi', border: OutlineInputBorder(), hintText: 'Məsələn: 12345'),
                  onChanged: (value) {
                    if (value == '12345') {
                      setDialogState(() {
                        tempCustomer = _Customer(id: '1', name: 'Elvin Məmmədov', loyaltyCard: '12345', discountPercent: 10);
                      });
                    } else {
                      setDialogState(() {
                        tempCustomer = null;
                      });
                    }
                  },
                ),
                if (tempCustomer != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      border: Border.all(color: const Color(0xFF4CAF50)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓ Müştəri Tapıldı',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 8),
                        Text('Ad: ${tempCustomer!.name}'),
                        Text('Endirim: ${tempCustomer!.discountPercent}%'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.microtask(() => _searchFocusNode.requestFocus());
              },
              child: const Text('Ləğv et'),
            ),
            ElevatedButton(
              onPressed: tempCustomer != null
                  ? () {
                      setState(() {
                        _selectedCustomer = tempCustomer;
                      });
                      Navigator.pop(context);
                      Future.microtask(() => _searchFocusNode.requestFocus());
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              child: const Text('Seç'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Re-focus search when clicking anywhere in the POS area
        _searchFocusNode.requestFocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4A6C8F),
        body: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 12),
                          Expanded(child: _buildProductTable()),
                          const SizedBox(height: 12),
                          _buildBottomButtons(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(width: 360, child: _buildSummaryPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5B7A9D), Color(0xFF4A6C8F)])),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text(
              'POS - Nizami Filialı Kassa',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            Text('Satıcı: $_currentUser', style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(width: 24),
            Text('Tarix: $_currentDate', style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), foregroundColor: Colors.white),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // Get filtered products based on search
    final filteredProducts = _searchController.text.isEmpty
        ? _products
        : _products.where((product) {
            final searchLower = _searchController.text.toLowerCase();
            return product.name.toLowerCase().contains(searchLower) || product.barcode.contains(_searchController.text);
          }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB0BEC5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF607D8B)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Barkod oxut və ya axtar...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() {}), // Trigger rebuild for dropdown
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedDropdownProduct = null;
                });
                _searchFocusNode.requestFocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
          const SizedBox(width: 8),
          const Text('|', style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_Product>(
                value: _selectedDropdownProduct,
                hint: Text('Məhsul seçin...', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF607D8B)),
                items: filteredProducts.map((product) {
                  final price = _getCurrentPrice(product);
                  return DropdownMenuItem<_Product>(
                    value: product,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Barkod: ${product.barcode}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${price.toStringAsFixed(0)} ₼',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onDropdownChanged,
                dropdownColor: Colors.white,
                menuMaxHeight: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB0BEC5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF616161),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Məhsul',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      'Miqdar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      'Vahid Qiymət',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Center(
                    child: Text(
                      'Endirim',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      'Toplam',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      'Sil',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Text('Səbət boşdur', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final unitPrice = _getCurrentPrice(item.product);
                      final discountAmount = unitPrice * item.discountPercent / 100;
                      final priceAfterDiscount = unitPrice - discountAmount;
                      final total = priceAfterDiscount * item.quantity;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? const Color(0xFFF5F5F5) : Colors.white,
                          border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuantityButton(Icons.remove, () => _updateQuantity(index, item.quantity - 1)),
                                  Container(
                                    width: 40,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  _buildQuantityButton(Icons.add, () => _updateQuantity(index, item.quantity + 1)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Center(child: Text('${unitPrice.toStringAsFixed(2)} ₼', style: const TextStyle(fontSize: 14))),
                            ),
                            // Discount fields (percent and amount)
                            SizedBox(
                              width: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Percent field
                                  SizedBox(
                                    width: 50,
                                    height: 32,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.discountPercent > 0 ? item.discountPercent.toStringAsFixed(0) : '',
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                      ),
                                      onChanged: (value) {
                                        final percent = double.tryParse(value) ?? 0.0;
                                        setState(() {
                                          _cartItems[index].discountPercent = percent;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  // Amount field
                                  SizedBox(
                                    width: 60,
                                    height: 32,
                                    child: TextField(
                                      controller: TextEditingController(text: discountAmount > 0 ? discountAmount.toStringAsFixed(2) : ''),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                      ),
                                      onChanged: (value) {
                                        final amount = double.tryParse(value) ?? 0.0;
                                        final percent = unitPrice > 0 ? (amount / unitPrice * 100) : 0.0;
                                        setState(() {
                                          _cartItems[index].discountPercent = percent;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('₼', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Text('${total.toStringAsFixed(2)} ₼', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFD32F2F),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  onPressed: () => _removeFromCart(index),
                                ),
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

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cartItems.isEmpty ? null : _freezeOrder,
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('Sifarişi Dondur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA726),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: Colors.black38,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showFrozenOrdersDialog,
            icon: Badge(label: Text('${_frozenOrders.length}'), isLabelVisible: _frozenOrders.isNotEmpty, child: const Icon(Icons.history)),
            label: const Text('Donmuş Sifarişlər'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Səbəti Təmizlə'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateTotalDiscount();
    final customerDiscount = _calculateCustomerDiscount();
    final total = _calculateTotal();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB0BEC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Price Type
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qiymət Növü', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFB0BEC5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PriceType>(
                      value: _priceType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: PriceType.retail, child: Text('Pərakəndə')),
                        DropdownMenuItem(value: PriceType.wholesale, child: Text('Topdan')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _priceType = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Discount
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFB0BEC5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Endirim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${_globalDiscountPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _discountEnabled,
                        onChanged: _onDiscountEnabledChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        enabled: _discountEnabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _discountEnabled ? Colors.white : const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: _onDiscountFieldChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB0BEC5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB0BEC5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('₼', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_discountEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPercentBadgeButton(5)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPercentBadgeButton(10)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFB0BEC5))),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Ara Cəmi:', '${subtotal.toStringAsFixed(2)} ₼'),
                if (discount > 0) _buildSummaryRow('Endirim (${_globalDiscountPercent.toStringAsFixed(0)}%):', '${discount.toStringAsFixed(2)} ₼'),
                if (customerDiscount > 0 && _selectedCustomer != null)
                  _buildSummaryRow('Müştəri Endirimi (${_selectedCustomer!.discountPercent}%):', '${customerDiscount.toStringAsFixed(2)} ₼'),
                const Divider(thickness: 2, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ödəniləcək:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${total.toStringAsFixed(2)} ₼', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          // Payment
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFB0BEC5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ödəniş Metodu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPaymentMethodButton(PaymentMethod.cash, Icons.money, 'Nağd')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPaymentMethodButton(PaymentMethod.card, Icons.credit_card, 'Kart')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPaymentMethodButton(PaymentMethod.transfer, Icons.account_balance, 'Köçürmə')),
                  ],
                ),
              ],
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : _completeSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print),
                        SizedBox(width: 8),
                        Text('[SATIŞI TAMAMLA (F12)]', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showCustomerDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9E9E9E),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      _selectedCustomer != null ? 'Müştəri: ${_selectedCustomer!.name}' : 'Müştəri Seç',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentBadgeButton(int percent) {
    final isSelected = _selectedDiscountBadge == percent;
    return InkWell(
      onTap: _discountEnabled ? () => _onDiscountBadgeSelected(percent) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFB0BEC5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$percent%',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (_discountEnabled ? Colors.black : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF90CAF9) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFB0BEC5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1976D2) : Colors.black54, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1976D2) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Product {
  final String id;
  final String name;
  final double retailPrice;
  final double wholesalePrice;
  final String barcode;

  _Product({required this.id, required this.name, required this.retailPrice, required this.wholesalePrice, required this.barcode});
}

class _CartItem {
  final _Product product;
  int quantity;
  double discountPercent;

  _CartItem({required this.product, required this.quantity, this.discountPercent = 0.0});
}

class _Customer {
  final String id;
  final String name;
  final String loyaltyCard;
  final double discountPercent;

  _Customer({required this.id, required this.name, required this.loyaltyCard, required this.discountPercent});
}

class _FrozenOrder {
  final String id;
  final List<_CartItem> items;
  final PriceType priceType;
  final _Customer? customer;
  final PaymentMethod paymentMethod;
  final DateTime timestamp;

  _FrozenOrder({required this.id, required this.items, required this.priceType, this.customer, required this.paymentMethod, required this.timestamp});
}
