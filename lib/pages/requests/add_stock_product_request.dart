import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/auth/auth_cubit.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_cubit.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_state.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_repository.dart';
import 'package:inventory/features/product_requests/cubit/product_requests_cubit.dart';
import 'package:inventory/features/stocks/cubit/stocks_cubit.dart';
import 'package:inventory/features/stocks/cubit/stocks_state.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Cart item ─────────────────────────────────────────────────────────────────

class _CartItem {
  final String productUuid;
  final String displayName;
  final String barcode;
  int creatingCount;

  _CartItem({required this.productUuid, required this.displayName, required this.barcode, required this.creatingCount});
}

// ── Dialog widget ─────────────────────────────────────────────────────────────

class AddStockProductRequest extends StatefulWidget {
  const AddStockProductRequest({super.key});

  @override
  State<AddStockProductRequest> createState() => _AddStockProductRequestState();
}

class _AddStockProductRequestState extends State<AddStockProductRequest> {
  // ── inventories ──────────────────────────────────────────────────────────
  bool _inventoriesLoading = true;
  String? _inventoriesError;
  List<InventoryModel> _inventories = [];

  InventoryModel? _sourceInventory;
  InventoryModel? _destinationInventory;

  // ── product search ───────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // ── cart ─────────────────────────────────────────────────────────────────
  final List<_CartItem> _cart = [];

  // ── submission ───────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── owned cubits ─────────────────────────────────────────────────────────
  late final StocksCubit _stocksCubit = StocksCubit();
  late final InventoryProductsCubit _invProductsCubit = InventoryProductsCubit();

  @override
  void initState() {
    super.initState();
    _loadInventories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _stocksCubit.close();
    _invProductsCubit.close();
    super.dispose();
  }

  // ── inventory loading ────────────────────────────────────────────────────

