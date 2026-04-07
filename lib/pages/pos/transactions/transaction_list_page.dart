import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/auth/auth_service.dart';
import 'package:inventory/features/selling_transactions/cubit/transaction_list_cubit.dart';
import 'package:inventory/features/selling_transactions/cubit/transaction_list_state.dart';
import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';
import 'package:inventory/features/selling_transactions/data/repositories/selling_transactions_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/auth_models.dart';

// ── Entry widget ─────────────────────────────────────────────────────────────

class TransactionListPage extends StatelessWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => TransactionListCubit(), child: const _TransactionListView());
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _TransactionListView extends StatefulWidget {
  const _TransactionListView();

  @override
  State<_TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<_TransactionListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _searchQuery = '';
  String? _paymentMethodFilter;
  String? _priceTypeFilter;
  String? _loggedInInventoryId;
  LoginInventory? _loggedInInventory;

  static const _paymentMethods = ['cash', 'card', 'transfer'];
  static const _priceTypes = ['retail_sale', 'whole_sale'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInventoryAndFetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryAndFetch() async {
    final loginResponse = await AuthService.instance.getLoginResponse();
    if (!mounted) return;
    setState(() {
      _loggedInInventory = loginResponse?.loggedInInventory;
      _loggedInInventoryId = loginResponse?.loggedInInventory?.id;
    });
    _fetch();
  }

  void _fetch() {
    context.read<TransactionListCubit>().fetchTransactions(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      loggedInInventory: _loggedInInventoryId,
      paymentMethod: _paymentMethodFilter,
      priceType: _priceTypeFilter,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionListCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      _fetch();
    });
  }

  void _onPaymentMethodChanged(String? value) {
    setState(() => _paymentMethodFilter = value);
    _fetch();
  }

  void _onPriceTypeChanged(String? value) {
    setState(() => _priceTypeFilter = value);
    _fetch();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _paymentMethodLabel(String? method, AppLocalizations l10n) {
    switch (method) {
      case 'cash':
        return l10n.paymentCash;
      case 'card':
        return l10n.paymentCard;
      case 'transfer':
        return l10n.paymentTransfer;
      default:
        return method ?? '';
    }
  }

  String _priceTypeLabel(String? type, AppLocalizations l10n) {
    switch (type) {
      case 'retail_sale':
        return l10n.priceRetailSale;
      case 'whole_sale':
        return l10n.priceWholeSale;
      default:
        return type ?? '';
    }
  }

  Color _paymentColor(String? method) {
    switch (method) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'card':
        return const Color(0xFF6366F1);
      case 'transfer':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _priceTypeColor(String? type) {
    switch (type) {
      case 'retail_sale':
        return const Color(0xFF3B82F6);
      case 'whole_sale':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(l10n),
          SizedBox(height: context.isMobile ? 16 : 20),
          _buildSummaryRow(l10n),
          SizedBox(height: context.isMobile ? 12 : 16),
          _buildFilters(l10n),
          SizedBox(height: context.isMobile ? 12 : 16),
          Expanded(child: _buildList(l10n)),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sellingTransactions,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              if (_loggedInInventory != null)
                Row(
                  children: [
                    const Icon(Icons.store_rounded, size: 13, color: Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _loggedInInventory!.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Text(l10n.sellingTransactionsSubtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RefreshButton(onTap: _fetch),
      ],
    );
  }

  Widget _buildSummaryRow(AppLocalizations l10n) {
    return BlocBuilder<TransactionListCubit, TransactionListState>(
      builder: (context, state) {
        final count = state is TransactionListLoaded ? state.totalCount : 0;
        final total = state is TransactionListLoaded ? state.transactions.fold<double>(0, (s, t) => s + t.totalSellingPrice) : 0.0;

        return Row(
          children: [
            _StatCard(label: l10n.totalTransactions, value: count.toString(), icon: Icons.receipt_long_rounded, color: const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            _StatCard(
              label: l10n.totalRevenue,
              value: '₼ ${NumberFormat('#,##0.00').format(total)}',
              icon: Icons.attach_money_rounded,
              color: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final isMobile = context.isMobile;
    final searchField = TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: l10n.searchTransactions,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );

    final paymentDropdown = _FilterDropdown<String?>(
      value: _paymentMethodFilter,
      hint: l10n.allPaymentMethods,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.allPaymentMethods)),
        ..._paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(_paymentMethodLabel(m, l10n)))),
      ],
      onChanged: _onPaymentMethodChanged,
    );

    final priceTypeDropdown = _FilterDropdown<String?>(
      value: _priceTypeFilter,
      hint: l10n.allPriceTypes,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.allPriceTypes)),
        ..._priceTypes.map((t) => DropdownMenuItem(value: t, child: Text(_priceTypeLabel(t, l10n)))),
      ],
      onChanged: _onPriceTypeChanged,
    );

    if (isMobile) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: paymentDropdown),
              const SizedBox(width: 8),
              Expanded(child: priceTypeDropdown),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: paymentDropdown),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: priceTypeDropdown),
      ],
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    return BlocBuilder<TransactionListCubit, TransactionListState>(
      builder: (context, state) {
        if (state is TransactionListLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }
        if (state is TransactionListError) {
          return _ErrorView(message: state.message, onRetry: _fetch);
        }
        if (state is TransactionListLoaded) {
          if (state.transactions.isEmpty) {
            return _EmptyView(l10n: l10n);
          }
          return _buildTransactionListView(state, l10n);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionListView(TransactionListLoaded state, AppLocalizations l10n) {
    final isMobile = context.isMobile;
    return Column(
      children: [
        // Count bar
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                '${state.transactions.length} / ${state.totalCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(child: isMobile ? _buildMobileList(state, l10n) : _buildDesktopTable(state, l10n)),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
          ),
      ],
    );
  }

  // ── Mobile list ───────────────────────────────────────────────────────────────

  Widget _buildMobileList(TransactionListLoaded state, AppLocalizations l10n) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: state.transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        return _TransactionCard(
          transaction: tx,
          paymentMethodLabel: _paymentMethodLabel(tx.paymentMethod, l10n),
          priceTypeLabel: _priceTypeLabel(tx.priceType, l10n),
          paymentColor: _paymentColor(tx.paymentMethod),
          priceTypeColor: _priceTypeColor(tx.priceType),
          onTap: () => _showTransactionDetail(context, tx, l10n),
        );
      },
    );
  }

  // ── Desktop table ─────────────────────────────────────────────────────────────

  Widget _buildDesktopTable(TransactionListLoaded state, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              child: Row(
                children: [
                  _TableHeader(label: l10n.receiptNumber, flex: 3),
                  _TableHeader(label: l10n.seller, flex: 2),
                  _TableHeader(label: l10n.paymentMethod, flex: 2),
                  _TableHeader(label: l10n.priceType, flex: 2),
                  _TableHeader(label: l10n.totalAmount, flex: 2),
                  _TableHeader(label: l10n.discountAmount, flex: 2),
                  _TableHeader(label: l10n.nisye, flex: 2),
                  _TableHeader(label: l10n.createdAt, flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Rows
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                itemCount: state.transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final tx = state.transactions[index];
                  return _TransactionTableRow(
                    transaction: tx,
                    paymentMethodLabel: _paymentMethodLabel(tx.paymentMethod, l10n),
                    priceTypeLabel: _priceTypeLabel(tx.priceType, l10n),
                    paymentColor: _paymentColor(tx.paymentMethod),
                    priceTypeColor: _priceTypeColor(tx.priceType),
                    onTap: () => _showTransactionDetail(context, tx, l10n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail popup ──────────────────────────────────────────────────────────────

  void _showTransactionDetail(BuildContext context, SellingTransactionResponse tx, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => _TransactionDetailDialog(transaction: tx, l10n: l10n, onNisyePaid: _fetch),
    );
  }
}

// ── Refresh button ─────────────────────────────────────────────────────────────

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
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

// ── Filter dropdown ────────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({required this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}

// ── Table header ───────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: SelectableText(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5),
      ),
    );
  }
}

