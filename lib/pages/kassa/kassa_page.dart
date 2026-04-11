import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/kassa/cubit/kassa_cubit.dart';
import 'package:inventory/features/kassa/cubit/kassa_state.dart';
import 'package:inventory/features/kassa/data/models/kassa_models.dart';
import 'package:universal_html/html.dart' as html;

// ── Palette ───────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF6366F1);
const _kSuccess = Color(0xFF10B981);
const _kDanger = Color(0xFFEF4444);
const _kWarning = Color(0xFFF59E0B);
const _kCash = Color(0xFF10B981);
const _kCard = Color(0xFF3B82F6);
const _kTransfer = Color(0xFF8B5CF6);

// ── Page ──────────────────────────────────────────────────────────────────────

class KassaPage extends StatefulWidget {
  const KassaPage({super.key});

  @override
  State<KassaPage> createState() => _KassaPageState();
}

class _KassaPageState extends State<KassaPage> {
  late final KassaCubit _cubit;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = KassaCubit();
    _cubit.loadPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<KassaCubit, KassaState>(
        listener: (context, state) {
          if (state is KassaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: _kDanger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _cubit.refresh,
            color: _kPrimary,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(context, isMobile),
                  const SizedBox(height: 20),

                  if (state is KassaLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(color: _kPrimary),
                      ),
                    )
                  else if (state is KassaLoaded) ...[
                    // ── Active Session Card ──────────────────────────────
                    _ActiveSessionCard(session: state.activeSession, isActionLoading: state.isActionLoading),
                    const SizedBox(height: 24),

                    // ── History Table ────────────────────────────────────
                    _KassaHistorySection(
                      history: state.history,
                      totalCount: state.totalCount,
                      hasMore: state.hasMore,
                      isLoadingMore: state.isLoadingMore,
                      isMobile: isMobile,
                    ),
                  ] else ...[
                    // Fallback empty state
                    _ActiveSessionCard(session: null, isActionLoading: false),
                    const SizedBox(height: 24),
                    _KassaHistorySection(history: const [], totalCount: 0, hasMore: false, isLoadingMore: false, isMobile: isMobile),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(now).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KASSA & SMENA İDARƏTMƏSİ',
                style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text('Kassanı açın, günü izləyin, bağlayın', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
        ),
        if (!isMobile)
          Text(
            dateStr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
      ],
    );
  }
}

// ── Active Session Card ───────────────────────────────────────────────────────

class _ActiveSessionCard extends StatelessWidget {
  final KassaSessionSummary? session;
  final bool isActionLoading;

  const _ActiveSessionCard({required this.session, required this.isActionLoading});

