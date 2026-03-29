import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/pages/finance/price_calculation_page.dart';

// ── Mock product model ───────────────────────────────────────────────────────

class CalcProduct {
  final String generatedName;
  final String barcode;
  final int receivedQty;
  final double invoicePerPrice;
  final String color;

  const CalcProduct({
    required this.generatedName,
    required this.barcode,
    required this.receivedQty,
    required this.invoicePerPrice,
    required this.color,
  });
}

const List<CalcProduct> _mockProducts = [
  CalcProduct(generatedName: 'Qara köynək L', barcode: '4006381333931', receivedQty: 50, invoicePerPrice: 10.00, color: 'Qara'),
  CalcProduct(generatedName: 'Ağ köynək M', barcode: '4006381333948', receivedQty: 30, invoicePerPrice: 12.50, color: 'Ağ'),
  CalcProduct(generatedName: 'Mavi cins XL', barcode: '4006381333955', receivedQty: 20, invoicePerPrice: 25.00, color: 'Mavi'),
  CalcProduct(generatedName: 'Qırmızı dress S', barcode: '4006381333962', receivedQty: 15, invoicePerPrice: 18.00, color: 'Qırmızı'),
];

// ── Per-product calculation state ────────────────────────────────────────────

class _ProductCalcState {
  // Cost price block
  final TextEditingController costPctCtrl = TextEditingController();
  final TextEditingController costAmtCtrl = TextEditingController();
  bool costLocked = false; // becomes true once both filled

  // Wholesale block
  final TextEditingController wholePctCtrl = TextEditingController();
  final TextEditingController wholeAmtCtrl = TextEditingController();
  bool wholeLocked = false;

  // Retail block
  final TextEditingController retailPctCtrl = TextEditingController();
  final TextEditingController retailAmtCtrl = TextEditingController();
  bool retailLocked = false;

  double? costPrice; // maya qiymet
  double? wholePrice; // topdan qiymet
  double? retailPrice; // perakende qiymet

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
  final PriceRequest request;

  const CalculationDetailPage({super.key, required this.request});

  @override
  State<CalculationDetailPage> createState() => _CalculationDetailPageState();
}

class _CalculationDetailPageState extends State<CalculationDetailPage> {
  late final List<_ProductCalcState> _states;

  @override
  void initState() {
    super.initState();
    _states = List.generate(_mockProducts.length, (_) => _ProductCalcState());
  }

  @override
  void dispose() {
    for (final s in _states) {
      s.dispose();
    }
    super.dispose();
  }

  bool get _allComplete => _states.every((s) => s.isComplete);

  // ── Sync helpers ─────────────────────────────────────────────────────────

