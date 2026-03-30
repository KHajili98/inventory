/// Response model for GET /api/stocks/
class StockProductResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<StockProductItemModel> results;

  const StockProductResponseModel({required this.count, this.next, this.previous, required this.results});

  factory StockProductResponseModel.fromJson(Map<String, dynamic> json) => StockProductResponseModel(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => StockProductItemModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class StockProductItemModel {
  final String id;
  final String? modelCode;
  final String? productCode;
  final String? productName;
  final String? productGeneratedName;
  final String? size;
  final String? color;
  final String? colorCode;
  final double? invoiceUnitPriceUsd;
  final double? invoiceUnitPriceAzn;
  final int? invoiceQuantity;
  final double? invoiceTotalPrice;
  final int? actualQuantity;
  final double? actualTotalPrice;
  final int? invoicePiecesPerCarton;
  final int? invoiceCartonCount;
  final int? actualPiecesPerCarton;
  final int? actualCartonCount;
  final String? invoice;
  final String? inventory;
  final String? inventoryName;
  final String? barcode;
  final String? barcodeType;
  final bool? barcodePrinted;
  final String? locationZone;
  final String? locationRow;
  final String? locationShelf;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockProductItemModel({
    required this.id,
    this.modelCode,
    this.productCode,
    this.productName,
    this.productGeneratedName,
    this.size,
    this.color,
    this.colorCode,
    this.invoiceUnitPriceUsd,
    this.invoiceUnitPriceAzn,
    this.invoiceQuantity,
    this.invoiceTotalPrice,
    this.actualQuantity,
    this.actualTotalPrice,
    this.invoicePiecesPerCarton,
    this.invoiceCartonCount,
    this.actualPiecesPerCarton,
    this.actualCartonCount,
    this.invoice,
    this.inventory,
    this.inventoryName,
    this.barcode,
    this.barcodeType,
    this.barcodePrinted,
    this.locationZone,
    this.locationRow,
    this.locationShelf,
    this.source,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => productGeneratedName?.isNotEmpty == true ? productGeneratedName! : (productName ?? id);

  factory StockProductItemModel.fromJson(Map<String, dynamic> json) => StockProductItemModel(
    id: json['id'] as String,
    modelCode: json['model_code'] as String?,
    productCode: json['product_code'] as String?,
    productName: json['product_name'] as String?,
    productGeneratedName: json['product_generated_name'] as String?,
    size: json['size'] as String?,
    color: json['color'] as String?,
    colorCode: json['color_code'] as String?,
    invoiceUnitPriceUsd: (json['invoice_unit_price_usd'] as num?)?.toDouble(),
    invoiceUnitPriceAzn: (json['invoice_unit_price_azn'] as num?)?.toDouble(),
    invoiceQuantity: (json['invoice_quantity'] as num?)?.toInt(),
    invoiceTotalPrice: (json['invoice_total_price'] as num?)?.toDouble(),
    actualQuantity: (json['actual_quantity'] as num?)?.toInt(),
    actualTotalPrice: (json['actual_total_price'] as num?)?.toDouble(),
    invoicePiecesPerCarton: (json['invoice_pieces_per_carton'] as num?)?.toInt(),
    invoiceCartonCount: (json['invoice_carton_count'] as num?)?.toInt(),
    actualPiecesPerCarton: (json['actual_pieces_per_carton'] as num?)?.toInt(),
    actualCartonCount: (json['actual_carton_count'] as num?)?.toInt(),
    invoice: json['invoice'] as String?,
    inventory: json['inventory'] as String?,
    inventoryName: json['inventory_name'] as String?,
    barcode: json['barcode'] as String?,
    barcodeType: json['barcode_type'] as String?,
    barcodePrinted: json['barcode_printed'] as bool?,
    locationZone: json['location_zone'] as String?,
    locationRow: json['location_row'] as String?,
    locationShelf: json['location_shelf'] as String?,
    source: json['source'] as String?,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}
