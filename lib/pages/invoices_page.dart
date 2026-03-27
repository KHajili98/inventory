import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inventory/models/invoice_models.dart';
import 'package:inventory/pages/invoice_detail_page.dart';
import 'package:inventory/l10n/app_localizations.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final List<InvoiceRecord> _invoices = List.from(mockInvoices);
  final bool _isProcessing = false;

  // ── Upload & OCR flow ───────────────────────────────────────────────────────
  Future<void> _pickAndProcessImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    _showProcessingDialog(file.name, file.bytes);
  }

  void _showProcessingDialog(String filename, Uint8List? bytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OcrProcessingDialog(
        filename: filename,
        imageBytes: bytes,
        onConfirm: (rows) {
          Navigator.of(context, rootNavigator: true).pop(); // close dialog only
          final newInvoice = InvoiceRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            invoiceNo: 'NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            date: DateTime.now().toIso8601String().split('T').first,
            supplier: 'Pending OCR Review',
            buyer: 'Aydinoglu Trend NO.1LLC',
            totalItems: rows.fold(0, (s, r) => s + r.qty),
            totalAmount: rows.fold(0.0, (s, r) => s + r.total),
            status: InvoiceStatus.pending,
            rows: rows,
          );
          setState(() => _invoices.insert(0, newInvoice));
          _openDetail(newInvoice);
        },
      ),
    );
  }

  void _openDetail(InvoiceRecord inv) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: inv,
          onConfirmed: () {
            setState(() {
              final idx = _invoices.indexWhere((i) => i.id == inv.id);
              if (idx != -1) {
                _invoices[idx] = InvoiceRecord(
                  id: inv.id,
                  invoiceNo: inv.invoiceNo,
                  date: inv.date,
                  supplier: inv.supplier,
                  buyer: inv.buyer,
                  totalItems: inv.totalItems,
                  totalAmount: inv.totalAmount,
                  status: InvoiceStatus.confirmed,
                  rows: inv.rows,
                );
              }
            });
          },
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.invoices,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 2),
            Text(l10n.manageInvoices, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        const Spacer(),
        // Upload button
        FilledButton.icon(
          onPressed: _isProcessing ? null : _pickAndProcessImage,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(l10n.addInvoiceFromImage),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context)!;
    final totalAmount = _invoices.fold(0.0, (s, i) => s + i.totalAmount);
    final pending = _invoices.where((i) => i.status == InvoiceStatus.pending).length;
    final confirmed = _invoices.where((i) => i.status == InvoiceStatus.confirmed).length;
    return Row(
      children: [
        _StatCard(label: l10n.totalInvoices, value: '${_invoices.length}', icon: Icons.receipt_long_rounded, color: const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        _StatCard(label: l10n.totalValue, value: '\$${totalAmount.toStringAsFixed(2)}', icon: Icons.payments_outlined, color: const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _StatCard(label: l10n.pending, value: '$pending', icon: Icons.hourglass_empty_rounded, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 16),
        _StatCard(label: l10n.confirmed, value: '$confirmed', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF0EA5E9)),
      ],
    );
  }

  Widget _buildInvoiceList() {
    if (_invoices.isEmpty) {
      return _EmptyState(onAdd: _pickAndProcessImage);
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
          _buildListHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: _invoices.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) => _buildInvoiceRow(_invoices[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final l10n = AppLocalizations.of(context)!;
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(l10n.invoiceNumber, style: style)),
          SizedBox(width: 240, child: Text(l10n.supplier, style: style)),
          SizedBox(width: 110, child: Text(l10n.date, style: style)),
          SizedBox(width: 90, child: Text(l10n.items, style: style)),
          SizedBox(width: 120, child: Text(l10n.amount, style: style)),
          SizedBox(width: 110, child: Text(l10n.status, style: style)),
          const Spacer(),
          Text(l10n.actions, style: style),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(InvoiceRecord inv) {
    return InkWell(
      onTap: () => _openDetail(inv),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Invoice number
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_rounded, size: 18, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '#${inv.invoiceNo}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            // Supplier
            SizedBox(
              width: 240,
              child: Text(
                inv.supplier,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            SizedBox(
              width: 110,
              child: Text(inv.date, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ),
            // Items
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return SizedBox(
                  width: 90,
                  child: Text('${inv.totalItems} ${l10n.pcs}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                );
              },
            ),
            // Amount
            SizedBox(
              width: 120,
              child: Text(
                '\$${inv.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
            ),
            // Status
            SizedBox(width: 110, child: _StatusBadge(status: inv.status)),
            const Spacer(),
            // Actions
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  children: [
                    _ActionBtn(icon: Icons.visibility_outlined, tooltip: l10n.view, onTap: () => _openDetail(inv)),
                    const SizedBox(width: 4),
                    _ActionBtn(icon: Icons.download_outlined, tooltip: l10n.export, onTap: () {}),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      tooltip: l10n.delete,
                      color: const Color(0xFFEF4444),
                      onTap: () => setState(() => _invoices.remove(inv)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── OCR Processing Dialog ──────────────────────────────────────────────────────
class _OcrProcessingDialog extends StatefulWidget {
  final String filename;
  final Uint8List? imageBytes;
  final ValueChanged<List<InvoiceRow>> onConfirm;

  const _OcrProcessingDialog({required this.filename, required this.imageBytes, required this.onConfirm});

  @override
  State<_OcrProcessingDialog> createState() => _OcrProcessingDialogState();
}

class _OcrProcessingDialogState extends State<_OcrProcessingDialog> {
  // Simulated OCR stages
  int _stage = 0; // 0=uploading 1=processing 2=done
  late List<InvoiceRow> _rows;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  Future<void> _runOcr() async {
    // Stage 1: uploading
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _stage = 1);

    // Stage 2: OCR processing
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Use mock rows as OCR result (replace with real API response)
    _rows = List.from(mockOcrRows);
    setState(() => _stage = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(padding: const EdgeInsets.all(28), child: _stage < 2 ? _buildProcessing() : _buildPreview()),
      ),
    );
  }

  Widget _buildProcessing() {
    final l10n = AppLocalizations.of(context)!;
    final stages = [l10n.uploadingImage, l10n.runningOCR];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF6366F1), size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.processingInvoiceImage,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        Text(widget.filename, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 24),
        const LinearProgressIndicator(backgroundColor: Color(0xFFE2E8F0), color: Color(0xFF6366F1)),
        const SizedBox(height: 14),
        Text(
          stages[_stage],
          style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ocrComplete,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(l10n.reviewExtractedData, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Mini preview table
        Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        l10n.model,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        l10n.sku,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        l10n.qty,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.totalUSD,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final r = _rows[i];
                    return Container(
                      color: r.hasWarning ? const Color(0xFFFFFBEB) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(r.modelCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(r.sku, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ),
                          SizedBox(width: 60, child: Text('${r.qty}', style: const TextStyle(fontSize: 12))),
                          Row(
                            children: [
                              Text('\$${r.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              if (r.hasWarning) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              '${_rows.where((r) => r.hasWarning).length} ${l10n.rowsWithMissingData}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => widget.onConfirm(_rows),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(l10n.openAndEditTable),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      InvoiceStatus.pending => (l10n.pending, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      InvoiceStatus.confirmed => (l10n.confirmed, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      InvoiceStatus.cancelled => (l10n.cancelled, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  const _ActionBtn({required this.icon, required this.tooltip, required this.onTap, this.color = const Color(0xFF64748B)});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noInvoicesYet,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(l10n.uploadInvoiceToStart, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.addInvoiceFromImage),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
