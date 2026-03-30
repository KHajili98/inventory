import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/auth/auth_cubit.dart';
import 'package:inventory/features/product_requests/cubit/product_requests_cubit.dart';
import 'package:inventory/features/product_requests/cubit/product_requests_state.dart';
import 'package:inventory/features/product_requests/data/models/product_requests_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/auth_models.dart';
import 'package:inventory/pages/inventory/add_stock_product_request.dart';

class ProductRequestsPage extends StatelessWidget {
  const ProductRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProductRequestsCubit()..fetchRequests(), child: const _ProductRequestsView());
  }
}

class _ProductRequestsView extends StatefulWidget {
  const _ProductRequestsView();

  @override
  State<_ProductRequestsView> createState() => _ProductRequestsViewState();
}

class _ProductRequestsViewState extends State<_ProductRequestsView> {
  String _searchQuery = '';
  String? _statusFilter;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductRequestsCubit>().loadMore();
    }
  }

  List<ProductRequestModel> _filtered(List<ProductRequestModel> requests) {
    return requests.where((r) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.id.toLowerCase().contains(q) ||
          r.sourceInventoryName.toLowerCase().contains(q) ||
          r.destinationInventoryName.toLowerCase().contains(q) ||
          r.productsWithDetails.any((p) => (p.productDetails?.productName ?? '').toLowerCase().contains(q));
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _applyStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<ProductRequestsCubit>().fetchRequests(status: status);
  }

  Future<void> _onDeleteRequest(String requestId) async {
    final cubit = context.read<ProductRequestsCubit>();
    final result = await cubit.deleteRequest(requestId);
    if (!mounted) return;
    if (result is Failure<void>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  void _openCreateRequest() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(value: context.read<ProductRequestsCubit>(), child: const AddStockProductRequest()),
    ).then((created) {
      if (created == true) context.read<ProductRequestsCubit>().refresh();
    });
  }

  /// Returns the logged-in user from AuthCubit, or null if not authenticated.
  LoginResponse? _loggedInUser(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) return authState.response;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loggedInUser = _loggedInUser(context);

    return BlocBuilder<ProductRequestsCubit, ProductRequestsState>(
      builder: (context, state) {
        final requests = state is ProductRequestsLoaded ? state.requests : <ProductRequestModel>[];
        final totalCount = state is ProductRequestsLoaded ? state.totalCount : 0;
        final isLoadingMore = state is ProductRequestsLoaded && state.isLoadingMore;
        final filtered = _filtered(requests);

        // Status counts from current loaded list
        final statusCounts = <String, int>{};
        for (final r in requests) {
          statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
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
                        // Show "Create Request" only for seller (creator == logged in user)
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
                        const SizedBox(width: 8),
                        // Refresh button
                        IconButton(
                          onPressed: () => context.read<ProductRequestsCubit>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                          tooltip: 'Refresh',
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
                            count: totalCount,
                            isSelected: _statusFilter == null,
                            color: const Color(0xFF6366F1),
                            onTap: () => _applyStatusFilter(null),
                          ),
                          const SizedBox(width: 8),
                          ..._apiStatusValues.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _StatusChip(
                                label: _apiStatusLabel(context, s),
                                count: statusCounts[s] ?? 0,
                                isSelected: _statusFilter == s,
                                color: _apiStatusColor(s),
                                onTap: () => _applyStatusFilter(_statusFilter == s ? null : s),
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

              // ── Request list ─────────────────────────────────────────────
              Expanded(
                child: switch (state) {
                  ProductRequestsLoading() => const Center(child: CircularProgressIndicator()),
                  ProductRequestsError(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProductRequestsCubit>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ =>
                    filtered.isEmpty
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
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding, vertical: 8),
                            itemCount: filtered.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _ApiRequestCard(
                                request: filtered[i],
                                authUserId: loggedInUser?.user.id ?? '',
                                onDeleteRequest: _onDeleteRequest,
                                statusLabel: (s) => _apiStatusLabel(context, s),
                              );
                            },
                          ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// All status values returned by the API.
const _apiStatusValues = ['pending', 'preparing', 'ready_for_delivery', 'on_way', 'waiting_for_pricing', 'closed'];

String _apiStatusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case 'pending':
      return l10n.statusPending;
    case 'preparing':
      return l10n.statusPreparing;
    case 'ready_for_delivery':
      return l10n.statusReadyForDelivery;
    case 'on_way':
      return l10n.statusOnWay;
    case 'waiting_for_pricing':
      return l10n.statusWaitingForPricing;
    case 'closed':
      return l10n.statusClosed;
    default:
      return status;
  }
}

Color _apiStatusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'preparing':
      return const Color(0xFF6366F1);
    case 'ready_for_delivery':
      return const Color(0xFF10B981);
    case 'on_way':
      return const Color(0xFF3B82F6);
    case 'waiting_for_pricing':
      return const Color(0xFFEC4899);
    case 'closed':
      return const Color(0xFF64748B);
    default:
      return const Color(0xFF94A3B8);
  }
}

IconData _apiStatusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_empty_rounded;
    case 'preparing':
      return Icons.inventory_rounded;
    case 'ready_for_delivery':
      return Icons.check_circle_outline_rounded;
    case 'on_way':
      return Icons.local_shipping_rounded;
    case 'waiting_for_pricing':
      return Icons.price_change_rounded;
    case 'closed':
      return Icons.lock_rounded;
    default:
      return Icons.circle_outlined;
  }
}

