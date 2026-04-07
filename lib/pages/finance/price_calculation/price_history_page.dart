import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Price History Page ────────────────────────────────────────────────────────

class PriceHistoryPage extends StatelessWidget {
  final StockProductItemModel item;

  const PriceHistoryPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = item.changeHistory.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.priceHistory, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product info header ─────────────────────────────────────────
          _ProductInfoHeader(item: item, l10n: l10n),

          // ── History list ────────────────────────────────────────────────
          Expanded(
            child: history.isEmpty
                ? _EmptyHistory(l10n: l10n)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HistoryCard(entry: history[index], index: history.length - index, l10n: l10n);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Product Info Header ───────────────────────────────────────────────────────

class _ProductInfoHeader extends StatelessWidget {
  final StockProductItemModel item;
  final AppLocalizations l10n;

  const _ProductInfoHeader({required this.item, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productGeneratedName?.isNotEmpty == true ? item.productGeneratedName! : (item.productName ?? '—'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (item.barcode?.isNotEmpty == true) _InfoChip(label: item.barcode!),
              if (item.modelCode?.isNotEmpty == true) _InfoChip(label: item.modelCode!),
              _InfoChip(label: item.inventoryName),
            ],
          ),
          const SizedBox(height: 10),
          // Current prices row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (item.invoiceUnitPriceAzn != null)
                _PriceChip(label: l10n.invoicePriceAznLabel, value: item.invoiceUnitPriceAzn!, color: const Color(0xFF64748B)),
              if (item.costUnitPrice != null) _PriceChip(label: l10n.costUnitPriceLabel, value: item.costUnitPrice!, color: const Color(0xFF6366F1)),
              if (item.wholeUnitSalesPrice != null)
                _PriceChip(label: l10n.wholeUnitSalesPriceLabel, value: item.wholeUnitSalesPrice!, color: const Color(0xFF0EA5E9)),
              if (item.retailUnitPrice != null)
                _PriceChip(label: l10n.retailUnitPriceLabel, value: item.retailUnitPrice!, color: const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PriceChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
          Text(
            '₼ ${value.toStringAsFixed(3)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final PriceChangeHistoryEntry entry;
  final int index;
  final AppLocalizations l10n;

  const _HistoryCard({required this.entry, required this.index, required this.l10n});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    return DateFormat('dd MMM yyyy, HH:mm').format(local);
  }

  String _fieldLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'cost_unit_price':
        return l10n.costUnitPriceLabel;
      case 'whole_unit_sales_price':
        return l10n.wholeUnitSalesPriceLabel;
      case 'retail_unit_price':
        return l10n.retailUnitPriceLabel;
      default:
        return key;
    }
  }

  Color _fieldColor(String key) {
    switch (key) {
      case 'cost_unit_price':
        return const Color(0xFF6366F1);
      case 'whole_unit_sales_price':
        return const Color(0xFF0EA5E9);
      case 'retail_unit_price':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.priceChange,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(_formatDate(entry.changedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                if (entry.changedByUsername != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF6366F1)),
                        const SizedBox(width: 4),
                        Text(
                          entry.changedByUsername!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Changes ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: entry.changes.entries.map((e) {
                final color = _fieldColor(e.key);
                final label = _fieldLabel(e.key, l10n);
                final detail = e.value;
                final isNew = detail.oldValue == null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Old value
                            Expanded(
                              child: _ValueBox(
                                label: l10n.oldValue,
                                value: detail.oldValue != null ? '₼ ${detail.oldValue!.toStringAsFixed(3)}' : '—',
                                isHighlighted: false,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, size: 16, color: isNew ? const Color(0xFF10B981) : color),
                            ),
                            // New value
                            Expanded(
                              child: _ValueBox(
                                label: l10n.newValue,
                                value: detail.newValue != null ? '₼ ${detail.newValue!.toStringAsFixed(3)}' : '—',
                                isHighlighted: true,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        if (!isNew && detail.oldValue != null && detail.newValue != null) ...[
                          const SizedBox(height: 6),
                          _DeltaRow(oldVal: detail.oldValue!, newVal: detail.newValue!),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color color;

  const _ValueBox({required this.label, required this.value, required this.isHighlighted, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isHighlighted ? color.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: isHighlighted ? color : const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isHighlighted ? color : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final double oldVal;
  final double newVal;

  const _DeltaRow({required this.oldVal, required this.newVal});

  @override
  Widget build(BuildContext context) {
    final delta = newVal - oldVal;
    final pct = oldVal != 0 ? (delta / oldVal * 100) : 0.0;
    final isUp = delta > 0;
    final color = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = isUp ? '+' : '';

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$sign${delta.toStringAsFixed(3)} ($sign${pct.toStringAsFixed(1)}%)',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyHistory({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noHistory, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
