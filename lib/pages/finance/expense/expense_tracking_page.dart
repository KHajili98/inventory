import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/expense/data/models/fee_category_model.dart';
import 'package:inventory/features/expense/data/models/fee_model.dart';
import 'package:inventory/features/expense/data/repositories/fee_category_repository.dart';
import 'package:inventory/features/expense/data/repositories/fee_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/pages/finance/expense/expense_categories_page.dart';

// ── Payment type enum (for UI labels) ─────────────────────────────────────────

enum ExpensePaymentType { cash, card, transfer }

extension ExpensePaymentTypeX on ExpensePaymentType {
  String get apiValue => switch (this) {
    ExpensePaymentType.cash => 'cash',
    ExpensePaymentType.card => 'card',
    ExpensePaymentType.transfer => 'transfer',
  };

  static ExpensePaymentType fromApi(String value) => switch (value) {
    'cash' => ExpensePaymentType.cash,
    'card' => ExpensePaymentType.card,
    'transfer' => ExpensePaymentType.transfer,
    _ => ExpensePaymentType.cash,
  };
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ExpenseTrackingPage extends StatefulWidget {
  const ExpenseTrackingPage({super.key});

  @override
  State<ExpenseTrackingPage> createState() => _ExpenseTrackingPageState();
}

class _ExpenseTrackingPageState extends State<ExpenseTrackingPage> {
  final _feeRepo = FeeRepository.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  List<Fee> _fees = [];
  int _totalCount = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  // ── Pagination ────────────────────────────────────────────────────────────
  int _page = 1;
  static const int _pageSize = 20;
  bool get _hasMore => _fees.length < _totalCount;

  // ── Filters ───────────────────────────────────────────────────────────────
  DateTime? _filterFrom;
  DateTime? _filterTo;
  ExpensePaymentType? _filterPaymentType;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Scroll ────────────────────────────────────────────────────────────────
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFees(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadFees({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _fees = [];
      });
    }

