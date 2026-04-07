import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Custom formatter: max 10 digits, max 2 decimal places ────────────────────

class _DecimalInputFormatter extends TextInputFormatter {
  final int maxDigits;
  final int maxDecimals;

  const _DecimalInputFormatter({this.maxDigits = 10, this.maxDecimals = 3});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Allow clearing
    if (text.isEmpty) return newValue;

    // Only digits and a single dot
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    // Only one leading dot → reject
    if (text == '.') return oldValue;

    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    // Integer digits must not exceed maxDigits
    if (intPart.length > maxDigits) return oldValue;

    // Decimal part must not exceed maxDecimals digits
    if (decPart != null && decPart.length > maxDecimals) return oldValue;

    return newValue;
  }
}

// ── Per-product calculation state ────────────────────────────────────────────

class _ProductCalcState {
  // Cost price block
  final TextEditingController costPctCtrl = TextEditingController();
  final TextEditingController costAmtCtrl = TextEditingController();

  // Wholesale block
  final TextEditingController wholePctCtrl = TextEditingController();
  final TextEditingController wholeAmtCtrl = TextEditingController();

  // Retail block
  final TextEditingController retailPctCtrl = TextEditingController();
  final TextEditingController retailAmtCtrl = TextEditingController();

  double? costPrice;
  double? wholePrice;
  double? retailPrice;

  void dispose() {
    costPctCtrl.dispose();
    costAmtCtrl.dispose();
    wholePctCtrl.dispose();
    wholeAmtCtrl.dispose();
    retailPctCtrl.dispose();
    retailAmtCtrl.dispose();
  }

  bool get isComplete => costPrice != null && wholePrice != null && retailPrice != null;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class CalculationDetailPage extends StatefulWidget {
  final StockProductItemModel item;
  final VoidCallback? onSuccess;

  const CalculationDetailPage({super.key, required this.item, this.onSuccess});

  @override
  State<CalculationDetailPage> createState() => _CalculationDetailPageState();
}

class _CalculationDetailPageState extends State<CalculationDetailPage> {
  late final _ProductCalcState _state = _ProductCalcState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  // ── Sync helpers ─────────────────────────────────────────────────────────

  void _onPctChanged(double base, TextEditingController pctCtrl, TextEditingController amtCtrl, VoidCallback onDone) {
    final pct = double.tryParse(pctCtrl.text);
    if (pct == null) return;
    final amt = base * pct / 100;
    final formatted = _fmt(amt);
    if (amtCtrl.text != formatted) {
      amtCtrl.text = formatted;
      amtCtrl.selection = TextSelection.collapsed(offset: formatted.length);
    }
    onDone();
  }

  void _onAmtChanged(double base, TextEditingController pctCtrl, TextEditingController amtCtrl, VoidCallback onDone) {
    final amt = double.tryParse(amtCtrl.text);
    if (amt == null) return;
    final pct = base > 0 ? (amt / base * 100) : 0.0;
    final formatted = _fmt(pct);
    if (pctCtrl.text != formatted) {
      pctCtrl.text = formatted;
      pctCtrl.selection = TextSelection.collapsed(offset: formatted.length);
    }
    onDone();
  }

