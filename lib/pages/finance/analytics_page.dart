import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:universal_html/html.dart' as html;

// ── Palette ──────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF6366F1);
const _kSecondary = Color(0xFF8B5CF6);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kDanger = Color(0xFFEF4444);

const _kCategoryColors = <Color>[
  Color(0xFF6366F1), // rent
  Color(0xFF10B981), // communal
  Color(0xFFF59E0B), // salary
  Color(0xFF3B82F6), // transport
  Color(0xFFEF4444), // customs
  Color(0xFF8B5CF6), // other
];

// ── Mock data helpers ─────────────────────────────────────────────────────────

class _DailyProfit {
  final DateTime date;
  final double profit;
  const _DailyProfit(this.date, this.profit);
}

class _DailyRow {
  final DateTime date;
  final String store;
  final double sales;
  final double costOfGoods;
  final double expenses;
  final double tax;

  _DailyRow({required this.date, required this.store, required this.sales, required this.costOfGoods, required this.expenses, required this.tax});

  double get margin => sales == 0 ? 0 : ((sales - costOfGoods - expenses - tax) / sales * 100);
  double get netProfit => sales - costOfGoods - expenses - tax;
}

List<_DailyRow> _generateDailyRows(DateTimeRange range) {
  final rng = math.Random(42);
  final days = range.end.difference(range.start).inDays + 1;
  final stores = ['Sədərək', 'Abşeron'];

  final rows = <_DailyRow>[];
  for (var i = 0; i < days; i++) {
    final d = range.start.add(Duration(days: i));
    for (final store in stores) {
      final sales = 450 + rng.nextDouble() * 900; // Split revenue per store
      final cog = sales * (0.35 + rng.nextDouble() * 0.15);
      final exp = 40 + rng.nextDouble() * 100; // Split expenses per store
      final tax = sales * 0.12;
      rows.add(_DailyRow(date: d, store: store, sales: sales, costOfGoods: cog, expenses: exp, tax: tax));
    }
  }
  return rows;
}

List<_DailyProfit> _generateDailyProfits(DateTimeRange range) {
  final rows = _generateDailyRows(range);
  return rows.map((r) => _DailyProfit(r.date, r.netProfit)).toList();
}

double _mockRevenueSederek(DateTimeRange range) {
  final days = range.end.difference(range.start).inDays + 1;
  return 4200.0 * days / 7;
}

double _mockRevenueAbseron(DateTimeRange range) {
  final days = range.end.difference(range.start).inDays + 1;
  return 3100.0 * days / 7;
}

Map<String, double> _mockExpensesByCategory(DateTimeRange range) {
  final days = range.end.difference(range.start).inDays + 1;
  final factor = days / 7.0;
  return {
    'rent': 1200 * factor,
    'communal': 350 * factor,
    'salary': 3800 * factor,
    'transport': 680 * factor,
    'customs': 920 * factor,
    'other': 450 * factor,
  };
}

