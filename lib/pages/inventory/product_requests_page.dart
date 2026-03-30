import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/product_request_models.dart';
import 'package:inventory/models/stock_models.dart';
import 'package:inventory/pages/inventory/add_stock_product_request.dart';

class ProductRequestsPage extends StatefulWidget {
  const ProductRequestsPage({super.key});

  @override
  State<ProductRequestsPage> createState() => _ProductRequestsPageState();
}

class _ProductRequestsPageState extends State<ProductRequestsPage> {
  // Simulated current user – toggle to switch perspective
  AppUser _currentUser = mockSeller;

  final List<ProductRequest> _requests = List.from(mockProductRequests);
  String _searchQuery = '';
  ProductRequestStatus? _statusFilter;

  List<ProductRequest> get _filtered {
    return _requests.where((r) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.fromInventory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.toInventory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.items.any((i) => i.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _updateStatus(String requestId, ProductRequestStatus newStatus, List<ProductRequestItem> items) {
    setState(() {
      final idx = _requests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _requests[idx] = _requests[idx].copyWith(status: newStatus, items: items);
      }
    });
  }

  void _deleteRequest(String requestId) {
    setState(() {
      _requests.removeWhere((r) => r.id == requestId);
    });
  }

  void _openCreateRequest() {
    final inventories = mockStockItems.map((i) => i.sourceInventoryName).toSet().toList()..sort();
    showDialog(
      context: context,
      builder: (_) => AddStockProductRequest(availableStockItems: mockStockItems, inventories: inventories),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;

    // Status summary counts
    final counts = {for (final s in ProductRequestStatus.values) s: _requests.where((r) => r.status == s).length};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(context.responsivePadding),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.productRequests,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.productRequestsSubtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    // User switcher (demo)
                    _UserSwitcher(currentUser: _currentUser, onSwitch: (u) => setState(() => _currentUser = u)),
                    const SizedBox(width: 12),
                    if (_currentUser.role == AppUserRole.seller)
                      ElevatedButton.icon(
                        onPressed: _openCreateRequest,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.createRequest),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status summary chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: l10n.allRequests,
                        count: _requests.length,
                        isSelected: _statusFilter == null,
                        color: const Color(0xFF6366F1),
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ...ProductRequestStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _StatusChip(
                            label: _statusLabel(context, s),
                            count: counts[s] ?? 0,
                            isSelected: _statusFilter == s,
                            color: _statusColor(s),
                            onTap: () => setState(() => _statusFilter = _statusFilter == s ? null : s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchRequests,
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Request list ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(l10n.noRequestsFound, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.responsivePadding, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _RequestCard(
                      request: filtered[i],
                      currentUser: _currentUser,
                      onStatusChanged: _updateStatus,
                      onDeleteRequest: _deleteRequest,
                      statusLabel: (s) => _statusLabel(context, s),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, ProductRequestStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ProductRequestStatus.pending:
        return l10n.statusPending;
      case ProductRequestStatus.preparing:
        return l10n.statusPreparing;
      case ProductRequestStatus.readyForDelivery:
        return l10n.statusReadyForDelivery;
      case ProductRequestStatus.onWay:
        return l10n.statusOnWay;
      case ProductRequestStatus.waitingForPricing:
        return l10n.statusWaitingForPricing;
      case ProductRequestStatus.closed:
        return l10n.statusClosed;
    }
  }
}

Color _statusColor(ProductRequestStatus status) {
  switch (status) {
    case ProductRequestStatus.pending:
      return const Color(0xFFF59E0B);
    case ProductRequestStatus.preparing:
      return const Color(0xFF6366F1);
    case ProductRequestStatus.readyForDelivery:
      return const Color(0xFF10B981);
    case ProductRequestStatus.onWay:
      return const Color(0xFF3B82F6);
    case ProductRequestStatus.waitingForPricing:
      return const Color(0xFFEC4899);
    case ProductRequestStatus.closed:
      return const Color(0xFF64748B);
  }
}

IconData _statusIcon(ProductRequestStatus status) {
  switch (status) {
    case ProductRequestStatus.pending:
      return Icons.hourglass_empty_rounded;
    case ProductRequestStatus.preparing:
      return Icons.inventory_rounded;
    case ProductRequestStatus.readyForDelivery:
      return Icons.check_circle_outline_rounded;
    case ProductRequestStatus.onWay:
      return Icons.local_shipping_rounded;
    case ProductRequestStatus.waitingForPricing:
      return Icons.price_change_rounded;
    case ProductRequestStatus.closed:
      return Icons.lock_rounded;
  }
}

/// Which statuses a given role can transition to from the current status.
List<ProductRequestStatus> _allowedTransitions(ProductRequestStatus current, AppUserRole role) {
  if (role == AppUserRole.seller) {
    // Seller cannot change status when pending (can only delete)
    // Seller can only accept when onWay — handled via dedicated _submitAccepting
    // No generic status transitions available for seller
    return [];
  }

  // Inventory man drives the workflow forward
  switch (current) {
    case ProductRequestStatus.pending:
      // Can only move to preparing (no close/delete via status — must use delete button)
      return [ProductRequestStatus.preparing];
    case ProductRequestStatus.preparing:
      return [ProductRequestStatus.readyForDelivery, ProductRequestStatus.waitingForPricing];
    case ProductRequestStatus.readyForDelivery:
      return [ProductRequestStatus.onWay];
    case ProductRequestStatus.onWay:
      // Inventory man cannot change status when onWay
      return [];
    case ProductRequestStatus.waitingForPricing:
      // Neither side can change status
      return [];
    case ProductRequestStatus.closed:
      return [];
  }
}

// ── User switcher widget (demo helper) ────────────────────────────────────────

class _UserSwitcher extends StatelessWidget {
  final AppUser currentUser;
  final ValueChanged<AppUser> onSwitch;

  const _UserSwitcher({required this.currentUser, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final other = currentUser.role == AppUserRole.seller ? mockInventoryMan : mockSeller;
    return GestureDetector(
      onTap: () => onSwitch(other),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: currentUser.role == AppUserRole.seller
                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              child: Icon(
                currentUser.role == AppUserRole.seller ? Icons.storefront_rounded : Icons.warehouse_rounded,
                size: 15,
                color: currentUser.role == AppUserRole.seller ? const Color(0xFF6366F1) : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currentUser.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.count, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  final ProductRequest request;
  final AppUser currentUser;
  final void Function(String id, ProductRequestStatus status, List<ProductRequestItem> items) onStatusChanged;
  final void Function(String id) onDeleteRequest;
  final String Function(ProductRequestStatus) statusLabel;

  const _RequestCard({
    required this.request,
    required this.currentUser,
    required this.onStatusChanged,
    required this.onDeleteRequest,
    required this.statusLabel,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;

  // Inventory man: prepared quantities (barcode -> controller)
  late final Map<String, TextEditingController> _prepControllers;

  // Seller: accepted quantities (barcode -> controller)
  late final Map<String, TextEditingController> _acceptControllers;

  @override
  void initState() {
    super.initState();
    _prepControllers = {
      for (final item in widget.request.items) item.barcode: TextEditingController(text: '${item.preparedQuantity ?? item.requestedQuantity}'),
    };
    _acceptControllers = {
      for (final item in widget.request.items)
        item.barcode: TextEditingController(text: '${item.acceptedQuantity ?? item.preparedQuantity ?? item.requestedQuantity}'),
    };
  }

  @override
  void dispose() {
    for (final c in _prepControllers.values) {
      c.dispose();
    }
    for (final c in _acceptControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitPreparing() {
    final updatedItems = widget.request.items.map((item) {
      final val = int.tryParse(_prepControllers[item.barcode]!.text) ?? item.requestedQuantity;
      return item.copyWith(preparedQuantity: val.clamp(0, item.requestedQuantity));
    }).toList();
    widget.onStatusChanged(widget.request.id, ProductRequestStatus.readyForDelivery, updatedItems);
    setState(() => _expanded = false);
  }

  void _submitAccepting() {
    final updatedItems = widget.request.items.map((item) {
      final sent = item.preparedQuantity ?? item.requestedQuantity;
      final val = int.tryParse(_acceptControllers[item.barcode]!.text) ?? sent;
      return item.copyWith(acceptedQuantity: val.clamp(0, sent));
    }).toList();
    widget.onStatusChanged(widget.request.id, ProductRequestStatus.waitingForPricing, updatedItems);
    setState(() => _expanded = false);
  }

  bool _canDelete() {
    // Both seller and inventory man can delete when status is pending
    return widget.request.status == ProductRequestStatus.pending;
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRequest),
        content: Text(l10n.deleteRequestConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDeleteRequest(widget.request.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final req = widget.request;
    final color = _statusColor(req.status);
    final transitions = _allowedTransitions(req.status, widget.currentUser.role);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    // Special interactive states
    final isInventoryManPreparing = widget.currentUser.role == AppUserRole.inventoryMan && req.status == ProductRequestStatus.preparing;

    final isSellerAccepting = widget.currentUser.role == AppUserRole.seller && req.status == ProductRequestStatus.onWay;

    // Seller sees prepared qty as read-only when status >= readyForDelivery
    final showPreparedReadOnly =
        widget.currentUser.role == AppUserRole.seller &&
        (req.status == ProductRequestStatus.readyForDelivery ||
            req.status == ProductRequestStatus.onWay ||
            req.status == ProductRequestStatus.waitingForPricing ||
            req.status == ProductRequestStatus.closed) &&
        req.items.any((i) => i.preparedQuantity != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _expanded ? color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Card header ───────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_statusIcon(req.status), color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req.id,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 10),
                            _StatusBadge(label: widget.statusLabel(req.status), color: color),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${req.fromInventory}  →  ${req.toInventory}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${req.totalItems} ${l10n.pcs}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(fmt.format(req.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          // ── Expanded body ─────────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Created by
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text('${l10n.createdBy}: ${req.createdBy.name}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Hint banner for active interactive states ─────────────
                  if (isInventoryManPreparing) ...[
                    _HintBanner(icon: Icons.edit_note_rounded, color: _statusColor(ProductRequestStatus.preparing), text: l10n.preparingHint),
                    const SizedBox(height: 14),
                  ] else if (isSellerAccepting) ...[
                    _HintBanner(
                      icon: Icons.check_circle_outline_rounded,
                      color: _statusColor(ProductRequestStatus.waitingForPricing),
                      text: l10n.acceptingHint,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Items table ───────────────────────────────────────────
                  Text(
                    l10n.requestedItems,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),

                  // Table header
                  _ItemTableHeader(
                    l10n: l10n,
                    showPrepared: isInventoryManPreparing || showPreparedReadOnly || isSellerAccepting,
                    showAccepted: isSellerAccepting || (req.items.any((i) => i.acceptedQuantity != null)),
                    isEditing: isInventoryManPreparing || isSellerAccepting,
                    isPrepEditing: isInventoryManPreparing,
                    isAcceptEditing: isSellerAccepting,
                  ),
                  const SizedBox(height: 4),

                  ...req.items.map((item) {
                    final prepCtrl = _prepControllers[item.barcode]!;
                    final acceptCtrl = _acceptControllers[item.barcode]!;
                    final sentQty = item.preparedQuantity ?? item.requestedQuantity;

                    return _ItemRow(
                      item: item,
                      color: color,
                      l10n: l10n,
                      // Inventory man preparing: editable prepared qty
                      prepController: isInventoryManPreparing ? prepCtrl : null,
                      // Seller accepting: editable accepted qty
                      acceptController: isSellerAccepting ? acceptCtrl : null,
                      // Show sent qty read-only to seller
                      showSentReadOnly: showPreparedReadOnly || isSellerAccepting,
                      sentQty: sentQty,
                      // Show accepted qty read-only after accepted
                      showAcceptedReadOnly: !isSellerAccepting && item.acceptedQuantity != null,
                    );
                  }),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),

                  // ── Primary action for special states ─────────────────────
                  if (isInventoryManPreparing)
                    _PrimaryActionButton(
                      label: l10n.markAsReady,
                      icon: Icons.check_circle_outline_rounded,
                      color: _statusColor(ProductRequestStatus.readyForDelivery),
                      onTap: _submitPreparing,
                    )
                  else if (isSellerAccepting)
                    _PrimaryActionButton(
                      label: l10n.acceptDelivery,
                      icon: Icons.inventory_2_rounded,
                      color: _statusColor(ProductRequestStatus.waitingForPricing),
                      onTap: _submitAccepting,
                    )
                  // ── Generic status transitions ────────────────────────────
                  else if (transitions.isNotEmpty) ...[
                    Text(
                      l10n.updateStatus,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: transitions.map((nextStatus) {
                        final nextColor = _statusColor(nextStatus);
                        return GestureDetector(
                          onTap: () {
                            widget.onStatusChanged(req.id, nextStatus, req.items);
                            setState(() => _expanded = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(color: nextColor, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(nextStatus), size: 15, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  widget.statusLabel(nextStatus),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else if (req.status != ProductRequestStatus.closed) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(l10n.noActionsAvailable, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Delete button (shown when delete is allowed) ───────────
                  if (_canDelete()) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, l10n),
                        icon: const Icon(Icons.delete_outline_rounded, size: 17),
                        label: Text(l10n.deleteRequest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hint banner ───────────────────────────────────────────────────────────────

class _HintBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _HintBanner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item table header ─────────────────────────────────────────────────────────

class _ItemTableHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool showPrepared;
  final bool showAccepted;
  final bool isEditing;
  final bool isPrepEditing;
  final bool isAcceptEditing;

  const _ItemTableHeader({
    required this.l10n,
    required this.showPrepared,
    required this.showAccepted,
    required this.isEditing,
    required this.isPrepEditing,
    required this.isAcceptEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.productNameColumn,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              l10n.requestedQty,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ),
          if (showPrepared)
            SizedBox(
              width: 100,
              child: Text(
                isPrepEditing ? l10n.preparedQty : l10n.sentQty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrepEditing ? _statusColor(ProductRequestStatus.preparing) : _statusColor(ProductRequestStatus.onWay),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (showAccepted)
            SizedBox(
              width: 100,
              child: Text(
                l10n.acceptedQty,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(ProductRequestStatus.waitingForPricing)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final ProductRequestItem item;
  final Color color;
  final AppLocalizations l10n;
  final TextEditingController? prepController;
  final TextEditingController? acceptController;
  final bool showSentReadOnly;
  final int sentQty;
  final bool showAcceptedReadOnly;

  const _ItemRow({
    required this.item,
    required this.color,
    required this.l10n,
    this.prepController,
    this.acceptController,
    required this.showSentReadOnly,
    required this.sentQty,
    required this.showAcceptedReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final prepColor = _statusColor(ProductRequestStatus.preparing);
    final acceptColor = _statusColor(ProductRequestStatus.waitingForPricing);
    final sentColor = _statusColor(ProductRequestStatus.onWay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Product name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
                Text(item.barcode, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),

          // Requested qty (always shown, read-only)
          SizedBox(
            width: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${item.requestedQuantity}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Prepared qty — editable by inventory man OR read-only to seller
          if (prepController != null)
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QtyField(controller: prepController!, accentColor: prepColor, max: item.requestedQuantity),
              ),
            )
          else if (showSentReadOnly)
            SizedBox(
              width: 100,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: sentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '$sentQty',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sentColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Accepted qty — editable by seller OR read-only after accepted
          if (acceptController != null)
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QtyField(controller: acceptController!, accentColor: acceptColor, max: sentQty),
              ),
            )
          else if (showAcceptedReadOnly)
            SizedBox(
              width: 100,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: acceptColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '${item.acceptedQuantity}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: acceptColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quantity text field ───────────────────────────────────────────────────────

class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final int max;

  const _QtyField({required this.controller, required this.accentColor, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 8), isDense: true),
      ),
    );
  }
}

// ── Primary action button ─────────────────────────────────────────────────────

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