  Future<void> _loadInventories() async {
    setState(() {
      _inventoriesLoading = true;
      _inventoriesError = null;
    });

    final result = await InventoryRepository.instance.fetchInventories(pageSize: 200);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        // Auto-select the logged-in user's inventory as the destination.
        final authState = context.read<AuthCubit>().state;
        final loggedInInventoryId = authState is AuthAuthenticated ? authState.response.loggedInInventory?.id : null;
        final destination = loggedInInventoryId != null ? data.results.where((inv) => inv.id == loggedInInventoryId).firstOrNull : null;
        setState(() {
          _inventories = data.results;
          _destinationInventory = destination;
          _inventoriesLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _inventoriesError = message;
          _inventoriesLoading = false;
        });
    }
  }

  // ── source inventory changed ─────────────────────────────────────────────

  void _onSourceChanged(InventoryModel? inv) {
    setState(() {
      _sourceInventory = inv;
      _searchController.clear();
    });
    if (inv != null) _triggerSearch('');
  }

  // ── product search ───────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _triggerSearch(query));
  }

  void _triggerSearch(String query) {
    final src = _sourceInventory;
    if (src == null) return;
    final q = query.isEmpty ? null : query;

    if (src.isStock) {
      _stocksCubit.fetchStocks(search: q, inventoryId: src.id);
    } else {
      _invProductsCubit.updateSearch(q);
    }
  }

  // ── cart management ──────────────────────────────────────────────────────

  void _addToCart(String uuid, String displayName, String barcode, int count) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.productUuid == uuid);
      if (idx != -1) {
        _cart[idx].creatingCount += count;
      } else {
        _cart.add(_CartItem(productUuid: uuid, displayName: displayName, barcode: barcode, creatingCount: count));
      }
    });
  }

  void _removeFromCart(int index) => setState(() => _cart.removeAt(index));

  // ── submission ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_sourceInventory == null || _destinationInventory == null) {
      _showSnack(l10n.pleaseSelectFromAndTo, Colors.orange);
      return;
    }
    if (_cart.isEmpty) {
      _showSnack(l10n.pleaseAddProducts, Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    final products = _cart
        .map((c) => {'product_uuid': c.productUuid, 'creating_count': c.creatingCount, 'sending_count': 0, 'receiving_count': 0})
        .toList();

    final result = await context.read<ProductRequestsCubit>().createRequest(
      sourceInventory: _sourceInventory!.id,
      destinationInventory: _destinationInventory!.id,
      products: products,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        _showSnack(l10n.stockRequestCreated, const Color(0xFF10B981));
        Navigator.of(context).pop(true);
      case Failure(:final message):
        _showSnack(message, const Color(0xFFEF4444));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _stocksCubit),
        BlocProvider.value(value: _invProductsCubit),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 720,
          constraints: const BoxConstraints(maxHeight: 820),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInventorySelectors(l10n),
                      if (_sourceInventory != null) ...[
                        const SizedBox(height: 20),
                        _buildProductSearch(l10n),
                        const SizedBox(height: 16),
                        _buildProductResults(l10n),
                      ],
                      if (_cart.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                        _buildCart(l10n),
                      ],
                    ],
                  ),
                ),
              ),
              _buildFooter(l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, size: 20), color: const Color(0xFF64748B)),
        ],
      ),
    );
  }

  // ── inventory selectors ───────────────────────────────────────────────────

  Widget _buildInventorySelectors(AppLocalizations l10n) {
    if (_inventoriesLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
      );
    }
    if (_inventoriesError != null) {
      return _ErrorCard(message: _inventoriesError!, onRetry: _loadInventories);
    }

    // Exclude the inventory the user is currently logged into from source options.
    final authState = context.read<AuthCubit>().state;
    final loggedInInventoryId = authState is AuthAuthenticated ? authState.response.loggedInInventory?.id : null;
    final sourceInventories = loggedInInventoryId == null ? _inventories : _inventories.where((inv) => inv.id != loggedInInventoryId).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InventoryDropdown(
            label: l10n.from,
            hint: l10n.selectInventory,
            inventories: sourceInventories,
            value: _sourceInventory,
            onChanged: _onSourceChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _LockedInventoryField(label: l10n.to, inventory: _destinationInventory),
        ),
      ],
    );
  }

  // ── product search bar ────────────────────────────────────────────────────

  Widget _buildProductSearch(AppLocalizations l10n) {
    final src = _sourceInventory!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                src.isStock ? 'Search Stock Products (${src.name})' : 'Search Inventory Products (${src.name})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: src.isStock ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                src.isStock ? 'STOCK' : 'INVENTORY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: src.isStock ? const Color(0xFF6366F1) : const Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── product results ───────────────────────────────────────────────────────

  Widget _buildProductResults(AppLocalizations l10n) {
    final src = _sourceInventory;
    if (src == null) return const SizedBox.shrink();

    if (src.isStock) {
      return BlocBuilder<StocksCubit, StocksState>(
        bloc: _stocksCubit,
        builder: (_, state) {
          if (state is StocksLoading) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            );
          }
          if (state is StocksError) {
            return _ErrorCard(message: state.message, onRetry: () => _triggerSearch(_searchController.text));
          }
          if (state is StocksLoaded) {
            if (state.products.isEmpty) return _EmptyState(label: l10n.noProductsFound);
            return Column(
              children: state.products
                  .map(
                    (p) => _StockProductTile(
                      product: p,
                      inCart: _cart.any((c) => c.productUuid == p.id),
                      onAdd: (count) => _addToCart(p.id, p.displayName, p.barcode ?? '', count),
                    ),
                  )
                  .toList(),
            );
          }
          return _EmptyState(label: l10n.searchProducts);
        },
      );
    } else {
      return BlocBuilder<InventoryProductsCubit, InventoryProductsState>(
        bloc: _invProductsCubit,
        builder: (_, state) {
          if (state is InventoryProductsLoading) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            );
          }
          if (state is InventoryProductsError) {
            return _ErrorCard(message: state.message, onRetry: () => _triggerSearch(_searchController.text));
          }
          if (state is InventoryProductsLoaded) {
            if (state.products.isEmpty) return _EmptyState(label: l10n.noProductsFound);
            return Column(
              children: state.products
                  .map(
                    (p) => _InvProductTile(
                      product: p,
                      inCart: _cart.any((c) => c.productUuid == p.id),
                      onAdd: (count) => _addToCart(
                        p.id,
                        p.productGeneratedName?.isNotEmpty == true ? p.productGeneratedName! : (p.productName ?? p.id),
                        p.barcode ?? '',
                        count,
                      ),
                    ),
                  )
                  .toList(),
            );
          }
          return _EmptyState(label: l10n.searchProducts);
        },
      );
    }
  }

  // ── cart ──────────────────────────────────────────────────────────────────

  Widget _buildCart(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_cart_rounded, size: 18, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              l10n.requestedItems,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(width: 8),
            _CountBadge(count: _cart.length),
          ],
        ),
        const SizedBox(height: 12),
        ..._cart.asMap().entries.map((e) => _CartItemCard(item: e.value, onRemove: () => _removeFromCart(e.key))),
      ],
    );
  }

  // ── footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (_cart.isNotEmpty) _CountBadge(count: _cart.fold(0, (s, c) => s + c.creatingCount), suffix: ' pcs'),
          const Spacer(),
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.submitRequest, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Locked inventory field (destination — always the logged-in user's inventory) ──

class _LockedInventoryField extends StatelessWidget {
  final String label;
  final InventoryModel? inventory;

  const _LockedInventoryField({required this.label, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 10, color: Color(0xFF6366F1)),
                  SizedBox(width: 3),
                  Text(
                    'Your inventory',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.warehouse_rounded, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  inventory?.name ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (inventory != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: inventory!.isStock ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inventory!.isStock ? 'STOCK' : 'INV',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: inventory!.isStock ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (inventory != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              inventory!.address.isEmpty ? '—' : inventory!.address,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ── Inventory dropdown ────────────────────────────────────────────────────────

class _InventoryDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<InventoryModel> inventories;
  final InventoryModel? value;
  final ValueChanged<InventoryModel?> onChanged;

  const _InventoryDropdown({required this.label, required this.hint, required this.inventories, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: value != null ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InventoryModel>(
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              onChanged: onChanged,
              items: inventories.map((inv) {
                return DropdownMenuItem<InventoryModel>(
                  value: inv,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(inv.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: inv.isStock ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.isStock ? 'STOCK' : 'INV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: inv.isStock ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              value!.address.isEmpty ? '—' : value!.address,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ── Stock product tile ────────────────────────────────────────────────────────

class _StockProductTile extends StatefulWidget {
  final StockProductItemModel product;
  final bool inCart;
  final void Function(int count) onAdd;

  const _StockProductTile({required this.product, required this.inCart, required this.onAdd});

  @override
  State<_StockProductTile> createState() => _StockProductTileState();
}

class _StockProductTileState extends State<_StockProductTile> {
  bool _expanded = false;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.product;

    return _ProductTileShell(
      expanded: _expanded,
      inCart: widget.inCart,
      onToggle: () => setState(() => _expanded = !_expanded),
      name: p.displayName,
      barcode: p.barcode ?? '—',
      subtitle: 'Code: ${p.productCode ?? '—'}  •  Qty: ${p.quantity}',
      qtyLabel: '${p.barcode}',
      expandedContent: _ExpandedQtyRow(
        qtyCtrl: _qtyCtrl,
        l10n: l10n,
        onAdd: () {
          final qty = int.tryParse(_qtyCtrl.text) ?? 0;
          if (qty > 0) {
            widget.onAdd(qty);
            setState(() {
              _expanded = false;
              _qtyCtrl.text = '1';
            });
          }
        },
      ),
    );
  }
}

// ── Inventory product tile ────────────────────────────────────────────────────

class _InvProductTile extends StatefulWidget {
  final InventoryProductItemModel product;
  final bool inCart;
  final void Function(int count) onAdd;

  const _InvProductTile({required this.product, required this.inCart, required this.onAdd});

  @override
  State<_InvProductTile> createState() => _InvProductTileState();
}

class _InvProductTileState extends State<_InvProductTile> {
  bool _expanded = false;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.product;
    final name = p.productGeneratedName?.isNotEmpty == true ? p.productGeneratedName! : (p.productName ?? p.id);

    return _ProductTileShell(
      expanded: _expanded,
      inCart: widget.inCart,
      onToggle: () => setState(() => _expanded = !_expanded),
      name: name,
      barcode: p.barcode ?? '—',
      subtitle: 'Code: ${p.productCode ?? '—'}  •  Qty: ${p.actualQuantity ?? 0}',
      qtyLabel: '${p.actualQuantity ?? 0}',
      expandedContent: _ExpandedQtyRow(
        qtyCtrl: _qtyCtrl,
        l10n: l10n,
        onAdd: () {
          final qty = int.tryParse(_qtyCtrl.text) ?? 0;
          if (qty > 0) {
            widget.onAdd(qty);
            setState(() {
              _expanded = false;
              _qtyCtrl.text = '1';
            });
          }
        },
      ),
    );
  }
}

// ── Shared expanded row (qty field + add button) ──────────────────────────────

class _ExpandedQtyRow extends StatelessWidget {
  final TextEditingController qtyCtrl;
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _ExpandedQtyRow({required this.qtyCtrl, required this.l10n, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onAdd,
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
    );
  }
}

// ── Shared product tile shell ─────────────────────────────────────────────────

class _ProductTileShell extends StatelessWidget {
  final bool expanded;
  final bool inCart;
  final VoidCallback onToggle;
  final String name;
  final String barcode;
  final String subtitle;
  final String qtyLabel;
  final Widget expandedContent;

  const _ProductTileShell({
    required this.expanded,
    required this.inCart,
    required this.onToggle,
    required this.name,
    required this.barcode,
    required this.subtitle,
    required this.qtyLabel,
    required this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: expanded
              ? const Color(0xFF6366F1)
              : inCart
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (inCart) ...[const SizedBox(width: 6), const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981))],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '$qtyLabel ${l10n.pcs}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: expandedContent,
            ),
        ],
      ),
    );
  }
}

// ── Cart item card ────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.04),
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
                  item.displayName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text('${l10n.barcode}: ${item.barcode}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${item.creatingCount} ${l10n.pcs}',
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

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final String suffix;

  const _CountBadge({required this.count, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$count$suffix',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
      ),
    );
  }
}
