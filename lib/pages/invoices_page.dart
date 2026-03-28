import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/invoice_list/cubit/invoice_list_cubit.dart';
import 'package:inventory/features/invoice_list/cubit/invoice_list_state.dart';
import 'package:inventory/features/invoice_list/data/models/invoice_list_response_model.dart';
import 'package:inventory/features/invoice_ocr/cubit/invoice_ocr_cubit.dart';
import 'package:inventory/features/invoice_ocr/cubit/invoice_ocr_state.dart';
import 'package:inventory/features/invoice_ocr/data/models/invoice_upload_response_model.dart';
import 'package:inventory/models/invoice_models.dart';
import 'package:inventory/pages/invoice_detail_page.dart';
import 'package:inventory/pages/invoice_edit_page.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/core/utils/responsive.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  // Locally-added invoices (from OCR upload in this session) are stored here
  // so they appear immediately without waiting for a re-fetch.
  final List<InvoiceListItemModel> _locallyAdded = [];
  final bool _isProcessing = false;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Combines locally-added entries with the server list, de-duplicating by id.
  List<InvoiceListItemModel> _mergeInvoices(List<InvoiceListItemModel> serverList) {
    final serverIds = serverList.map((i) => i.id).toSet();
    final extras = _locallyAdded.where((i) => !serverIds.contains(i.id)).toList();
    return [...extras, ...serverList];
  }

  InvoiceRecord _toRecord(InvoiceListItemModel item) {
    return InvoiceRecord(
      id: item.id,
      invoiceNo: item.invoiceNumber ?? item.id.substring(0, 8),
      date: item.invoiceDate ?? '',
      supplier: item.supplierName ?? 'Unknown Supplier',
      buyer: 'Aydinoglu Trend NO.1LLC',
      totalItems: item.totalItemsCount,
      totalAmount: item.totalAmount ?? 0.0,
      status: InvoiceStatus.pending,
      rows: const [],
      invoiceUrls: item.invoiceImageUrls,
      processingIds: item.invoiceProcessing,
    );
  }

  // ── Upload & OCR flow ───────────────────────────────────────────────────────
  Future<void> _pickAndProcessImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    _showProcessingDialog(file.name, file.bytes!);
  }

  void _showProcessingDialog(String filename, Uint8List bytes) {
    // Reset cubit before opening dialog
    context.read<InvoiceOcrCubit>().reset();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<InvoiceOcrCubit>(),
        child: _OcrProcessingDialog(
          filename: filename,
          imageBytes: bytes,
          onConfirm: (rows, response, allResponses) {
            Navigator.of(context, rootNavigator: true).pop();

            // Collect all image URLs and processing IDs from every uploaded page
            final allImageUrls = allResponses.map((r) => r.invoiceUrl).whereType<String>().toList();
            final allProcessingIds = allResponses.map((r) => r.processingMetadata?.id).whereType<String>().toList();

            final newItem = InvoiceListItemModel(
              id: response.processingMetadata?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              invoiceNumber: response.invoiceNumber ?? 'NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              invoiceDate: response.invoiceDate ?? DateTime.now().toIso8601String().split('T').first,
              supplierName: response.supplierName ?? 'Unknown Supplier',
              totalAmount: response.totalAmount ?? rows.fold<double>(0.0, (s, r) => s + r.total),
              currency: 'USD',
              invoiceImageUrls: allImageUrls,
              invoiceProcessing: allProcessingIds,
              totalItemsCount: rows.fold(0, (s, r) => s + r.qty),
              createdAt: DateTime.now(),
            );

            setState(() => _locallyAdded.insert(0, newItem));

            final newRecord = InvoiceRecord(
              id: newItem.id,
              invoiceNo: newItem.invoiceNumber ?? newItem.id,
              date: newItem.invoiceDate ?? '',
              supplier: newItem.supplierName ?? 'Unknown Supplier',
              buyer: 'Aydinoglu Trend NO.1LLC',
              totalItems: rows.fold(0, (s, r) => s + r.qty),
              totalAmount: newItem.totalAmount ?? 0.0,
              status: InvoiceStatus.pending,
              rows: rows,
              invoiceUrls: allImageUrls,
              supplierAddress: response.extractedData?.supplierAddress,
              supplierTaxId: response.extractedData?.supplierTaxId,
              contactNumber: response.extractedData?.contactNumber,
              contractNumber: response.extractedData?.contractNumber,
              currency: response.extractedData?.currency ?? 'USD',
              processingIds: allProcessingIds,
            );
            _openEditPage(newRecord);
          },
        ),
      ),
    );

    // Kick off the upload immediately after dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceOcrCubit>().uploadInvoice(fileBytes: bytes, fileName: filename);
    });
  }

  void _openDetail(InvoiceRecord inv) {
    // Open read-only detail page using the UUID from the server
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoiceId: inv.id)));
  }

  void _openEditPage(InvoiceRecord inv) {
    // Open editable page after OCR — allows the user to review and confirm
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditPage(
          invoice: inv,
          onConfirmed: () {
            setState(() {
              final idx = _locallyAdded.indexWhere((i) => i.id == inv.id);
              if (idx != -1) {
                _locallyAdded[idx] = InvoiceListItemModel(
                  id: inv.id,
                  invoiceNumber: inv.invoiceNo,
                  invoiceDate: inv.date,
                  supplierName: inv.supplier,
                  totalAmount: inv.totalAmount,
                  currency: 'USD',
                  invoiceImageUrls: inv.invoiceUrls,
                  invoiceProcessing: inv.processingIds,
                  totalItemsCount: inv.totalItems,
                  createdAt: _locallyAdded[idx].createdAt,
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
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          SizedBox(height: context.isMobile ? 16 : 20),
          _buildStatsRow(),
          SizedBox(height: context.isMobile ? 16 : 24),
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.invoices,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(l10n.manageInvoices, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _pickAndProcessImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(l10n.addInvoiceFromImage),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

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
    final isMobile = context.isMobile;

    return BlocBuilder<InvoiceListCubit, InvoiceListState>(
      builder: (context, state) {
        final invoices = state is InvoiceListLoaded ? _mergeInvoices(state.invoices) : _locallyAdded;
        final totalCount = state is InvoiceListLoaded ? state.totalCount : _locallyAdded.length;
        final totalAmount = invoices.fold(0.0, (s, i) => s + (i.totalAmount ?? 0.0));

        final stats = [
          _StatCard(label: l10n.totalInvoices, value: '$totalCount', icon: Icons.receipt_long_rounded, color: const Color(0xFF6366F1)),
          _StatCard(
            label: l10n.totalValue,
            value: '\$${totalAmount.toStringAsFixed(2)}',
            icon: Icons.payments_outlined,
            color: const Color(0xFF22C55E),
          ),
          // _StatCard(label: l10n.pending, value: '–', icon: Icons.hourglass_empty_rounded, color: const Color(0xFFF59E0B)),
          //    _StatCard(label: l10n.confirmed, value: '–', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF0EA5E9)),
        ];

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 12), SizedBox(child: stats[i])],
              ],
            ),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: stats[i])],
          ],
        );
      },
    );
  }

  Widget _buildInvoiceList() {
    return BlocBuilder<InvoiceListCubit, InvoiceListState>(
      builder: (context, state) {
        return switch (state) {
          InvoiceListInitial() || InvoiceListLoading() =>
            _locallyAdded.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _buildLoadedList(_locallyAdded, hasMore: false, isLoadingMore: false),
          InvoiceListLoaded(:final invoices, :final hasMore, :final isLoadingMore) => _buildLoadedList(
            _mergeInvoices(invoices),
            hasMore: hasMore,
            isLoadingMore: isLoadingMore,
          ),
          InvoiceListError(:final message) =>
            _locallyAdded.isEmpty ? _buildErrorState(message) : _buildLoadedList(_locallyAdded, hasMore: false, isLoadingMore: false),
        };
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<InvoiceListCubit>().refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedList(List<InvoiceListItemModel> invoices, {required bool hasMore, required bool isLoadingMore}) {
    if (invoices.isEmpty) {
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
            child: RefreshIndicator(
              color: const Color(0xFF6366F1),
              onRefresh: () => context.read<InvoiceListCubit>().refresh(),
              child: ListView.separated(
                itemCount: invoices.length + (hasMore || isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, i) {
                  if (i == invoices.length) {
                    return _buildPaginationFooter(isLoadingMore);
                  }
                  return _buildInvoiceRow(invoices[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(bool isLoadingMore) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2.5)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Center(
        child: TextButton.icon(
          onPressed: () => context.read<InvoiceListCubit>().loadMoreInvoices(),
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF6366F1)),
          label: const Text(
            'Load more',
            style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    // Mobile: no header row (cards are self-describing)
    if (isMobile) {
      return const SizedBox.shrink();
    }

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
          SizedBox(width: 130, child: Text(l10n.invoiceNumber, style: style)),
          Expanded(child: Text(l10n.supplier, style: style)),
          SizedBox(width: 100, child: Text(l10n.invoiceDate, style: style)),
          SizedBox(width: 160, child: Text(l10n.createdAt, style: style)),
          SizedBox(width: 80, child: Text(l10n.items, style: style)),
          SizedBox(width: 110, child: Text(l10n.amount, style: style)),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(InvoiceListItemModel inv) {
    final record = _toRecord(inv);
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    String createdAtStr = inv.createdAt != null ? _formatDateTime(inv.createdAt!) : '–';

    // Mobile: card layout
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            onTap: () => _openDetail(record),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_rounded, size: 18, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${inv.invoiceNumber ?? inv.id.substring(0, 8)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              inv.supplierName ?? '–',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _DeleteButton(invoiceId: inv.id, onDeleted: () => _onInvoiceDeleted(inv.id)),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  // Details
                  Row(
                    children: [
                      Expanded(
                        child: _MobileInfoItem(icon: Icons.calendar_today_outlined, label: l10n.invoiceDate, value: inv.invoiceDate ?? '–'),
                      ),
                      Expanded(
                        child: _MobileInfoItem(icon: Icons.inventory_2_outlined, label: l10n.items, value: '${inv.totalItemsCount} ${l10n.pcs}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MobileInfoItem(icon: Icons.access_time_rounded, label: l10n.createdAt, value: createdAtStr),
                      ),
                      Expanded(
                        child: _MobileInfoItem(
                          icon: Icons.attach_money_rounded,
                          label: l10n.amount,
                          value: '\$${(inv.totalAmount ?? 0.0).toStringAsFixed(2)}',
                          isHighlight: true,
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

    // Desktop: table row layout
    return InkWell(
      onTap: () => _openDetail(record),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Invoice number
            SizedBox(
              width: 130,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_rounded, size: 16, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${inv.invoiceNumber ?? inv.id.substring(0, 8)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Supplier
            Expanded(
              child: Text(
                inv.supplierName ?? '–',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            SizedBox(
              width: 100,
              child: Text(inv.invoiceDate ?? '–', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ),
            // Created At
            SizedBox(
              width: 160,
              child: Text(createdAtStr, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ),
            // Items
            SizedBox(
              width: 80,
              child: Text('${inv.totalItemsCount} ${l10n.pcs}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            ),
            // Amount
            SizedBox(
              width: 110,
              child: Text(
                '\$${(inv.totalAmount ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
            ),
            // Delete
            _DeleteButton(invoiceId: inv.id, onDeleted: () => _onInvoiceDeleted(inv.id)),
          ],
        ),
      ),
    );
  }

  Future<void> _onInvoiceDeleted(String id) async {
    // Remove from local list first for immediate feedback
    setState(() => _locallyAdded.removeWhere((i) => i.id == id));
    final result = await context.read<InvoiceListCubit>().deleteInvoice(id);
    if (result is Failure && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete invoice: ${(result as dynamic).message}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    // Convert to local time if the DateTime is in UTC
    final local = dt.isUtc ? dt.toLocal() : dt;
    // Format: yyyy-MM-dd | HH:mm:ss
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} | '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }
}

// ── OCR Processing Dialog ──────────────────────────────────────────────────────
class _OcrProcessingDialog extends StatefulWidget {
  final String filename;
  final Uint8List imageBytes;
  final void Function(List<InvoiceRow> rows, InvoiceUploadResponseModel firstResponse, List<InvoiceUploadResponseModel> allResponses) onConfirm;

  const _OcrProcessingDialog({required this.filename, required this.imageBytes, required this.onConfirm});

  @override
  State<_OcrProcessingDialog> createState() => _OcrProcessingDialogState();
}

class _OcrProcessingDialogState extends State<_OcrProcessingDialog> {
  final List<InvoiceUploadResponseModel> _responses = [];
  bool _isAddingMore = false;

  /// Maps the API response items to the existing [InvoiceRow] model used by
  /// the detail page / table.
  List<InvoiceRow> _mapToRows(InvoiceUploadResponseModel response) {
    final items = response.extractedData?.items ?? [];
    return items.map((item) {
      return InvoiceRow(
        modelCode: item.modelCode ?? '',
        productName: item.productName ?? '',
        size: item.size ?? '',
        color: item.color ?? '',
        colorCode: item.colorCode ?? '',
        qty: item.quantity ?? 0,
        unitPrice: item.unitPriceUsd ?? 0.0,
        totalPrice: item.totalPrice ?? 0.0,
        piecesPerCarton: item.piecesPerCarton ?? 0,
        cartonCount: item.cartonCount ?? 0.0,
        grossWeight: item.grossWeightKg ?? 0.0,
        totalWeightKg: item.totalWeightKg ?? 0.0,
        hasWarning: item.quantity == null || item.unitPriceUsd == null,
      );
    }).toList();
  }

  /// Combines all rows from multiple responses
  List<InvoiceRow> _getAllRows() {
    final allRows = <InvoiceRow>[];
    for (final response in _responses) {
      allRows.addAll(_mapToRows(response));
    }
    return allRows;
  }

  /// Gets the first response (for invoice metadata)
  InvoiceUploadResponseModel get _firstResponse => _responses.first;

  /// Pick and process another image
  Future<void> _addAnotherImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isAddingMore = true);

    // Reset cubit and process new image
    if (mounted) {
      context.read<InvoiceOcrCubit>().reset();
      await Future.delayed(const Duration(milliseconds: 100));
      context.read<InvoiceOcrCubit>().uploadInvoice(fileBytes: file.bytes!, fileName: file.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceOcrCubit, InvoiceOcrState>(
      listener: (context, state) {
        if (state is InvoiceOcrSuccess && _isAddingMore) {
          setState(() {
            _responses.add(state.response);
            _isAddingMore = false;
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: switch (state) {
                InvoiceOcrInitial() || InvoiceOcrUploading() || InvoiceOcrProcessing() => _buildProcessing(context, state),
                InvoiceOcrSuccess(:final response) => _buildPreview(context, response),
                InvoiceOcrFailure(:final message) => _buildError(context, message),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessing(BuildContext context, InvoiceOcrState state) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (state) {
      InvoiceOcrUploading() => l10n.uploadingImage,
      InvoiceOcrProcessing() => l10n.runningOCR,
      _ => l10n.uploadingImage,
    };

    final pageCount = _responses.length + 1;

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
        Text(_responses.isEmpty ? widget.filename : 'Page $pageCount', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        if (_responses.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Processing additional page...', style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
        ],
        const SizedBox(height: 24),
        const LinearProgressIndicator(backgroundColor: Color(0xFFE2E8F0), color: Color(0xFF6366F1)),
        const SizedBox(height: 14),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, InvoiceUploadResponseModel response) {
    final l10n = AppLocalizations.of(context)!;

    // Add current response to list if not already there
    if (!_isAddingMore && (_responses.isEmpty || _responses.last != response)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _responses.add(response);
          });
        }
      });
    }

    // Get combined rows from all responses
    final rows = _responses.isEmpty ? _mapToRows(response) : _getAllRows();
    final ocr = _firstResponse.extractedData;
    final pageCount = _responses.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.ocrComplete,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      if (pageCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '$pageCount pages',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(l10n.reviewExtractedData, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            // Add button for more images
            IconButton(
              onPressed: _addAnotherImage,
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add another page',
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), foregroundColor: const Color(0xFF6366F1)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Supplier / Invoice info chips ────────────────────────────────────
        if (ocr != null)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (ocr.supplierName != null) _InfoChip(icon: Icons.business_outlined, label: ocr.supplierName!),
              if (ocr.invoiceNumber != null) _InfoChip(icon: Icons.tag_rounded, label: '#${ocr.invoiceNumber}'),
              if (ocr.invoiceDate != null) _InfoChip(icon: Icons.calendar_today_outlined, label: ocr.invoiceDate!),
              if (pageCount > 1) _InfoChip(icon: Icons.description_outlined, label: '$pageCount pages'),
            ],
          ),
        const SizedBox(height: 16),

        // ── Items table ──────────────────────────────────────────────────────
        Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: context.isMobile
                      ? [_th(l10n.productName, null, flex: 1), _th(l10n.qty, null, flex: 1)]
                      : [
                          _th(l10n.productName, null, flex: 1),
                          _th(l10n.qty, null, flex: 1),
                          _th(l10n.color, null, flex: 1),
                          _th(l10n.unitPrice, null, flex: 1),
                          _th(l10n.pcsPerCarton, null, flex: 1),
                          _th(l10n.grossWeight, null, flex: 1),
                          _th(l10n.total, null, flex: 1),
                        ],
                ),
              ),
              // Table rows
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    // Find the corresponding API item from all responses
                    OcrItemModel? apiItem;
                    var currentIndex = i;
                    for (final resp in _responses) {
                      final items = resp.extractedData?.items ?? [];
                      if (currentIndex < items.length) {
                        apiItem = items[currentIndex];
                        break;
                      }
                      currentIndex -= items.length;
                    }

                    return context.isMobile
                        ? Container(
                            color: r.hasWarning ? const Color(0xFFFFFBEB) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.modelCode.isEmpty ? r.productName : r.modelCode,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 60, child: Text('${r.qty}', style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )
                        : Container(
                            color: r.hasWarning ? const Color(0xFFFFFBEB) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            child: Row(
                              children: [
                                // Product name / model code — takes remaining space
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    r.modelCode.isEmpty ? r.productName : r.modelCode,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 46, child: Text('${r.qty}', style: const TextStyle(fontSize: 12))),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    r.color.isEmpty ? '–' : r.color,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 72, child: Text('\$${r.unitPrice.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12))),
                                SizedBox(
                                  width: 58,
                                  child: Text('${apiItem?.piecesPerCarton ?? '–'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ),
                                SizedBox(
                                  width: 62,
                                  child: Text(
                                    apiItem?.grossWeightKg?.toStringAsFixed(1) ?? '–',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: Row(
                                    children: [
                                      Text('\$${r.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                      if (r.hasWarning) ...[
                                        const SizedBox(width: 3),
                                        const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFF59E0B)),
                                      ],
                                    ],
                                  ),
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
            if (rows.any((r) => r.hasWarning))
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${rows.where((r) => r.hasWarning).length} ${l10n.rowsWithMissingData}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            const Spacer(),
            Text(
              'Total: ${rows.length} items',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                onPressed: () => widget.onConfirm(rows, _firstResponse, List.unmodifiable(_responses)),
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

  Widget _buildError(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'OCR Failed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
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
        const SizedBox(height: 8),
      ],
    );
  }

  // Helper: table header cell
  Widget _th(String text, double? width, {int? flex}) {
    final cell = Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      overflow: TextOverflow.ellipsis,
    );
    if (flex != null) return Expanded(flex: flex, child: cell);
    if (width == null) return cell;
    return SizedBox(width: width, child: cell);
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6366F1)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: context.isMobile ? 10 : 12, fontWeight: FontWeight.w500, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }
}

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

// ── Mobile info item ─────────────────────────────────────────────────────────

class _MobileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _MobileInfoItem({required this.icon, required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                  color: isHighlight ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final String invoiceId;
  final VoidCallback onDeleted;
  const _DeleteButton({required this.invoiceId, required this.onDeleted});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Invoice',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        content: const Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _confirmAndDelete(context),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      tooltip: 'Delete invoice',
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        backgroundColor: const Color(0xFFFEF2F2),
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(32, 32),
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
