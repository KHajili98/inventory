import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/features/auth/auth_service.dart';
import 'package:inventory/features/loyal_customers/data/models/customer_model.dart';
import 'package:inventory/features/loyal_customers/data/repositories/customers_repository.dart';
import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';
import 'package:inventory/features/selling_transactions/data/repositories/selling_transactions_repository.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';
import 'package:inventory/models/auth_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

enum PriceType { retail, wholesale }

enum PaymentMethod { cash, card, transfer }

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final List<_CartItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Cached PDF font bytes (loaded once, reused on every PDF export)
  static Uint8List? _pdfFontRegular;
  static Uint8List? _pdfFontBold;

  bool _discountEnabled = false;
  double _globalDiscountPercent = 0.0;
  int? _selectedDiscountBadge;
  bool _discountIsPercent = true; // true for %, false for AZN

  PriceType _priceType = PriceType.retail;
  CustomerModel? _selectedCustomer;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;

  final String _currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

  AuthUser? _authUser;
  LoginInventory? _loggedInInventory;

  List<StockProductItemModel> _searchResults = [];
  bool _isSearching = false;
  bool _isCompletingSale = false;
  StockProductItemModel? _selectedDropdownProduct;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
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
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final loginResponse = await AuthService.instance.getLoginResponse();
    if (loginResponse != null && mounted) {
      setState(() {
        _authUser = loginResponse.user;
        _loggedInInventory = loginResponse.loggedInInventory;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    if (value.isEmpty) return;
    // Try exact barcode match from current results
    final product = _searchResults.cast<StockProductItemModel?>().firstWhere((p) => p?.barcode == value, orElse: () => null);
    if (product != null) {
      _addToCart(product);
      _searchController.clear();
      setState(() {
        _searchResults = [];
        _selectedDropdownProduct = null;
      });
      _searchFocusNode.requestFocus();
    }
  }

  void _onDropdownChanged(StockProductItemModel? product) {
    if (product == null) return;
    _addToCart(product);
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _selectedDropdownProduct = null;
    });
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchStocks(value));
  }

  Future<void> _searchStocks(String query) async {
    if (_loggedInInventory == null) return;
    setState(() => _isSearching = true);
    final result = await StocksRepository.instance.fetchStocks(search: query, inventoryId: _loggedInInventory!.id, priced: true, pageSize: 30);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // Filter to products with stock and deduplicate by id to prevent
        // DropdownButton assertion errors with duplicate values.
        final seen = <String>{};
        setState(() {
          _searchResults = data.results.where((p) => p.quantity > 0 && seen.add(p.id)).toList();
          _isSearching = false;
        });
      case Failure():
        setState(() => _isSearching = false);
    }
  }

  double _getCurrentPrice(StockProductItemModel product) {
    return _priceType == PriceType.retail ? (product.retailUnitPrice ?? 0.0) : (product.wholeUnitSalesPrice ?? 0.0);
  }

  void _addToCart(StockProductItemModel product) {
    setState(() {
      // Log barcode for debugging
      log('Adding product to cart: ${product.displayName}, barcode: ${product.barcode}');

      // Use barcode as the unique key when available so that products with
      // the same name but different barcodes are treated as separate items,
      // and the same physical product (same barcode) always increments quantity.
      final existingIndex = _cartItems.indexWhere((item) {
        if (product.barcode != null && product.barcode!.isNotEmpty) {
          return item.product.barcode == product.barcode;
        }
        return item.product.id == product.id;
      });
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
    if (_discountIsPercent) {
      // Percentage mode
      var percent = double.tryParse(value) ?? 0.0;
      // Limit to 100%
      if (percent > 100) {
        percent = 100;
        _discountController.text = '100';
        _discountController.selection = TextSelection.fromPosition(TextPosition(offset: _discountController.text.length));
      }
      setState(() {
        _globalDiscountPercent = percent;
        _selectedDiscountBadge = null;
        for (var item in _cartItems) {
          item.discountPercent = _globalDiscountPercent;
        }
      });
    } else {
      // Amount mode (AZN)
      final amount = double.tryParse(value) ?? 0.0;
      final subtotal = _calculateSubtotal();
      // Calculate percentage from amount
      final percent = subtotal > 0 ? (amount / subtotal * 100) : 0.0;
      // Limit to 100%
      final limitedPercent = (percent > 100 ? 100.0 : percent.toDouble());
      setState(() {
        _globalDiscountPercent = limitedPercent;
        _selectedDiscountBadge = null;
        for (var item in _cartItems) {
          item.discountPercent = _globalDiscountPercent;
        }
      });
    }
  }

  double _calculateSubtotal() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = _getCurrentPrice(item.product);
      return sum + (price * item.quantity);
    });
  }

  /// The combined discount % = custom discount % + customer loyalty discount %.
  /// Both are summed and applied once to the subtotal.
  double _combinedDiscountPercent() {
    final customPercent = _discountEnabled ? _globalDiscountPercent : 0.0;
    final customerPercent = _selectedCustomer?.discountPercentage ?? 0.0;
    return customPercent + customerPercent;
  }

  double _calculateTotalDiscount() {
    final subtotal = _calculateSubtotal();
    return subtotal * _combinedDiscountPercent() / 100;
  }

  /// Portion of the total discount attributable to the custom (manual) discount.
  double _calculateCustomDiscount() {
    if (!_discountEnabled || _globalDiscountPercent == 0) return 0.0;
    final subtotal = _calculateSubtotal();
    return subtotal * _globalDiscountPercent / 100;
  }

  /// Portion of the total discount attributable to the customer loyalty discount.
  double _calculateCustomerDiscount() {
    if (_selectedCustomer == null) return 0.0;
    final subtotal = _calculateSubtotal();
    return subtotal * _selectedCustomer!.discountPercentage / 100;
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _calculateTotalDiscount();
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    // Keep focus on search after clearing cart
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  SellingPriceType get _sellingPriceType => _priceType == PriceType.retail ? SellingPriceType.retailSale : SellingPriceType.wholeSale;

  SellingPaymentMethod get _sellingPaymentMethod {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        return SellingPaymentMethod.cash;
      case PaymentMethod.card:
        return SellingPaymentMethod.card;
      case PaymentMethod.transfer:
        return SellingPaymentMethod.transfer;
    }
  }

  /// Rounds a monetary price/amount value to max 3 decimal places.
  double _rPrice(double v) => double.parse(v.toStringAsFixed(3));

  /// Rounds a percentage value to max 2 decimal places
  /// (server rejects more than 2 decimals for percentage fields).
  double _rPct(double v) => double.parse(v.toStringAsFixed(2));

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) return;
    if (_loggedInInventory == null) return;
    if (_isCompletingSale) return;

    setState(() => _isCompletingSale = true);

    final totalDiscount = _rPrice(_calculateTotalDiscount());
    final combinedPercent = _rPct(_combinedDiscountPercent());
    final total = _rPrice(_calculateTotal());

    final items = _cartItems.map((item) {
      final unitPrice = _getCurrentPrice(item.product);
      final itemDiscountAmount = _rPrice(unitPrice * item.discountPercent / 100 * item.quantity);
      final itemTotal = _rPrice((unitPrice - unitPrice * item.discountPercent / 100) * item.quantity);

      // Determine the correct product UUID - prioritize sourceProductUuid, then id
      final productUuid = (item.product.sourceProductUuid != null && item.product.sourceProductUuid!.isNotEmpty)
          ? item.product.sourceProductUuid!
          : item.product.id;

      // Log product details for debugging
      log('Preparing item for sale: ${item.product.displayName}');
      log('  - id: ${item.product.id}');
      log('  - sourceProductUuid: ${item.product.sourceProductUuid}');
      log('  - Using productUuid: $productUuid');
      log('  - barcode: ${item.product.barcode}');

      return SellingTransactionItemRequest(
        productUuid: productUuid,
        count: item.quantity,
        discountPercentage: _rPct(item.discountPercent),
        discountAmount: itemDiscountAmount,
        totalPrice: itemTotal,
        barcode: item.product.barcode,
      );
    }).toList();

    // Log the complete request for debugging
    log('Complete payment request items: ${items.map((i) => 'barcode: ${i.barcode}').join(', ')}');

    final request = CompletePaymentRequest(
      loggedInInventoryId: _loggedInInventory!.id,
      selectedLoyalCustomerId: _selectedCustomer?.id,
      totalSellingPrice: total,
      priceType: _sellingPriceType,
      paymentMethod: _sellingPaymentMethod,
      discountAmount: totalDiscount,
      discountPercentage: combinedPercent,
      items: items,
    );

    final result = await SellingTransactionsRepository.instance.completePayment(request);

    if (!mounted) return;
    setState(() => _isCompletingSale = false);

    switch (result) {
      case Success(:final data):
        _showSaleSuccessDialog(data, total);
      case Failure(:final message):
        log(message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.posErrorPrefix(message)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }

  void _showSaleSuccessDialog(SellingTransactionResponse data, double total) {
    final receiptNumber = data.receiptNumber;
    final sellerName = data.sellerDetailedInfo != null ? '${data.sellerDetailedInfo!.firstName} ${data.sellerDetailedInfo!.lastName}'.trim() : null;
    final inventoryName = data.sellingLocationInventoryDetails?.name;
    final inventoryAddress = data.sellingLocationInventoryDetails?.address ?? '';
    final paymentMethodLabel = switch (data.paymentMethod) {
      'cash' => AppLocalizations.of(context)!.posPaymentCash,
      'card' => AppLocalizations.of(context)!.posPaymentCard,
      'transfer' => AppLocalizations.of(context)!.posPaymentTransfer,
      _ => data.paymentMethod,
    };
    final priceTypeLabel = data.priceType == 'retail_sale'
        ? AppLocalizations.of(context)!.posPriceRetail
        : AppLocalizations.of(context)!.posPriceWholesale;
    final itemCount = data.items.fold<int>(0, (sum, i) => sum + i.count);
    final now = data.createdAt ?? DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy  HH:mm').format(now);

    // Snapshot cart items for PDF (capture before cart is cleared)
    final cartSnapshot = List<_CartItem>.from(_cartItems);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Green header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF38A169), Color(0xFF48BB78)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.posSaleSuccess,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),

              // ── Receipt number ─────────────────────────────────────────
              if (receiptNumber.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: const Color(0xFFF0FFF4),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long, size: 16, color: Color(0xFF38A169)),
                        const SizedBox(width: 8),
                        Text(
                          receiptNumber,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF276749), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Details grid ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Total
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.posAmountDue, style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568))),
                          Text(
                            '${total.toStringAsFixed(2)} AZN',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info rows
                    _buildReceiptRow(Icons.local_atm_outlined, AppLocalizations.of(context)!.posPaymentLabel, paymentMethodLabel),
                    _buildReceiptRow(Icons.sell_outlined, AppLocalizations.of(context)!.posPriceTypeLabel, priceTypeLabel),
                    _buildReceiptRow(
                      Icons.shopping_bag_outlined,
                      AppLocalizations.of(context)!.posProductCount,
                      AppLocalizations.of(context)!.posProductCountValue(itemCount),
                    ),
                    if (sellerName != null && sellerName.isNotEmpty)
                      _buildReceiptRow(Icons.person_outline, AppLocalizations.of(context)!.posSeller, sellerName),
                    if (inventoryName != null && inventoryName.isNotEmpty)
                      _buildReceiptRow(Icons.store_outlined, AppLocalizations.of(context)!.posStoreLabel, inventoryName),
                  ],
                ),
              ),

              // ── Action buttons ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Generate PDF button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _generateAndDownloadReceiptPdf(
                          data: data,
                          total: total,
                          cartItems: cartSnapshot,
                          inventoryName: inventoryName,
                          inventoryAddress: inventoryAddress,
                          sellerName: sellerName,
                          paymentMethodLabel: paymentMethodLabel,
                          manualDiscountPercent: _discountEnabled ? _globalDiscountPercent : 0.0,
                          customerDiscountPercent: _selectedCustomer?.discountPercentage ?? 0.0,
                          customerName: _selectedCustomer?.fullName,
                          l10n: AppLocalizations.of(context)!,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                        label: Text(AppLocalizations.of(context)!.posDownloadPdf, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667EEA),
                          side: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // New sale button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearCart();
                          setState(() {
                            _selectedCustomer = null;
                            _discountEnabled = false;
                            _globalDiscountPercent = 0.0;
                            _selectedDiscountBadge = null;
                            _discountController.clear();
                          });
                          Future.microtask(() => _searchFocusNode.requestFocus());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48BB78),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(AppLocalizations.of(context)!.posNewSale, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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

  Future<void> _generateAndDownloadReceiptPdf({
    required SellingTransactionResponse data,
    required double total,
    required List<_CartItem> cartItems,
    required String? inventoryName,
    required String inventoryAddress,
    required String? sellerName,
    required String paymentMethodLabel,
    required double manualDiscountPercent,
    required double customerDiscountPercent,
    required String? customerName,
    required AppLocalizations l10n,
  }) async {
    try {
      // ── Load Unicode font from bundled assets (supports all Azerbaijani chars) ──
      if (_pdfFontRegular == null || _pdfFontBold == null) {
        final regularData = await rootBundle.load('assets/fonts/Arial-Regular.ttf');
        final boldData = await rootBundle.load('assets/fonts/Arial-Bold.ttf');
        _pdfFontRegular = regularData.buffer.asUint8List();
        _pdfFontBold = boldData.buffer.asUint8List();
      }

      final ttfRegular = pw.Font.ttf(_pdfFontRegular!.buffer.asByteData());
      final ttfBold = pw.Font.ttf(_pdfFontBold!.buffer.asByteData());

      // Helper style builders that always use the loaded font
      pw.TextStyle body({bool bold = false, double size = 10, PdfColor? color}) => pw.TextStyle(
        font: bold ? ttfBold : ttfRegular,
        fontBold: ttfBold,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

      final pdf = pw.Document();
      final now = data.createdAt ?? DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy').format(now);
      final subtotal = cartItems.fold(0.0, (sum, item) {
        final price = _getCurrentPrice(item.product);
        return sum + price * item.quantity;
      });
      final manualDiscountAmount = subtotal * manualDiscountPercent / 100;
      final customerDiscountAmount = subtotal * customerDiscountPercent / 100;

      // Load logo
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('logo_aydinoglu.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }

      // ── Colors ─────────────────────────────────────────────────────────────
      const headerYellow = PdfColor.fromInt(0xFFFFD700);
      const headerBlue = PdfColor.fromInt(0xFFADD8E6);
      const tableHeaderRed = PdfColor.fromInt(0xFFD32F2F);
      const tableHeaderBg = PdfColor.fromInt(0xFFFFF9C4);
      const rowBgGray = PdfColor.fromInt(0xFFF5F5F5);
      const borderColor = PdfColor.fromInt(0xFF555555);
      const redText = PdfColor.fromInt(0xFFD32F2F);
      const darkText = PdfColor.fromInt(0xFF212121);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            // Build table data rows
            final tableRows = <List<String>>[];
            for (int i = 0; i < cartItems.length; i++) {
              final item = cartItems[i];
              final unitPrice = _getCurrentPrice(item.product);
              final lineTotal = unitPrice * item.quantity;
              tableRows.add([
                '${i + 1}',
                item.product.displayName,
                l10n.posPdfUnitPcs,
                '${item.quantity}',
                '${unitPrice.toStringAsFixed(2)} AZN',
                '${lineTotal.toStringAsFixed(2)} AZN',
              ]);
            }

            // Cell builder that uses the loaded font
            pw.Widget cell(String text, {bool bold = false, PdfColor? color, pw.TextAlign align = pw.TextAlign.center}) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  text,
                  style: body(bold: bold, size: 9, color: color),
                  textAlign: align,
                ),
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header Row: Logo + store info ──────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 120,
                      height: 110,
                      child: logoImage != null
                          ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                          : pw.Center(child: pw.Text('Aydınoğlu', style: body(bold: true, size: 14))),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            color: headerYellow,
                            child: pw.Text(
                              inventoryAddress.isNotEmpty ? inventoryAddress : (inventoryName ?? 'Aydınoğlu MMC'),
                              style: body(bold: true, color: darkText),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            color: headerBlue,
                            child: pw.Text(
                              l10n.posPdfReceiptNo(data.receiptNumber),
                              style: body(bold: true, color: darkText),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // ── From / To / Date row ───────────────────────────────────
                pw.Row(
                  children: [
                    pw.Text(l10n.posPdfFrom, style: body(bold: true, color: tableHeaderRed)),
                    pw.Text('Aydınoğlu MMC', style: body()),
                    pw.Spacer(),
                    if (sellerName != null && sellerName.isNotEmpty) ...[
                      pw.Text(l10n.posPdfSeller, style: body(bold: true, color: tableHeaderRed)),
                      pw.Text(sellerName, style: body()),
                    ],
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(l10n.posPdfTo, style: body(bold: true, color: tableHeaderRed)),
                    pw.Text(customerName ?? '—', style: body()),
                    pw.Spacer(),
                    pw.Text(l10n.posPdfPayment, style: body(bold: true, color: tableHeaderRed)),
                    pw.Text(paymentMethodLabel, style: body()),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(l10n.posPdfDate, style: body(bold: true, color: tableHeaderRed)),
                    pw.Text(dateStr, style: body()),
                  ],
                ),
                pw.SizedBox(height: 10),

                // ── Items table ────────────────────────────────────────────
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(24),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FixedColumnWidth(40),
                    4: const pw.FlexColumnWidth(1.8),
                    5: const pw.FlexColumnWidth(1.8),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: tableHeaderBg),
                      children: [
                        cell('№', bold: true, color: tableHeaderRed),
                        cell(l10n.posPdfItemName, bold: true, color: tableHeaderRed),
                        cell(l10n.posPdfUnit, bold: true, color: tableHeaderRed),
                        cell(l10n.posPdfQty, bold: true, color: tableHeaderRed),
                        cell(l10n.posPdfPrice, bold: true, color: tableHeaderRed),
                        cell(l10n.posPdfAmount, bold: true, color: tableHeaderRed),
                      ],
                    ),
                    ...tableRows.asMap().entries.map((e) {
                      final isEven = e.key % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : rowBgGray),
                        children: e.value.map((c) => cell(c)).toList(),
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 14),

                // ── Totals section ─────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _totalRow(l10n.posPdfSubtotal, '${subtotal.toStringAsFixed(2)} AZN', body, borderColor, redText),
                        pw.SizedBox(height: 4),
                        if (manualDiscountAmount > 0.001) ...[
                          _totalRow(
                            l10n.posPdfDiscount(manualDiscountPercent.toStringAsFixed(0)),
                            '- ${manualDiscountAmount.toStringAsFixed(2)} AZN',
                            body,
                            borderColor,
                            redText,
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        if (customerDiscountAmount > 0.001) ...[
                          _totalRow(
                            l10n.posPdfCustomerDiscount(customerDiscountPercent.toStringAsFixed(0)),
                            '- ${customerDiscountAmount.toStringAsFixed(2)} AZN',
                            body,
                            borderColor,
                            redText,
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        _totalRow(l10n.posPdfBalance, '${total.toStringAsFixed(2)} AZN', body, borderColor, redText),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // ── Signature row ──────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(l10n.posPdfDeliveredBy, style: body()),
                        pw.SizedBox(width: 60),
                        pw.Container(width: 120, height: 0.5, color: borderColor),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(l10n.posPdfReceivedBy, style: body()),
                        pw.SizedBox(width: 60),
                        pw.Container(width: 120, height: 0.5, color: borderColor),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'qebz_${data.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      log('PDF generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.posPdfError(e.toString())), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    }
  }

  /// Builds a labelled totals row (e.g. CƏMİ / QALIQ) for the PDF.
  static pw.Widget _totalRow(
    String label,
    String value,
    pw.TextStyle Function({bool bold, double size, PdfColor? color}) styleBuilder,
    PdfColor borderColor,
    PdfColor labelColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(width: 100),
        pw.Text(label, style: styleBuilder(bold: true, size: 11, color: labelColor)),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 90,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.5)),
          child: pw.Text(value, style: styleBuilder(bold: true, size: 11), textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF667EEA)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF718096))),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _CustomerSearchDialog(
        onCustomerSelected: (customer) {
          setState(() => _selectedCustomer = customer);
          Future.microtask(() => _searchFocusNode.requestFocus());
        },
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
    final l10n = AppLocalizations.of(context)!;
    final String currentUser = _authUser != null ? '${_authUser!.firstName} ${_authUser!.lastName[0]}.' : '—';
    final String inventoryName = _loggedInInventory?.name ?? l10n.posKassa;

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
                Text(
                  'POS - $inventoryName',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF667EEA)),
                    const SizedBox(width: 4),
                    Text(currentUser, style: const TextStyle(fontSize: 13, color: Color(0xFF718096))),
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
    final l10n = AppLocalizations.of(context)!;
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
            child: _isSearching
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n.posScanOrSearch,
                hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, color: Color(0xFF2D3748)),
              onChanged: _onSearchChanged,
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
                  _searchResults = [];
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
              child: DropdownButton<StockProductItemModel>(
                value: _selectedDropdownProduct,
                hint: Text(
                  _searchController.text.isEmpty
                      ? l10n.posSelectFromList
                      : _isSearching
                      ? l10n.posSearching
                      : _searchResults.isEmpty
                      ? l10n.posNoResults
                      : l10n.posSelectFromList,
                  style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667EEA)),
                items: _searchResults.map((product) {
                  final price = _getCurrentPrice(product);
                  return DropdownMenuItem<StockProductItemModel>(
                    value: product,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.displayName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.posBarcodeStockInfo(product.barcode ?? '—', product.quantity),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                              ),
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
                            '${price.toStringAsFixed(2)} AZN',
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
    final l10n = AppLocalizations.of(context)!;
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
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.posProduct,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      l10n.posQuantity,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      l10n.posUnitPrice,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Center(
                    child: Text(
                      l10n.posDiscountCol,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      l10n.posTotal,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      l10n.posDeleteCol,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                        Text(
                          l10n.posCartEmpty,
                          style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.posCartEmptyHint, style: const TextStyle(color: Color(0xFFCBD5E0), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final unitPrice = _getCurrentPrice(item.product);
                      final costPrice = item.product.costUnitPrice ?? 0.0;
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.product.displayName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.product.barcode != null && item.product.barcode!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.product.barcode!,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
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
                                  '${unitPrice.toStringAsFixed(2)} AZN',
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
                                              content: Text(AppLocalizations.of(context)!.posDiscountBelowCost(costPrice.toStringAsFixed(2))),
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
                                                AppLocalizations.of(
                                                  context,
                                                )!.posMaxDiscount(maxDiscountAmount.toStringAsFixed(2), costPrice.toStringAsFixed(2)),
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
                                    'AZN',
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
                                    '${total.toStringAsFixed(2)} AZN',
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(l10n.posClearCart, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    final l10n = AppLocalizations.of(context)!;
    final subtotal = _calculateSubtotal();
    final customDiscount = _calculateCustomDiscount();
    final customerDiscount = _calculateCustomerDiscount();
    final totalDiscount = _calculateTotalDiscount();
    final combinedPercent = _combinedDiscountPercent();
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
                  Text(
                    l10n.posPriceType,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPriceTypeButton(PriceType.retail, l10n.posRetail)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPriceTypeButton(PriceType.wholesale, l10n.posWholesale)),
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
                  Text(
                    l10n.posPaymentMethod,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.cash, l10n.posCash)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.card, l10n.posCard)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildPaymentMethodButton(PaymentMethod.transfer, l10n.posTransfer)),
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
                      Text(
                        l10n.posDiscountCol,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFED7D7), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          _discountIsPercent
                              ? '${_globalDiscountPercent.toStringAsFixed(0)}%'
                              : '${(_calculateSubtotal() * _globalDiscountPercent / 100).toStringAsFixed(2)} AZN',
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
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
                      // Toggle buttons for % and AZN
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _discountEnabled
                                ? () {
                                    if (!_discountIsPercent) {
                                      setState(() {
                                        _discountIsPercent = true;
                                        // Convert current amount to percentage
                                        final subtotal = _calculateSubtotal();
                                        final currentAmount = double.tryParse(_discountController.text) ?? 0.0;
                                        final percent = subtotal > 0 ? (currentAmount / subtotal * 100) : 0.0;
                                        _discountController.text = percent.toStringAsFixed(0);
                                        _onDiscountFieldChanged(_discountController.text);
                                      });
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _discountIsPercent ? const Color(0xFF667EEA) : const Color(0xFFF7FAFC),
                                border: Border.all(color: _discountIsPercent ? const Color(0xFF667EEA) : const Color(0xFFE2E8F0)),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                              ),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _discountIsPercent ? Colors.white : const Color(0xFF718096),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _discountEnabled
                                ? () {
                                    if (_discountIsPercent) {
                                      setState(() {
                                        _discountIsPercent = false;
                                        // Convert current percentage to amount
                                        final subtotal = _calculateSubtotal();
                                        final currentPercent = double.tryParse(_discountController.text) ?? 0.0;
                                        final amount = (subtotal * currentPercent / 100).toStringAsFixed(2);
                                        _discountController.text = amount;
                                        _onDiscountFieldChanged(_discountController.text);
                                      });
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: !_discountIsPercent ? const Color(0xFF667EEA) : const Color(0xFFF7FAFC),
                                border: Border.all(color: !_discountIsPercent ? const Color(0xFF667EEA) : const Color(0xFFE2E8F0)),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                              ),
                              child: Text(
                                'AZN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_discountIsPercent ? Colors.white : const Color(0xFF718096),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                  _buildSummaryRow(l10n.posSubtotal, '${subtotal.toStringAsFixed(2)} AZN'),
                  if (customDiscount > 0)
                    _buildSummaryRow(
                      _discountIsPercent
                          ? l10n.posDiscountLabel(_globalDiscountPercent.toStringAsFixed(0))
                          : l10n.posDiscountAmountLabel(customDiscount.toStringAsFixed(2)),
                      '- ${customDiscount.toStringAsFixed(2)} AZN',
                      isDiscount: true,
                    ),
                  if (customerDiscount > 0 && _selectedCustomer != null)
                    _buildSummaryRow(
                      l10n.posCustomerDiscountLabel(_selectedCustomer!.discountPercentage.toStringAsFixed(0)),
                      '- ${customerDiscount.toStringAsFixed(2)} AZN',
                      isDiscount: true,
                    ),
                  if (totalDiscount > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    ),
                    _buildSummaryRow(
                      l10n.posTotalDiscountLabel(combinedPercent.toStringAsFixed(0)),
                      '- ${totalDiscount.toStringAsFixed(2)} AZN',
                      isDiscount: true,
                      isBold: true,
                    ),
                  ],
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
                        Text(
                          l10n.posAmountDue,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)} AZN',
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
                      onPressed: (_cartItems.isEmpty || _isCompletingSale) ? null : _completeSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48BB78),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFFA0AEC0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isCompletingSale
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.print, size: 22),
                                const SizedBox(width: 12),
                                Text(l10n.posCompleteSale, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCustomerDialog,
                          icon: Icon(_selectedCustomer != null ? Icons.person : Icons.person_add_outlined, size: 20),
                          label: Text(
                            _selectedCustomer != null ? l10n.posCustomerLabel(_selectedCustomer!.fullName) : l10n.posSelectCustomer,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
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
                      if (_selectedCustomer != null) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _selectedCustomer = null);
                              Future.microtask(() => _searchFocusNode.requestFocus());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC8181),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ],
                    ],
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

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: const Color(0xFF4A5568), fontWeight: isBold ? FontWeight.w700 : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isDiscount ? const Color(0xFFC53030) : const Color(0xFF2D3748),
            ),
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

class _CartItem {
  final StockProductItemModel product;
  int quantity;
  double discountPercent;

  _CartItem({required this.product, required this.quantity, this.discountPercent = 0.0});
}

// ── Customer Search Dialog ────────────────────────────────────────────────────

class _CustomerSearchDialog extends StatefulWidget {
  final ValueChanged<CustomerModel?> onCustomerSelected;

  const _CustomerSearchDialog({required this.onCustomerSelected});

  @override
  State<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<_CustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<CustomerModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    final result = await CustomersRepository.instance.fetchCustomers(search: query, pageSize: 20);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _results = data.results;
          _isLoading = false;
          _hasSearched = true;
        });
      case Failure():
        setState(() {
          _results = [];
          _isLoading = false;
          _hasSearched = true;
        });
    }
  }

  void _selectCustomer(CustomerModel customer) {
    setState(() => _selectedCustomer = customer);
  }

  void _confirm() {
    widget.onCustomerSelected(_selectedCustomer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_search, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.posCustomerSearchTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(l10n.posCustomerSearchSubtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF667EEA)))
                        : const Icon(Icons.search, color: Color(0xFF667EEA), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF2D3748)),
                        decoration: InputDecoration(
                          hintText: l10n.posCustomerSearchField,
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF718096)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          _focusNode.requestFocus();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

            // ── Results list ─────────────────────────────────────────────
            ConstrainedBox(constraints: const BoxConstraints(maxHeight: 360, minHeight: 120), child: _buildResultsBody()),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (_selectedCustomer != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF4FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF667EEA), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCustomer!.fullName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(l10n.posNoCustomerSelected, style: const TextStyle(fontSize: 13, color: Color(0xFFA0AEC0))),
                    ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF718096),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedCustomer != null ? _confirm : null,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(l10n.posConfirmSelect, style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFFA0AEC0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
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

  Widget _buildResultsBody() {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasSearched && !_isLoading) {
      return _buildEmptyState(
        icon: Icons.manage_search_rounded,
        iconColor: const Color(0xFF667EEA),
        bgColor: const Color(0xFFEBF4FF),
        title: l10n.posStartSearch,
        subtitle: l10n.posStartSearchHint,
      );
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF667EEA)),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        iconColor: const Color(0xFFA0AEC0),
        bgColor: const Color(0xFFF7FAFC),
        title: l10n.posCustomerNotFound,
        subtitle: l10n.posCustomerNotFoundHint,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final customer = _results[index];
        final isSelected = _selectedCustomer?.id == customer.id;
        return _CustomerTile(customer: customer, isSelected: isSelected, onTap: () => _selectCustomer(customer));
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final CustomerModel customer;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerTile({required this.customer, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF4FF) : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF667EEA) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isSelected ? null : const Color(0xFFEDF2F7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF667EEA)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF2D3748) : const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF718096)),
                      const SizedBox(width: 4),
                      Text(customer.phoneNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                      if (customer.loyaltyId.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.card_membership, size: 13, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Text(customer.loyaltyId, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Discount badge
            if (customer.discountPercentage > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667EEA) : const Color(0xFFEBF4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${customer.discountPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF667EEA)),
                ),
              ),
            if (isSelected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: Color(0xFF667EEA), size: 20)],
          ],
        ),
      ),
    );
  }
}
