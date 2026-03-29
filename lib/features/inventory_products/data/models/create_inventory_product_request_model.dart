/// Request body for POST /api/inventory-products/
///
/// [barcodeType] must be either `'preprinted'` (user typed the barcode manually)
/// or `'generated'` (barcode was obtained via POST /api/generate-barcode/).
class CreateInventoryProductRequestModel {
  final String modelCode;
  final String productName;
  final String size;
  final String color;
  final String colorCode;
  final double invoiceUnitPriceUsd;
  final double invoiceUnitPriceAzn;
  final int invoiceQuantity;
  final double invoiceTotalPrice;
  final int actualQuantity;
  final double actualTotalPrice;
  final int invoicePiecesPerCarton;
  final int invoiceCartonCount;
  final int actualPiecesPerCarton;
  final int actualCartonCount;
  final String invoice;
  final String barcode;

  /// `'preprinted'` or `'generated'`
  final String barcodeType;
  final String locationZone;
  final String locationRow;
  final String locationShelf;
  final String source;

  /// UUID of the inventory (warehouse) this product belongs to.
  /// Pass an empty string or null to leave unassigned.
  final String? inventory;

  const CreateInventoryProductRequestModel({
    required this.modelCode,
    required this.productName,
    this.size = '',
    required this.color,
    required this.colorCode,
    this.invoiceUnitPriceUsd = 0,
    this.invoiceUnitPriceAzn = 0,
    this.invoiceQuantity = 0,
    this.invoiceTotalPrice = 0,
    required this.actualQuantity,
    required this.actualTotalPrice,
    this.invoicePiecesPerCarton = 0,
    this.invoiceCartonCount = 0,
    required this.actualPiecesPerCarton,
    required this.actualCartonCount,
    this.invoice = '',
    required this.barcode,
    this.barcodeType = 'preprinted',
    required this.locationZone,
    required this.locationRow,
    required this.locationShelf,
    this.source = 'manual',
    this.inventory,
  });

  /// Helper method to round double to max 10 decimal places
  double _roundToMaxDecimals(double value) {
    return double.parse(value.toStringAsFixed(10));
  }

  Map<String, dynamic> toJson() => {
    'model_code': modelCode,
    'product_name': productName,
    'size': size,
    'color': color,
    'color_code': colorCode,
    'invoice_unit_price_usd': _roundToMaxDecimals(invoiceUnitPriceUsd),
    'invoice_unit_price_azn': _roundToMaxDecimals(invoiceUnitPriceAzn),
    'invoice_quantity': invoiceQuantity,
    'invoice_total_price': _roundToMaxDecimals(invoiceTotalPrice),
    'actual_quantity': actualQuantity,
    'actual_total_price': _roundToMaxDecimals(actualTotalPrice),
    'invoice_pieces_per_carton': invoicePiecesPerCarton,
    'invoice_carton_count': invoiceCartonCount,
    'actual_pieces_per_carton': actualPiecesPerCarton,
    'actual_carton_count': actualCartonCount,
    'invoice': invoice,
    'barcode': barcode,
    'barcode_type': barcodeType,
    'location_zone': locationZone,
    'location_row': locationRow,
    'location_shelf': locationShelf,
    'source': source,
    if (inventory != null && inventory!.isNotEmpty) 'inventory': inventory,
  };
}
