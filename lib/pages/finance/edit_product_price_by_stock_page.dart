import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Mock data ────────────────────────────────────────────────────────────────

class StockLocation {
  final String id;
  final String name;

  const StockLocation({required this.id, required this.name});
}

const List<StockLocation> _mockStocks = [
  StockLocation(id: '1', name: 'Sederek mağaza'),
  StockLocation(id: '2', name: 'Bakı mərkəz mağaza'),
  StockLocation(id: '3', name: 'Gəncə filialı'),
  StockLocation(id: '4', name: 'Sumqayıt mağaza'),
];

class ProductStock {
  final String productCode;
  final String productName;
  final String barcode;
  final int quantity;
  double? invoicePrice;
  double? costPrice;
  double? wholesalePrice;
  double? retailPrice;

  ProductStock({
    required this.productCode,
    required this.productName,
    required this.barcode,
    required this.quantity,
    this.invoicePrice,
    this.costPrice,
    this.wholesalePrice,
    this.retailPrice,
  });
}

List<ProductStock> _getMockProducts(String stockId) {
  return [
    ProductStock(
      productCode: 'PRD001',
      productName: 'Qara köynək L',
      barcode: '4006381333931',
      quantity: 150,
      invoicePrice: 10.00,
      costPrice: 12.00,
      wholesalePrice: 15.00,
      retailPrice: 18.00,
    ),
    ProductStock(
      productCode: 'PRD002',
      productName: 'Ağ köynək M',
      barcode: '4006381333948',
      quantity: 120,
      invoicePrice: 12.50,
      costPrice: 15.00,
      wholesalePrice: 18.50,
      retailPrice: 22.00,
    ),
    ProductStock(
      productCode: 'PRD003',
      productName: 'Mavi cins XL',
      barcode: '4006381333955',
      quantity: 95,
      invoicePrice: 25.00,
      costPrice: 30.00,
      wholesalePrice: 37.00,
      retailPrice: 45.00,
    ),
    ProductStock(
      productCode: 'PRD004',
      productName: 'Qırmızı dress S',
      barcode: '4006381333962',
      quantity: 85,
      invoicePrice: 18.00,
      costPrice: 22.00,
      wholesalePrice: 27.00,
      retailPrice: 32.00,
    ),
    ProductStock(
      productCode: 'PRD005',
      productName: 'Yaşıl polo M',
      barcode: '4006381333979',
      quantity: 78,
      invoicePrice: 14.00,
      costPrice: 17.00,
      wholesalePrice: 21.00,
      retailPrice: 25.00,
    ),
  ];
}

// ── Page ─────────────────────────────────────────────────────────────────────

class EditProductPriceByStockPage extends StatefulWidget {
  const EditProductPriceByStockPage({super.key});

  @override
  State<EditProductPriceByStockPage> createState() => _EditProductPriceByStockPageState();
}

class _EditProductPriceByStockPageState extends State<EditProductPriceByStockPage> {
  StockLocation? _selectedStock;
  String _searchQuery = '';
  List<ProductStock> _products = [];