  /// When percent changes → compute amount, and vice versa.
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
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Təsdiqləmə', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text('Hesablamaları təsdiqləmək istədiyinizə əminsiniz?', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Xeyr', style: TextStyle(color: Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // back to request list
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Bəli, təsdiqlə'),
          ),
        ],
      ),
    );
  }

  // ── Product table header ──────────────────────────────────────────────────

  Widget _buildProductTableHeader() {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569));
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Məhsul adı', style: style)),
          Expanded(flex: 2, child: Text('Barkod', style: style)),
          Expanded(flex: 1, child: Text('Miqdar', style: style)),
          Expanded(flex: 1, child: Text('Faktura qiyməti (AZN)', style: style)),
          Expanded(flex: 1, child: Text('Rəng', style: style)),
        ],
      ),
    );
  }

  Widget _buildProductTableRow(CalcProduct p, int index) {
    final isEven = index.isEven;
    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.generatedName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              p.barcode,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${p.receivedQty}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${p.invoicePerPrice.toStringAsFixed(2)} ₼',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _colorFromName(p.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                Text(p.color, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'qara':
        return Colors.black87;
      case 'ağ':
        return Colors.white;
      case 'mavi':
        return Colors.blue;
      case 'qırmızı':
        return Colors.red;
      default:
        return Colors.grey.shade300;
    }
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
          color: accentColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
            ),
            const SizedBox(height: 10),
            Row(
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                  ),
                ),
                // Percent field
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: pctCtrl,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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
                const SizedBox(width: 8),
                // Amount field
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: amtCtrl,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '=',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                  ),
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

  // ── Per-product card ─────────────────────────────────────────────────────

  Widget _buildProductCalcCard(int index) {
    final p = _mockProducts[index];
    final s = _states[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info header
          _buildProductTableHeader(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildProductTableRow(p, 0),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Calculation section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qiymət Hesablaması',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),

                // 1. Cost price (maya qiymet)
                _buildCalcBlock(
                  title: '1. Maya Qiymət',
                  basePrice: p.invoicePerPrice,
                  resultLabel: 'AZN  maya qiymət',
                  resultValue: s.costPrice,
                  enabled: true,
                  pctCtrl: s.costPctCtrl,
                  amtCtrl: s.costAmtCtrl,
                  accentColor: const Color(0xFF6366F1),
                  onPctChanged: () {
                    _onPctChanged(p.invoicePerPrice, s.costPctCtrl, s.costAmtCtrl, () {
                      final pct = double.tryParse(s.costPctCtrl.text);
                      final amt = double.tryParse(s.costAmtCtrl.text);
                      setState(() {
                        if (pct != null && amt != null) {
                          s.costPrice = p.invoicePerPrice + amt;
                        } else {
                          s.costPrice = null;
                        }
                      });
                    });
                  },
                  onAmtChanged: () {
                    _onAmtChanged(p.invoicePerPrice, s.costPctCtrl, s.costAmtCtrl, () {
                      final amt = double.tryParse(s.costAmtCtrl.text);
                      setState(() {
                        if (amt != null) {
                          s.costPrice = p.invoicePerPrice + amt;
                        } else {
                          s.costPrice = null;
                        }
                      });
                    });
                  },
                ),
                const SizedBox(height: 10),

                // 2. Wholesale (topdan)
                _buildCalcBlock(
                  title: '2. Topdan Qiymət',
                  basePrice: s.costPrice ?? 0,
                  resultLabel: 'AZN  topdan qiymət',
                  resultValue: s.wholePrice,
                  enabled: s.costPrice != null,
                  pctCtrl: s.wholePctCtrl,
                  amtCtrl: s.wholeAmtCtrl,
                  accentColor: const Color(0xFF0EA5E9),
                  onPctChanged: () {
                    if (s.costPrice == null) return;
                    _onPctChanged(s.costPrice!, s.wholePctCtrl, s.wholeAmtCtrl, () {
                      final amt = double.tryParse(s.wholeAmtCtrl.text);
                      setState(() {
                        s.wholePrice = amt != null ? s.costPrice! + amt : null;
                      });
                    });
                  },
                  onAmtChanged: () {
                    if (s.costPrice == null) return;
                    _onAmtChanged(s.costPrice!, s.wholePctCtrl, s.wholeAmtCtrl, () {
                      final amt = double.tryParse(s.wholeAmtCtrl.text);
                      setState(() {
                        s.wholePrice = amt != null ? s.costPrice! + amt : null;
                      });
                    });
                  },
                ),
                const SizedBox(height: 10),

                // 3. Retail (perakende)
                _buildCalcBlock(
                  title: '3. Pərakəndə Qiymət',
                  basePrice: s.costPrice ?? 0,
                  resultLabel: 'AZN  pərakəndə qiymət',
                  resultValue: s.retailPrice,
                  enabled: s.costPrice != null,
                  pctCtrl: s.retailPctCtrl,
                  amtCtrl: s.retailAmtCtrl,
                  accentColor: const Color(0xFF10B981),
                  onPctChanged: () {
                    if (s.costPrice == null) return;
                    _onPctChanged(s.costPrice!, s.retailPctCtrl, s.retailAmtCtrl, () {
                      final amt = double.tryParse(s.retailAmtCtrl.text);
                      setState(() {
                        s.retailPrice = amt != null ? s.costPrice! + amt : null;
                      });
                    });
                  },
                  onAmtChanged: () {
                    if (s.costPrice == null) return;
                    _onAmtChanged(s.costPrice!, s.retailPctCtrl, s.retailAmtCtrl, () {
                      final amt = double.tryParse(s.retailAmtCtrl.text);
                      setState(() {
                        s.retailPrice = amt != null ? s.costPrice! + amt : null;
                      });
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final allDone = _allComplete;

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
              widget.request.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            Text(widget.request.source, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                label: Text(isMobile ? 'Təsdiqlə' : 'Hesablamanı Təsdiqlə'),
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
        child: ListView.builder(itemCount: _mockProducts.length, itemBuilder: (context, i) => _buildProductCalcCard(i)),
      ),
    );
  }
}