    final dateFmt = DateFormat('yyyy-MM-dd');
    final result = await _feeRepo.fetchFees(
      page: _page,
      pageSize: _pageSize,
      search: _searchQuery,
      paymentType: _filterPaymentType?.apiValue ?? '',
      paymentDateGte: _filterFrom != null ? dateFmt.format(_filterFrom!) : '',
      paymentDateLte: _filterTo != null ? dateFmt.format(_filterTo!) : '',
    );

    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _fees = reset ? data.results : [..._fees, ...data.results];
          _totalCount = data.count;
          _loading = false;
          _loadingMore = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loading = false;
          _loadingMore = false;
        });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _page++;
    });
    await _loadFees();
  }

  void _applyFilters() => _loadFees(reset: true);

  // ── Date range picker ──────────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
          child: Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
              datePickerTheme: const DatePickerThemeData(headerBackgroundColor: Color(0xFF6366F1), headerForegroundColor: Colors.white),
            ),
            child: _DateRangePickerDialog(
              initialDateRange: (_filterFrom != null && _filterTo != null) ? DateTimeRange(start: _filterFrom!, end: _filterTo!) : null,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      _filterFrom = picked.start;
      _filterTo = picked.end;
      _applyFilters();
    }
  }

  void _clearFilter() {
    _filterFrom = null;
    _filterTo = null;
    _filterPaymentType = null;
    _searchCtrl.clear();
    _searchQuery = '';
    _applyFilters();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _openAddDialog() async {
    final created = await showDialog<Fee>(context: context, barrierDismissible: false, builder: (ctx) => const _ExpenseFormDialog());
    if (created != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.expenseAdded), backgroundColor: const Color(0xFF22C55E)));
      _loadFees(reset: true);
    }
  }

  void _openEditDialog(Fee existing) async {
    final result = await showDialog<_EditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ExpenseFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.deleted ? l10n.expenseDeleted : l10n.expenseUpdated),
        backgroundColor: result.deleted ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      ),
    );
    _loadFees(reset: true);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _paymentLabel(String pt, AppLocalizations l10n) => switch (pt) {
    'cash' => l10n.expensePaymentCash,
    'card' => l10n.expensePaymentCard,
    'transfer' => l10n.expensePaymentTransfer,
    _ => pt,
  };

  Color _paymentColor(String pt) => switch (pt) {
    'cash' => const Color(0xFF22C55E),
    'card' => const Color(0xFF6366F1),
    'transfer' => const Color(0xFF0EA5E9),
    _ => const Color(0xFF94A3B8),
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final totalAmount = _fees.fold(0.0, (s, e) => s + e.paymentAmount);
    final fmt = NumberFormat('#,##0.00');

    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(l10n, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          _buildStats(l10n, isMobile, totalAmount, fmt),
          SizedBox(height: isMobile ? 12 : 16),
          _buildFilterBar(l10n, isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          Expanded(child: _buildBody(l10n, isMobile, fmt)),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(AppLocalizations l10n, bool isMobile) {
    final addButton = FilledButton.icon(
      onPressed: _openAddDialog,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(l10n.addExpense),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

    final categoriesButton = OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpenseCategoriesPage())),
      icon: const Icon(Icons.category_outlined, size: 18),
      label: Text(l10n.expenseCategories),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6366F1),
        side: const BorderSide(color: Color(0xFF6366F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.expenseTracking,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: addButton),
              const SizedBox(width: 10),
              Expanded(child: categoriesButton),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          l10n.expenseTracking,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const Spacer(),
        categoriesButton,
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats(AppLocalizations l10n, bool isMobile, double totalAmount, NumberFormat fmt) {
    final stats = [
      _StatCard(
        label: l10n.totalExpenses,
        value: '${fmt.format(totalAmount)} ₼',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF6366F1),
      ),
      _StatCard(label: l10n.expenseCount, value: '$_totalCount', icon: Icons.receipt_long_rounded, color: const Color(0xFF0EA5E9)),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 12), SizedBox(width: 200, child: stats[i])],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: stats[i])],
      ],
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(AppLocalizations l10n, bool isMobile) {
    final hasDateFilter = _filterFrom != null || _filterTo != null;
    final hasTypeFilter = _filterPaymentType != null;
    final hasFilter = hasDateFilter || hasTypeFilter || _searchQuery.isNotEmpty;
    final dateFmt = DateFormat('dd.MM.yyyy');

    final String dateLabel;
    if (_filterFrom != null && _filterTo != null) {
      dateLabel = '${dateFmt.format(_filterFrom!)}  –  ${dateFmt.format(_filterTo!)}';
    } else if (_filterFrom != null) {
      dateLabel = '${dateFmt.format(_filterFrom!)} –';
    } else if (_filterTo != null) {
      dateLabel = '– ${dateFmt.format(_filterTo!)}';
    } else {
      dateLabel = l10n.expenseFilterByDate;
    }

    final paymentTypeOptions = <(ExpensePaymentType?, String)>[
      (null, l10n.expenseFilterAll),
      (ExpensePaymentType.cash, l10n.expensePaymentCash),
      (ExpensePaymentType.card, l10n.expensePaymentCard),
      (ExpensePaymentType.transfer, l10n.expensePaymentTransfer),
    ];

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 220,
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: l10n.searchExpenses,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _applyFilters();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
        onSubmitted: (_) => _applyFilters(),
        textInputAction: TextInputAction.search,
      ),
    );

    final dateChip = InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: hasDateFilter ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasDateFilter ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded, size: 16, color: hasDateFilter ? const Color(0xFF6366F1) : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasDateFilter ? FontWeight.w600 : FontWeight.w400,
                color: hasDateFilter ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );

    final typeDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hasTypeFilter ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasTypeFilter ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExpensePaymentType?>(
          value: _filterPaymentType,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
          style: TextStyle(
            fontSize: 13,
            fontWeight: hasTypeFilter ? FontWeight.w600 : FontWeight.w400,
            color: hasTypeFilter ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          ),
          items: paymentTypeOptions.map((pt) => DropdownMenuItem<ExpensePaymentType?>(value: pt.$1, child: Text(pt.$2))).toList(),
          onChanged: (v) {
            setState(() => _filterPaymentType = v);
            _applyFilters();
          },
        ),
      ),
    );

    final clearBtn = hasFilter
        ? InkWell(
            onTap: _clearFilter,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
            ),
          )
        : const SizedBox.shrink();

    if (isMobile) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: dateChip),
              const SizedBox(width: 8),
              typeDropdown,
              const SizedBox(width: 8),
              clearBtn,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [searchField, const SizedBox(width: 12), dateChip, const SizedBox(width: 8), typeDropdown, const SizedBox(width: 8), clearBtn],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(AppLocalizations l10n, bool isMobile, NumberFormat fmt) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              l10n.expenseLoadFailed(_error!),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _loadFees(reset: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (_fees.isEmpty) return _buildEmptyState(l10n);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (!isMobile) _buildTableHeader(l10n),
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              itemCount: _fees.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                if (i == _fees.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
                  );
                }
                final e = _fees[i];
                return InkWell(
                  onTap: () => _openEditDialog(e),
                  hoverColor: const Color(0xFFF8FAFF),
                  child: isMobile ? _buildMobileRow(e, l10n, fmt) : _buildDesktopRow(e, l10n, fmt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noExpensesYet,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(l10n.addFirstExpense, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.addExpense),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations l10n) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569));
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(l10n.expenseCategory, style: style)),
          Expanded(flex: 2, child: Text(l10n.expensePaymentType, style: style)),
          Expanded(flex: 2, child: Text(l10n.expenseAmount, style: style)),
          Expanded(flex: 2, child: Text(l10n.expenseDate, style: style)),
          Expanded(flex: 2, child: Text(l10n.expenseDocument, style: style)),
          Expanded(flex: 3, child: Text(l10n.expenseNote, style: style)),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(Fee e, AppLocalizations l10n, NumberFormat fmt) {
    final payLabel = _paymentLabel(e.paymentType, l10n);
    final payColor = _paymentColor(e.paymentType);
    final dateStr = DateFormat('dd.MM.yyyy').format(e.paymentDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.category_outlined, size: 16, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    e.feeCategoryDetails.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: payColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  payLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: payColor),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(e.paymentAmount)} ₼',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 2,
            child: e.fileUrl != null
                ? Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Document',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
          ),
          Expanded(
            flex: 3,
            child: Text(
              e.note.isEmpty ? '—' : e.note,
              style: TextStyle(fontSize: 13, color: e.note.isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRow(Fee e, AppLocalizations l10n, NumberFormat fmt) {
    final payLabel = _paymentLabel(e.paymentType, l10n);
    final payColor = _paymentColor(e.paymentType);
    final dateStr = DateFormat('dd.MM.yyyy').format(e.paymentDate);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_outlined, size: 20, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.feeCategoryDetails.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: payColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        payLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: payColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    if (e.fileUrl != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF6366F1)),
                      const SizedBox(width: 2),
                      const Text('Doc', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
                    ],
                  ],
                ),
                if (e.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.note,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${fmt.format(e.paymentAmount)} ₼',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit dialog result ────────────────────────────────────────────────────────

class _EditDialogResult {
  final bool deleted;
  const _EditDialogResult({this.deleted = false});
}

// ── Expense Form Dialog (Add + Edit) ─────────────────────────────────────────

class _ExpenseFormDialog extends StatefulWidget {
  final Fee? existing;
  const _ExpenseFormDialog({this.existing});

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _feeRepo = FeeRepository.instance;
  final _catRepo = FeeCategoryRepository.instance;

  // Categories
  List<FeeCategory> _categories = [];
  bool _loadingCategories = true;
  String? _categoryError;

  // Form fields
  FeeCategory? _selectedCategory;
  ExpensePaymentType? _paymentType;
  late final TextEditingController _amountCtrl;
  late DateTime _date;
  String? _documentName;
  Uint8List? _documentBytes;
  late final TextEditingController _noteCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _paymentType = e != null ? ExpensePaymentTypeX.fromApi(e.paymentType) : null;
    _amountCtrl = TextEditingController(text: e != null ? e.paymentAmount.toStringAsFixed(2) : '');
    _date = e?.paymentDate ?? DateTime.now();
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    final result = await _catRepo.fetchCategories(pageSize: 200);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _categories = data.results;
          _loadingCategories = false;
          if (widget.existing != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.id == widget.existing!.feeCategoryId);
            } catch (_) {
              _selectedCategory = null;
            }
          }
        });
      case Failure(:final message):
        setState(() {
          _categoryError = message;
          _loadingCategories = false;
        });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _documentName = file.name;
      _documentBytes = file.bytes;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _paymentType == null) return;

    setState(() => _submitting = true);
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final l10n = AppLocalizations.of(context)!;

    if (_isEdit) {
      final result = await _feeRepo.updateFee(
        id: widget.existing!.id,
        feeCategoryId: _selectedCategory!.id,
        paymentType: _paymentType!.apiValue,
        paymentAmount: amount,
        paymentDate: _date,
        note: _noteCtrl.text.trim(),
        fileBytes: _documentBytes,
        fileName: _documentName,
      );
      if (!mounted) return;
      switch (result) {
        case Success():
          Navigator.of(context).pop(const _EditDialogResult());
        case Failure(:final message):
          setState(() => _submitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.expenseUpdateFailed(message)), backgroundColor: const Color(0xFFEF4444)));
      }
    } else {
      final result = await _feeRepo.createFee(
        feeCategoryId: _selectedCategory!.id,
        paymentType: _paymentType!.apiValue,
        paymentAmount: amount,
        paymentDate: _date,
        note: _noteCtrl.text.trim(),
        fileBytes: _documentBytes,
        fileName: _documentName,
      );
      if (!mounted) return;
      switch (result) {
        case Success(:final data):
          Navigator.of(context).pop(data);
        case Failure(:final message):
          setState(() => _submitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.expenseAddFailed(message)), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.expenseDeleteTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(l10n.expenseDeleteConfirm, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF475569))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);

    final result = await _feeRepo.deleteFee(widget.existing!.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(const _EditDialogResult(deleted: true));
      case Failure(:final message):
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.expenseDeleteFailed(message)), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('dd.MM.yyyy').format(_date);

    final paymentTypes = [
      (ExpensePaymentType.cash, l10n.expensePaymentCash),
      (ExpensePaymentType.card, l10n.expensePaymentCard),
      (ExpensePaymentType.transfer, l10n.expensePaymentTransfer),
    ];

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isEdit ? const Color(0xFFFFF7ED) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEdit ? Icons.edit_rounded : Icons.add_rounded,
                          color: _isEdit ? const Color(0xFFF97316) : const Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEdit ? l10n.expenseEditTitle : l10n.addExpense,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      if (_isEdit)
                        IconButton(
                          onPressed: _submitting ? null : _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                          tooltip: l10n.delete,
                          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      IconButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Category ──────────────────────────────────────────
                  _FieldLabel(l10n.expenseCategory),
                  const SizedBox(height: 6),
                  if (_loadingCategories)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
                      ),
                    )
                  else if (_categoryError != null)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEF4444)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _loadCategories,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(l10n.retry),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<FeeCategory>(
                      initialValue: _selectedCategory,
                      decoration: inputDecoration.copyWith(hintText: l10n.expenseSelectCategory),
                      borderRadius: BorderRadius.circular(10),
                      items: _categories.map((c) => DropdownMenuItem<FeeCategory>(value: c, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? l10n.required : null,
                    ),
                  const SizedBox(height: 16),

                  // 2. Payment type ──────────────────────────────────────
                  _FieldLabel(l10n.expensePaymentType),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ExpensePaymentType>(
                    initialValue: _paymentType,
                    decoration: inputDecoration.copyWith(hintText: l10n.expenseSelectPaymentType),
                    borderRadius: BorderRadius.circular(10),
                    items: paymentTypes.map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2))).toList(),
                    onChanged: (v) => setState(() => _paymentType = v),
                    validator: (v) => v == null ? l10n.required : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Amount ────────────────────────────────────────────
                  _FieldLabel(l10n.expenseAmount),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: inputDecoration.copyWith(hintText: l10n.expenseAmountHint, suffixText: '₼'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return l10n.required;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Date ──────────────────────────────────────────────
                  _FieldLabel(l10n.expenseDate),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6366F1)),
                          const SizedBox(width: 10),
                          Text(dateStr, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Document ──────────────────────────────────────────
                  _FieldLabel(l10n.expenseDocument),
                  const SizedBox(height: 6),
                  _buildDocumentPicker(l10n),
                  const SizedBox(height: 16),

                  // 6. Note ──────────────────────────────────────────────
                  _FieldLabel(l10n.expenseNote),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: inputDecoration.copyWith(hintText: l10n.expenseNoteHint),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Actions ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _submitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPicker(AppLocalizations l10n) {
    final hasExistingFile = widget.existing?.fileUrl != null;
    final hasNewFile = _documentName != null;
    final hasFile = hasNewFile || hasExistingFile;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasFile ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.attach_file_rounded : Icons.upload_file_outlined,
              size: 18,
              color: hasFile ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasNewFile
                    ? l10n.expenseDocumentSelected(_documentName!)
                    : hasExistingFile
                    ? l10n.expenseDocumentSelected('document')
                    : l10n.expenseDocumentHint,
                style: TextStyle(fontSize: 14, color: hasFile ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.expenseDocumentChoose, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact date range picker dialog ─────────────────────────────────────────

class _DateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DateRangePickerDialog({this.initialDateRange, required this.firstDate, required this.lastDate});

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _start;
  DateTime? _end;
  int _step = 0;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange?.start;
    _end = widget.initialDateRange?.end;
    _focusedMonth = _start ?? DateTime.now();
    _step = _start == null ? 0 : 1;
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_step == 0) {
        _start = day;
        _end = null;
        _step = 1;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
        _step = 0;
      }
    });
  }

  void _prevMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final monthFmt = DateFormat('MMMM yyyy');
    final canConfirm = _start != null && _end != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          color: const Color(0xFF6366F1),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.expenseFilterByDate,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _HeaderDateChip(
                    label: _start != null ? dateFmt.format(_start!) : '—',
                    isActive: _step == 0,
                    onTap: () => setState(() {
                      _step = 0;
                      _end = null;
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                  ),
                  _HeaderDateChip(
                    label: _end != null ? dateFmt.format(_end!) : '—',
                    isActive: _step == 1,
                    onTap: _start != null ? () => setState(() => _step = 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left_rounded), iconSize: 20, color: const Color(0xFF475569)),
              Expanded(
                child: Text(
                  monthFmt.format(_focusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right_rounded), iconSize: 20, color: const Color(0xFF475569)),
            ],
          ),
        ),

        // Day-of-week headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['B', 'T', 'Ç', 'T', 'C', 'Ş', 'B']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildGrid()),
        const SizedBox(height: 8),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canConfirm ? () => Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!)) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.expenseFilterApply, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 36));
            }
            final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final isStart = _start != null && _isSameDay(day, _start!);
            final isEnd = _end != null && _isSameDay(day, _end!);
            final inRange = _start != null && _end != null && day.isAfter(_start!) && day.isBefore(_end!);
            final isSelected = isStart || isEnd;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onDayTap(day),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : inRange
                        ? const Color(0xFFEEF2FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : inRange
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _HeaderDateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _HeaderDateChip({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? Colors.white : Colors.white38),
        ),
        child: Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400),
        ),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
    );
  }
}