/// Allowed next statuses per current status.
/// [isSeller] = creator of the request (logged-in user == creator).
List<String> _allowedApiTransitions(String current, {required bool isSeller}) {
  // Seller (creator) can only act when goods are "on_way" → accept as waiting_for_pricing
  if (isSeller) {
    if (current == 'on_way') return ['waiting_for_pricing'];
    return [];
  }
  // Inventory man
  switch (current) {
    case 'pending':
      return ['preparing'];
    case 'preparing':
      return ['ready_for_delivery', 'waiting_for_pricing'];
    case 'ready_for_delivery':
      return ['on_way'];
    default:
      return [];
  }
}

// ── API Request Card ──────────────────────────────────────────────────────────

class _ApiRequestCard extends StatefulWidget {
  final ProductRequestModel request;

  /// The id of the currently logged-in user.
  final String authUserId;
  final Future<void> Function(String id) onDeleteRequest;
  final String Function(String status) statusLabel;

  const _ApiRequestCard({required this.request, required this.authUserId, required this.onDeleteRequest, required this.statusLabel});

  @override
  State<_ApiRequestCard> createState() => _ApiRequestCardState();
}

class _ApiRequestCardState extends State<_ApiRequestCard> {
  bool _expanded = false;
  bool _isUpdating = false;

  // Per-product quantity controllers: productUuid → controller
  // Inventory man edits sending_count; seller edits receiving_count.
  late final Map<String, TextEditingController> _qtyControllers;

  /// True when the logged-in user is the creator of this request (seller flow).
  bool get _isSeller => widget.authUserId == widget.request.creatorUserId;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final products = widget.request.productsWithDetails;
    _qtyControllers = {
      for (final p in products)
        p.productUuid: TextEditingController(
          text: _isSeller ? '${p.receivingCount ?? p.sendingCount ?? p.creatingCount ?? 0}' : '${p.sendingCount ?? p.creatingCount ?? 0}',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _canDelete() => widget.request.status == 'pending';

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
      await widget.onDeleteRequest(widget.request.id);
    }
  }

