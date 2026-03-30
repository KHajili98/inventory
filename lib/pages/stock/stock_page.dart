import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/product_requests/cubit/product_requests_cubit.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/stock_models.dart';
import 'package:inventory/pages/requests/add_stock_product_request.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final List<StockItem> _stockItems = mockStockItems;
  List<StockItem> _filteredItems = mockStockItems;
  String _selectedInventory = 'all';
  String _searchQuery = '';

  // Table column widths
  static const double _colModelCode = 140.0;
  static const double _colProductName = 180.0;
  static const double _colGeneratedName = 200.0;
  static const double _colProductCode = 120.0;
  static const double _colSize = 80.0;
  static const double _colColor = 100.0;
  static const double _colColorCode = 100.0;
  static const double _colQuantity = 100.0;
  static const double _colBarcode = 150.0;
  static const double _colSource = 150.0;
  static const double _colInvoicePrice = 130.0;
  static const double _colCostPrice = 120.0;
  static const double _colWholePrice = 140.0;
  static const double _colRetailPrice = 120.0;
  static const double _colStatus = 130.0;

  static double get _tableWidth =>
      _colModelCode +
      _colProductName +
      _colGeneratedName +
      _colProductCode +
      _colSize +
      _colColor +
      _colColorCode +
      _colQuantity +
      _colBarcode +
      _colSource +
      _colInvoicePrice +
      _colCostPrice +
      _colWholePrice +
      _colRetailPrice +
      _colStatus;

  final ScrollController _hScrollController = ScrollController();
  final ScrollController _hHeaderController = ScrollController();
  final ScrollController _vScrollController = ScrollController();

  bool _hSyncing = false;

  @override
  void initState() {
    super.initState();
    _hScrollController.addListener(_onHScroll);
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _hHeaderController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  void _onHScroll() {
    if (_hSyncing) return;
    _hSyncing = true;
    final offset = _hScrollController.offset;
    if (_hHeaderController.hasClients && _hHeaderController.offset != offset) {
      _hHeaderController.jumpTo(offset);
    }
    _hSyncing = false;
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _stockItems.where((item) {
        final matchesInventory = _selectedInventory == 'all' || item.sourceInventoryName == _selectedInventory;
        final matchesSearch =
            _searchQuery.isEmpty ||
            item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.modelCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.barcode.contains(_searchQuery);
        return matchesInventory && matchesSearch;
      }).toList();
    });
  }

  List<String> get _inventoryOptions {
    final inventories = _stockItems.map((item) => item.sourceInventoryName).toSet().toList();
    inventories.sort();
    return ['all', ...inventories];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;
    final summary = StockSummary.fromStockList(_stockItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header with stats cards
          Container(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                _buildStatsCards(context, summary, isMobile),
                const SizedBox(height: 20),

                // Inventory selector and search
                Row(
                  children: [
                    Expanded(
                      flex: isMobile ? 1 : 0,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedInventory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                            onChanged: (value) {
                              setState(() {
                                _selectedInventory = value!;
                                _filterItems();
                              });
                            },
                            items: _inventoryOptions.map((inventory) {
                              return DropdownMenuItem(
                                value: inventory,
                                child: Text(inventory == 'all' ? l10n.allInventories : inventory, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    if (!isMobile) const SizedBox(width: 12),
                    if (!isMobile)
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _filterItems();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: l10n.searchStock,
                              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    if (!isMobile) const SizedBox(width: 12),
                    if (!isMobile)
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => BlocProvider(create: (_) => ProductRequestsCubit(), child: const AddStockProductRequest()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(l10n.createStockRequest),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
                if (isMobile) const SizedBox(height: 12),
                if (isMobile)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => BlocProvider(create: (_) => ProductRequestsCubit(), child: const AddStockProductRequest()),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(l10n.createStockRequest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: context.responsivePadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  // Table header
                  SingleChildScrollView(
                    controller: _hHeaderController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      width: _tableWidth + 32,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: _buildTableHeader(l10n),
                    ),
                  ),

                  // Table body
                  Expanded(
                    child: Scrollbar(
                      controller: _vScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _vScrollController,
                        child: SingleChildScrollView(
                          controller: _hScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _tableWidth,
                            child: Column(children: _filteredItems.map((item) => _buildTableRow(item, l10n)).toList()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, StockSummary summary, bool isMobile) {
    final l10n = AppLocalizations.of(context)!;

    final cards = [
      _StatCard(
        title: l10n.activeStockAmount,
        value: summary.activeStockAmount.toString(),
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF10B981),
        isMobile: isMobile,
      ),
      _StatCard(
        title: l10n.activeProducts,
        value: summary.activeProductQuantity.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF6366F1),
        isMobile: isMobile,
      ),
      _StatCard(
        title: l10n.pricePending,
        value: summary.pricePendingProductsQuantity.toString(),
        icon: Icons.pending_rounded,
        color: const Color(0xFFF59E0B),
        isMobile: isMobile,
      ),
      _StatCard(
        title: l10n.lowStock,
        value: summary.lowStockQuantity.toString(),
        icon: Icons.warning_rounded,
        color: const Color(0xFFEF4444),
        isMobile: isMobile,
      ),
      _StatCard(
        title: l10n.outOfStock,
        value: summary.outOfStockQuantity.toString(),
        icon: Icons.cancel_rounded,
        color: const Color(0xFF64748B),
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
      );
    }

    return Wrap(spacing: 16, runSpacing: 16, children: cards);
  }

  Widget _buildTableHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: SizedBox(
        width: _tableWidth, // Subtract horizontal padding
        child: Row(
          children: [
            _buildHeaderCell(l10n.modelCode, _colModelCode),
            _buildHeaderCell(l10n.productName, _colProductName),
            _buildHeaderCell(l10n.generatedName, _colGeneratedName),
            _buildHeaderCell(l10n.productCode, _colProductCode),
            _buildHeaderCell(l10n.size, _colSize),
            _buildHeaderCell(l10n.color, _colColor),
            _buildHeaderCell(l10n.colorCode, _colColorCode),
            _buildHeaderCell(l10n.quantity, _colQuantity),
            _buildHeaderCell(l10n.barcode, _colBarcode),
            _buildHeaderCell(l10n.sourceInventory, _colSource),
            _buildHeaderCell(l10n.invoicePriceUsd, _colInvoicePrice),
            _buildHeaderCell(l10n.costPrice, _colCostPrice),
            _buildHeaderCell(l10n.wholesalePrice, _colWholePrice),
            _buildHeaderCell(l10n.retailPrice, _colRetailPrice),
            _buildHeaderCell(l10n.status, _colStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.3),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableRow(StockItem item, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SizedBox(
        width: _tableWidth - 32, // Subtract horizontal padding
        child: Row(
          children: [
            _buildCell(item.modelCode, _colModelCode),
            _buildCell(item.productName, _colProductName),
            _buildCell(item.productGeneratedName, _colGeneratedName),
            _buildCell(item.productCode, _colProductCode),
            _buildCell(item.size, _colSize),
            _buildCellWithColor(item.color, item.colorCode, _colColor),
            _buildCell(item.colorCode, _colColorCode, isColorCode: true),
            _buildCell(item.quantity.toString(), _colQuantity, bold: true),
            _buildCell(item.barcode, _colBarcode),
            _buildCell(item.sourceInventoryName, _colSource),
            _buildCell(item.invoiceUnitPriceUsd?.toStringAsFixed(2) ?? '-', _colInvoicePrice),
            _buildCell(item.costUnitPrice?.toStringAsFixed(2) ?? '-', _colCostPrice),
            _buildCell(item.wholeUnitSalesPrice?.toStringAsFixed(2) ?? '-', _colWholePrice),
            _buildCell(item.retailUnitPrice?.toStringAsFixed(2) ?? '-', _colRetailPrice),
            _buildStatusCell(item.status, _colStatus, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {bool bold = false, bool isColorCode = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isColorCode ? const Color(0xFF64748B) : const Color(0xFF1E293B),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCellWithColor(String colorName, String colorCode, double width) {
    Color? color;
    try {
      color = Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      color = Colors.grey;
    }

    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              colorName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(StockStatus status, double width, AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case StockStatus.active:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = l10n.activeStatus;
        break;
      case StockStatus.lowStock:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        label = l10n.lowStock;
        break;
      case StockStatus.outOfStock:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        label = l10n.outOfStock;
        break;
      case StockStatus.pricePending:
        bgColor = const Color(0xFFFED7AA);
        textColor = const Color(0xFF9A3412);
        label = l10n.pricePending;
        break;
    }

    return SizedBox(
      // width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