  List<ProductStock> get _filtered {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      return p.productCode.toLowerCase().contains(q) || p.productName.toLowerCase().contains(q) || p.barcode.contains(q);
    }).toList();
  }

  void _onStockChanged(StockLocation? stock) {
    setState(() {
      _selectedStock = stock;
      if (stock != null) {
        _products = _getMockProducts(stock.id);
      } else {
        _products = [];
      }
    });
  }

  void _showEditPriceDialog(ProductStock product) {
    final l10n = AppLocalizations.of(context)!;

    // Controllers initialized with current prices
    final costPctCtrl = TextEditingController();
    final costAmtCtrl = TextEditingController();
    final wholePctCtrl = TextEditingController();
    final wholeAmtCtrl = TextEditingController();
    final retailPctCtrl = TextEditingController();
    final retailAmtCtrl = TextEditingController();

    // Pre-fill values based on existing prices
    if (product.invoicePrice != null && product.costPrice != null) {
      final costDiff = product.costPrice! - product.invoicePrice!;
      final costPct = (costDiff / product.invoicePrice!) * 100;
      costPctCtrl.text = costPct.toStringAsFixed(2);
      costAmtCtrl.text = costDiff.toStringAsFixed(2);
    }

    if (product.costPrice != null && product.wholesalePrice != null) {
      final wholeDiff = product.wholesalePrice! - product.costPrice!;
      final wholePct = (wholeDiff / product.costPrice!) * 100;
      wholePctCtrl.text = wholePct.toStringAsFixed(2);
      wholeAmtCtrl.text = wholeDiff.toStringAsFixed(2);
    }

    if (product.costPrice != null && product.retailPrice != null) {
      final retailDiff = product.retailPrice! - product.costPrice!;
      final retailPct = (retailDiff / product.costPrice!) * 100;
      retailPctCtrl.text = retailPct.toStringAsFixed(2);
      retailAmtCtrl.text = retailDiff.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editPrices,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(product.productName, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // Product info
              _buildInfoRow(l10n.productCode, product.productCode),
              _buildInfoRow(l10n.barcodeColumn, product.barcode),
              _buildInfoRow(l10n.quantityColumn, '${product.quantity}'),
              const SizedBox(height: 20),

              // Price calculation blocks
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalcBlock(
                        title: l10n.costPriceStep,
                        basePrice: product.invoicePrice ?? 0,
                        resultLabel: l10n.costPriceLabel,
                        pctCtrl: costPctCtrl,
                        amtCtrl: costAmtCtrl,
                        accentColor: const Color(0xFF6366F1),
                        onChanged: () {
                          final pct = double.tryParse(costPctCtrl.text);
                          final amt = double.tryParse(costAmtCtrl.text);
                          if (pct != null && product.invoicePrice != null) {
                            final newAmt = product.invoicePrice! * pct / 100;
                            if (costAmtCtrl.text != newAmt.toStringAsFixed(2)) {
                              costAmtCtrl.text = newAmt.toStringAsFixed(2);
                            }
                          } else if (amt != null && product.invoicePrice != null) {
                            final newPct = (amt / product.invoicePrice!) * 100;
                            if (costPctCtrl.text != newPct.toStringAsFixed(2)) {
                              costPctCtrl.text = newPct.toStringAsFixed(2);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCalcBlock(
                        title: l10n.wholesalePriceStep,
                        basePrice: product.costPrice ?? 0,
                        resultLabel: l10n.wholesalePriceLabel,
                        pctCtrl: wholePctCtrl,
                        amtCtrl: wholeAmtCtrl,
                        accentColor: const Color(0xFF0EA5E9),
                        onChanged: () {
                          final pct = double.tryParse(wholePctCtrl.text);
                          final amt = double.tryParse(wholeAmtCtrl.text);
                          if (pct != null && product.costPrice != null) {
                            final newAmt = product.costPrice! * pct / 100;
                            if (wholeAmtCtrl.text != newAmt.toStringAsFixed(2)) {
                              wholeAmtCtrl.text = newAmt.toStringAsFixed(2);
                            }
                          } else if (amt != null && product.costPrice != null) {
                            final newPct = (amt / product.costPrice!) * 100;
                            if (wholePctCtrl.text != newPct.toStringAsFixed(2)) {
                              wholePctCtrl.text = newPct.toStringAsFixed(2);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCalcBlock(
                        title: l10n.retailPriceStep,
                        basePrice: product.costPrice ?? 0,
                        resultLabel: l10n.retailPriceLabel,
                        pctCtrl: retailPctCtrl,
                        amtCtrl: retailAmtCtrl,
                        accentColor: const Color(0xFF10B981),
                        onChanged: () {
                          final pct = double.tryParse(retailPctCtrl.text);
                          final amt = double.tryParse(retailAmtCtrl.text);
                          if (pct != null && product.costPrice != null) {
                            final newAmt = product.costPrice! * pct / 100;
                            if (retailAmtCtrl.text != newAmt.toStringAsFixed(2)) {
                              retailAmtCtrl.text = newAmt.toStringAsFixed(2);
                            }
                          } else if (amt != null && product.costPrice != null) {
                            final newPct = (amt / product.costPrice!) * 100;
                            if (retailPctCtrl.text != newPct.toStringAsFixed(2)) {
                              retailPctCtrl.text = newPct.toStringAsFixed(2);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(l10n.no, style: const TextStyle(color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      // Update prices
                      setState(() {
                        final costAmt = double.tryParse(costAmtCtrl.text);
                        final wholeAmt = double.tryParse(wholeAmtCtrl.text);
                        final retailAmt = double.tryParse(retailAmtCtrl.text);

                        if (costAmt != null && product.invoicePrice != null) {
                          product.costPrice = product.invoicePrice! + costAmt;
                        }
                        if (wholeAmt != null && product.costPrice != null) {
                          product.wholesalePrice = product.costPrice! + wholeAmt;
                        }
                        if (retailAmt != null && product.costPrice != null) {
                          product.retailPrice = product.costPrice! + retailAmt;
                        }
                      });
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.confirm),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcBlock({
    required String title,
    required double basePrice,
    required String resultLabel,
    required TextEditingController pctCtrl,
    required TextEditingController amtCtrl,
    required Color accentColor,
    required VoidCallback onChanged,
  }) {
    final pct = double.tryParse(pctCtrl.text);
    final amt = double.tryParse(amtCtrl.text);
    final result = (pct != null && amt != null) ? basePrice + amt : null;

    return Container(
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
              SizedBox(
                width: 90,
                child: TextField(
                  controller: pctCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (_) => onChanged(),
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
              SizedBox(
                width: 90,
                child: TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (_) => onChanged(),
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
              Text(
                result != null ? '${result.toStringAsFixed(2)} ₼' : '— ₼',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: result != null ? accentColor : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTable() {
    final l10n = AppLocalizations.of(context)!;
    final rows = _filtered.take(5).toList();
    final isMobile = context.isMobile;

    if (_selectedStock == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(l10n.selectStock, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(l10n.noResultsFound, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => GestureDetector(onTap: () => _showEditPriceDialog(rows[i]), child: _buildMobileCard(rows[i])),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(l10n.productCode, style: _headerStyle)),
                  Expanded(flex: 2, child: Text(l10n.productNameColumn, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.quantityColumn, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.barcodeColumn, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.invoicePriceAzn, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.costPrice, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.wholesalePrice, style: _headerStyle)),
                  Expanded(flex: 1, child: Text(l10n.retailPrice, style: _headerStyle)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, i) {
                  final p = rows[i];
                  return InkWell(
                    onTap: () => _showEditPriceDialog(p),
                    child: Container(
                      color: i.isEven ? Colors.white : const Color(0xFFFAFAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(p.productCode, style: _cellStyle, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.productName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Text('${p.quantity}', style: _cellStyle)),
                          Expanded(flex: 1, child: Text(p.barcode, style: _monoStyle)),
                          Expanded(flex: 1, child: _priceCell(p.invoicePrice)),
                          Expanded(flex: 1, child: _priceCell(p.costPrice)),
                          Expanded(flex: 1, child: _priceCell(p.wholesalePrice)),
                          Expanded(flex: 1, child: _priceCell(p.retailPrice)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(ProductStock p) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    Text(p.productCode, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _cardRow(Icons.qr_code_outlined, p.barcode),
          const SizedBox(height: 6),
          _cardRow(Icons.inventory_outlined, '${l10n.quantityColumn}: ${p.quantity}'),
          const SizedBox(height: 6),
          _cardRow(Icons.attach_money, '${l10n.invoicePriceAzn}: ${p.invoicePrice?.toStringAsFixed(2) ?? '-'} ₼'),
          const SizedBox(height: 6),
          _cardRow(Icons.monetization_on_outlined, '${l10n.costPrice}: ${p.costPrice?.toStringAsFixed(2) ?? '-'} ₼'),
        ],
      ),
    );
  }

  Widget _cardRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _priceCell(double? price) {
    return Text(
      price != null ? '${price.toStringAsFixed(2)} ₼' : '—',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: price != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
    );
  }

  TextStyle get _headerStyle => const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569));
  TextStyle get _cellStyle => const TextStyle(fontSize: 13, color: Color(0xFF334155));
  TextStyle get _monoStyle => const TextStyle(fontSize: 13, color: Color(0xFF334155), fontFamily: 'monospace');

  void _confirmPrices() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
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
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

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
        title: Text(
          l10n.editProductPrices,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Padding(
        padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StockLocation>(
                  value: _selectedStock,
                  hint: Text(l10n.selectStockHint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
                  items: _mockStocks.map((stock) {
                    return DropdownMenuItem(
                      value: stock,
                      child: Text(stock.name, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                    );
                  }).toList(),
                  onChanged: _onStockChanged,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search field
            if (_selectedStock != null) ...[
              SizedBox(
                height: 44,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                l10n.top5Products,
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
            ],

            // Table
            Expanded(child: _buildProductsTable()),

            // Confirm button
            if (_selectedStock != null && _filtered.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirmPrices,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(l10n.confirm),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
