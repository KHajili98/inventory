import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Model ────────────────────────────────────────────────────────────────────

enum ExpenseCategory { rent, communal, salary, transport, customs, other }

enum ExpensePaymentType { cash, card, transfer }

class ExpenseEntry {
  final String id;
  final ExpenseCategory category;
  final ExpensePaymentType paymentType;
  final double amount;
  final DateTime date;
  final String? documentName;
  final Uint8List? documentBytes;
  final String note;

  ExpenseEntry({
    required this.id,
    required this.category,
    required this.paymentType,
    required this.amount,
    required this.date,
    this.documentName,
    this.documentBytes,
    required this.note,
  });
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ExpenseTrackingPage extends StatefulWidget {
  const ExpenseTrackingPage({super.key});

  @override
  State<ExpenseTrackingPage> createState() => _ExpenseTrackingPageState();
}

class _ExpenseTrackingPageState extends State<ExpenseTrackingPage> {
  final List<ExpenseEntry> _expenses = [];

  void _openAddDialog() async {
    final entry = await showDialog<ExpenseEntry>(context: context, barrierDismissible: false, builder: (ctx) => const _AddExpenseDialog());
    if (entry != null) {
      setState(() => _expenses.insert(0, entry));
    }
  }

  String _categoryLabel(ExpenseCategory cat, AppLocalizations l10n) {
    return switch (cat) {
      ExpenseCategory.rent => l10n.expenseCategoryRent,
      ExpenseCategory.communal => l10n.expenseCategoryCommunal,
      ExpenseCategory.salary => l10n.expenseCategorySalary,
      ExpenseCategory.transport => l10n.expenseCategoryTransport,
      ExpenseCategory.customs => l10n.expenseCategoryCustoms,
      ExpenseCategory.other => l10n.expenseCategoryOther,
    };
  }

  String _paymentLabel(ExpensePaymentType pt, AppLocalizations l10n) {
    return switch (pt) {
      ExpensePaymentType.cash => l10n.expensePaymentCash,
      ExpensePaymentType.card => l10n.expensePaymentCard,
      ExpensePaymentType.transfer => l10n.expensePaymentTransfer,
    };
  }

  Color _categoryColor(ExpenseCategory cat) {
    return switch (cat) {
      ExpenseCategory.rent => const Color(0xFF6366F1),
      ExpenseCategory.communal => const Color(0xFF0EA5E9),
      ExpenseCategory.salary => const Color(0xFF22C55E),
      ExpenseCategory.transport => const Color(0xFFF59E0B),
      ExpenseCategory.customs => const Color(0xFFEF4444),
      ExpenseCategory.other => const Color(0xFF94A3B8),
    };
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    return switch (cat) {
      ExpenseCategory.rent => Icons.home_work_outlined,
      ExpenseCategory.communal => Icons.bolt_outlined,
      ExpenseCategory.salary => Icons.people_outline_rounded,
      ExpenseCategory.transport => Icons.local_shipping_outlined,
      ExpenseCategory.customs => Icons.gavel_rounded,
      ExpenseCategory.other => Icons.category_outlined,
    };
  }

