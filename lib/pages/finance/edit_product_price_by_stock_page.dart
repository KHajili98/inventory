import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_repository.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class EditProductPriceByStockPage extends StatefulWidget {
  const EditProductPriceByStockPage({super.key});

  @override
  State<EditProductPriceByStockPage> createState() => _EditProductPriceByStockPageState();
}

class _EditProductPriceByStockPageState extends State<EditProductPriceByStockPage> {
  // ── Repositories ──────────────────────────────────────────────────────────
  final _inventoryRepo = InventoryRepository.instance;
  final _stocksRepo = StocksRepository.instance;

  // ── Inventories (is_stock = true) ─────────────────────────────────────────
  List<InventoryModel> _inventories = [];
  bool _loadingInventories = false;
  String? _inventoriesError;

  // ── Selected inventory ────────────────────────────────────────────────────
  InventoryModel? _selectedInventory;

  // ── Products ──────────────────────────────────────────────────────────────
  List<StockProductItemModel> _products = [];
  bool _loadingProducts = false;
  bool _loadingMoreProducts = false;
  String? _productsError;
  int _totalCount = 0;
  bool _hasMore = false;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _vScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInventories();
    _vScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _vScroll.dispose();
    super.dispose();
  }

  // ── Fetch inventories (is_stock = true) ───────────────────────────────────
  Future<void> _fetchInventories() async {
    setState(() {
      _loadingInventories = true;
      _inventoriesError = null;
    });
    final result = await _inventoryRepo.fetchInventories(pageSize: 200);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        final stocks = data.results.where((i) => i.isStock).toList();
        setState(() {
          _inventories = stocks;
          _loadingInventories = false;
          _inventoriesError = stocks.isEmpty ? 'noInventoriesFound' : null;
        });
      case Failure(:final message):
        setState(() {
          _loadingInventories = false;
          _inventoriesError = message;
        });
    }
  }

  // ── Fetch products for selected inventory ─────────────────────────────────
  Future<void> _fetchProducts({bool reset = true}) async {
    if (_selectedInventory == null) return;
    if (reset) {
      setState(() {
        _loadingProducts = true;
        _productsError = null;
        _products = [];
        _currentPage = 1;
        _hasMore = false;
      });
    }
    final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    final result = await _stocksRepo.fetchStocks(
      page: reset ? 1 : _currentPage,
      pageSize: _pageSize,
      inventoryId: _selectedInventory!.id,
      search: search,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _products = reset ? data.results : [..._products, ...data.results];
          _totalCount = data.count;
          _hasMore = data.next != null;
          _loadingProducts = false;
          _loadingMoreProducts = false;
          _productsError = null;
        });
      case Failure(:final message):
        setState(() {
          _loadingProducts = false;
          _loadingMoreProducts = false;
          _productsError = message;
        });
    }
  }

  // ── Infinite scroll ───────────────────────────────────────────────────────
  void _onScroll() {
    if (_loadingMoreProducts || !_hasMore) return;
    if (_vScroll.position.pixels >= _vScroll.position.maxScrollExtent - 300) {
      setState(() {
        _loadingMoreProducts = true;
        _currentPage++;
      });
      _fetchProducts(reset: false);
    }
  }

  // ── Search debounce ───────────────────────────────────────────────────────
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchProducts());
  }

  // ── Inventory selected ────────────────────────────────────────────────────
  void _onInventoryChanged(InventoryModel? inv) {
    setState(() {
      _selectedInventory = inv;
      _searchCtrl.clear();
      _products = [];
      _productsError = null;
    });
    if (inv != null) _fetchProducts();
  }

  // ── Edit price dialog ─────────────────────────────────────────────────────
  void _showEditPriceDialog(StockProductItemModel item) {
    final l10n = AppLocalizations.of(context)!;

    final costPctCtrl = TextEditingController();
    final costAmtCtrl = TextEditingController();
    final wholePctCtrl = TextEditingController();
    final wholeAmtCtrl = TextEditingController();
    final retailPctCtrl = TextEditingController();
    final retailAmtCtrl = TextEditingController();
    bool isSaving = false;

    // Pre-fill from existing prices
    final baseInvoice = item.invoiceUnitPriceAzn ?? 0;
    if (item.costUnitPrice != null) {
      final diff = item.costUnitPrice! - baseInvoice;
      costAmtCtrl.text = diff.toStringAsFixed(2);
      if (baseInvoice > 0) costPctCtrl.text = ((diff / baseInvoice) * 100).toStringAsFixed(2);
    }
    if (item.costUnitPrice != null && item.wholeUnitSalesPrice != null) {
      final diff = item.wholeUnitSalesPrice! - item.costUnitPrice!;
      wholeAmtCtrl.text = diff.toStringAsFixed(2);
      if (item.costUnitPrice! > 0) wholePctCtrl.text = ((diff / item.costUnitPrice!) * 100).toStringAsFixed(2);
    }
    if (item.costUnitPrice != null && item.retailUnitPrice != null) {
      final diff = item.retailUnitPrice! - item.costUnitPrice!;
      retailAmtCtrl.text = diff.toStringAsFixed(2);
      if (item.costUnitPrice! > 0) retailPctCtrl.text = ((diff / item.costUnitPrice!) * 100).toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double costBase() => baseInvoice;
          double wholRetailBase() => baseInvoice + (double.tryParse(costAmtCtrl.text) ?? 0);
          Future<void> save() async {
            setDialogState(() => isSaving = true);
            final newCost = baseInvoice + (double.tryParse(costAmtCtrl.text) ?? 0);
            final newWhole = newCost + (double.tryParse(wholeAmtCtrl.text) ?? 0);
            final newRetail = newCost + (double.tryParse(retailAmtCtrl.text) ?? 0);
            final messenger = ScaffoldMessenger.of(this.context);

            final result = await _stocksRepo.pricingStock(
              item: item,
              costUnitPrice: newCost,
              wholeUnitSalesPrice: newWhole,
              retailUnitPrice: newRetail,
            );
            if (!ctx.mounted) return;
            switch (result) {
              case Success(:final data):
                final idx = _products.indexWhere((p) => p.id == data.id);
                if (idx != -1) setState(() => _products[idx] = data);
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.priceSavedSuccess),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              case Failure(:final message):
                setDialogState(() => isSaving = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.priceSaveFailed(message)),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 620,
              constraints: const BoxConstraints(maxHeight: 720),
              padding: const EdgeInsets.all(24),
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
                        child: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.editPrices,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              item.displayName,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  // Info rows
                  _infoRow(l10n.productCode, item.productCode ?? '—'),
                  _infoRow(l10n.barcodeColumn, item.barcode ?? '—'),
                  _infoRow(l10n.quantityColumn, '${item.quantity}'),
                  _infoRow(l10n.invoicePriceAznLabel, baseInvoice > 0 ? '₼ ${baseInvoice.toStringAsFixed(2)}' : '—'),
                  const SizedBox(height: 16),
                  // Calc blocks
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _CalcBlock(
                            title: l10n.costPriceStep,
                            basePrice: costBase(),
                            resultLabel: l10n.costPriceLabel,
                            pctCtrl: costPctCtrl,
                            amtCtrl: costAmtCtrl,
                            accentColor: const Color(0xFF6366F1),
                            onChanged: (isPct) => setDialogState(() {
                              final base = costBase();
                              if (base <= 0) return;
                              if (isPct) {
                                final pct = double.tryParse(costPctCtrl.text);
                                if (pct != null) costAmtCtrl.text = (base * pct / 100).toStringAsFixed(2);
                              } else {
                                final amt = double.tryParse(costAmtCtrl.text);
                                if (amt != null) costPctCtrl.text = ((amt / base) * 100).toStringAsFixed(2);
                              }
                            }),
                          ),
                          const SizedBox(height: 12),
                          _CalcBlock(
                            title: l10n.wholesalePriceStep,
                            basePrice: wholRetailBase(),
                            resultLabel: l10n.wholesalePriceLabel,
                            pctCtrl: wholePctCtrl,
                            amtCtrl: wholeAmtCtrl,
                            accentColor: const Color(0xFF0EA5E9),
                            onChanged: (isPct) => setDialogState(() {
                              final base = wholRetailBase();
                              if (base <= 0) return;
                              if (isPct) {
                                final pct = double.tryParse(wholePctCtrl.text);
                                if (pct != null) wholeAmtCtrl.text = (base * pct / 100).toStringAsFixed(2);
                              } else {
                                final amt = double.tryParse(wholeAmtCtrl.text);
                                if (amt != null) wholePctCtrl.text = ((amt / base) * 100).toStringAsFixed(2);
                              }
                            }),
                          ),
                          const SizedBox(height: 12),
                          _CalcBlock(
                            title: l10n.retailPriceStep,
                            basePrice: wholRetailBase(),
                            resultLabel: l10n.retailPriceLabel,
                            pctCtrl: retailPctCtrl,
                            amtCtrl: retailAmtCtrl,
                            accentColor: const Color(0xFF10B981),
                            onChanged: (isPct) => setDialogState(() {
                              final base = wholRetailBase();
                              if (base <= 0) return;
                              if (isPct) {
                                final pct = double.tryParse(retailPctCtrl.text);
                                if (pct != null) retailAmtCtrl.text = (base * pct / 100).toStringAsFixed(2);
                              } else {
                                final amt = double.tryParse(retailAmtCtrl.text);
                                if (amt != null) retailPctCtrl.text = ((amt / base) * 100).toStringAsFixed(2);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(l10n.no, style: const TextStyle(color: Color(0xFF475569))),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: isSaving ? null : save,
                        icon: isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: Text(isSaving ? l10n.savingPrice : l10n.confirm),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.editProductPrices,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Padding(
        padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Inventory dropdown ─────────────────────────────────────
            _buildInventoryDropdown(l10n),
            const SizedBox(height: 16),

            if (_selectedInventory != null) ...[
              // ── Search ────────────────────────────────────────────────
              _buildSearchBar(l10n),
              const SizedBox(height: 16),
              // ── Section title + count ─────────────────────────────────
              Row(
                children: [
                  Text(
                    l10n.allStockProducts,
                    style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  if (_totalCount > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '$_totalCount',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Content ────────────────────────────────────────────────
            Expanded(child: _buildContent(l10n, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryDropdown(AppLocalizations l10n) {
    if (_loadingInventories) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
            const SizedBox(width: 12),
            Text(l10n.loadingInventories, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    if (_inventoriesError != null && _inventories.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _inventoriesError == 'noInventoriesFound' ? l10n.noInventoriesFound : _inventoriesError!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            TextButton(onPressed: _fetchInventories, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InventoryModel>(
          value: _selectedInventory,
          hint: Row(
            children: [
              const Icon(Icons.warehouse_outlined, size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Text(l10n.selectStockHint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
          items: _inventories.map((inv) {
            return DropdownMenuItem<InventoryModel>(
              value: inv,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.warehouse_outlined, size: 16, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          inv.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        if (inv.address.isNotEmpty)
                          Text(
                            inv.address,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _onInventoryChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.searchPlaceholder,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _fetchProducts();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, bool isMobile) {
    if (_selectedInventory == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              l10n.selectStock,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Text(l10n.selectStockHint, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productsError != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _productsError!,
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProducts,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(l10n.noResultsFound, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return isMobile ? _buildMobileList(l10n) : _buildDesktopTable(l10n);
  }

  // ── Mobile list ───────────────────────────────────────────────────────────
  Widget _buildMobileList(AppLocalizations l10n) {
    return ListView.builder(
      controller: _vScroll,
      itemCount: _products.length + (_loadingMoreProducts ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _products.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final p = _products[i];
        return GestureDetector(
          onTap: () => _showEditPriceDialog(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(p.productCode ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6366F1)),
                  ],
                ),
                const SizedBox(height: 10),
                _mobileRow(Icons.qr_code_outlined, p.barcode ?? '—'),
                const SizedBox(height: 4),
                _mobileRow(Icons.inventory_outlined, '${l10n.quantityColumn}: ${p.quantity}'),
                const SizedBox(height: 4),
                _mobileRow(Icons.receipt_outlined, '${l10n.invoicePriceAznLabel}: ${p.invoiceUnitPriceAzn?.toStringAsFixed(2) ?? '—'} ₼'),
                const SizedBox(height: 4),
                _mobileRow(Icons.monetization_on_outlined, '${l10n.costPrice}: ${p.costUnitPrice?.toStringAsFixed(2) ?? '—'} ₼'),
                const SizedBox(height: 4),
                _mobileRow(Icons.store_outlined, '${l10n.wholesalePrice}: ${p.wholeUnitSalesPrice?.toStringAsFixed(2) ?? '—'} ₼'),
                const SizedBox(height: 4),
                _mobileRow(Icons.price_change_outlined, '${l10n.retailPrice}: ${p.retailUnitPrice?.toStringAsFixed(2) ?? '—'} ₼'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ),
      ],
    );
  }

  // ── Desktop table ─────────────────────────────────────────────────────────
  Widget _buildDesktopTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(l10n.productCode, style: _headerStyle)),
                  Expanded(flex: 2, child: Text(l10n.productName, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.quantityColumn, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.barcode, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.invoicePriceAznLabel, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.costPrice, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.wholesalePrice, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.retailPrice, style: _headerStyle)),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Rows
            Expanded(
              child: ListView.separated(
                controller: _vScroll,
                itemCount: _products.length + (_loadingMoreProducts ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  if (i == _products.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final p = _products[i];
                  return InkWell(
                    onTap: () => _showEditPriceDialog(p),
                    child: Container(
                      color: i.isEven ? Colors.white : const Color(0xFFFAFAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(p.productCode ?? '—', style: _cellStyle, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(7)),
                                  child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.displayName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Text('${p.quantity}', style: _cellStyle)),
                          Expanded(
                            flex: 1,
                            child: Text(p.barcode ?? '—', style: _monoStyle, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(flex: 1, child: _priceCell(p.invoiceUnitPriceAzn)),
                          Expanded(flex: 1, child: _priceCell(p.costUnitPrice)),
                          Expanded(flex: 1, child: _priceCell(p.wholeUnitSalesPrice)),
                          Expanded(flex: 1, child: _priceCell(p.retailUnitPrice)),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              onPressed: () => _showEditPriceDialog(p),
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6366F1)),
                              tooltip: l10n.editPrices,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer
            if (_products.isNotEmpty && !_loadingMoreProducts)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Text('$_totalCount items total', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _priceCell(double? price) {
    return Text(
      price != null ? '₼ ${price.toStringAsFixed(2)}' : '—',
      style: TextStyle(
        fontSize: 13,
        fontWeight: price != null ? FontWeight.w600 : FontWeight.normal,
        color: price != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569));
  TextStyle get _cellStyle => const TextStyle(fontSize: 13, color: Color(0xFF334155));
  TextStyle get _monoStyle => const TextStyle(fontSize: 13, color: Color(0xFF334155), fontFamily: 'monospace');
}

// ── Reusable calc block ───────────────────────────────────────────────────────

class _CalcBlock extends StatelessWidget {
  final String title;
  final double basePrice;
  final String resultLabel;
  final TextEditingController pctCtrl;
  final TextEditingController amtCtrl;
  final Color accentColor;
  final void Function(bool isPctChanged) onChanged;

  const _CalcBlock({
    required this.title,
    required this.basePrice,
    required this.resultLabel,
    required this.pctCtrl,
    required this.amtCtrl,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final amt = double.tryParse(amtCtrl.text);
    final result = amt != null ? basePrice + amt : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${basePrice.toStringAsFixed(2)} ₼',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '+',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: pctCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (_) => onChanged(true),
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDeco('%', accentColor),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (_) => onChanged(false),
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDeco('₼', accentColor),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '=',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ),
              Text(
                result != null ? '${result.toStringAsFixed(2)} ₼' : '— ₼',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: result != null ? accentColor : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String suffix, Color accent) => InputDecoration(
    suffixText: suffix,
    hintText: '0',
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
      borderSide: BorderSide(color: accent),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
