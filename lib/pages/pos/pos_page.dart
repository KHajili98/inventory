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
    _Product(id: '1', name: 'iPhone 15 Pro, Qara', retailPrice: 2350, wholesalePrice: 2200, costPrice: 2000, barcode: '123456789'),
    _Product(id: '2', name: 'Nike Air Max, 43', retailPrice: 120, wholesalePrice: 100, costPrice: 80, barcode: '987654321'),
    _Product(id: '3', name: 'T-shirt, Ağ, M', retailPrice: 25, wholesalePrice: 20, costPrice: 15, barcode: '456789123'),
    _Product(id: '4', name: 'Samsung Galaxy S24', retailPrice: 1800, wholesalePrice: 1650, costPrice: 1500, barcode: '111222333'),
    _Product(id: '5', name: 'Adidas Sneakers, 42', retailPrice: 150, wholesalePrice: 130, costPrice: 110, barcode: '444555666'),
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
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 16),

                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildProductTable()),
                          const SizedBox(height: 16),
                          _buildBottomButtons(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(width: 400, child: _buildSummaryPanel()),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'POS - Nizami Filialı Kassa',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF667EEA)),
                    const SizedBox(width: 4),
                    Text(_currentUser, style: const TextStyle(fontSize: 13, color: Color(0xFF718096))),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF667EEA)),
                    const SizedBox(width: 4),
                    Text(_currentDate, style: const TextStyle(fontSize: 13, color: Color(0xFF718096))),
                  ],
                ),
              ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Barkod oxut və ya məhsul axtar...',
                hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, color: Color(0xFF2D3748)),
              onChanged: (value) => setState(() {}), // Trigger rebuild for dropdown
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Color(0xFF718096)),
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
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_Product>(
                value: _selectedDropdownProduct,
                hint: const Text('Siyahıdan seçin...', style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 15)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667EEA)),
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
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text('Barkod: ${product.barcode}', style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF48BB78), Color(0xFF38A169)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${price.toStringAsFixed(0)} ₼',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFFF7FAFC), shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCBD5E0)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Səbət boşdur',
                          style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text('Məhsul əlavə etmək üçün axtar', style: TextStyle(color: Color(0xFFCBD5E0), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final unitPrice = _getCurrentPrice(item.product);
                      final costPrice = item.product.costPrice;
                      final maxDiscountAmount = unitPrice - costPrice; // Max discount to not go below cost
                      final maxDiscountPercent = unitPrice > 0 ? (maxDiscountAmount / unitPrice * 100) : 0.0;

                      final discountAmount = unitPrice * item.discountPercent / 100;
                      final priceAfterDiscount = unitPrice - discountAmount;
                      final total = priceAfterDiscount * item.quantity;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.product.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuantityButton(Icons.remove, () => _updateQuantity(index, item.quantity - 1)),
                                  Container(
                                    width: 40,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
                                    ),
                                  ),
                                  _buildQuantityButton(Icons.add, () => _updateQuantity(index, item.quantity + 1)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(
                                  '${unitPrice.toStringAsFixed(2)} ₼',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
                                ),
                              ),
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
                                    height: 36,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.discountPercent > 0 ? item.discountPercent.toStringAsFixed(0) : '',
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                                          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                                        ),
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E0)),
                                      ),
                                      onChanged: (value) {
                                        final percent = double.tryParse(value) ?? 0.0;
                                        // Limit to max discount percent
                                        final limitedPercent = percent > maxDiscountPercent ? maxDiscountPercent : percent;
                                        setState(() {
                                          _cartItems[index].discountPercent = limitedPercent;
                                        });
                                        // Show warning if exceeded
                                        if (percent > maxDiscountPercent) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Endirim maya dəyərindən (${costPrice.toStringAsFixed(2)} ₼) aşağı düşə bilməz!'),
                                              backgroundColor: Colors.orange,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '%',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF718096)),
                                  ),
                                  const SizedBox(width: 8),
                                  // Amount field
                                  SizedBox(
                                    width: 60,
                                    height: 36,
                                    child: TextField(
                                      controller: TextEditingController(text: discountAmount > 0 ? discountAmount.toStringAsFixed(2) : ''),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                                          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                                        ),
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E0)),
                                      ),
                                      onChanged: (value) {
                                        final amount = double.tryParse(value) ?? 0.0;
                                        // Limit to max discount amount
                                        final limitedAmount = amount > maxDiscountAmount ? maxDiscountAmount : amount;
                                        final percent = unitPrice > 0 ? (limitedAmount / unitPrice * 100) : 0.0;
                                        setState(() {
                                          _cartItems[index].discountPercent = percent;
                                        });
                                        // Show warning if exceeded
                                        if (amount > maxDiscountAmount) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Maksimum endirim: ${maxDiscountAmount.toStringAsFixed(2)} ₼ (Maya: ${costPrice.toStringAsFixed(2)} ₼)',
                                              ),
                                              backgroundColor: Colors.orange,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '₼',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF718096)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF48BB78), Color(0xFF38A169)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${total.toStringAsFixed(2)} ₼',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFFC8181),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cartItems.isEmpty ? null : _freezeOrder,
            icon: const Icon(Icons.pause_circle_outline, size: 20),
            label: const Text('Sifarişi Dondur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED8936),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFFA0AEC0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showFrozenOrdersDialog,
            icon: Badge(label: Text('${_frozenOrders.length}'), isLabelVisible: _frozenOrders.isNotEmpty, child: const Icon(Icons.history, size: 20)),
            label: const Text('Donmuş Sifarişlər', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4299E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Səbəti Təmizlə', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7FAFC),
              foregroundColor: const Color(0xFF718096),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Price Type
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qiymət Növü',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPriceTypeButton(PriceType.retail, 'Pərakəndə')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPriceTypeButton(PriceType.wholesale, 'Topdan')),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            // Payment
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ödəniş Metodu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.cash, 'Nağd')),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.card, 'Kart')),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.transfer, 'Köçürmə')),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            // Discount
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 18, color: Color(0xFF667EEA)),
                      const SizedBox(width: 8),
                      const Text(
                        'Endirim',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFED7D7), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${_globalDiscountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC53030)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _discountEnabled ? const Color(0xFF667EEA) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _discountEnabled,
                            onChanged: _onDiscountEnabledChanged,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            fillColor: WidgetStateProperty.all(Colors.transparent),
                            checkColor: Colors.white,
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          enabled: _discountEnabled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _discountEnabled ? const Color(0xFFF7FAFC) : const Color(0xFFFAFAFA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          onChanged: _onDiscountFieldChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF718096)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '₼',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF718096)),
                        ),
                      ),
                    ],
                  ),
                  if (_discountEnabled) ...[
                    const SizedBox(height: 12),
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
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('Ara Cəmi:', '${subtotal.toStringAsFixed(2)} ₼'),
                  if (discount > 0)
                    _buildSummaryRow(
                      'Endirim (${_globalDiscountPercent.toStringAsFixed(0)}%):',
                      '${discount.toStringAsFixed(2)} ₼',
                      isDiscount: true,
                    ),
                  if (customerDiscount > 0 && _selectedCustomer != null)
                    _buildSummaryRow(
                      'Müştəri Endirimi (${_selectedCustomer!.discountPercent}%):',
                      '${customerDiscount.toStringAsFixed(2)} ₼',
                      isDiscount: true,
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ödəniləcək:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)} ₼',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _completeSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48BB78),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFFA0AEC0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print, size: 22),
                          SizedBox(width: 12),
                          Text('SATIŞI TAMAMLA (F12)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCustomerDialog,
                      icon: Icon(_selectedCustomer != null ? Icons.person : Icons.person_add_outlined, size: 20),
                      label: Text(
                        _selectedCustomer != null ? 'Müştəri: ${_selectedCustomer!.name}' : 'Müştəri Seç',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCustomer != null ? const Color(0xFF9F7AEA) : const Color(0xFFF7FAFC),
                        foregroundColor: _selectedCustomer != null ? Colors.white : const Color(0xFF718096),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentBadgeButton(int percent) {
    final isSelected = _selectedDiscountBadge == percent;
    return InkWell(
      onTap: _discountEnabled ? () => _onDiscountBadgeSelected(percent) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0xFFF7FAFC),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$percent%',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (_discountEnabled ? const Color(0xFF2D3748) : const Color(0xFFA0AEC0)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDiscount ? const Color(0xFFC53030) : const Color(0xFF2D3748)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(PaymentMethod method, String label) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0xFFF7FAFC),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF4A5568)),
        ),
      ),
    );
  }

  Widget _buildPriceTypeButton(PriceType type, String label) {
    final isSelected = _priceType == type;
    return InkWell(
      onTap: () => setState(() => _priceType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0xFFF7FAFC),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF4A5568)),
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
  final double costPrice;
  final String barcode;

  _Product({
    required this.id,
    required this.name,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.costPrice,
    required this.barcode,
  });
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
