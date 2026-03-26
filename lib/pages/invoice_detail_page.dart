import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/models/invoice_models.dart';

class InvoiceDetailPage extends StatefulWidget {
  final InvoiceRecord invoice;
  final VoidCallback? onConfirmed;
  const InvoiceDetailPage({super.key, required this.invoice, this.onConfirmed});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late List<InvoiceRow> _rows;
  final Set<int> _selectedRows = {};
  bool _isEditing = false;

  // Column widths
  static const double _colCheck = 48;
  static const double _colIdx = 48;
  static const double _colModel = 100;
  static const double _colSku = 130;
  static const double _colSize = 80;
  static const double _colColor = 80;
  static const double _colQty = 70;
  static const double _colUnit = 100;
  static const double _colTotal = 100;
  static const double _colBox = 120;
  static const double _colCbm = 80;
  static const double _colNet = 90;
  static const double _colGross = 90;
  static const double _colNotes = 160;

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.invoice.rows);
  }

  double get _grandTotal => _rows.fold(0, (s, r) => s + r.total);
  int get _grandQty => _rows.fold(0, (s, r) => s + r.qty);

  void _addRow() {
    setState(() {
      _rows.add(
        InvoiceRow(
          modelCode: '',
          sku: '',
          size: '',
          color: '',
          qty: 0,
          unitPrice: 0,
          boxDimensions: '',
          cbm: 0,
          netWeight: 0,
          grossWeight: 0,
          notes: '',
        ),
      );
    });
  }

  void _deleteSelected() {
    setState(() {
      final indices = _selectedRows.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        _rows.removeAt(i);
      }
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(InvoiceRecord inv) {
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
                      'Invoice #${inv.invoiceNo}',
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
          // Action buttons
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export'),
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
            label: Text(_isEditing ? 'Done' : 'Edit'),
            style: FilledButton.styleFrom(
              backgroundColor: _isEditing ? const Color(0xFF22C55E) : const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary cards ────────────────────────────────────────────────────────────
  Widget _buildSummaryBar(InvoiceRecord inv) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          _SummaryCard(label: 'Total Items', value: '$_grandQty pcs', icon: Icons.inventory_2_outlined, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'Total Amount',
            value: '\$${_grandTotal.toStringAsFixed(2)}',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          _SummaryCard(label: 'SKU Lines', value: '${_rows.length} rows', icon: Icons.list_alt_rounded, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'Warnings',
            value: '${_rows.where((r) => r.hasWarning).length} rows',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
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
            'OCR Result — Editable Table',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const Spacer(),
          if (_selectedRows.isNotEmpty) ...[
            Text(
              '${_selectedRows.length} selected',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),
            const SizedBox(width: 8),
          ],
          if (_isEditing)
            FilledButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Row'),
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
          _headerCell('Model', _colModel, style),
          _headerCell('SKU', _colSku, style),
          _headerCell('Size', _colSize, style),
          _headerCell('Color', _colColor, style),
          _headerCell('Qty', _colQty, style),
          _headerCell('Unit (USD)', _colUnit, style),
          _headerCell('Total (USD)', _colTotal, style),
          _headerCell('Box (cm)', _colBox, style),
          _headerCell('CBM', _colCbm, style),
          _headerCell('Net (kg)', _colNet, style),
          _headerCell('Gross (kg)', _colGross, style),
          _headerCell('Notes', _colNotes, style),
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
    final isOdd = index.isOdd;
    Color rowBg;
    if (isSelected) {
      rowBg = const Color(0xFFEEF2FF);
    } else if (row.hasWarning) {
      rowBg = const Color(0xFFFFFBEB);
    } else if (isOdd) {
      rowBg = const Color(0xFFFAFAFA);
    } else {
      rowBg = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
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
          // Index
          _staticCell('${index + 1}', _colIdx, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          // Editable cells
          _editableCell(
            value: row.modelCode,
            width: _colModel,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(modelCode: v)),
            bold: true,
          ),
          _editableCell(
            value: row.sku,
            width: _colSku,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(sku: v)),
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
          // Total (read-only computed)
          _staticCell(
            row.total.toStringAsFixed(2),
            _colTotal,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          _editableCell(
            value: row.boxDimensions,
            width: _colBox,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(boxDimensions: v)),
          ),
          _numericCell(
            value: row.cbm.toString(),
            width: _colCbm,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(cbm: double.tryParse(v) ?? row.cbm)),
          ),
          _numericCell(
            value: row.netWeight.toString(),
            width: _colNet,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(netWeight: double.tryParse(v) ?? row.netWeight)),
            warning: row.hasWarning,
          ),
          _numericCell(
            value: row.grossWeight.toString(),
            width: _colGross,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(grossWeight: double.tryParse(v) ?? row.grossWeight)),
            warning: row.hasWarning,
          ),
          _editableCell(
            value: row.notes,
            width: _colNotes,
            onChanged: (v) => setState(() => _rows[index] = row.copyWith(notes: v)),
            warning: row.hasWarning,
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
                decoration: InputDecoration(
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
                ),
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
                decoration: InputDecoration(
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
                ),
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

  // ── Footer totals ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          const Text(
            'TOTALS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.5),
          ),
          const Spacer(),
          _FooterStat(label: 'Total Qty', value: '$_grandQty pcs'),
          const SizedBox(width: 32),
          _FooterStat(label: 'Grand Total', value: '\$${_grandTotal.toStringAsFixed(2)}', highlight: true),
          const SizedBox(width: 32),
          FilledButton.icon(
            onPressed: () {
              widget.onConfirmed?.call();
              Navigator.of(context, rootNavigator: true).pop();
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Confirm & Save'),
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
    final (label, bg, fg) = switch (status) {
      InvoiceStatus.pending => ('Pending', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      InvoiceStatus.confirmed => ('Confirmed', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      InvoiceStatus.cancelled => ('Cancelled', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
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
