enum StockStatus { active, lowStock, outOfStock, pricePending }

class StockItem {
  final String id;
  final String modelCode;
  final String productName;
  final String productGeneratedName;
  final String productCode;
  final String size;
  final String color;
  final String colorCode;
  final int quantity;
  final String barcode;
  final String sourceInventoryName;
  final double? invoiceUnitPriceUsd;
  final double? costUnitPrice;
  final double? wholeUnitSalesPrice;
  final double? retailUnitPrice;
  final StockStatus status;

  StockItem({
    required this.id,
    required this.modelCode,
    required this.productName,
    required this.productGeneratedName,
    required this.productCode,
    required this.size,
    required this.color,
    required this.colorCode,
    required this.quantity,
    required this.barcode,
    required this.sourceInventoryName,
    this.invoiceUnitPriceUsd,
    this.costUnitPrice,
    this.wholeUnitSalesPrice,
    this.retailUnitPrice,
    required this.status,
  });

  StockItem copyWith({
    String? id,
    String? modelCode,
    String? productName,
    String? productGeneratedName,
    String? productCode,
    String? size,
    String? color,
    String? colorCode,
    int? quantity,
    String? barcode,
    String? sourceInventoryName,
    double? invoiceUnitPriceUsd,
    double? costUnitPrice,
    double? wholeUnitSalesPrice,
    double? retailUnitPrice,
    StockStatus? status,
  }) {
    return StockItem(
      id: id ?? this.id,
      modelCode: modelCode ?? this.modelCode,
      productName: productName ?? this.productName,
      productGeneratedName: productGeneratedName ?? this.productGeneratedName,
      productCode: productCode ?? this.productCode,
      size: size ?? this.size,
      color: color ?? this.color,
      colorCode: colorCode ?? this.colorCode,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      sourceInventoryName: sourceInventoryName ?? this.sourceInventoryName,
      invoiceUnitPriceUsd: invoiceUnitPriceUsd ?? this.invoiceUnitPriceUsd,
      costUnitPrice: costUnitPrice ?? this.costUnitPrice,
      wholeUnitSalesPrice: wholeUnitSalesPrice ?? this.wholeUnitSalesPrice,
      retailUnitPrice: retailUnitPrice ?? this.retailUnitPrice,
      status: status ?? this.status,
    );
  }

  static StockStatus determineStatus(int quantity, bool hasPrices) {
    if (!hasPrices) return StockStatus.pricePending;
    if (quantity == 0) return StockStatus.outOfStock;
    if (quantity <= 10) return StockStatus.lowStock;
    return StockStatus.active;
  }
}

class StockSummary {
  final int activeStockAmount;
  final int activeProductQuantity;
  final int pricePendingProductsQuantity;
  final int lowStockQuantity;
  final int outOfStockQuantity;

  StockSummary({
    required this.activeStockAmount,
    required this.activeProductQuantity,
    required this.pricePendingProductsQuantity,
    required this.lowStockQuantity,
    required this.outOfStockQuantity,
  });

  static StockSummary fromStockList(List<StockItem> items) {
    int activeAmount = 0;
    int activeProducts = 0;
    int pricePending = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (var item in items) {
      switch (item.status) {
        case StockStatus.active:
          activeAmount += item.quantity;
          activeProducts++;
          break;
        case StockStatus.pricePending:
          pricePending++;
          break;
        case StockStatus.lowStock:
          lowStock++;
          break;
        case StockStatus.outOfStock:
          outOfStock++;
          break;
      }
    }

    return StockSummary(
      activeStockAmount: activeAmount,
      activeProductQuantity: activeProducts,
      pricePendingProductsQuantity: pricePending,
      lowStockQuantity: lowStock,
      outOfStockQuantity: outOfStock,
    );
  }
}

// Mock data for demonstration
final List<StockItem> mockStockItems = [
  StockItem(
    id: '1',
    modelCode: 'MD-2024-001',
    productName: 'Cotton T-Shirt',
    productGeneratedName: 'Cotton T-Shirt Blue L',
    productCode: 'TSH-001',
    size: 'L',
    color: 'Blue',
    colorCode: '#0000FF',
    quantity: 150,
    barcode: '1234567890123',
    sourceInventoryName: 'Warehouse A',
    invoiceUnitPriceUsd: 12.50,
    costUnitPrice: 15.00,
    wholeUnitSalesPrice: 20.00,
    retailUnitPrice: 25.00,
    status: StockStatus.active,
  ),
  StockItem(
    id: '2',
    modelCode: 'MD-2024-002',
    productName: 'Denim Jeans',
    productGeneratedName: 'Denim Jeans Black 32',
    productCode: 'JNS-002',
    size: '32',
    color: 'Black',
    colorCode: '#000000',
    quantity: 8,
    barcode: '1234567890124',
    sourceInventoryName: 'Warehouse B',
    invoiceUnitPriceUsd: 25.00,
    costUnitPrice: 30.00,
    wholeUnitSalesPrice: 40.00,
    retailUnitPrice: 50.00,
    status: StockStatus.lowStock,
  ),
  StockItem(
    id: '3',
    modelCode: 'MD-2024-003',
    productName: 'Sneakers',
    productGeneratedName: 'Sneakers White 42',
    productCode: 'SNK-003',
    size: '42',
    color: 'White',
    colorCode: '#FFFFFF',
    quantity: 0,
    barcode: '1234567890125',
    sourceInventoryName: 'Warehouse A',
    invoiceUnitPriceUsd: 45.00,
    costUnitPrice: 55.00,
    wholeUnitSalesPrice: 70.00,
    retailUnitPrice: 85.00,
    status: StockStatus.outOfStock,
  ),
  StockItem(
    id: '4',
    modelCode: 'MD-2024-004',
    productName: 'Leather Jacket',
    productGeneratedName: 'Leather Jacket Brown XL',
    productCode: 'JKT-004',
    size: 'XL',
    color: 'Brown',
    colorCode: '#8B4513',
    quantity: 25,
    barcode: '1234567890126',
    sourceInventoryName: 'Warehouse C',
    invoiceUnitPriceUsd: 80.00,
    costUnitPrice: null,
    wholeUnitSalesPrice: null,
    retailUnitPrice: null,
    status: StockStatus.pricePending,
  ),
  StockItem(
    id: '5',
    modelCode: 'MD-2024-005',
    productName: 'Running Shoes',
    productGeneratedName: 'Running Shoes Red 40',
    productCode: 'RUN-005',
    size: '40',
    color: 'Red',
    colorCode: '#FF0000',
    quantity: 45,
    barcode: '1234567890127',
    sourceInventoryName: 'Warehouse B',
    invoiceUnitPriceUsd: 60.00,
    costUnitPrice: 72.00,
    wholeUnitSalesPrice: 90.00,
    retailUnitPrice: 110.00,
    status: StockStatus.active,
  ),
];
