import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/invoice_confirm/data/repositories/invoice_confirm_repository.dart';
import 'package:inventory/features/invoice_list/cubit/invoice_list_cubit.dart';
import 'package:inventory/models/invoice_models.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/core/utils/responsive.dart';
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
  bool _hasEdits = false;
  bool _isSubmitting = false;

  // ── Editable header fields ───────────────────────────────────────────────────
  late String _invoiceNo;
  late final TextEditingController _invoiceNoController;
  late final TextEditingController _supplierNameController;
  late final TextEditingController _supplierAddressController;
  late final TextEditingController _supplierTaxIdController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _invoiceDateController;
  late final TextEditingController _contractNumberController;

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
    _invoiceNo = widget.invoice.invoiceNo;
    _invoiceNoController = TextEditingController(text: _invoiceNo);
    _supplierNameController = TextEditingController(text: widget.invoice.supplier);
    _supplierAddressController = TextEditingController(text: widget.invoice.supplierAddress ?? '');
    _supplierTaxIdController = TextEditingController(text: widget.invoice.supplierTaxId ?? '');
    _contactNumberController = TextEditingController(text: widget.invoice.contactNumber ?? '');
    _invoiceDateController = TextEditingController(text: widget.invoice.date);
    _contractNumberController = TextEditingController(text: widget.invoice.contractNumber ?? '');
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _supplierNameController.dispose();
    _supplierAddressController.dispose();
    _supplierTaxIdController.dispose();
    _contactNumberController.dispose();
    _invoiceDateController.dispose();
    _contractNumberController.dispose();
    super.dispose();
  }

  /// Called whenever any cell value changes so we can enable the submit button.
  void _markEdited() {
    if (!_hasEdits) setState(() => _hasEdits = true);
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
      _hasEdits = true;
    });
  }

  void _deleteSelected() {
    setState(() {
      final indices = _selectedRows.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) _rows.removeAt(i);
      _selectedRows.clear();
      _hasEdits = true;
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
          _buildHeaderInfo(),
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
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.fromLTRB(context.responsivePadding, isMobile ? 16 : 20, context.responsivePadding, 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.read<InvoiceListCubit>().fetchInvoices();
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _invoiceNoController,
                          onChanged: (v) {
                            _invoiceNo = v;
                            _markEdited();
                          },
                          style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            hintText: l10n.invoiceNoHint,
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    _StatusChip(status: inv.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _supplierNameController,
                          onChanged: (_) => _markEdited(),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            hintText: l10n.supplierNameHint,
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('·', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    Text(inv.date, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
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

  // ── Header info (editable) ────────────────────────────────────────────────────
  Widget _buildHeaderInfo() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    final fullWidth = screenWidth - (context.responsivePadding * 2);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(context.responsivePadding, 0, context.responsivePadding, 16),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoField(label: l10n.supplierAddress, controller: _supplierAddressController, width: fullWidth, onChanged: (_) => _markEdited()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoField(
                        label: l10n.taxIdLabel,
                        controller: _supplierTaxIdController,
                        width: double.infinity,
                        onChanged: (_) => _markEdited(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoField(
                        label: l10n.invoiceDateLabel,
                        controller: _invoiceDateController,
                        width: double.infinity,
                        hint: 'YYYY-MM-DD',
                        onChanged: (_) => _markEdited(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoField(label: l10n.contactNumber, controller: _contactNumberController, width: fullWidth, onChanged: (_) => _markEdited()),
                const SizedBox(height: 12),
                _infoField(label: l10n.contractNumber, controller: _contractNumberController, width: fullWidth, onChanged: (_) => _markEdited()),
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _infoField(label: l10n.supplierAddress, controller: _supplierAddressController, width: 340, onChanged: (_) => _markEdited()),
                _infoField(label: l10n.taxIdLabel, controller: _supplierTaxIdController, width: 140, onChanged: (_) => _markEdited()),
                _infoField(label: l10n.contactNumber, controller: _contactNumberController, width: 180, onChanged: (_) => _markEdited()),
                _infoField(
                  label: l10n.invoiceDateLabel,
                  controller: _invoiceDateController,
                  width: 140,
                  hint: 'YYYY-MM-DD',
                  onChanged: (_) => _markEdited(),
                ),
                _infoField(label: l10n.contractNumber, controller: _contractNumberController, width: 160, onChanged: (_) => _markEdited()),
              ],
            ),
    );
  }

  Widget _infoField({
    required String label,
    required TextEditingController controller,
    required double width,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
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
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────────────
  Widget _buildSummaryBar(InvoiceRecord inv) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(context.responsivePadding, 0, context.responsivePadding, 16),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    child: _SummaryCard(
                      label: l10n.totalItems,
                      value: '$_grandQty ${l10n.pcs}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    child: _SummaryCard(
                      label: l10n.totalAmount,
                      value: '\$${_grandTotal.toStringAsFixed(2)}',
                      icon: Icons.attach_money_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    child: _SummaryCard(
                      label: l10n.total,
                      value: '${_rows.length} ${l10n.rows}',
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  ...inv.invoiceUrls.asMap().entries.map(
                    (e) => Row(
                      children: [
                        const SizedBox(width: 10),
                        _ImageSummaryCard(url: e.value, label: inv.invoiceUrls.length > 1 ? l10n.pageN(e.key + 1) : null),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: l10n.totalItems,
                    value: '$_grandQty ${l10n.pcs}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.totalAmount,
                    value: '\$${_grandTotal.toStringAsFixed(2)}',
                    icon: Icons.attach_money_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.total,
                    value: '${_rows.length} ${l10n.rows}',
                    icon: Icons.list_alt_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                ...inv.invoiceUrls.asMap().entries.map(
                  (e) => Row(
                    children: [
                      const SizedBox(width: 12),
                      _ImageSummaryCard(url: e.value, label: inv.invoiceUrls.length > 1 ? l10n.pageN(e.key + 1) : null),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.responsivePadding, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ocrResultEditableTable,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_selectedRows.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteSelected,
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: Text('${l10n.delete} (${_selectedRows.length})'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_isEditing)
                      Expanded(
                        flex: _selectedRows.isEmpty ? 1 : 0,
                        child: FilledButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(l10n.addRow),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )
          : Row(
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
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(productName: v));
              _markEdited();
            },
            bold: true,
          ),
          _editableCell(
            value: row.modelCode,
            width: _colModel,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(modelCode: v));
              _markEdited();
            },
          ),
          _editableCell(
            value: row.size,
            width: _colSize,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(size: v));
              _markEdited();
            },
          ),
          _editableCell(
            value: row.color,
            width: _colColor,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(color: v));
              _markEdited();
            },
          ),
          _editableCell(
            value: row.colorCode,
            width: _colColorCode,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(colorCode: v));
              _markEdited();
            },
          ),
          _numericCell(
            value: row.qty.toString(),
            width: _colQty,
            isInt: true,
            onChanged: (v) {
              final newQty = int.tryParse(v) ?? row.qty;
              setState(
                () => _rows[index] = row.copyWith(
                  qty: newQty,
                  totalPrice: newQty * row.unitPrice, // keep total in sync
                ),
              );
              _markEdited();
            },
          ),
          _numericCell(
            value: row.unitPrice.toStringAsFixed(4),
            width: _colUnit,
            onChanged: (v) {
              final newPrice = double.tryParse(v) ?? row.unitPrice;
              setState(
                () => _rows[index] = row.copyWith(
                  unitPrice: newPrice,
                  totalPrice: row.qty * newPrice, // keep total in sync
                ),
              );
              _markEdited();
            },
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
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(piecesPerCarton: int.tryParse(v) ?? row.piecesPerCarton));
              _markEdited();
            },
          ),
          _numericCell(
            value: row.cartonCount.toString(),
            width: _colCarton,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(cartonCount: double.tryParse(v) ?? row.cartonCount));
              _markEdited();
            },
          ),
          _numericCell(
            value: row.grossWeight.toString(),
            width: _colGross,
            warning: row.hasWarning,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(grossWeight: double.tryParse(v) ?? row.grossWeight));
              _markEdited();
            },
          ),
          _numericCell(
            value: row.totalWeightKg.toString(),
            width: _colTotalWt,
            warning: row.hasWarning,
            onChanged: (v) {
              setState(() => _rows[index] = row.copyWith(totalWeightKg: double.tryParse(v) ?? row.totalWeightKg));
              _markEdited();
            },
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
    final isMobile = context.isMobile;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
      ),
      padding: EdgeInsets.symmetric(horizontal: context.responsivePadding, vertical: isMobile ? 12 : 14),
      child: isMobile
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.totalQty, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        Text(
                          '$_grandQty ${l10n.pcs}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.grandTotal,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        Text(
                          '\$${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _hasEdits && !_isSubmitting ? _onConfirmAndSave : null,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(l10n.confirmAndSave),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            )
          : Row(
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
                  onPressed: _hasEdits && !_isSubmitting ? _onConfirmAndSave : null,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Text(l10n.confirmAndSave),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _onConfirmAndSave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          l10n.confirmAndSave,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        content: Text(l10n.confirmAndSaveDialogBody, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
              context.read<InvoiceListCubit>().fetchInvoices();
            },
            child: Text(l10n.noLabel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.yesLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final result = await InvoiceConfirmRepository.instance.confirmInvoice(
      invoiceId: widget.invoice.id,
      rows: _rows,
      invoice: widget.invoice,
      supplierName: _supplierNameController.text.trim(),
      invoiceNumber: _invoiceNo,
      supplierAddress: _supplierAddressController.text.trim(),
      supplierTaxId: _supplierTaxIdController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      invoiceDate: _invoiceDateController.text.trim(),
      contractNumber: _contractNumberController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        widget.onConfirmed?.call();
        Navigator.of(context, rootNavigator: true).pop();
        context.read<InvoiceListCubit>().fetchInvoices();
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
    }
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
  final String? label;
  const _ImageSummaryCard({required this.url, this.label});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0EA5E9);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.viewOriginalImage,
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
          child: Row(
            children: [
              const Icon(Icons.image_search_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label ?? l10n.invoiceImageTitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    l10n.viewOriginal,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new_rounded, color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
