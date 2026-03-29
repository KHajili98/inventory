/// Response model for GET /api/inventory-products/
class InventoryProductResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<InventoryProductItemModel> results;

  const InventoryProductResponseModel({required this.count, this.next, this.previous, required this.results});

  factory InventoryProductResponseModel.fromJson(Map<String, dynamic> json) => InventoryProductResponseModel(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => InventoryProductItemModel.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {'count': count, 'next': next, 'previous': previous, 'results': results.map((e) => e.toJson()).toList()};
}

class InventoryProductItemModel {
  final String id;
  final String? modelCode;
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
  final String? barcode;

  /// `'preprinted'` or `'generated'`
  final String? barcodeType;
  final bool? barcodePrinted;
  final String? locationZone;
  final String? locationRow;
  final String? locationShelf;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryProductItemModel({
    required this.id,
    this.modelCode,
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

  factory InventoryProductItemModel.fromJson(Map<String, dynamic> json) => InventoryProductItemModel(
    id: json['id'] as String,
    modelCode: json['model_code'] as String?,
    productName: json['product_name'] as String?,
    productGeneratedName: json['product_generated_name'] as String?,
    size: json['size'] as String?,
    color: json['color'] as String?,
    colorCode: json['color_code'] as String?,
    invoiceUnitPriceUsd: json['invoice_unit_price_usd'] != null ? (json['invoice_unit_price_usd'] as num).toDouble() : null,
    invoiceUnitPriceAzn: json['invoice_unit_price_azn'] != null ? (json['invoice_unit_price_azn'] as num).toDouble() : null,
    invoiceQuantity: json['invoice_quantity'] != null ? (json['invoice_quantity'] as num).toInt() : null,
    invoiceTotalPrice: json['invoice_total_price'] != null ? (json['invoice_total_price'] as num).toDouble() : null,
    actualQuantity: json['actual_quantity'] != null ? (json['actual_quantity'] as num).toInt() : null,
    actualTotalPrice: json['actual_total_price'] != null ? (json['actual_total_price'] as num).toDouble() : null,
    invoicePiecesPerCarton: json['invoice_pieces_per_carton'] != null ? (json['invoice_pieces_per_carton'] as num).toInt() : null,
    invoiceCartonCount: json['invoice_carton_count'] != null ? (json['invoice_carton_count'] as num).toInt() : null,
    actualPiecesPerCarton: json['actual_pieces_per_carton'] != null ? (json['actual_pieces_per_carton'] as num).toInt() : null,
    actualCartonCount: json['actual_carton_count'] != null ? (json['actual_carton_count'] as num).toInt() : null,
    invoice: json['invoice'] as String?,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'model_code': modelCode,
    'product_name': productName,
    'product_generated_name': productGeneratedName,
    'size': size,
    'color': color,
    'color_code': colorCode,
    'invoice_unit_price_usd': invoiceUnitPriceUsd,
    'invoice_unit_price_azn': invoiceUnitPriceAzn,
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
    'barcode_printed': barcodePrinted,
    'location_zone': locationZone,
    'location_row': locationRow,
    'location_shelf': locationShelf,
    'source': source,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
