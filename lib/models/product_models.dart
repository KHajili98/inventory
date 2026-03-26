enum ProductStatus { inStock, lowStock, outOfStock }

class WarehouseCoordinate {
  final String zone; // e.g. "A"
  final int row; // e.g. 3
  final int shelf; // e.g. 2

  const WarehouseCoordinate({required this.zone, required this.row, required this.shelf});

  String get label => '$zone-$row-$shelf';

  WarehouseCoordinate copyWith({String? zone, int? row, int? shelf}) =>
      WarehouseCoordinate(zone: zone ?? this.zone, row: row ?? this.row, shelf: shelf ?? this.shelf);
}

class Product {
  final String id;
  final String sku;
  final String name;
  final String color;
  final int quantity;
  final double unitPrice;
  final String barcode;
  final WarehouseCoordinate coordinate;
  final ProductStatus status;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    required this.barcode,
    required this.coordinate,
    required this.status,
  });

  double get totalPrice => quantity * unitPrice;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? color,
    int? quantity,
    double? unitPrice,
    String? barcode,
    WarehouseCoordinate? coordinate,
    ProductStatus? status,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      barcode: barcode ?? this.barcode,
      coordinate: coordinate ?? this.coordinate,
      status: status ?? this.status,
    );
  }

  static ProductStatus statusFromQty(int qty) {
    if (qty == 0) return ProductStatus.outOfStock;
    if (qty <= 10) return ProductStatus.lowStock;
    return ProductStatus.inStock;
  }
}

// ── Mock data built from the Lanzi invoice ────────────────────────────────────
final List<Product> mockProducts = [
  Product(
    id: '1',
    sku: 'X-1-500',
    name: 'X-1',
    color: '—',
    quantity: 38,
    unitPrice: 2.1306,
    barcode: '6901234500010',
    coordinate: const WarehouseCoordinate(zone: 'A', row: 1, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '2',
    sku: 'X-34-300',
    name: 'X-34',
    color: '—',
    quantity: 38,
    unitPrice: 1.1363,
    barcode: '6901234500027',
    coordinate: const WarehouseCoordinate(zone: 'A', row: 1, shelf: 2),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '3',
    sku: 'X-2-500-SL',
    name: 'X-2',
    color: 'SL Silver',
    quantity: 50,
    unitPrice: 2.1306,
    barcode: '6901234500034',
    coordinate: const WarehouseCoordinate(zone: 'A', row: 2, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '4',
    sku: 'X-3-500-GD',
    name: 'X-3',
    color: 'GD Gold',
    quantity: 30,
    unitPrice: 2.1306,
    barcode: '6901234500041',
    coordinate: const WarehouseCoordinate(zone: 'B', row: 1, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '5',
    sku: 'X-3-500-WH',
    name: 'X-3',
    color: 'WH White',
    quantity: 29,
    unitPrice: 2.1306,
    barcode: '6901234500058',
    coordinate: const WarehouseCoordinate(zone: 'B', row: 1, shelf: 2),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '6',
    sku: 'X-4-500',
    name: 'X-4',
    color: '—',
    quantity: 34,
    unitPrice: 2.1306,
    barcode: '6901234500065',
    coordinate: const WarehouseCoordinate(zone: 'B', row: 2, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '7',
    sku: 'X-5-500',
    name: 'X-5',
    color: '—',
    quantity: 70,
    unitPrice: 2.1306,
    barcode: '6901234500072',
    coordinate: const WarehouseCoordinate(zone: 'C', row: 1, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '8',
    sku: 'X-6-500',
    name: 'X-6',
    color: '—',
    quantity: 26,
    unitPrice: 2.1306,
    barcode: '6901234500089',
    coordinate: const WarehouseCoordinate(zone: 'C', row: 1, shelf: 2),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '9',
    sku: 'X-7-500',
    name: 'X-7',
    color: '—',
    quantity: 50,
    unitPrice: 2.1306,
    barcode: '6901234500096',
    coordinate: const WarehouseCoordinate(zone: 'C', row: 2, shelf: 1),
    status: ProductStatus.inStock,
  ),
  Product(
    id: '10',
    sku: 'X-8-900',
    name: 'X-8',
    color: '—',
    quantity: 7,
    unitPrice: 2.1306,
    barcode: '6901234500102',
    coordinate: const WarehouseCoordinate(zone: 'D', row: 1, shelf: 1),
    status: ProductStatus.lowStock,
  ),
  Product(
    id: '11',
    sku: 'X-24-400',
    name: 'X-24',
    color: '—',
    quantity: 30,
    unitPrice: 1.7044,
    barcode: '6901234500119',
    coordinate: const WarehouseCoordinate(zone: 'D', row: 1, shelf: 2),
    status: ProductStatus.inStock,
  ),
];