  String _fmt(double v) {
    // Round to 3 decimal places to avoid floating-point noise (e.g. 12.2000000001)
    final rounded = double.parse(v.toStringAsFixed(3));
    if (rounded == rounded.truncateToDouble()) return rounded.toInt().toString();
    return rounded.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  static double _round3(double v) => double.parse(v.toStringAsFixed(3));

  Future<void> _submitPrices() async {
    final l10n = AppLocalizations.of(context)!;
    final s = _state;

    // Show loading dialog on the same navigator as this page (not root)
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await StocksRepository.instance.pricingStock(
      item: widget.item,
      costUnitPrice: s.costPrice!,
      wholeUnitSalesPrice: s.wholePrice!,
      retailUnitPrice: s.retailPrice!,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    switch (result) {
      case Success():
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.confirmationTitle),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(); // back to list
      case Failure(:final message):
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Text(l10n.errorTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(l10n.okLabel),
                ),
              ],
            );
          },
        );
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  void _showConfirmDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmationTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(l10n.confirmCalculationMessage, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n.no, style: const TextStyle(color: Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitPrices();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(l10n.yesConfirm),
          ),
        ],
      ),
    );
  }

  // ── Item info header ──────────────────────────────────────────────────────

  Widget _buildItemInfoHeader(AppLocalizations l10n) {
    final item = widget.item;
    final invoicePrice = item.invoiceUnitPriceAzn;

    // Color swatch
    Color? swatch;
    final code = item.colorCode ?? '';
    if (code.startsWith('#') && code.length == 7) {
      try {
        swatch = Color(int.parse(code.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.productGeneratedName ?? item.productName ?? item.id,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          // Details grid
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              if (item.modelCode != null) _infoChip(l10n.modelCode, item.modelCode!),
              if (item.productCode != null) _infoChip(l10n.productCode, item.productCode!),
              if (item.barcode != null) _infoChip(l10n.barcode, item.barcode!),
              if (item.size != null) _infoChip(l10n.size, item.size!),
              _infoChipWidget(
                l10n.color,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (swatch != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(item.color ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                  ],
                ),
              ),
              _infoChip(l10n.quantity, '${item.quantity}'),
              _infoChip(l10n.sourceInventory, item.inventoryName.isNotEmpty ? item.inventoryName : '—'),
              _infoChip(l10n.invoicePriceAznLabel, invoicePrice != null ? '₼ ${invoicePrice.toStringAsFixed(2)}' : '—', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, {bool highlight = false}) {
    return _infoChipWidget(
      label,
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
          color: highlight ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _infoChipWidget(String label, Widget valueWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }

  // ── Calculation block ─────────────────────────────────────────────────────

  Widget _buildCalcBlock({
    required String title,
    required double basePrice,
    required String resultLabel,
    required double? resultValue,
    required bool enabled,
    required TextEditingController pctCtrl,
    required TextEditingController amtCtrl,
    required VoidCallback onPctChanged,
    required VoidCallback onAmtChanged,
    required Color accentColor,
  }) {
    final resultText = resultValue != null ? '${resultValue.toStringAsFixed(2)} ₼  $resultLabel' : '— $resultLabel';

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Base price chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${basePrice.toStringAsFixed(2)} ₼',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
                const Text(
                  '+',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                // Percent field
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: pctCtrl,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [const _DecimalInputFormatter(maxDigits: 10, maxDecimals: 3)],
                    onChanged: (_) => onPctChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      suffixText: '%',
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        borderSide: BorderSide(color: accentColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                // Amount field
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: amtCtrl,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [const _DecimalInputFormatter(maxDigits: 10, maxDecimals: 3)],
                    onChanged: (_) => onAmtChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      suffixText: '₼',
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        borderSide: BorderSide(color: accentColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  '=',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                // Result
                Text(
                  resultText,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: resultValue != null ? accentColor : const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Calculation card ──────────────────────────────────────────────────────

  Widget _buildCalcCard(AppLocalizations l10n) {
    final s = _state;
    final invoicePrice = widget.item.invoiceUnitPriceAzn ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.priceCalculationTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),

          // 1. Cost price
          _buildCalcBlock(
            title: l10n.costPriceStep,
            basePrice: invoicePrice,
            resultLabel: l10n.costPriceLabel,
            resultValue: s.costPrice,
            enabled: true,
            pctCtrl: s.costPctCtrl,
            amtCtrl: s.costAmtCtrl,
            accentColor: const Color(0xFF6366F1),
            onPctChanged: () {
              _onPctChanged(invoicePrice, s.costPctCtrl, s.costAmtCtrl, () {
                final amt = double.tryParse(s.costAmtCtrl.text);
                setState(() => s.costPrice = amt != null ? _round3(invoicePrice + amt) : null);
              });
            },
            onAmtChanged: () {
              _onAmtChanged(invoicePrice, s.costPctCtrl, s.costAmtCtrl, () {
                final amt = double.tryParse(s.costAmtCtrl.text);
                setState(() => s.costPrice = amt != null ? _round3(invoicePrice + amt) : null);
              });
            },
          ),
          const SizedBox(height: 10),

          // 2. Wholesale
          _buildCalcBlock(
            title: l10n.wholesalePriceStep,
            basePrice: s.costPrice ?? 0,
            resultLabel: l10n.wholesalePriceLabel,
            resultValue: s.wholePrice,
            enabled: s.costPrice != null,
            pctCtrl: s.wholePctCtrl,
            amtCtrl: s.wholeAmtCtrl,
            accentColor: const Color(0xFF0EA5E9),
            onPctChanged: () {
              if (s.costPrice == null) return;
              _onPctChanged(s.costPrice!, s.wholePctCtrl, s.wholeAmtCtrl, () {
                final amt = double.tryParse(s.wholeAmtCtrl.text);
                setState(() => s.wholePrice = amt != null ? _round3(s.costPrice! + amt) : null);
              });
            },
            onAmtChanged: () {
              if (s.costPrice == null) return;
              _onAmtChanged(s.costPrice!, s.wholePctCtrl, s.wholeAmtCtrl, () {
                final amt = double.tryParse(s.wholeAmtCtrl.text);
                setState(() => s.wholePrice = amt != null ? _round3(s.costPrice! + amt) : null);
              });
            },
          ),
          const SizedBox(height: 10),

          // 3. Retail
          _buildCalcBlock(
            title: l10n.retailPriceStep,
            basePrice: s.costPrice ?? 0,
            resultLabel: l10n.retailPriceLabel,
            resultValue: s.retailPrice,
            enabled: s.costPrice != null,
            pctCtrl: s.retailPctCtrl,
            amtCtrl: s.retailAmtCtrl,
            accentColor: const Color(0xFF10B981),
            onPctChanged: () {
              if (s.costPrice == null) return;
              _onPctChanged(s.costPrice!, s.retailPctCtrl, s.retailAmtCtrl, () {
                final amt = double.tryParse(s.retailAmtCtrl.text);
                setState(() => s.retailPrice = amt != null ? _round3(s.costPrice! + amt) : null);
              });
            },
            onAmtChanged: () {
              if (s.costPrice == null) return;
              _onAmtChanged(s.costPrice!, s.retailPctCtrl, s.retailAmtCtrl, () {
                final amt = double.tryParse(s.retailAmtCtrl.text);
                setState(() => s.retailPrice = amt != null ? _round3(s.costPrice! + amt) : null);
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final allDone = _state.isComplete;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.productGeneratedName ?? widget.item.productName ?? widget.item.id,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.item.inventoryName.isNotEmpty) Text(widget.item.inventoryName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedOpacity(
              opacity: allDone ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: FilledButton.icon(
                onPressed: allDone ? _showConfirmDialog : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(isMobile ? l10n.confirm : l10n.confirmCalculation),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: const Color(0xFF6366F1),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: ListView(children: [_buildItemInfoHeader(l10n), const SizedBox(height: 16), _buildCalcCard(l10n), const SizedBox(height: 24)]),
      ),
    );
  }
}
