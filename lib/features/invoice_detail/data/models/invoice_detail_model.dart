/// Response model for GET /api/invoices-list/{id}/
library;

class InvoiceDetailItemModel {
  final String id;
  final String? modelCode;
  final String? productName;
  final String? size;
  final String? color;
  final String? colorCode;
  final double? unitPriceUsd;
  final int? quantity;
  final double? totalPrice;
  final int? piecesPerCarton;
  final double? cartonCount;
  final double? grossWeightKg;
  final double? totalWeightKg;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InvoiceDetailItemModel({
    required this.id,
    this.modelCode,
    this.productName,
    this.size,
    this.color,
    this.colorCode,
    this.unitPriceUsd,
    this.quantity,
    this.totalPrice,
    this.piecesPerCarton,
    this.cartonCount,
    this.grossWeightKg,
    this.totalWeightKg,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceDetailItemModel.fromJson(Map<String, dynamic> json) => InvoiceDetailItemModel(
    id: json['id'] as String,
    modelCode: json['model_code'] as String?,
    productName: json['product_name'] as String?,
    size: json['size'] as String?,
    color: json['color'] as String?,
    colorCode: json['color_code'] as String?,
    unitPriceUsd: (json['unit_price_usd'] as num?)?.toDouble(),
    quantity: (json['quantity'] as num?)?.toInt(),
    totalPrice: (json['total_price'] as num?)?.toDouble(),
    piecesPerCarton: (json['pieces_per_carton'] as num?)?.toInt(),
    cartonCount: (json['carton_count'] as num?)?.toDouble(),
    grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble(),
    totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble(),
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

class InvoiceDetailModel {
  final String id;
  final String? supplierName;
  final String? supplierAddress;
  final String? supplierTaxId;
  final String? contactNumber;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? contractNumber;
  final double? totalAmount;
  final String? currency;
  final List<String> invoiceImageUrls;
  final List<String> invoiceProcessing;

  /// Convenience getter — first image URL or null.
  String? get invoiceImageUrl => invoiceImageUrls.isNotEmpty ? invoiceImageUrls.first : null;
  final List<InvoiceDetailItemModel> items;
  final int totalItemsCount;
  final int? totalQuantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InvoiceDetailModel({
    required this.id,
    this.supplierName,
    this.supplierAddress,
    this.supplierTaxId,
    this.contactNumber,
    this.invoiceNumber,
    this.invoiceDate,
    this.contractNumber,
    this.totalAmount,
    this.currency,
    this.invoiceImageUrls = const [],
    this.invoiceProcessing = const [],
    this.items = const [],
    required this.totalItemsCount,
    this.totalQuantity,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) => InvoiceDetailModel(
    id: json['id'] as String,
    supplierName: json['supplier_name'] as String?,
    supplierAddress: json['supplier_address'] as String?,
    supplierTaxId: json['supplier_tax_id'] as String?,
    contactNumber: json['contact_number'] as String?,
    invoiceNumber: json['invoice_number'] as String?,
    invoiceDate: json['invoice_date'] as String?,
    contractNumber: json['contract_number'] as String?,
    totalAmount: (json['total_amount'] as num?)?.toDouble(),
    currency: json['currency'] as String?,
    invoiceImageUrls: (json['invoice_image_url'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    invoiceProcessing: (json['invoice_processing'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    items: (json['items'] as List<dynamic>?)?.map((e) => InvoiceDetailItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    totalItemsCount: (json['total_items_count'] as num?)?.toInt() ?? 0,
    totalQuantity: (json['total_quantity'] as num?)?.toInt(),
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}
