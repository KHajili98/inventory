import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/models/invoice_models.dart';
import 'package:inventory/l10n/app_localizations.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Editable invoice page — used right after OCR upload so the user can
/// review, correct, and confirm the extracted data before saving.
class InvoiceEditPage extends StatefulWidget {
  final InvoiceRecord invoice;
  final VoidCallback? onConfirmed;
  const InvoiceEditPage({super.key, required this.invoice, this.onConfirmed});

  @override
  State<InvoiceEditPage> createState() => _InvoiceEditPageState();
}

class _InvoiceEditPageState extends State<InvoiceEditPage> {
  late List<InvoiceRow> _rows;
  final Set<int> _selectedRows = {};
  bool _isEditing = false;

  static const double _colCheck = 44;
  static const double _colIdx = 44;
  static const double _colProduct = 180;
  static const double _colModel = 100;
  static const double _colSize = 70;
  static const double _colColor = 70;
  static const double _colColorCode = 80;
  static const double _colQty = 64;
  static const double _colUnit = 96;
  static const double _colTotal = 96;
  static const double _colPcsCarton = 82;
  static const double _colCarton = 80;
  static const double _colGross = 86;
  static const double _colTotalWt = 96;

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.invoice.rows);
  }

  double get _grandTotal => _rows.fold(0.0, (s, r) => s + r.total);
  int get _grandQty => _rows.fold(0, (s, r) => s + r.qty);

  void _addRow() {
    setState(() {
      _rows.add(
        InvoiceRow(
          modelCode: '',
          productName: '',
          size: '',
          color: '',
          colorCode: '',
          qty: 0,
          unitPrice: 0,
          totalPrice: 0,
          piecesPerCarton: 0,
          cartonCount: 0,
          grossWeight: 0,
          totalWeightKg: 0,
        ),
      );
    });
  }

  void _deleteSelected() {
    setState(() {
      final indices = _selectedRows.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) _rows.removeAt(i);
      _selectedRows.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(inv),
          _buildSummaryBar(inv),
          _buildToolbar(),
          Expanded(child: _buildTable()),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(InvoiceRecord inv) {
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
                      l10n.invoiceDetail(inv.invoiceNo),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(status: inv.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${inv.supplier}  ·  ${inv.date}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(l10n.export),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, size: 16),
            label: Text(_isEditing ? l10n.done : l10n.edit),
            style: FilledButton.styleFrom(
              backgroundColor: _isEditing ? const Color(0xFF22C55E) : const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────────────
  Widget _buildSummaryBar(InvoiceRecord inv) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          _SummaryCard(label: l10n.totalItems, value: '$_grandQty ${l10n.pcs}', icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          _SummaryCard(
            label: l10n.totalAmount,
            value: '\$${_grandTotal.toStringAsFixed(2)}',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          _SummaryCard(label: l10n.total, value: '${_rows.length} ${l10n.rows}', icon: Icons.list_alt_rounded, color: const Color(0xFFF59E0B)),
          if (inv.invoiceUrl != null) ...[const SizedBox(width: 12), _ImageSummaryCard(url: inv.invoiceUrl!)],
        ],
      ),
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.ocrResultEditableTable,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const Spacer(),
          if (_selectedRows.isNotEmpty) ...[
            Text(
              '${_selectedRows.length} ${l10n.selectAll.toLowerCase()}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: Text(l10n.delete),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),
            const SizedBox(width: 8),
          ],
          if (_isEditing)
            FilledButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.addRow),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(children: [_buildTableHeader(), ..._rows.asMap().entries.map((e) => _buildTableRow(e.key, e.value))]),
      ),
    );
  }

  Widget _buildTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.3);
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Row(
        children: [
          SizedBox(
            width: _colCheck,
            child: Checkbox(
              value: _selectedRows.length == _rows.length && _rows.isNotEmpty,
              tristate: _selectedRows.isNotEmpty && _selectedRows.length < _rows.length,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedRows.addAll(List.generate(_rows.length, (i) => i));
                } else {
                  _selectedRows.clear();
                }
              }),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
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

  Widget _buildTableRow(int index, InvoiceRow row) {
    final isSelected = _selectedRows.contains(index);
    Color rowBg;
    if (isSelected) {
      rowBg = const Color(0xFFEEF2FF);
    } else if (row.hasWarning) {
      rowBg = const Color(0xFFFFFBEB);
    } else if (index.isOdd) {
      rowBg = const Color(0xFFFAFAFA);
    } else {
      rowBg = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colCheck,
            child: Checkbox(
              value: isSelected,
              onChanged: (v) => setState(() {
                if (v == true)
                  _selectedRows.add(index);
                else
                  _selectedRows.remove(index);
              }),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          _staticCell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          _editableCell(
            value: row.productName,
            width: _colProduct,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(productName: v)),
            bold: true,
          ),
          _editableCell(
            value: row.modelCode,
            width: _colModel,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(modelCode: v)),
          ),
          _editableCell(
            value: row.size,
            width: _colSize,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(size: v)),
          ),
          _editableCell(
            value: row.color,
            width: _colColor,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(color: v)),
          ),
          _editableCell(
            value: row.colorCode,
            width: _colColorCode,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(colorCode: v)),
          ),
          _numericCell(
            value: row.qty.toString(),
            width: _colQty,
            isInt: true,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(qty: int.tryParse(v) ?? row.qty)),
          ),
          _numericCell(
            value: row.unitPrice.toStringAsFixed(4),
            width: _colUnit,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(unitPrice: double.tryParse(v) ?? row.unitPrice)),
          ),
          _staticCell(
            row.total.toStringAsFixed(2),
            _colTotal,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          _numericCell(
            value: row.piecesPerCarton.toString(),
            width: _colPcsCarton,
            isInt: true,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(piecesPerCarton: int.tryParse(v) ?? row.piecesPerCarton)),
          ),
          _numericCell(
            value: row.cartonCount.toString(),
            width: _colCarton,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(cartonCount: double.tryParse(v) ?? row.cartonCount)),
          ),
          _numericCell(
            value: row.grossWeight.toString(),
            width: _colGross,
            warning: row.hasWarning,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(grossWeight: double.tryParse(v) ?? row.grossWeight)),
          ),
          _numericCell(
            value: row.totalWeightKg.toString(),
            width: _colTotalWt,
            warning: row.hasWarning,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(totalWeightKg: double.tryParse(v) ?? row.totalWeightKg)),
          ),
        ],
      ),
    );
  }

  Widget _staticCell(String text, double width, {TextStyle? style}) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Text(text, style: style ?? const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
    );
  }

  Widget _editableCell({
    required String value,
    required double width,
    required ValueChanged<String> onChanged,
    bool bold = false,
    bool warning = false,
  }) {
    return SizedBox(
      width: width,
      height: 48,
      child: _isEditing
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: warning ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                ),
                decoration: _inputDecoration(warning: warning),
              ),
            )
          : Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: value.isEmpty
                      ? const Color(0xFFCBD5E1)
                      : warning
                      ? const Color(0xFFB45309)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
    );
  }

  Widget _numericCell({
    required String value,
    required double width,
    required ValueChanged<String> onChanged,
    bool isInt = false,
    bool warning = false,
  }) {
    return SizedBox(
      width: width,
      height: 48,
      child: _isEditing
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                style: TextStyle(fontSize: 13, color: warning ? const Color(0xFFB45309) : const Color(0xFF1E293B)),
                decoration: _inputDecoration(warning: warning),
              ),
            )
          : Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Text(
                value == '0' || value == '0.0' ? (warning ? '⚠ —' : '—') : value,
                style: TextStyle(fontSize: 13, color: warning ? const Color(0xFFB45309) : const Color(0xFF475569)),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({bool warning = false}) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    filled: true,
    fillColor: warning ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: warning ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: warning ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
    ),
  );

  // ── Footer ───────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
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
          _FooterStat(label: l10n.grandTotal, value: '\$${_grandTotal.toStringAsFixed(2)}', highlight: true),
          const SizedBox(width: 32),
          FilledButton.icon(
            onPressed: () {
              widget.onConfirmed?.call();
              Navigator.of(context, rootNavigator: true).pop();
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: Text(l10n.confirmAndSave),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      InvoiceStatus.pending => (l10n.pending, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      InvoiceStatus.confirmed => (l10n.confirmed, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      InvoiceStatus.cancelled => (l10n.cancelled, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ],
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

class _ImageSummaryCard extends StatelessWidget {
  final String url;
  const _ImageSummaryCard({required this.url});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0EA5E9);
    return Tooltip(
      message: 'View original invoice image',
      child: InkWell(
        onTap: () => html.window.open(url, '_blank'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.image_search_rounded, color: color, size: 20),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice Image', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    'View original',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