  @override
  Widget build(BuildContext context) {
    final hasSession = session != null;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasSession ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: hasSession ? _kSuccess : _kWarning),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasSession ? 'AKTİV SMENA: CANLI REJİM' : 'SMENA BAĞLIDIR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasSession ? const Color(0xFF166534) : const Color(0xFF92400E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasSession) _CloseKassaButton(isLoading: isActionLoading, session: session!) else _OpenKassaButton(isLoading: isActionLoading),
              ],
            ),
          ),

          // ── Card body ──────────────────────────────────────────────────
          if (hasSession) _ActiveSessionBody(session: session!, isMobile: isMobile) else _NoSessionBody(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _ActiveSessionBody extends StatelessWidget {
  final KassaSessionSummary session;
  final bool isMobile;

  const _ActiveSessionBody({required this.session, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'az');
    final dateFmt = DateFormat('dd.MM.yyyy, HH:mm');
    final openedStr = session.openedDate != null ? dateFmt.format(session.openedDate!.toLocal()) : '—';
    final openedByName = _getOpenedByName(context);
    final openedCash = session.openedCashAmount;
    final openedCard = session.openedCardAmount;

    final salesCash = session.totalSalesCash;
    final salesCard = session.totalSalesCard;
    final salesTransfer = session.totalSalesTransfer;
    final totalSales = session.totalSales;

    final expCash = session.totalExpensesCash;
    final expCard = session.totalExpensesCard;
    final expTransfer = session.totalExpensesTransfer;
    final totalExp = session.totalExpenses;

    // Compute expected cash in register: opening cash + cash sales - cash expenses (min 0)
    final expectedCash = (session.openedCashAmount + salesCash - expCash).clamp(0.0, double.infinity);
    // Compute expected card in register: opening card + card sales - card expenses (min 0)
    final expectedCard = (session.openedCardAmount + salesCard - expCard).clamp(0.0, double.infinity);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        children: [
          if (isMobile)
            Column(
              children: [
                _SessionInfoColumn(openedBy: openedByName, openedAt: openedStr, openedCash: openedCash, openedCard: openedCard, fmt: fmt),
                const SizedBox(height: 16),
                _SalesColumn(cashSales: salesCash, cardSales: salesCard, transferSales: salesTransfer, totalSales: totalSales, fmt: fmt),
                const SizedBox(height: 16),
                _ExpensesColumn(cashExp: expCash, cardExp: expCard, transferExp: expTransfer, totalExp: totalExp, fmt: fmt),
                const SizedBox(height: 16),
                _CashStatusColumn(expectedCash: expectedCash, expectedCard: expectedCard, fmt: fmt),
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SessionInfoColumn(openedBy: openedByName, openedAt: openedStr, openedCash: openedCash, openedCard: openedCard, fmt: fmt),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _SalesColumn(cashSales: salesCash, cardSales: salesCard, transferSales: salesTransfer, totalSales: totalSales, fmt: fmt),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _ExpensesColumn(cashExp: expCash, cardExp: expCard, transferExp: expTransfer, totalExp: totalExp, fmt: fmt),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _CashStatusColumn(expectedCash: expectedCash, expectedCard: expectedCard, fmt: fmt),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getOpenedByName(BuildContext context) {
    // The session summary doesn't return user details directly; show placeholder
    return '—';
  }

  Widget _vDivider() => Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0xFFF1F5F9));
}

class _NoSessionBody extends StatelessWidget {
  final bool isMobile;
  const _NoSessionBody({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.point_of_sale_outlined, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktiv smena yoxdur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text('Kassanı açmaq üçün "Kassanı Aç" düyməsinə basın', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class _SessionInfoColumn extends StatelessWidget {
  final String openedBy;
  final String openedAt;
  final double openedCash;
  final double openedCard;
  final NumberFormat fmt;

  const _SessionInfoColumn({required this.openedBy, required this.openedAt, required this.openedCash, required this.openedCard, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (openedBy != '—') ...[
          Text(
            'Smenanı Açan: $openedBy',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
        ],
        Text(openedAt, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 12),
        _SalesRow(label: 'Açılış Nağd:', value: openedCash, fmt: fmt, color: _kCash, icon: Icons.payments_outlined, fontSize: 15),
        const SizedBox(height: 8),
        _SalesRow(label: 'Açılış Kart:', value: openedCard, fmt: fmt, color: _kCard, icon: Icons.credit_card_outlined, fontSize: 15),
      ],
    );
  }
}

class _SalesColumn extends StatelessWidget {
  final double cashSales;
  final double cardSales;
  final double transferSales;
  final double totalSales;
  final NumberFormat fmt;

  const _SalesColumn({required this.cashSales, required this.cardSales, required this.transferSales, required this.totalSales, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SATIŞLAR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        _SalesRow(label: 'Nağd:', value: cashSales, fmt: fmt, color: _kCash, icon: Icons.payments_outlined),
        const SizedBox(height: 6),
        _SalesRow(label: 'Kart:', value: cardSales, fmt: fmt, color: _kCard, icon: Icons.credit_card_outlined),
        const SizedBox(height: 6),
        _SalesRow(label: 'Köçürmə:', value: transferSales, fmt: fmt, color: _kTransfer, icon: Icons.compare_arrows_rounded),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Toplam Satış:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            Text(
              '${fmt.format(totalSales)} ₼',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SalesRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat fmt;
  final Color color;
  final IconData icon;
  final double fontSize;

  const _SalesRow({required this.label, required this.value, required this.fmt, required this.color, required this.icon, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: fontSize + 1, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: fontSize, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          '${fmt.format(value)} ₼',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _ExpensesColumn extends StatelessWidget {
  final double cashExp;
  final double cardExp;
  final double transferExp;
  final double totalExp;
  final NumberFormat fmt;

  const _ExpensesColumn({required this.cashExp, required this.cardExp, required this.transferExp, required this.totalExp, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'XƏRCLƏR (Kassadan çıxan)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        _ExpenseRow(label: 'Nağd:', value: cashExp, fmt: fmt),
        const SizedBox(height: 6),
        _ExpenseRow(label: 'Kart:', value: cardExp, fmt: fmt),
        const SizedBox(height: 6),
        _ExpenseRow(label: 'Köçürmə:', value: transferExp, fmt: fmt),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Toplam Xərc:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            Text(
              '-${fmt.format(totalExp)} ₼',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDanger),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat fmt;

  const _ExpenseRow({required this.label, required this.value, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const Spacer(),
        Text(
          '-${fmt.format(value)} ₼',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kDanger),
        ),
      ],
    );
  }
}

class _CashStatusColumn extends StatelessWidget {
  final double expectedCash;
  final double expectedCard;
  final NumberFormat fmt;

  const _CashStatusColumn({required this.expectedCash, required this.expectedCard, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SİSTEMDƏ OLMALI OLAN',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        _SalesRow(label: 'Nağd:', value: expectedCash, fmt: fmt, color: _kCash, icon: Icons.payments_outlined, fontSize: 15),
        const SizedBox(height: 8),
        _SalesRow(label: 'Kart:', value: expectedCard, fmt: fmt, color: _kCard, icon: Icons.credit_card_outlined, fontSize: 15),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PhysicalCashInput extends StatefulWidget {
  final double expectedCash;
  final NumberFormat fmt;

  const _PhysicalCashInput({required this.expectedCash, required this.fmt});

  @override
  State<_PhysicalCashInput> createState() => _PhysicalCashInputState();
}

class _PhysicalCashInputState extends State<_PhysicalCashInput> {
  final _ctrl = TextEditingController();
  double? _physicalCash;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _diff => (_physicalCash ?? widget.expectedCash) - widget.expectedCash;
  bool get _hasDiff => _physicalCash != null;

  @override
  Widget build(BuildContext context) {
    final fmt = widget.fmt;
    final diffColor = _diff >= 0 ? _kSuccess : _kDanger;
    final diffPrefix = _diff >= 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (v) => setState(() => _physicalCash = double.tryParse(v)),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: fmt.format(widget.expectedCash),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
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
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ),
        if (_hasDiff) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'KƏSİR / ARTIQ:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 8),
              Text(
                '$diffPrefix${fmt.format(_diff)} ₼',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: diffColor),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Open Kassa Button ─────────────────────────────────────────────────────────

class _OpenKassaButton extends StatelessWidget {
  final bool isLoading;
  const _OpenKassaButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => _showOpenDialog(context),
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.lock_open_rounded, size: 18),
      label: const Text('Kassanı Aç', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kSuccess,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  void _showOpenDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(value: context.read<KassaCubit>(), child: const _OpenKassaDialog()),
    );
  }
}

// ── Close Kassa Button ────────────────────────────────────────────────────────

class _CloseKassaButton extends StatelessWidget {
  final bool isLoading;
  final KassaSessionSummary session;
  const _CloseKassaButton({required this.isLoading, required this.session});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => _showCloseDialog(context),
      icon: isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.receipt_long_rounded, size: 18),
      label: const Text('Kassanı Bağla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kSuccess,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  void _showCloseDialog(BuildContext context) {
    final expectedCash = (session.openedCashAmount + session.totalSalesCash - session.totalExpensesCash).clamp(0.0, double.infinity);
    final expectedCard = (session.openedCardAmount + session.totalSalesCard - session.totalExpensesCard).clamp(0.0, double.infinity);
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<KassaCubit>(),
        child: _CloseKassaDialog(expectedCash: expectedCash, expectedCard: expectedCard),
      ),
    );
  }
}

// ── Open Kassa Dialog ─────────────────────────────────────────────────────────

class _OpenKassaDialog extends StatefulWidget {
  const _OpenKassaDialog();

  @override
  State<_OpenKassaDialog> createState() => _OpenKassaDialogState();
}

class _OpenKassaDialogState extends State<_OpenKassaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final cash = double.tryParse(_cashCtrl.text) ?? 0;
    final card = double.tryParse(_cardCtrl.text) ?? 0;

    await context.read<KassaCubit>().openKassa(cashAmount: cash, cardAmount: card, date: DateTime.now());

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_open_rounded, color: _kSuccess, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Kassanı Aç',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), padding: EdgeInsets.zero),
                  ],
                ),
                const SizedBox(height: 20),
                _AmountField(controller: _cashCtrl, label: 'Açılış Nağd Məbləği (₼)', hint: '0.00'),
                const SizedBox(height: 12),
                _AmountField(controller: _cardCtrl, label: 'Açılış Kart Məbləği (₼)', hint: '0.00'),
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: _kDanger, fontSize: 13))],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text('Ləğv et', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kassanı Aç', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Close Kassa Dialog ────────────────────────────────────────────────────────

class _CloseKassaDialog extends StatefulWidget {
  final double expectedCash;
  final double expectedCard;
  const _CloseKassaDialog({required this.expectedCash, required this.expectedCard});

  @override
  State<_CloseKassaDialog> createState() => _CloseKassaDialogState();
}

class _CloseKassaDialogState extends State<_CloseKassaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _closedCashCtrl = TextEditingController();
  final _closedCardCtrl = TextEditingController();
  final _cuttedCashCtrl = TextEditingController(text: '0.00');
  final _cuttedCardCtrl = TextEditingController(text: '0.00');
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  double? _physicalCash;
  double? _physicalCard;

  @override
  void initState() {
    super.initState();
    _closedCashCtrl.addListener(_onCashChanged);
    _closedCardCtrl.addListener(_onCardChanged);
  }

  void _onCashChanged() {
    final val = double.tryParse(_closedCashCtrl.text);
    setState(() {
      _physicalCash = val;
      if (val != null) {
        final cutted = val - widget.expectedCash;
        _cuttedCashCtrl.text = cutted != 0 ? cutted.toStringAsFixed(2) : '0.00';
      }
    });
  }

  void _onCardChanged() {
    final val = double.tryParse(_closedCardCtrl.text);
    setState(() {
      _physicalCard = val;
      if (val != null) {
        final cutted = val - widget.expectedCard;
        _cuttedCardCtrl.text = cutted != 0 ? cutted.toStringAsFixed(2) : '0.00';
      }
    });
  }

  @override
  void dispose() {
    _closedCashCtrl.removeListener(_onCashChanged);
    _closedCardCtrl.removeListener(_onCardChanged);
    _closedCashCtrl.dispose();
    _closedCardCtrl.dispose();
    _cuttedCashCtrl.dispose();
    _cuttedCardCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    await context.read<KassaCubit>().closeKassa(
      closedCashAmount: double.tryParse(_closedCashCtrl.text) ?? 0,
      closedCardAmount: double.tryParse(_closedCardCtrl.text) ?? 0,
      closedDate: DateTime.now(),
      cuttedCashAmount: double.tryParse(_cuttedCashCtrl.text) ?? 0,
      cuttedCardAmount: double.tryParse(_cuttedCardCtrl.text) ?? 0,
      cuttedAmountDescription: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'az');

    final cashDiff = (_physicalCash != null && _physicalCash! - widget.expectedCash != 0) ? _physicalCash! - widget.expectedCash : null;
    final cardDiff = (_physicalCard != null && _physicalCard! - widget.expectedCard != 0) ? _physicalCard! - widget.expectedCard : null;

    final cuttedCash = double.tryParse(_cuttedCashCtrl.text) ?? 0.0;
    final cuttedCard = double.tryParse(_cuttedCardCtrl.text) ?? 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: const Color(0xFFF8FAFC),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog Header ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_long_rounded, color: _kDanger, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Kassanı Bağla / Z-Hesabat',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section: Bağlanış ──────────────────────────────
                      _DialogCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _CardSectionTitle('BAĞLANIŞ MƏBLƏĞLƏRİ'),
                            const SizedBox(height: 12),
                            // Cash row
                            _CloseFieldRow(
                              icon: Icons.payments_outlined,
                              iconColor: _kCash,
                              label: 'Fiziki Nağd',
                              expected: widget.expectedCash,
                              diff: cashDiff,
                              fmt: fmt,
                              child: _BorderlessAmountField(controller: _closedCashCtrl, hint: fmt.format(widget.expectedCash)),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),
                            // Card row
                            _CloseFieldRow(
                              icon: Icons.credit_card_outlined,
                              iconColor: _kCard,
                              label: 'Fiziki Kart',
                              expected: widget.expectedCard,
                              diff: cardDiff,
                              fmt: fmt,
                              child: _BorderlessAmountField(controller: _closedCardCtrl, hint: fmt.format(widget.expectedCard)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Section: Fərq ──────────────────────────────────
                      _DialogCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _CardSectionTitle('FƏRQ'),
                            const SizedBox(height: 12),
                            _CuttedReadOnlyRow(icon: Icons.payments_outlined, iconColor: _kCash, label: 'Fərq (Nağd)', value: cuttedCash, fmt: fmt),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 10),
                            _CuttedReadOnlyRow(
                              icon: Icons.credit_card_outlined,
                              iconColor: _kCard,
                              label: 'Fərq (Kart)',
                              value: cuttedCard,
                              fmt: fmt,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Section: Qeyd ──────────────────────────────────
                      _DialogCard(
                        child: TextFormField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          decoration: const InputDecoration(
                            hintText: 'Qeyd (isteğe bağlı)...',
                            hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: _kDanger, fontSize: 13))],

                      const SizedBox(height: 20),

                      // ── Buttons ────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: const Text(
                                'Ləğv et',
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kDanger,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Kassanı Bağla', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Close dialog helper widgets ───────────────────────────────────────────────

class _DialogCard extends StatelessWidget {
  final Widget child;
  const _DialogCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _CardSectionTitle extends StatelessWidget {
  final String text;
  const _CardSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
    );
  }
}

class _BorderlessAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _BorderlessAmountField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        validator: (v) {
          if (v == null || v.isEmpty) return '';
          if (double.tryParse(v) == null) return '';
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400, fontSize: 14),
          suffixText: '₼',
          suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
      ),
    );
  }
}

class _CloseFieldRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double expected;
  final double? diff;
  final NumberFormat fmt;
  final Widget child;

  const _CloseFieldRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.expected,
    required this.diff,
    required this.fmt,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  Text(
                    'Sistemdə: ${fmt.format(expected)} ₼',
                    style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
        if (diff != null && diff != 0) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: _InlineDiff(diff: diff!, fmt: fmt),
          ),
        ],
      ],
    );
  }
}

