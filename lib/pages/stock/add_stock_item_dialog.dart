import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/stocks/cubit/stocks_cubit.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/l10n/app_localizations.dart';

class AddStockItemDialog extends StatefulWidget {
  final List<InventoryModel> inventories;
  final String? defaultInventoryId;
  final StocksCubit cubit;

  const AddStockItemDialog({super.key, required this.inventories, required this.defaultInventoryId, required this.cubit});

  @override
  State<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<AddStockItemDialog> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _productNameCtrl = TextEditingController();
  final _modelCodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _colorCodeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _barcodeCtrl = TextEditingController();
  final _invoicePriceCtrl = TextEditingController();

  InventoryModel? _selectedInventory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-select logged-in user's inventory
    if (widget.defaultInventoryId != null) {
      _selectedInventory = widget.inventories.where((i) => i.id == widget.defaultInventoryId).firstOrNull;
    }
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _modelCodeCtrl.dispose();
    _productCodeCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _colorCodeCtrl.dispose();
    _quantityCtrl.dispose();
    _barcodeCtrl.dispose();
    _invoicePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSubmitting = true);

    final request = CreateStockItemRequest(
      productName: _productNameCtrl.text.trim(),
      modelCode: _modelCodeCtrl.text.trim().isEmpty ? null : _modelCodeCtrl.text.trim(),
      productCode: _productCodeCtrl.text.trim().isEmpty ? null : _productCodeCtrl.text.trim(),
      size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      colorCode: _colorCodeCtrl.text.trim().isEmpty ? null : _colorCodeCtrl.text.trim(),
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      barcode: _barcodeCtrl.text.trim(),
      inventory: _selectedInventory!.id,
      invoiceUnitPriceAzn: double.tryParse(_invoicePriceCtrl.text.trim()),
    );

    final result = await widget.cubit.createStock(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.stockItemCreateFailed(message)), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inventory selector
                      _sectionLabel('Inventory'),
                      const SizedBox(height: 8),
                      _buildInventoryDropdown(l10n),
                      const SizedBox(height: 20),

                      // Product Name (required)
                      _buildField(controller: _productNameCtrl, label: l10n.productName, hint: 'e.g. 3 gang 1 way switch', required: true),
                      const SizedBox(height: 14),

                      // Model Code + Product Code
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(controller: _modelCodeCtrl, label: l10n.modelCode, hint: 'e.g. MDL-001'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildField(controller: _productCodeCtrl, label: l10n.productCode, hint: 'e.g. PRD-001'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Size + Color + Color Code
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(controller: _sizeCtrl, label: l10n.size, hint: 'e.g. M'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildField(controller: _colorCtrl, label: l10n.color, hint: 'e.g. Black'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildField(controller: _colorCodeCtrl, label: l10n.colorCode, hint: 'e.g. BLK'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quantity + Barcode
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: _buildField(
                              controller: _quantityCtrl,
                              label: l10n.quantity,
                              hint: '1',
                              required: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final n = int.tryParse(v);
                                if (n == null || n < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildField(controller: _barcodeCtrl, label: l10n.barcode, hint: 'e.g. AY-000001', required: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Invoice Price AZN
                      SizedBox(
                        width: 200,
                        child: _buildField(
                          controller: _invoicePriceCtrl,
                          label: l10n.invoicePriceAznLabel,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_box_rounded, color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.addStockItem,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const Spacer(),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, size: 20), color: const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildInventoryDropdown(AppLocalizations l10n) {
    final inv = _selectedInventory;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.warehouse_rounded, size: 16, color: Color(0xFF6366F1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              inv?.name ?? '—',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 10, color: Color(0xFF6366F1)),
                SizedBox(width: 3),
                Text(
                  'Your inventory',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSubmitting || _selectedInventory == null ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.addStockItem, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.4),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
        ),
      ],
    );
  }
}
