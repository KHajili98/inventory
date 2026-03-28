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

  const CreateInventoryProductRequestModel({
    required this.modelCode,
    required this.productName,
    this.size = '',
    required this.color,
    required this.colorCode,
    this.invoiceUnitPriceUsd = 0,
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
  });

  Map<String, dynamic> toJson() => {
    'model_code': modelCode,
    'product_name': productName,
    'size': size,
    'color': color,
    'color_code': colorCode,
    'invoice_unit_price_usd': invoiceUnitPriceUsd,
    'invoice_quantity': invoiceQuantity,
    'invoice_total_price': invoiceTotalPrice,
    'actual_quantity': actualQuantity,
    'actual_total_price': actualTotalPrice,
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
  };
}