// ── Page ─────────────────────────────────────────────────────────────────────

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
  }

  // ─── Computed ─────────────────────────────────────────────────────────────

  double get _revenue => _mockRevenueSederek(_range) + _mockRevenueAbseron(_range);
  double get _totalExpenses => _mockExpensesByCategory(_range).values.fold(0, (a, b) => a + b);
  double get _tax => _revenue * 0.12;
  double get _netProfit => _revenue - _totalExpenses - _tax;

  // ─── Date picker ──────────────────────────────────────────────────────────

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
              colorScheme: const ColorScheme.light(primary: _kPrimary),
              datePickerTheme: const DatePickerThemeData(headerBackgroundColor: _kPrimary, headerForegroundColor: Colors.white),
            ),
            child: _AnalyticsDateRangePickerDialog(initialDateRange: _range, firstDate: DateTime(2020), lastDate: DateTime.now()),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final fmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _PageHeader(l10n: l10n, isMobile: isMobile),
          const SizedBox(height: 20),

          // ── Date range picker ────────────────────────────────────────────
          _DateRangeBar(range: _range, fmt: fmt, l10n: l10n, onTap: _pickDateRange, isMobile: isMobile),
          const SizedBox(height: 24),

          // ── Summary cards ────────────────────────────────────────────────
          _SummaryCards(revenue: _revenue, totalExpenses: _totalExpenses, tax: _tax, netProfit: _netProfit, l10n: l10n, isMobile: isMobile),
          const SizedBox(height: 28),

          // ── Charts row (bar + pie) ───────────────────────────────────────
          if (isMobile) ...[
            _BarChartCard(range: _range, l10n: l10n),
            const SizedBox(height: 24),
            _PieChartCard(range: _range, l10n: l10n),
            const SizedBox(height: 24),
            _LineChartCard(range: _range, l10n: l10n),
            const SizedBox(height: 24),
            _DailyBreakdownTableWithExport(range: _range, l10n: l10n),
          ] else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _BarChartCard(range: _range, l10n: l10n),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: _PieChartCard(range: _range, l10n: l10n),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LineChartCard(range: _range, l10n: l10n),
            const SizedBox(height: 24),
            _DailyBreakdownTableWithExport(range: _range, l10n: l10n),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;
  const _PageHeader({required this.l10n, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.analytics,
          style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(l10n.analyticsSubtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }
}

// ── Date range bar ────────────────────────────────────────────────────────────

class _DateRangeBar extends StatelessWidget {
  final DateTimeRange range;
  final DateFormat fmt;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final bool isMobile;

  const _DateRangeBar({required this.range, required this.fmt, required this.l10n, required this.onTap, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today_rounded, size: 18, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          l10n.dateRange,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${fmt.format(range.start)} – ${fmt.format(range.end)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final double revenue;
  final double totalExpenses;
  final double tax;
  final double netProfit;
  final AppLocalizations l10n;
  final bool isMobile;

  const _SummaryCards({
    required this.revenue,
    required this.totalExpenses,
    required this.tax,
    required this.netProfit,
    required this.l10n,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(label: l10n.revenue, value: revenue, icon: Icons.trending_up_rounded, color: _kPrimary, bgColor: const Color(0xFFEEF2FF)),
      _CardData(
        label: l10n.totalExpensesCard,
        value: totalExpenses,
        icon: Icons.receipt_long_rounded,
        color: _kDanger,
        bgColor: const Color(0xFFFFF1F2),
      ),
      _CardData(label: l10n.tax, value: tax, icon: Icons.account_balance_rounded, color: _kWarning, bgColor: const Color(0xFFFFFBEB)),
      _CardData(label: l10n.netProfit, value: netProfit, icon: Icons.savings_rounded, color: _kSuccess, bgColor: const Color(0xFFECFDF5)),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(data: cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(data: cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(data: cards[2])),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(data: cards[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: cards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: c == cards.last ? 0 : 16),
                child: _SummaryCard(data: c),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CardData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _CardData({required this.label, required this.value, required this.icon, required this.color, required this.bgColor});
}

class _SummaryCard extends StatelessWidget {
  final _CardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmtNum = NumberFormat('#,##0.00', 'en_US');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: data.bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '₼ ${fmtNum.format(data.value)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color, letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }
}

// ── Chart card container ──────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  const _ChartCard({required this.title, required this.chart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChartCard extends StatefulWidget {
  final DateTimeRange range;
  final AppLocalizations l10n;
  const _BarChartCard({required this.range, required this.l10n});

  @override
  State<_BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<_BarChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final sederek = _mockRevenueSederek(widget.range);
    final abseron = _mockRevenueAbseron(widget.range);
    final maxY = (math.max(sederek, abseron) * 1.25).ceilToDouble();
    final fmtNum = NumberFormat('#,##0', 'en_US');

    return _ChartCard(
      title: l10n.revenueByStore,
      chart: Column(
        children: [
          // Legend
          Row(
            children: [
              _LegendDot(color: _kPrimary, label: l10n.sedErekStore),
              const SizedBox(width: 20),
              _LegendDot(color: _kSecondary, label: l10n.abseronStore),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final storeName = rodIndex == 0 ? l10n.sedErekStore : l10n.abseronStore;
                      return BarTooltipItem(
                        '$storeName\n₼ ${fmtNum.format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null && event is! FlTapUpEvent) {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedIndex = -1;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [l10n.sedErekStore, l10n.abseronStore];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) =>
                          Text('₼${fmtNum.format(value)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [_makeBarGroup(0, sederek, _kPrimary, _touchedIndex == 0), _makeBarGroup(1, abseron, _kSecondary, _touchedIndex == 1)],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ValueBadge(label: l10n.sedErekStore, value: '₼ ${fmtNum.format(sederek)}', color: _kPrimary),
              _ValueBadge(label: l10n.abseronStore, value: '₼ ${fmtNum.format(abseron)}', color: _kSecondary),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color, bool isTouched) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 52,
          color: isTouched ? color.withValues(alpha: 0.75) : color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: (y * 1.25).ceilToDouble(), color: const Color(0xFFF8FAFC)),
        ),
      ],
    );
  }
}

// ── Pie Chart ─────────────────────────────────────────────────────────────────

class _PieChartCard extends StatefulWidget {
  final DateTimeRange range;
  final AppLocalizations l10n;
  const _PieChartCard({required this.range, required this.l10n});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final expenses = _mockExpensesByCategory(widget.range);
    final total = expenses.values.fold(0.0, (a, b) => a + b);
    final keys = expenses.keys.toList();

    String catLabel(String key) {
      switch (key) {
        case 'rent':
          return l10n.expenseCategoryRent;
        case 'communal':
          return l10n.expenseCategoryCommunal;
        case 'salary':
          return l10n.expenseCategorySalary;
        case 'transport':
          return l10n.expenseCategoryTransport;
        case 'customs':
          return l10n.expenseCategoryCustoms;
        default:
          return l10n.expenseCategoryOther;
      }
    }

    final sections = List.generate(keys.length, (i) {
      final key = keys[i];
      final val = expenses[key]!;
      final pct = val / total * 100;
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: val,
        color: _kCategoryColors[i],
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 72 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
        ),
      );
    });

    final fmtNum = NumberFormat('#,##0.00', 'en_US');

    return _ChartCard(
      title: l10n.expensesByCategory,
      chart: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.touchedSection != null && event is! FlTapUpEvent) {
                        _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                      } else {
                        _touchedIndex = -1;
                      }
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(keys.length, (i) {
              final key = keys[i];
              final val = expenses[key]!;
              final isHighlighted = i == _touchedIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighlighted ? _kCategoryColors[i].withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _kCategoryColors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${catLabel(key)}: ₼${fmtNum.format(val)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isHighlighted ? _kCategoryColors[i] : const Color(0xFF475569),
                        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Line Chart ────────────────────────────────────────────────────────────────

class _LineChartCard extends StatelessWidget {
  final DateTimeRange range;
  final AppLocalizations l10n;
  const _LineChartCard({required this.range, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final dailyProfits = _generateDailyProfits(range);
    final spots = dailyProfits.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.profit)).toList();

    final maxY = spots.map((s) => s.y).reduce(math.max) * 1.2;
    final minY = spots.map((s) => s.y).reduce(math.min);
    final adjustedMin = (minY < 0 ? minY * 1.2 : minY * 0.8).floorToDouble();

    final fmtNum = NumberFormat('#,##0', 'en_US');
    final dateFmt = dailyProfits.length <= 14 ? DateFormat('dd MMM') : DateFormat('dd/MM');

    return _ChartCard(
      title: l10n.netProfitOverTime,
      chart: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            minY: adjustedMin,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1E293B),
                tooltipRoundedRadius: 8,
                getTooltipItems: (spots) => spots.map((spot) {
                  final day = dailyProfits[spot.spotIndex];
                  return LineTooltipItem(
                    '${DateFormat('dd MMM').format(day.date)}\n₼ ${fmtNum.format(spot.y)}',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (v, meta) => Text('₼${fmtNum.format(v)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: dailyProfits.length <= 7 ? 1 : (dailyProfits.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= dailyProfits.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(dateFmt.format(dailyProfits[idx].date), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: _kSuccess,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: dailyProfits.length <= 14,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: _kSuccess),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [_kSuccess.withValues(alpha: 0.25), _kSuccess.withValues(alpha: 0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

// ── Helper widgets ────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
      ],
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ValueBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── Daily Breakdown Table With Export ─────────────────────────────────────────

class _DailyBreakdownTableWithExport extends StatelessWidget {
  final DateTimeRange range;
  final AppLocalizations l10n;
  const _DailyBreakdownTableWithExport({required this.range, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Export button header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showExportMenu(context),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(l10n.exportData),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // Table
        _DailyBreakdownTable(range: range, l10n: l10n),
      ],
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.exportData,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: _kDanger,
              bgColor: const Color(0xFFFEF2F2),
              title: l10n.exportToPdf,
              onTap: () {
                Navigator.pop(context);
                _exportToPdf(context);
              },
            ),
            const SizedBox(height: 8),
            _ExportOption(
              icon: Icons.table_chart_rounded,
              iconColor: _kSuccess,
              bgColor: const Color(0xFFECFDF5),
              title: l10n.exportToExcel,
              onTap: () {
                Navigator.pop(context);
                _exportToExcel(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context) async {
    try {
      final rows = _generateDailyRows(range);
      final pdf = pw.Document();
      final fmt = NumberFormat('#,##0.00', 'en_US');
      final dateFmt = DateFormat('dd.MM.yyyy');

      final totalSales = rows.fold(0.0, (s, r) => s + r.sales);
      final totalCog = rows.fold(0.0, (s, r) => s + r.costOfGoods);
      final totalExp = rows.fold(0.0, (s, r) => s + r.expenses);
      final totalTax = rows.fold(0.0, (s, r) => s + r.tax);
      final totalNet = rows.fold(0.0, (s, r) => s + r.netProfit);
      final avgMargin = totalSales == 0 ? 0.0 : (totalNet / totalSales * 100);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(l10n.dailyBreakdown, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('${dateFmt.format(range.start)} - ${dateFmt.format(range.end)}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerRight,
                data: [
                  [
                    l10n.colDate,
                    l10n.storeLabel,
                    l10n.colTotalSales,
                    l10n.colCostOfGoods,
                    l10n.colTotalExpenses,
                    l10n.colTax,
                    l10n.colMargin,
                    l10n.colNetProfit,
                  ],
                  ...rows.map(
                    (r) => [
                      dateFmt.format(r.date),
                      r.store,
                      '₼ ${fmt.format(r.sales)}',
                      '₼ ${fmt.format(r.costOfGoods)}',
                      '₼ ${fmt.format(r.expenses)}',
                      '₼ ${fmt.format(r.tax)}',
                      '${r.margin.toStringAsFixed(1)}%',
                      '₼ ${fmt.format(r.netProfit)}',
                    ],
                  ),
                  [
                    l10n.grandTotalRow,
                    '',
                    '₼ ${fmt.format(totalSales)}',
                    '₼ ${fmt.format(totalCog)}',
                    '₼ ${fmt.format(totalExp)}',
                    '₼ ${fmt.format(totalTax)}',
                    '${avgMargin.toStringAsFixed(1)}%',
                    '₼ ${fmt.format(totalNet)}',
                  ],
                ],
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'analytics_${dateFmt.format(DateTime.now())}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportSuccess), backgroundColor: _kSuccess));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: _kDanger));
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final rows = _generateDailyRows(range);
      final excel = Excel.createExcel();
      final sheet = excel['Analytics'];
      final fmt = NumberFormat('#,##0.00', 'en_US');
      final dateFmt = DateFormat('dd.MM.yyyy');

      final totalSales = rows.fold(0.0, (s, r) => s + r.sales);
      final totalCog = rows.fold(0.0, (s, r) => s + r.costOfGoods);
      final totalExp = rows.fold(0.0, (s, r) => s + r.expenses);
      final totalTax = rows.fold(0.0, (s, r) => s + r.tax);
      final totalNet = rows.fold(0.0, (s, r) => s + r.netProfit);
      final avgMargin = totalSales == 0 ? 0.0 : (totalNet / totalSales * 100);

      sheet.appendRow([TextCellValue(l10n.dailyBreakdown)]);
      sheet.appendRow([TextCellValue('${dateFmt.format(range.start)} - ${dateFmt.format(range.end)}')]);
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue(l10n.colDate),
        TextCellValue(l10n.storeLabel),
        TextCellValue(l10n.colTotalSales),
        TextCellValue(l10n.colCostOfGoods),
        TextCellValue(l10n.colTotalExpenses),
        TextCellValue(l10n.colTax),
        TextCellValue(l10n.colMargin),
        TextCellValue(l10n.colNetProfit),
      ]);

      for (final r in rows) {
        sheet.appendRow([
          TextCellValue(dateFmt.format(r.date)),
          TextCellValue(r.store),
          TextCellValue('₼ ${fmt.format(r.sales)}'),
          TextCellValue('₼ ${fmt.format(r.costOfGoods)}'),
          TextCellValue('₼ ${fmt.format(r.expenses)}'),
          TextCellValue('₼ ${fmt.format(r.tax)}'),
          TextCellValue('${r.margin.toStringAsFixed(1)}%'),
          TextCellValue('₼ ${fmt.format(r.netProfit)}'),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue(l10n.grandTotalRow),
        TextCellValue(''),
        TextCellValue('₼ ${fmt.format(totalSales)}'),
        TextCellValue('₼ ${fmt.format(totalCog)}'),
        TextCellValue('₼ ${fmt.format(totalExp)}'),
        TextCellValue('₼ ${fmt.format(totalTax)}'),
        TextCellValue('${avgMargin.toStringAsFixed(1)}%'),
        TextCellValue('₼ ${fmt.format(totalNet)}'),
      ]);

      final bytes = excel.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'analytics_${dateFmt.format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportSuccess), backgroundColor: _kSuccess));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: _kDanger));
      }
    }
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final VoidCallback onTap;

  const _ExportOption({required this.icon, required this.iconColor, required this.bgColor, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

// ── Daily Breakdown Table ─────────────────────────────────────────────────────

class _DailyBreakdownTable extends StatelessWidget {
  final DateTimeRange range;
  final AppLocalizations l10n;
  const _DailyBreakdownTable({required this.range, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rows = _generateDailyRows(range);
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd.MM.yyyy');

    // Grand totals
    final totalSales = rows.fold(0.0, (s, r) => s + r.sales);
    final totalCog = rows.fold(0.0, (s, r) => s + r.costOfGoods);
    final totalExp = rows.fold(0.0, (s, r) => s + r.expenses);
    final totalTax = rows.fold(0.0, (s, r) => s + r.tax);
    final totalNet = rows.fold(0.0, (s, r) => s + r.netProfit);
    final avgMargin = totalSales == 0 ? 0.0 : (totalNet / totalSales * 100);

    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.3);
    const cellStyle = TextStyle(fontSize: 12, color: Color(0xFF1E293B));
    const totalStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A));

    // Build a cell with flexible width
    Widget buildCell({
      required String text,
      required TextStyle style,
      TextAlign align = TextAlign.left,
      Color? textColor,
      double flex = 1.0,
      bool isLast = false,
    }) {
      return Expanded(
        flex: (flex * 10).toInt(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(right: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: Text(
            text,
            style: textColor != null ? style.copyWith(color: textColor) : style,
            textAlign: align,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Build a table row
    Widget buildRow({required List<Widget> cells, required Color bg, bool showDivider = true}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: bg,
            child: Row(children: cells),
          ),
          if (showDivider) const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              l10n.dailyBreakdown,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          // ── Table ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                buildRow(
                  cells: [
                    buildCell(text: l10n.colDate, style: headerStyle, flex: 1.2),
                    buildCell(text: l10n.storeLabel, style: headerStyle, flex: 1.0),
                    buildCell(text: l10n.colTotalSales, style: headerStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: l10n.colCostOfGoods, style: headerStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: l10n.colTotalExpenses, style: headerStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: l10n.colTax, style: headerStyle, align: TextAlign.right, flex: 1.0),
                    buildCell(text: l10n.colMargin, style: headerStyle, align: TextAlign.right, flex: 0.9),
                    buildCell(text: l10n.colNetProfit, style: headerStyle, align: TextAlign.right, flex: 1.2, isLast: true),
                  ],
                  bg: const Color(0xFFF8FAFC),
                ),

                // Data rows
                ...rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  final isEven = i % 2 == 0;
                  final netColor = r.netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                  final marginColor = r.margin >= 15 ? const Color(0xFF10B981) : (r.margin >= 5 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                  return buildRow(
                    cells: [
                      buildCell(text: dateFmt.format(r.date), style: cellStyle, flex: 1.2),
                      buildCell(text: r.store, style: cellStyle, flex: 1.0),
                      buildCell(text: '₼ ${fmt.format(r.sales)}', style: cellStyle, align: TextAlign.right, flex: 1.3),
                      buildCell(text: '₼ ${fmt.format(r.costOfGoods)}', style: cellStyle, align: TextAlign.right, flex: 1.3),
                      buildCell(text: '₼ ${fmt.format(r.expenses)}', style: cellStyle, align: TextAlign.right, flex: 1.3),
                      buildCell(text: '₼ ${fmt.format(r.tax)}', style: cellStyle, align: TextAlign.right, flex: 1.0),
                      buildCell(text: '${r.margin.toStringAsFixed(1)}%', style: cellStyle, textColor: marginColor, align: TextAlign.right, flex: 0.9),
                      buildCell(
                        text: '₼ ${fmt.format(r.netProfit)}',
                        style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                        textColor: netColor,
                        align: TextAlign.right,
                        flex: 1.2,
                        isLast: true,
                      ),
                    ],
                    bg: isEven ? Colors.white : const Color(0xFFFAFAFC),
                  );
                }),

                // Grand total row
                buildRow(
                  cells: [
                    buildCell(text: l10n.grandTotalRow, style: totalStyle, flex: 2.2), // Spans date + store
                    buildCell(text: '₼ ${fmt.format(totalSales)}', style: totalStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: '₼ ${fmt.format(totalCog)}', style: totalStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: '₼ ${fmt.format(totalExp)}', style: totalStyle, align: TextAlign.right, flex: 1.3),
                    buildCell(text: '₼ ${fmt.format(totalTax)}', style: totalStyle, align: TextAlign.right, flex: 1.0),
                    buildCell(text: '${avgMargin.toStringAsFixed(1)}%', style: totalStyle, textColor: _kPrimary, align: TextAlign.right, flex: 0.9),
                    buildCell(
                      text: '₼ ${fmt.format(totalNet)}',
                      style: totalStyle,
                      textColor: totalNet >= 0 ? _kSuccess : _kDanger,
                      align: TextAlign.right,
                      flex: 1.2,
                      isLast: true,
                    ),
                  ],
                  bg: const Color(0xFFEEF2FF),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Range Picker Dialog ──────────────────────────────────────────────────

class _AnalyticsDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AnalyticsDateRangePickerDialog({required this.initialDateRange, required this.firstDate, required this.lastDate});

  @override
  State<_AnalyticsDateRangePickerDialog> createState() => _AnalyticsDateRangePickerDialogState();
}

class _AnalyticsDateRangePickerDialogState extends State<_AnalyticsDateRangePickerDialog> {
  late DateTime? _start;
  late DateTime? _end;
  // 0 = picking start, 1 = picking end
  int _step = 0;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange.start;
    _end = widget.initialDateRange.end;
    _focusedMonth = _start ?? DateTime.now();
    _step = 1;
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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final monthFmt = DateFormat('MMMM yyyy');
    final canConfirm = _start != null && _end != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: _kPrimary,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dateRange,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _DateChip(
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
                  _DateChip(
                    label: _end != null ? dateFmt.format(_end!) : '—',
                    isActive: _step == 1,
                    onTap: _start != null ? () => setState(() => _step = 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Month navigation ──────────────────────────────────────────────
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

        // ── Day-of-week headers ───────────────────────────────────────────
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

        // ── Calendar grid ─────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildGrid()),
        const SizedBox(height: 8),

        // ── Actions ───────────────────────────────────────────────────────
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
                    backgroundColor: _kPrimary,
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
            final index = row * 7 + col;
            final dayNum = index - startOffset + 1;
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
                        ? _kPrimary
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
                            ? _kPrimary
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
}

// ── Date chip (header) ────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _DateChip({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
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