// ── Desktop table row ──────────────────────────────────────────────────────────

class _TransactionTableRow extends StatefulWidget {
  final SellingTransactionResponse transaction;
  final String paymentMethodLabel;
  final String priceTypeLabel;
  final Color paymentColor;
  final Color priceTypeColor;
  final VoidCallback onTap;

  const _TransactionTableRow({
    required this.transaction,
    required this.paymentMethodLabel,
    required this.priceTypeLabel,
    required this.paymentColor,
    required this.priceTypeColor,
    required this.onTap,
  });

  @override
  State<_TransactionTableRow> createState() => _TransactionTableRowState();
}

class _TransactionTableRowState extends State<_TransactionTableRow> {
  bool _hovered = false;
  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd.MM.yy HH:mm');

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Receipt number
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      tx.receiptNumber,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    SelectableText(
                      AppLocalizations.of(context)!.nItemsParens(tx.items.length),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              // Seller
              Expanded(
                flex: 2,
                child: SelectableText(tx.sellerDetailedInfo?.username ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              ),
              // Payment method
              Expanded(
                flex: 2,
                child: _Badge(label: widget.paymentMethodLabel, color: widget.paymentColor),
              ),
              // Price type
              Expanded(
                flex: 2,
                child: _Badge(label: widget.priceTypeLabel, color: widget.priceTypeColor),
              ),
              // Total
              Expanded(
                flex: 2,
                child: SelectableText(
                  '₼ ${_fmt.format(tx.totalSellingPrice)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
              // Discount
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('₼ ${_fmt.format(tx.discountAmount)}', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                    SelectableText('${tx.discountPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              // Nisye
              Expanded(
                flex: 2,
                child: tx.paymentNisye
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Badge(label: AppLocalizations.of(context)!.nisye, color: const Color(0xFFE87C0A)),
                          const SizedBox(height: 3),
                          // if (tx.nisyeAmount != null)
                          //   SelectableText('₼ ${_fmt.format(tx.nisyeAmount!)}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          // const SizedBox(height: 2),
                          SelectableText(
                            '₼ ${_fmt.format(tx.totalSellingPrice - (tx.paidAmount ?? 0))}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE87C0A)),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // Date
              Expanded(
                flex: 2,
                child: SelectableText(
                  tx.createdAt != null ? _dateFmt.format(tx.createdAt!.toLocal()) : '—',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile card ────────────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final SellingTransactionResponse transaction;
  final String paymentMethodLabel;
  final String priceTypeLabel;
  final Color paymentColor;
  final Color priceTypeColor;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.paymentMethodLabel,
    required this.priceTypeLabel,
    required this.paymentColor,
    required this.priceTypeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd.MM.yy HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    tx.receiptNumber,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    maxLines: 1,
                  ),
                ),
                SelectableText(
                  '₼ ${fmt.format(tx.totalSellingPrice)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Badge(label: paymentMethodLabel, color: paymentColor),
                const SizedBox(width: 6),
                _Badge(label: priceTypeLabel, color: priceTypeColor),
                const Spacer(),
                SelectableText(
                  tx.createdAt != null ? dateFmt.format(tx.createdAt!.toLocal()) : '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                SelectableText(tx.sellerDetailedInfo?.username ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Spacer(),
                const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                SelectableText(
                  AppLocalizations.of(context)!.nItemsParens(tx.items.length),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            if (tx.discountAmount > 0) ...[
              const SizedBox(height: 4),
              SelectableText(
                'Discount: ₼ ${fmt.format(tx.discountAmount)} (${tx.discountPercentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
              ),
            ],
            if (tx.paymentNisye) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, size: 12, color: Color(0xFFE87C0A)),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.nisye,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE87C0A)),
                        ),
                        const Spacer(),
                        if (tx.nisyeAmount != null)
                          SelectableText(
                            '₼ ${fmt.format(tx.nisyeAmount!)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE87C0A)),
                          ),
                      ],
                    ),
                    if (tx.nisyeCustomerFullname != null && tx.nisyeCustomerFullname!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          SelectableText(tx.nisyeCustomerFullname!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                    if (tx.nisyeCustomerPhoneNumber != null && tx.nisyeCustomerPhoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          SelectableText(tx.nisyeCustomerPhoneNumber!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                    if (tx.paidAmount != null && tx.nisyeAmount != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              '${AppLocalizations.of(context)!.nisyePaidAmount}: ₼ ${fmt.format(tx.paidAmount!)}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ),
                          SelectableText(
                            '${AppLocalizations.of(context)!.nisyeRemainingAmount}: ₼ ${fmt.format(tx.totalSellingPrice - tx.paidAmount!)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFE87C0A), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Empty view ─────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTransactionsFound,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(l10n.adjustFiltersOrSearch, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(AppLocalizations.of(context)!.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail dialog ─────────────────────────────────────────────────────────────

class _TransactionDetailDialog extends StatelessWidget {
  final SellingTransactionResponse transaction;
  final AppLocalizations l10n;
  final VoidCallback? onNisyePaid;

  const _TransactionDetailDialog({required this.transaction, required this.l10n, this.onNisyePaid});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    final isMobile = context.isMobile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.transactionDetail,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          SelectableText(tx.receiptNumber, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards row
                      Row(
                        children: [
                          _DetailCard(
                            label: l10n.totalAmount,
                            value: '₼ ${fmt.format(tx.totalSellingPrice)}',
                            valueColor: const Color(0xFF1E293B),
                            valueBold: true,
                          ),
                          const SizedBox(width: 10),
                          if (tx.paymentNisye) ...[
                            _DetailCard(
                              label: l10n.nisyePaidAmount,
                              value: '₼ ${fmt.format(tx.paidAmount ?? 0)}',
                              valueColor: const Color(0xFF10B981),
                              valueBold: true,
                            ),
                            const SizedBox(width: 10),
                            _DetailCard(
                              label: l10n.nisyeRemainingAmount,
                              value: '₼ ${fmt.format(tx.totalSellingPrice - (tx.paidAmount ?? 0))}',
                              valueColor: const Color(0xFFE87C0A),
                              valueBold: true,
                            ),
                          ] else
                            _DetailCard(
                              label: l10n.discountAmount,
                              value: '₼ ${fmt.format(tx.discountAmount)} (${tx.discountPercentage.toStringAsFixed(1)}%)',
                              valueColor: const Color(0xFFEF4444),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info grid
                      _InfoSection(
                        children: [
                          _InfoRow(icon: Icons.receipt_outlined, label: l10n.receiptNumber, value: tx.receiptNumber),
                          _InfoRow(icon: Icons.person_outline_rounded, label: l10n.seller, value: tx.sellerDetailedInfo?.username ?? '—'),
                          _InfoRow(icon: Icons.store_rounded, label: l10n.store, value: tx.sellingLocationInventoryDetails?.name ?? '—'),
                          _InfoRow(
                            icon: Icons.payment_rounded,
                            label: l10n.paymentMethod,
                            value: _paymentLabel(tx.paymentMethod, l10n),
                            valueColor: _paymentColor(tx.paymentMethod),
                          ),
                          _InfoRow(
                            icon: Icons.sell_rounded,
                            label: l10n.priceType,
                            value: _priceTypeLabel(tx.priceType, l10n),
                            valueColor: _priceTypeColor(tx.priceType),
                          ),
                          _InfoRow(
                            icon: Icons.loyalty_rounded,
                            label: l10n.customer,
                            value: tx.selectedLoyalCustomer != null ? tx.selectedLoyalCustomer!.substring(0, 8).toUpperCase() : l10n.noCustomer,
                            valueColor: tx.selectedLoyalCustomer != null ? const Color(0xFF6366F1) : null,
                          ),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: l10n.createdAt,
                            value: tx.createdAt != null ? dateFmt.format(tx.createdAt!.toLocal()) : '—',
                          ),
                        ],
                      ),
                      // Nisye section
                      if (tx.paymentNisye) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.credit_card_rounded, size: 15, color: Color(0xFFE87C0A)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.nisyeDetails,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDBA74)),
                          ),
                          child: Column(
                            children: [
                              if (tx.nisyeCustomerFullname != null && tx.nisyeCustomerFullname!.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: l10n.nisyeCustomer,
                                  value: tx.nisyeCustomerFullname!,
                                  valueColor: const Color(0xFF1E293B),
                                ),
                              if (tx.nisyeCustomerPhoneNumber != null && tx.nisyeCustomerPhoneNumber!.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: l10n.nisyePhone,
                                  value: tx.nisyeCustomerPhoneNumber!,
                                  valueColor: const Color(0xFF1E293B),
                                ),
                              if (tx.nisyeAmount != null)
                                _InfoRow(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: l10n.nisyeAmount,
                                  value: '₼ ${fmt.format(tx.nisyeAmount!)}',
                                  valueColor: const Color(0xFFE87C0A),
                                ),
                              if (tx.paidAmount != null)
                                _InfoRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: l10n.nisyePaidAmount,
                                  value: '₼ ${fmt.format(tx.paidAmount!)}',
                                  valueColor: const Color(0xFF10B981),
                                ),
                              if (tx.nisyeAmount != null && tx.paidAmount != null)
                                _InfoRow(
                                  icon: Icons.hourglass_bottom_rounded,
                                  label: l10n.nisyeRemainingAmount,
                                  value: '₼ ${fmt.format(tx.totalSellingPrice - tx.paidAmount!)}',
                                  valueColor: const Color(0xFFE87C0A),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NisyeHistorySection(transactionId: tx.id, l10n: l10n),
                      ],
                      const SizedBox(height: 20),
                      // Items section
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded, size: 15, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(
                            l10n.transactionItems,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${tx.items.length}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...tx.items.map((item) => _TransactionItemRow(item: item, fmt: fmt, l10n: l10n)),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: tx.paymentNisye && (tx.totalSellingPrice - (tx.paidAmount ?? 0)) > 0
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.close,
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (_) => _PayNisyeDialog(transaction: tx, l10n: l10n, onSuccess: onNisyePaid),
                                );
                              },
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: Text(l10n.payNisye, style: const TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE87C0A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentLabel(String? method, AppLocalizations l10n) {
    switch (method) {
      case 'cash':
        return l10n.paymentCash;
      case 'card':
        return l10n.paymentCard;
      case 'transfer':
        return l10n.paymentTransfer;
      default:
        return method ?? '—';
    }
  }

  String _priceTypeLabel(String? type, AppLocalizations l10n) {
    switch (type) {
      case 'retail_sale':
        return l10n.priceRetailSale;
      case 'whole_sale':
        return l10n.priceWholeSale;
      default:
        return type ?? '—';
    }
  }

  Color _paymentColor(String? method) {
    switch (method) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'card':
        return const Color(0xFF6366F1);
      case 'transfer':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _priceTypeColor(String? type) {
    switch (type) {
      case 'retail_sale':
        return const Color(0xFF3B82F6);
      case 'whole_sale':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

// ── Detail helpers ─────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _DetailCard({required this.label, required this.value, this.valueColor, this.valueBold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            SelectableText(
              value,
              style: TextStyle(fontSize: 16, fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? const Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: SelectableText(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1E293B)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItemRow extends StatelessWidget {
  final SellingTransactionItemResponse item;
  final NumberFormat fmt;
  final AppLocalizations l10n;

  const _TransactionItemRow({required this.item, required this.fmt, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      item.productUuid.substring(0, 8).toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'monospace'),
                    ),
                    SelectableText('ID: ${item.productUuid}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SelectableText(
                    '₼ ${fmt.format(item.totalPrice)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  SelectableText('x${item.count}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          if (item.discountAmount > 0) ...[
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 12, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                SelectableText(
                  'Discount: ₼ ${fmt.format(item.discountAmount)} (${item.discountPercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pay Nisye dialog ──────────────────────────────────────────────────────────

class _PayNisyeDialog extends StatefulWidget {
  final SellingTransactionResponse transaction;
  final AppLocalizations l10n;
  final VoidCallback? onSuccess;

  const _PayNisyeDialog({required this.transaction, required this.l10n, this.onSuccess});

  @override
  State<_PayNisyeDialog> createState() => _PayNisyeDialogState();
}

class _PayNisyeDialogState extends State<_PayNisyeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  double get _remaining => widget.transaction.totalSellingPrice - (widget.transaction.paidAmount ?? 0);
  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE87C0A),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() => _errorMessage = widget.l10n.payNisyeDateRequired);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final result = await SellingTransactionsRepository.instance.payNisye(
      PayNisyeRequest(
        receiptNumber: widget.transaction.receiptNumber,
        paymentAmount: amount,
        paymentDate: _selectedDate!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      ),
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(widget.l10n.payNisyeSuccess),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onSuccess?.call();
      case Failure(:final message):
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tx = widget.transaction;
    final isMobile = context.isMobile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 460),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE87C0A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.payNisyeTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(tx.receiptNumber, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.nisyeCustomer, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.nisyeCustomerFullname ?? '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (tx.nisyeCustomerPhoneNumber != null && tx.nisyeCustomerPhoneNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(tx.nisyeCustomerPhoneNumber!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(l10n.nisyeRemainingAmount, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  '₼ ${_fmt.format(_remaining)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFE87C0A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount field
                      Text(
                        l10n.payNisyeAmount,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: l10n.payNisyeAmountHint,
                          prefixText: '₼ ',
                          prefixStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: Color(0xFFE87C0A), width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l10n.payNisyeAmountRequired;
                          final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) return l10n.payNisyeAmountInvalid;
                          if (parsed > _remaining + 0.001) return l10n.payNisyeAmountExceeds;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Date field
                      Text(
                        l10n.payNisyeDate,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _isLoading ? null : _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedDate == null && _errorMessage == l10n.payNisyeDateRequired
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFE87C0A)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedDate != null ? _dateFmt.format(_selectedDate!) : l10n.payNisyeDateHint,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedDate != null ? FontWeight.w700 : FontWeight.w400,
                                    color: _selectedDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Note field
                      Text(
                        l10n.payNisyeNote,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l10n.payNisyeNoteHint,
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            borderSide: const BorderSide(color: Color(0xFFE87C0A), width: 1.5),
                          ),
                        ),
                      ),
                      // Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                l10n.close,
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE87C0A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(l10n.payNisye, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nisye History Section ─────────────────────────────────────────────────────

class _NisyeHistorySection extends StatefulWidget {
  final String transactionId;
  final AppLocalizations l10n;

  const _NisyeHistorySection({required this.transactionId, required this.l10n});

  @override
  State<_NisyeHistorySection> createState() => _NisyeHistorySectionState();
}

class _NisyeHistorySectionState extends State<_NisyeHistorySection> {
  List<NisyePaymentHistoryItem>? _items;
  bool _loading = true;
  String? _error;

  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await SellingTransactionsRepository.instance.fetchNisyeHistory(sellingTransactionId: widget.transactionId);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _items = data.results;
          _loading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 15, color: Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text(
              l10n.nisyeHistory,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            if (_items != null && _items!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_items!.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ),
            ],
            const Spacer(),
            if (!_loading)
              InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF64748B)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Content
        if (_loading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(l10n.nisyeHistoryLoading, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.nisyeHistoryError, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                ),
                InkWell(
                  onTap: _load,
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else if (_items == null || _items!.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, size: 28, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 6),
                Text(l10n.nisyeHistoryEmpty, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _items!.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _NisyeHistoryRow(item: _items![i], fmt: _fmt, dateFmt: _dateFmt, l10n: l10n),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _NisyeHistoryRow extends StatelessWidget {
  final NisyePaymentHistoryItem item;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final AppLocalizations l10n;

  const _NisyeHistoryRow({required this.item, required this.fmt, required this.dateFmt, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.payments_rounded, size: 16, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          // Middle — date + paid by
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.paymentDate != null)
                  Text(
                    dateFmt.format(item.paymentDate!),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                if (item.creatorDetails != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.creatorDetails!.displayName,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.note!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount
          Text(
            '₼ ${fmt.format(item.paymentAmount)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }
}