class _InlineDiff extends StatelessWidget {
  final double diff;
  final NumberFormat fmt;
  const _InlineDiff({required this.diff, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isPos = diff >= 0;
    final color = isPos ? _kSuccess : _kDanger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPos ? Icons.north_rounded : Icons.south_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '${isPos ? '+' : ''}${fmt.format(diff)} ₼  ${isPos ? 'Artıq' : 'Kəsir'}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CuttedReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;
  final NumberFormat fmt;

  const _CuttedReadOnlyRow({required this.icon, required this.iconColor, required this.label, required this.value, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != 0;
    final isPositive = value > 0;
    final displayColor = hasValue ? (isPositive ? _kSuccess : _kDanger) : const Color(0xFFCBD5E1);
    final sign = isPositive ? '+' : '';

    return Row(
      children: [
        Icon(icon, size: 14, color: hasValue ? displayColor : const Color(0xFFCBD5E1)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ),
        Text(
          hasValue ? '$sign${fmt.format(value)} ₼' : '—',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: displayColor),
        ),
      ],
    );
  }
}

// ── History Section ───────────────────────────────────────────────────────────

class _KassaHistorySection extends StatefulWidget {
  final List<Kassa> history;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isMobile;

  const _KassaHistorySection({
    required this.history,
    required this.totalCount,
    required this.hasMore,
    required this.isLoadingMore,
    required this.isMobile,
  });

  @override
  State<_KassaHistorySection> createState() => _KassaHistorySectionState();
}

class _KassaHistorySectionState extends State<_KassaHistorySection> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Kassa> get _filtered {
    if (_search.isEmpty) return widget.history;
    final q = _search.toLowerCase();
    return widget.history.where((k) {
      final name = k.openedUserDetails?.fullName.toLowerCase() ?? '';
      final closedName = k.closedByUserDetails?.fullName.toLowerCase() ?? '';
      return name.contains(q) || closedName.contains(q) || k.kassaState.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'az');
    final dateFmt = DateFormat('dd.MM.yyyy');
    final filtered = _filtered;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Text(
                  'KASSA TARİXÇƏSİ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Axtar...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
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
                        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),

          // Table
          if (widget.isMobile)
            _MobileHistoryList(history: filtered, fmt: fmt, dateFmt: dateFmt)
          else
            _DesktopHistoryTable(history: filtered, fmt: fmt, dateFmt: dateFmt),

          // Load more / empty
          if (filtered.isEmpty && !widget.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('Heç bir qeyd tapılmadı', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              ),
            ),

          if (widget.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
            ),

          if (widget.hasMore && !widget.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: () => context.read<KassaCubit>().loadMore(),
                  child: const Text(
                    'Daha çox yüklə',
                    style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Desktop History Table ─────────────────────────────────────────────────────

class _DesktopHistoryTable extends StatelessWidget {
  final List<Kassa> history;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _DesktopHistoryTable({required this.history, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: const [
              Expanded(flex: 2, child: _ColHeader('Tarix')),
              Expanded(flex: 2, child: _ColHeader('Smenanı Açan')),
              Expanded(flex: 2, child: _ColHeader('Smenanı Bağlayan')),
              Expanded(flex: 2, child: _ColHeader('Satış (Cəmi)')),
              Expanded(flex: 2, child: _ColHeader('Xərc (Cəmi)')),
              Expanded(flex: 2, child: _ColHeader('Kəsir/Artıq')),
              Expanded(flex: 2, child: _ColHeader('Detallar')),
            ],
          ),
        ),
        ...history.asMap().entries.map((e) => _HistoryTableRow(kassa: e.value, fmt: fmt, dateFmt: dateFmt, isEven: e.key.isEven)),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.3),
    );
  }
}

class _HistoryTableRow extends StatelessWidget {
  final Kassa kassa;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final bool isEven;

  const _HistoryTableRow({required this.kassa, required this.fmt, required this.dateFmt, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final dateStr = kassa.openedDate != null ? dateFmt.format(kassa.openedDate!.toLocal()) : '—';
    final openedBy = kassa.openedUserDetails?.fullName ?? '—';
    final closedBy = kassa.closedByUserDetails?.fullName ?? '—';
    final totalSales = kassa.totalSellingTransactionCashSum + kassa.totalSellingTransactionCardSum + kassa.totalSellingTransactionInvoiceSum;
    final totalFees = kassa.totalFeeTransactionCashSum + kassa.totalFeeTransactionCardSum + kassa.totalFeeTransactionInvoiceSum;

    // Use diffTotal from API
    final diff = kassa.diffTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(openedBy, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 2,
            child: Text(closedBy, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(totalSales)} ₼',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(totalFees)} ₼',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: diff == null
                ? const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))
                : Text(
                    '${diff >= 0 ? '+' : ''}${fmt.format(diff)} ₼',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: diff >= 0 ? _kSuccess : _kDanger),
                  ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showDetailDialog(context, kassa, fmt, dateFmt),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  'Bax/Çap et',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Kassa kassa, NumberFormat fmt, DateFormat dateFmt) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<KassaCubit>(),
        child: _KassaDetailDialog(kassa: kassa, fmt: fmt, dateFmt: dateFmt),
      ),
    );
  }
}