  Color _paymentColor(ExpensePaymentType pt) {
    return switch (pt) {
      ExpensePaymentType.cash => const Color(0xFF22C55E),
      ExpensePaymentType.card => const Color(0xFF6366F1),
      ExpensePaymentType.transfer => const Color(0xFF0EA5E9),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final totalAmount = _expenses.fold(0.0, (s, e) => s + e.amount);
    final fmt = NumberFormat('#,##0.00');

    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(l10n, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          _buildStats(l10n, isMobile, totalAmount, fmt),
          SizedBox(height: isMobile ? 16 : 24),
          Expanded(child: _buildTable(l10n, isMobile, fmt)),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(AppLocalizations l10n, bool isMobile) {
    final button = FilledButton.icon(
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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.expenseTracking,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: button),
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
        button,
      ],
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  Widget _buildStats(AppLocalizations l10n, bool isMobile, double totalAmount, NumberFormat fmt) {
    final stats = [
      _StatCard(
        label: l10n.totalExpenses,
        value: '${fmt.format(totalAmount)} ₼',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF6366F1),
      ),
      _StatCard(label: l10n.expenseCount, value: '${_expenses.length}', icon: Icons.receipt_long_rounded, color: const Color(0xFF0EA5E9)),
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

  // ── Table ─────────────────────────────────────────────────────────────────────

  Widget _buildTable(AppLocalizations l10n, bool isMobile, NumberFormat fmt) {
    if (_expenses.isEmpty) {
      return _buildEmptyState(l10n);
    }

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
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final e = _expenses[i];
                if (isMobile) return _buildMobileRow(e, l10n, fmt);
                return _buildDesktopRow(e, l10n, fmt);
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

  Widget _buildDesktopRow(ExpenseEntry e, AppLocalizations l10n, NumberFormat fmt) {
    final catColor = _categoryColor(e.category);
    final catLabel = _categoryLabel(e.category, l10n);
    final payLabel = _paymentLabel(e.paymentType, l10n);
    final payColor = _paymentColor(e.paymentType);
    final dateStr = DateFormat('dd.MM.yyyy').format(e.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_categoryIcon(e.category), size: 16, color: catColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    catLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
          // Payment type
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: payColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
              child: Text(
                payLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: payColor),
                textAlign: TextAlign.center,
              ),
            ).andConstrainWidth(120),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(e.amount)} ₼',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
          // Document
          Expanded(
            flex: 2,
            child: e.documentName != null
                ? Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          e.documentName!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text('—', style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
          ),
          // Note
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

  Widget _buildMobileRow(ExpenseEntry e, AppLocalizations l10n, NumberFormat fmt) {
    final catColor = _categoryColor(e.category);
    final catLabel = _categoryLabel(e.category, l10n);
    final payLabel = _paymentLabel(e.paymentType, l10n);
    final payColor = _paymentColor(e.paymentType);
    final dateStr = DateFormat('dd.MM.yyyy').format(e.date);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(_categoryIcon(e.category), size: 20, color: catColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      catLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
                    if (e.documentName != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF6366F1)),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          e.documentName!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
            '${fmt.format(e.amount)} ₼',
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

// ── Helper extension ──────────────────────────────────────────────────────────

extension _WidgetConstraint on Widget {
  Widget andConstrainWidth(double max) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: max),
    child: this,
  );
}

// ── Add Expense Dialog ────────────────────────────────────────────────────────

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  ExpenseCategory? _category;
  ExpensePaymentType? _paymentType;
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _documentName;
  Uint8List? _documentBytes;
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _paymentType == null) return;

    final entry = ExpenseEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _category!,
      paymentType: _paymentType!,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
      date: _date,
      documentName: _documentName,
      documentBytes: _documentBytes,
      note: _noteCtrl.text.trim(),
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('dd.MM.yyyy').format(_date);

    final categories = [
      (ExpenseCategory.rent, l10n.expenseCategoryRent),
      (ExpenseCategory.communal, l10n.expenseCategoryCommunal),
      (ExpenseCategory.salary, l10n.expenseCategorySalary),
      (ExpenseCategory.transport, l10n.expenseCategoryTransport),
      (ExpenseCategory.customs, l10n.expenseCategoryCustoms),
      (ExpenseCategory.other, l10n.expenseCategoryOther),
    ];

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
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.addExpense,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Category
                  _FieldLabel(l10n.expenseCategory),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: _category,
                    decoration: inputDecoration.copyWith(hintText: l10n.expenseSelectCategory),
                    borderRadius: BorderRadius.circular(10),
                    items: categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) => v == null ? l10n.required : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Payment type
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

                  // 3. Amount
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

                  // 4. Date
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

                  // 5. Document
                  _FieldLabel(l10n.expenseDocument),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _documentName != null ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _documentName != null ? Icons.attach_file_rounded : Icons.upload_file_outlined,
                            size: 18,
                            color: _documentName != null ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _documentName != null ? l10n.expenseDocumentSelected(_documentName!) : l10n.expenseDocumentHint,
                              style: TextStyle(fontSize: 14, color: _documentName != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
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
                  ),
                  const SizedBox(height: 16),

                  // 6. Note
                  _FieldLabel(l10n.expenseNote),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: inputDecoration.copyWith(hintText: l10n.expenseNoteHint),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w600)),
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
