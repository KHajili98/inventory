import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/returned_products/data/repositories/returned_products_repository.dart';
import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';
import 'package:inventory/features/selling_transactions/data/repositories/selling_transactions_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';

class AddReturnedProductDialog extends StatefulWidget {
  const AddReturnedProductDialog({super.key});

  @override
  State<AddReturnedProductDialog> createState() => _AddReturnedProductDialogState();
}

class _AddReturnedProductDialogState extends State<AddReturnedProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _receiptController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  bool _isDefected = false;
  bool _isSubmitting = false;
  bool _isValidatingReceipt = false;
  SellingTransactionResponse? _receiptData;
  String? _receiptError;
  String? _barcodeError;

  @override
  void dispose() {
    _receiptController.dispose();
    _barcodeController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _validateReceipt() async {
    final receiptNumber = _receiptController.text.trim();
    if (receiptNumber.isEmpty) {
      setState(() {
        _receiptData = null;
        _receiptError = null;
        _barcodeError = null;
      });
      return;
    }

    setState(() {
      _isValidatingReceipt = true;
      _receiptError = null;
      _barcodeError = null;
    });

    final result = await SellingTransactionsRepository.instance.fetchReceiptByNumber(receiptNumber);

    if (!mounted) return;

    setState(() {
      _isValidatingReceipt = false;
      switch (result) {
        case Success(:final data):
          if (data == null) {
            _receiptError = AppLocalizations.of(context)!.receiptNotFound;
            _receiptData = null;
          } else {
            _receiptData = data;
            _receiptError = null;
          }
        case Failure(:final message):
          _receiptError = message;
          _receiptData = null;
      }
    });

    // Re-validate barcode if it was already entered
    if (_barcodeController.text.isNotEmpty) {
      _validateBarcode();
    }
  }

  void _validateBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty || _receiptData == null) {
      setState(() => _barcodeError = null);
      return;
    }

    // Check if barcode exists in receipt items
    final foundItem = _receiptData!.items.cast<SellingTransactionItemResponse?>().firstWhere((item) => item?.barcode == barcode, orElse: () => null);

    setState(() {
      if (foundItem == null) {
        _barcodeError = AppLocalizations.of(context)!.barcodeNotFoundInReceipt;
      } else {
        _barcodeError = null;
        // Validate count as well
        _validateCount(foundItem);
      }
    });
  }

  void _validateCount(SellingTransactionItemResponse? item) {
    if (item == null) return;

    final count = int.tryParse(_countController.text);
    if (count != null && count > item.count) {
      // This will be shown in the validator
    }
  }

  Future<void> _showConfirmationDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Text(l10n.confirmReturn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(l10n.receiptNumber, _receiptController.text.trim()),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.barcode, _barcodeController.text.trim()),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.quantity, _countController.text),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.status, _isDefected ? l10n.defectedProduct : l10n.normal),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitReturnedProduct();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        ),
      ],
    );
  }

  Future<void> _submitReturnedProduct() async {
    setState(() => _isSubmitting = true);

    // Find the product UUID from the receipt item
    final barcode = _barcodeController.text.trim();
    final item = _receiptData!.items.firstWhere((item) => item.barcode == barcode);

    final result = await ReturnedProductsRepository.instance.createReturnedProduct(
      returnedProductBarcode: barcode,
      productUuid: item.productUuid, // Use the actual product UUID from receipt
      count: int.parse(_countController.text),
      isDefected: _isDefected,
      receiptNumber: _receiptController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.returnedProductAdded), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Return true to indicate success
        }
      case Failure(:final message):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
        }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    await _showConfirmationDialog();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.addReturnedProduct,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Number
                      Text(
                        l10n.receiptNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _receiptController,
                        onChanged: (_) => _validateReceipt(),
                        decoration: InputDecoration(
                          hintText: l10n.enterReceiptNumber,
                          prefixIcon: const Icon(Icons.receipt_rounded, color: Color(0xFF94A3B8), size: 20),
                          suffixIcon: _isValidatingReceipt
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : _receiptData != null
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _receiptError != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _receiptError != null ? const Color(0xFFEF4444) : const Color(0xFF6366F1), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return l10n.fieldRequired;
                          if (_receiptError != null) return _receiptError;
                          return null;
                        },
                      ),
                      if (_receiptData != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                l10n.productsInReceipt(_receiptData!.items.length),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ),

                      // Barcode
                      const SizedBox(height: 20),
                      Text(
                        l10n.barcode,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _barcodeController,
                        onChanged: (_) => _validateBarcode(),
                        decoration: InputDecoration(
                          hintText: l10n.enterBarcode,
                          prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF94A3B8), size: 20),
                          suffixIcon: _barcodeError == null && _barcodeController.text.isNotEmpty && _receiptData != null
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _barcodeError != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _barcodeError != null ? const Color(0xFFEF4444) : const Color(0xFF6366F1), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return l10n.fieldRequired;
                          if (_barcodeError != null) return _barcodeError;
                          return null;
                        },
                      ),
                      if (_barcodeController.text.isNotEmpty && _receiptData != null && _barcodeError == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Builder(
                            builder: (context) {
                              final item = _receiptData!.items.cast<SellingTransactionItemResponse?>().firstWhere(
                                (item) => item?.barcode == _barcodeController.text.trim(),
                                orElse: () => null,
                              );
                              if (item == null) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 4),
                                  Text(l10n.availableInReceipt(item.count), style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
                                ],
                              );
                            },
                          ),
                        ),

                      // Count
                      const SizedBox(height: 20),
                      Text(
                        l10n.quantity,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) {
                          if (_receiptData != null && _barcodeController.text.isNotEmpty) {
                            final item = _receiptData!.items.cast<SellingTransactionItemResponse?>().firstWhere(
                              (item) => item?.barcode == _barcodeController.text.trim(),
                              orElse: () => null,
                            );
                            if (item != null) {
                              _validateCount(item);
                            }
                          }
                        },
                        decoration: InputDecoration(
                          hintText: l10n.enterQuantity,
                          prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF94A3B8), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return l10n.fieldRequired;
                          final count = int.tryParse(value!);
                          if (count == null || count <= 0) return l10n.invalidNumber;

                          // Validate against receipt quantity
                          if (_receiptData != null && _barcodeController.text.isNotEmpty) {
                            final item = _receiptData!.items.cast<SellingTransactionItemResponse?>().firstWhere(
                              (item) => item?.barcode == _barcodeController.text.trim(),
                              orElse: () => null,
                            );
                            if (item != null && count > item.count) {
                              return l10n.quantityExceedsReceipt(item.count);
                            }
                          }

                          return null;
                        },
                      ),

                      // Is Defected Checkbox
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _isDefected = !_isDefected),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDefected ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _isDefected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isDefected,
                                  onChanged: (value) => setState(() => _isDefected = value ?? false),
                                  activeColor: const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.defectedProduct,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(l10n.markAsDefected, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l10n.cancel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(l10n.add, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