  Future<void> _changeStatus(BuildContext context, String nextStatus) async {
    setState(() => _isUpdating = true);

    final req = widget.request;
    final cubit = context.read<ProductRequestsCubit>();

    // Build products payload with the edited quantities.
    // - Inventory man: fills sending_count; creating_count kept from original.
    // - Seller: fills receiving_count; creating_count & sending_count kept.
    final products = req.productsWithDetails.map((p) {
      final editedValue = int.tryParse(_qtyControllers[p.productUuid]?.text ?? '') ?? 0;
      return {
        'product_uuid': p.productUuid,
        'creating_count': p.creatingCount,
        if (_isSeller) ...{'sending_count': p.sendingCount, 'receiving_count': editedValue} else ...{'sending_count': editedValue},
      };
    }).toList();

    // Step 1 — update counts
    final updateResult = await cubit.updateRequest(
      id: req.id,
      sourceInventory: req.sourceInventory,
      destinationInventory: req.destinationInventory,
      products: products,
    );

    if (!mounted) return;

    if (updateResult is Failure) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((updateResult as Failure).message), backgroundColor: const Color(0xFFEF4444)));
      return;
    }

    // Step 2 — change status
    final statusResult = await cubit.changeStatus(id: req.id, newStatus: nextStatus);

    if (!mounted) return;

    if (statusResult is Failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((statusResult as Failure).message), backgroundColor: const Color(0xFFEF4444)));
    }

    setState(() {
      _isUpdating = false;
      _expanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final req = widget.request;
    final color = _apiStatusColor(req.status);
    final transitions = _allowedApiTransitions(req.status, isSeller: _isSeller);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    // Whether there are editable quantity fields to show in the expanded table.
    final hasEditableFields = transitions.isNotEmpty;

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
          // ── Card header ──────────────────────────────────────────────────
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
                    child: _isUpdating
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: color),
                          )
                        : Icon(_apiStatusIcon(req.status), color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                req.id.substring(0, 8).toUpperCase(),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                            Flexible(
                              child: Text(
                                '${req.sourceInventoryName}  →  ${req.destinationInventoryName}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                      if (req.createdAt != null) Text(fmt.format(req.createdAt!), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          // ── Expanded body ────────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Created by
                  if (req.creatorUserDetails != null)
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.createdBy}: ${req.creatorUserDetails!.fullName}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            req.creatorUserDetails!.role,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Role hint banner
                  if (hasEditableFields) ...[
                    _HintBanner(
                      icon: _isSeller ? Icons.check_circle_outline_rounded : Icons.local_shipping_rounded,
                      color: _isSeller ? _apiStatusColor('waiting_for_pricing') : _apiStatusColor('on_way'),
                      text: _isSeller ? l10n.acceptingHint : l10n.preparingHint,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Products table ───────────────────────────────────────
                  Text(
                    l10n.requestedItems,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),

                  // Table header
                  _buildTableHeader(l10n, hasEditableFields),
                  const SizedBox(height: 4),

                  // Product rows
                  ...req.productsWithDetails.map((p) => _buildProductRow(p, color, hasEditableFields)),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),

                  // ── Status transitions ───────────────────────────────────
                  if (_isUpdating)
                    const Center(
                      child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
                    )
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
                        final nextColor = _apiStatusColor(nextStatus);
                        return GestureDetector(
                          onTap: () => _changeStatus(context, nextStatus),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(color: nextColor, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_apiStatusIcon(nextStatus), size: 15, color: Colors.white),
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
                  ] else if (req.status != 'closed') ...[
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

                  // ── Delete button ────────────────────────────────────────
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

  Widget _buildTableHeader(AppLocalizations l10n, bool hasEditableFields) {
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
          // Sending count column (read-only for seller, editable for inventory man when active)
          SizedBox(
            width: 80,
            child: Text(
              'Sent',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasEditableFields && !_isSeller
                    ? _apiStatusColor('on_way') // editable highlight
                    : _apiStatusColor('on_way'),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Receiving count column (read-only for inventory man, editable for seller when active)
          SizedBox(
            width: 80,
            child: Text(
              'Received',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasEditableFields && _isSeller ? _apiStatusColor('waiting_for_pricing') : _apiStatusColor('waiting_for_pricing'),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(ProductWithDetailsModel p, Color statusColor, bool hasEditableFields) {
    final detail = p.productDetails;
    final editController = _qtyControllers[p.productUuid];

    // Inventory man edits sending_count; seller edits receiving_count.
    final bool inventoryManEditing = hasEditableFields && !_isSeller;
    final bool sellerEditing = hasEditableFields && _isSeller;

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
                  detail?.productName ?? p.productUuid.substring(0, 8),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
                if (detail != null) Text(detail.barcode, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),

          // Creating count — always read-only (disabled)
          SizedBox(
            width: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${p.creatingCount ?? 0}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Sending count — editable for inventory man when transitioning, otherwise read-only
          SizedBox(
            width: 80,
            child: Center(
              child: inventoryManEditing && editController != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _QtyField(controller: editController, accentColor: _apiStatusColor('on_way')),
                    )
                  : p.sendingCount != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _apiStatusColor('on_way').withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${p.sendingCount}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _apiStatusColor('on_way')),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text('—', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
          ),

          // Receiving count — editable for seller when transitioning, otherwise read-only
          SizedBox(
            width: 80,
            child: Center(
              child: sellerEditing && editController != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _QtyField(controller: editController, accentColor: _apiStatusColor('waiting_for_pricing')),
                    )
                  : p.receivingCount != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _apiStatusColor('waiting_for_pricing').withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p.receivingCount}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _apiStatusColor('waiting_for_pricing')),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text('—', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
          ),
        ],
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

// ── Quantity text field ───────────────────────────────────────────────────────

class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;

  const _QtyField({required this.controller, required this.accentColor});

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
