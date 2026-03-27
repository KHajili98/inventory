import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/features/invoice_detail/cubit/invoice_detail_cubit.dart';
import 'package:inventory/features/invoice_detail/cubit/invoice_detail_state.dart';
import 'package:inventory/features/invoice_detail/data/models/invoice_detail_model.dart';
import 'package:inventory/l10n/app_localizations.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Read-only invoice detail page — fetches full invoice by UUID from the API.
class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => InvoiceDetailCubit()..fetchDetail(invoiceId), child: const _InvoiceDetailView());
  }
}

// ── Read-only detail view ──────────────────────────────────────────────────────

class _InvoiceDetailView extends StatelessWidget {
  const _InvoiceDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<InvoiceDetailCubit, InvoiceDetailState>(
        builder: (context, state) {
          return switch (state) {
            InvoiceDetailInitial() || InvoiceDetailLoading() => _buildLoading(),
            InvoiceDetailLoaded(:final invoice) => _InvoiceDetailContent(invoice: invoice),
            InvoiceDetailError(:final message) => _buildError(context, message),
          };
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 32),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final cubit = context.read<InvoiceDetailCubit>();
              final state = cubit.state;
              if (state is InvoiceDetailError) {
                // Re-trigger fetch — the cubit holds no id, so pop instead
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Go Back'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
}

// ── Detail content ─────────────────────────────────────────────────────────────

class _InvoiceDetailContent extends StatelessWidget {
  final InvoiceDetailModel invoice;
  const _InvoiceDetailContent({required this.invoice});

  static const double _colIdx = 44;
  static const double _colProduct = 200;
  static const double _colModel = 100;
  static const double _colSize = 70;
  static const double _colColor = 70;
  static const double _colColorCode = 80;
  static const double _colQty = 80;
  static const double _colUnit = 96;
  static const double _colTotal = 110;
  static const double _colPcsCarton = 82;
  static const double _colCarton = 80;
  static const double _colGross = 86;
  static const double _colTotalWt = 96;

  int get _grandQty => invoice.items.fold(0, (s, r) => s + (r.quantity ?? 0));
  double get _grandTotal => invoice.items.fold(0.0, (s, r) => s + (r.totalPrice ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        _buildInfoCards(context),
        _buildTableLabel(),
        Expanded(child: _buildTable(context)),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.invoiceDetail(invoice.invoiceNumber ?? invoice.id.substring(0, 8)),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    if (invoice.contractNumber != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          invoice.contractNumber!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${invoice.supplierName ?? '–'}  ·  ${invoice.invoiceDate ?? '–'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (invoice.invoiceImageUrl != null)
            OutlinedButton.icon(
              onPressed: () => html.window.open(invoice.invoiceImageUrl!, '_blank'),
              icon: const Icon(Icons.image_search_rounded, size: 16),
              label: const Text('View Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9),
                side: const BorderSide(color: Color(0xFF0EA5E9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          _InfoCard(icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1), label: l10n.totalItems, value: '$_grandQty ${l10n.pcs}'),
          _InfoCard(
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF22C55E),
            label: l10n.totalAmount,
            value: '${invoice.currency ?? 'USD'} ${_grandTotal.toStringAsFixed(2)}',
          ),
          _InfoCard(icon: Icons.list_alt_rounded, color: const Color(0xFFF59E0B), label: l10n.total, value: '${invoice.items.length} ${l10n.rows}'),
          if (invoice.supplierAddress != null)
            _InfoCard(
              icon: Icons.location_on_outlined,
              color: const Color(0xFF64748B),
              label: 'Address',
              value: invoice.supplierAddress!,
              maxWidth: 340,
            ),
          if (invoice.contactNumber != null)
            _InfoCard(icon: Icons.phone_outlined, color: const Color(0xFF64748B), label: 'Contact', value: invoice.contactNumber!),
        ],
      ),
    );
  }

  Widget _buildTableLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Invoice Items',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${invoice.items.length} items',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.3);
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  _headerCell('#', _colIdx, style),
                  _headerCell(l10n.productName, _colProduct, style),
                  _headerCell(l10n.model, _colModel, style),
                  _headerCell(l10n.size, _colSize, style),
                  _headerCell(l10n.color, _colColor, style),
                  _headerCell(l10n.colorCode, _colColorCode, style),
                  _headerCell(l10n.qty, _colQty, style),
                  _headerCell('${l10n.unit} (USD)', _colUnit, style),
                  _headerCell('${l10n.total} (USD)', _colTotal, style),
                  _headerCell(l10n.pcsPerCarton, _colPcsCarton, style),
                  _headerCell(l10n.cartons, _colCarton, style),
                  _headerCell(l10n.grossWeight, _colGross, style),
                  _headerCell(l10n.totalWeightKg, _colTotalWt, style),
                ],
              ),
            ),
            ...invoice.items.asMap().entries.map((e) => _buildRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width, TextStyle style) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Text(text, style: style),
    );
  }

  Widget _buildRow(int index, InvoiceDetailItemModel item) {
    final bg = index.isOdd ? const Color(0xFFFAFAFA) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          _cell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          _cell(item.productName ?? '–', _colProduct, bold: true),
          _cell(item.modelCode ?? '–', _colModel),
          _cell(item.size ?? '–', _colSize),
          _cell(item.color ?? '–', _colColor),
          _cell(item.colorCode ?? '–', _colColorCode),
          _cell(
            '${item.quantity ?? '–'}',
            _colQty,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          _cell('\$${item.unitPriceUsd?.toStringAsFixed(4) ?? '–'}', _colUnit),
          _cell(
            '\$${item.totalPrice?.toStringAsFixed(2) ?? '–'}',
            _colTotal,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
          ),
          _cell('${item.piecesPerCarton ?? '–'}', _colPcsCarton),
          _cell('${item.cartonCount ?? '–'}', _colCarton),
          _cell('${item.grossWeightKg ?? '–'}', _colGross),
          _cell('${item.totalWeightKg ?? '–'}', _colTotalWt),
        ],
      ),
    );
  }

  Widget _cell(String text, double width, {TextStyle? style, bool bold = false}) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Text(
        text,
        style: style ?? TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: const Color(0xFF1E293B)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Text(
            l10n.totals,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.5),
          ),
          const Spacer(),
          _FooterStat(label: l10n.totalQty, value: '$_grandQty ${l10n.pcs}'),
          const SizedBox(width: 32),
          _FooterStat(label: l10n.grandTotal, value: '${invoice.currency ?? 'USD'} ${_grandTotal.toStringAsFixed(2)}', highlight: true),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double? maxWidth;
  const _InfoCard({required this.icon, required this.color, required this.label, required this.value, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _FooterStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: highlight ? const Color(0xFF6366F1) : const Color(0xFF1E293B)),
        ),
      ],
    );
  }
}