// ── Mobile History List ───────────────────────────────────────────────────────

class _MobileHistoryList extends StatelessWidget {
  final List<Kassa> history;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _MobileHistoryList({required this.history, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: history.map((k) => _MobileHistoryCard(kassa: k, fmt: fmt, dateFmt: dateFmt)).toList(),
    );
  }
}

class _MobileHistoryCard extends StatelessWidget {
  final Kassa kassa;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _MobileHistoryCard({required this.kassa, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final dateStr = kassa.openedDate != null ? dateFmt.format(kassa.openedDate!.toLocal()) : '—';
    final openedBy = kassa.openedUserDetails?.fullName ?? '—';
    final totalSales = kassa.totalSellingTransactionCashSum + kassa.totalSellingTransactionCardSum + kassa.totalSellingTransactionInvoiceSum;
    final totalFees = kassa.totalFeeTransactionCashSum + kassa.totalFeeTransactionCardSum + kassa.totalFeeTransactionInvoiceSum;

    // Use diffTotal from API
    final diff = kassa.diffTotal;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              if (diff != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: diff >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${diff >= 0 ? '+' : ''}${fmt.format(diff)} ₼',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: diff >= 0 ? _kSuccess : _kDanger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Açan: $openedBy', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(label: 'Satış', value: '${fmt.format(totalSales)} ₼', color: _kSuccess),
              const SizedBox(width: 12),
              _MiniStat(label: 'Xərc', value: '${fmt.format(totalFees)} ₼', color: _kDanger),
              const Spacer(),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<KassaCubit>(),
                    child: _KassaDetailDialog(kassa: kassa, fmt: fmt, dateFmt: dateFmt),
                  ),
                ),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                child: const Text(
                  'Detallar',
                  style: TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── Kassa Detail Dialog ───────────────────────────────────────────────────────

class _KassaDetailDialog extends StatelessWidget {
  final Kassa kassa;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _KassaDetailDialog({required this.kassa, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final dateTimeFmt = DateFormat('dd.MM.yyyy, HH:mm');
    final openedStr = kassa.openedDate != null ? dateTimeFmt.format(kassa.openedDate!.toLocal()) : '—';
    final closedStr = kassa.closedDate != null ? dateTimeFmt.format(kassa.closedDate!.toLocal()) : '—';
    final openedBy = kassa.openedUserDetails?.fullName ?? '—';
    final closedBy = kassa.closedByUserDetails?.fullName ?? '—';
    final totalSales = kassa.totalSellingTransactionCashSum + kassa.totalSellingTransactionCardSum + kassa.totalSellingTransactionInvoiceSum;
    final totalFees = kassa.totalFeeTransactionCashSum + kassa.totalFeeTransactionCardSum + kassa.totalFeeTransactionInvoiceSum;

    // Use diffTotal from API
    final diff = kassa.diffTotal;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_rounded, color: _kCard, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kassa Detalları — $openedStr',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), padding: EdgeInsets.zero),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        _StatusBadge(isOpen: kassa.isOpen),
                        const Spacer(),
                        if (diff != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: diff >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kəsir/Artıq: ${diff >= 0 ? '+' : ''}${fmt.format(diff)} ₼',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: diff >= 0 ? _kSuccess : _kDanger),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Who
                    _DetailRow('Smenanı Açan', openedBy),
                    _DetailRow('Smenanı Bağlayan', closedBy),
                    _DetailRow('Açılış Tarixi', openedStr),
                    _DetailRow('Bağlanış Tarixi', closedStr),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Opening amounts
                    _DetailRow('Açılış Nağd', '${fmt.format(kassa.openedCashAmount)} ₼'),
                    _DetailRow('Açılış Kart', '${fmt.format(kassa.openedCardAmount)} ₼'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Sales
                    const _SectionLabel('Satışlar'),
                    const SizedBox(height: 6),
                    _DetailRow('Nağd', '${fmt.format(kassa.totalSellingTransactionCashSum)} ₼', valueColor: _kCash),
                    _DetailRow('Kart', '${fmt.format(kassa.totalSellingTransactionCardSum)} ₼', valueColor: _kCard),
                    _DetailRow('Köçürmə', '${fmt.format(kassa.totalSellingTransactionInvoiceSum)} ₼', valueColor: _kTransfer),
                    _DetailRow('TOPLAM', '${fmt.format(totalSales)} ₼', bold: true),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Fees
                    const _SectionLabel('Xərclər'),
                    const SizedBox(height: 6),
                    _DetailRow('Nağd', '${fmt.format(kassa.totalFeeTransactionCashSum)} ₼', valueColor: _kDanger),
                    _DetailRow('Kart', '${fmt.format(kassa.totalFeeTransactionCardSum)} ₼', valueColor: _kDanger),
                    _DetailRow('Köçürmə', '${fmt.format(kassa.totalFeeTransactionInvoiceSum)} ₼', valueColor: _kDanger),
                    _DetailRow('TOPLAM', '-${fmt.format(totalFees)} ₼', bold: true, valueColor: _kDanger),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Closing
                    if (kassa.closedCashAmount != null) ...[
                      const _SectionLabel('Bağlanış'),
                      const SizedBox(height: 6),
                      _DetailRow('Bağlanış Nağd', '${fmt.format(kassa.closedCashAmount!)} ₼'),
                      _DetailRow('Bağlanış Kart', '${fmt.format(kassa.closedCardAmount ?? 0)} ₼'),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const _SectionLabel('Fərq (Kəsir/Artıq)'),
                      const SizedBox(height: 6),
                      if (kassa.diffCash != null)
                        _DetailRow(
                          'Fərq (Nağd)',
                          '${kassa.diffCash! >= 0 ? '+' : ''}${fmt.format(kassa.diffCash!)} ₼',
                          valueColor: kassa.diffCash! >= 0 ? _kSuccess : _kDanger,
                        ),
                      if (kassa.diffCard != null)
                        _DetailRow(
                          'Fərq (Kart)',
                          '${kassa.diffCard! >= 0 ? '+' : ''}${fmt.format(kassa.diffCard!)} ₼',
                          valueColor: kassa.diffCard! >= 0 ? _kSuccess : _kDanger,
                        ),
                      if (kassa.diffTotal != null)
                        _DetailRow(
                          'Fərq (Toplam)',
                          '${kassa.diffTotal! >= 0 ? '+' : ''}${fmt.format(kassa.diffTotal!)} ₼',
                          bold: true,
                          valueColor: kassa.diffTotal! >= 0 ? _kSuccess : _kDanger,
                        ),
                      if (kassa.cuttedAmountDescription != null && kassa.cuttedAmountDescription!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _DetailRow('Qeyd', kassa.cuttedAmountDescription!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (kassa.kassaState == 'closed') ...[
                    OutlinedButton.icon(
                      onPressed: () => _downloadZReport(context, kassa.id),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Z Hesabatı Yüklə', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: _kPrimary, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadZReport(BuildContext context, String kassaId) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Z Hesabatı yüklənir...'), backgroundColor: _kSuccess, duration: Duration(seconds: 2)));

      // Download PDF through Dio (with auth token from interceptor)
      final result = await context.read<KassaCubit>().downloadZReport(kassaId);

      switch (result) {
        case Success(:final data):
          // Create blob and download
          final blob = html.Blob([data], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'z-hesabat-$kassaId.pdf')
            ..click();

          // Cleanup
          html.Url.revokeObjectUrl(url);
          anchor.remove();

          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Z Hesabatı yükləndi'), backgroundColor: _kSuccess, duration: Duration(seconds: 2)));
          }
        case Failure(:final message):
          throw message;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rapor yüklenirken xəta baş verdi: $e'), backgroundColor: _kDanger));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? _kSuccess : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'AÇIQ' : 'BAĞLI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOpen ? const Color(0xFF166534) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.6),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _AmountField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Zəhmət olmasa məbləği daxil edin';
        if (double.tryParse(v) == null) return 'Düzgün məbləğ daxil edin';
        return null;
      },
      decoration: _inputDecoration(label, hint),
    );
  }
}

InputDecoration _inputDecoration(String label, String hint) => InputDecoration(
  labelText: label,
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
  floatingLabelStyle: const TextStyle(color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w600),
  suffixText: '₼',
  suffixStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
  filled: true,
  fillColor: const Color(0xFFFAFAFC),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kPrimary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kDanger, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kDanger, width: 2),
  ),
);
