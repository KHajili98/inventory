// ── OCR Item ──────────────────────────────────────────────────────────────────

class OcrItemModel {
  final String? modelCode;
  final String? productName;
  final String? description;
  final String? size;
  final String? color;
  final String? colorCode;
  final double? unitPriceUsd;
  final int? quantity;
  final double? totalPrice;
  final int? piecesPerCarton;
  final double? cartonCount;
  final double? weightKg;
  final double? grossWeightKg;
  final double? totalWeightKg;

  const OcrItemModel({
    this.modelCode,
    this.productName,
    this.description,
    this.size,
    this.color,
    this.colorCode,
    this.unitPriceUsd,
    this.quantity,
    this.totalPrice,
    this.piecesPerCarton,
    this.cartonCount,
    this.weightKg,
    this.grossWeightKg,
    this.totalWeightKg,
  });

  factory OcrItemModel.fromJson(Map<String, dynamic> json) => OcrItemModel(
    modelCode: json['model_code'] as String?,
    productName: json['product_name'] as String?,
    description: json['description'] as String?,
    size: json['size'] as String?,
    color: json['color'] as String?,
    colorCode: json['color_code'] as String?,
    unitPriceUsd: (json['unit_price_usd'] as num?)?.toDouble(),
    quantity: (json['quantity'] as num?)?.toInt(),
    totalPrice: (json['total_price'] as num?)?.toDouble(),
    piecesPerCarton: (json['pieces_per_carton'] as num?)?.toInt(),
    cartonCount: (json['carton_count'] as num?)?.toDouble(),
    weightKg: (json['weight_kg'] as num?)?.toDouble(),
    grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble(),
    totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'model_code': modelCode,
    'product_name': productName,
    'description': description,
    'size': size,
    'color': color,
    'color_code': colorCode,
    'unit_price_usd': unitPriceUsd,
    'quantity': quantity,
    'total_price': totalPrice,
    'pieces_per_carton': piecesPerCarton,
    'carton_count': cartonCount,
    'weight_kg': weightKg,
    'gross_weight_kg': grossWeightKg,
    'total_weight_kg': totalWeightKg,
  };
}

// ── OCR Result ────────────────────────────────────────────────────────────────

class OcrResultModel {
  final String? supplierName;
  final String? supplierAddress;
  final String? supplierTaxId;
  final String? contactNumber;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? contractNumber;
  final double? totalAmount;
  final String? currency;
  final List<OcrItemModel> items;

  const OcrResultModel({
    this.supplierName,
    this.supplierAddress,
    this.supplierTaxId,
    this.contactNumber,
    this.invoiceNumber,
    this.invoiceDate,
    this.contractNumber,
    this.totalAmount,
    this.currency,
    this.items = const [],
  });

  factory OcrResultModel.fromJson(Map<String, dynamic> json) => OcrResultModel(
    supplierName: json['supplier_name'] as String?,
    supplierAddress: json['supplier_address'] as String?,
    supplierTaxId: json['supplier_tax_id'] as String?,
    contactNumber: json['contact_number'] as String?,
    invoiceNumber: json['invoice_number'] as String?,
    invoiceDate: json['invoice_date'] as String?,
    contractNumber: json['contract_number'] as String?,
    totalAmount: (json['total_amount'] as num?)?.toDouble(),
    currency: json['currency'] as String?,
    items: (json['items'] as List<dynamic>? ?? []).map((e) => OcrItemModel.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'supplier_name': supplierName,
    'supplier_address': supplierAddress,
    'supplier_tax_id': supplierTaxId,
    'contact_number': contactNumber,
    'invoice_number': invoiceNumber,
    'invoice_date': invoiceDate,
    'contract_number': contractNumber,
    'total_amount': totalAmount,
    'currency': currency,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

// ── Invoice Upload Response Data ───────────────────────────────────────────────

class InvoiceUploadDataModel {
  final String id;
  final String? originalFilename;
  final int? fileSizeBytes;
  final String? fileType;
  final String? s3Bucket;
  final String? s3Key;
  final String? s3Region;
  final String? publicUrl;
  final String? status;
  final String? ocrModelUsed;
  final OcrResultModel? ocrResultJson;
  final String? ocrErrorMessage;
  final String? processingStartedAt;
  final String? processingCompletedAt;
  final int? processingDurationMs;
  final String? createdAt;
  final String? updatedAt;
  final String? extractedInvoiceNumber;
  final String? extractedSupplierName;
  final String? extractedTotalAmount;
  final String? extractedDate;

  const InvoiceUploadDataModel({
    required this.id,
    this.originalFilename,
    this.fileSizeBytes,
    this.fileType,
    this.s3Bucket,
    this.s3Key,
    this.s3Region,
    this.publicUrl,
    this.status,
    this.ocrModelUsed,
    this.ocrResultJson,
    this.ocrErrorMessage,
    this.processingStartedAt,
    this.processingCompletedAt,
    this.processingDurationMs,
    this.createdAt,
    this.updatedAt,
    this.extractedInvoiceNumber,
    this.extractedSupplierName,
    this.extractedTotalAmount,
    this.extractedDate,
  });

  factory InvoiceUploadDataModel.fromJson(Map<String, dynamic> json) => InvoiceUploadDataModel(
    id: json['id'] as String,
    originalFilename: json['original_filename'] as String?,
    fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
    fileType: json['file_type'] as String?,
    s3Bucket: json['s3_bucket'] as String?,
    s3Key: json['s3_key'] as String?,
    s3Region: json['s3_region'] as String?,
    publicUrl: json['public_url'] as String?,
    status: json['status'] as String?,
    ocrModelUsed: json['ocr_model_used'] as String?,
    ocrResultJson: json['ocr_result_json'] != null ? OcrResultModel.fromJson(json['ocr_result_json'] as Map<String, dynamic>) : null,
    ocrErrorMessage: json['ocr_error_message'] as String?,
    processingStartedAt: json['processing_started_at'] as String?,
    processingCompletedAt: json['processing_completed_at'] as String?,
    processingDurationMs: (json['processing_duration_ms'] as num?)?.toInt(),
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    extractedInvoiceNumber: json['extracted_invoice_number'] as String?,
    extractedSupplierName: json['extracted_supplier_name'] as String?,
    extractedTotalAmount: json['extracted_total_amount'] as String?,
    extractedDate: json['extracted_date'] as String?,
  );
}

// ── Top-level API Response ─────────────────────────────────────────────────────

class InvoiceUploadResponseModel {
  final bool success;
  final String message;
  final InvoiceUploadDataModel? data;

  const InvoiceUploadResponseModel({required this.success, required this.message, this.data});

  factory InvoiceUploadResponseModel.fromJson(Map<String, dynamic> json) => InvoiceUploadResponseModel(
    success: json['success'] as bool? ?? false,
    message: json['message'] as String? ?? '',
    data: json['data'] != null ? InvoiceUploadDataModel.fromJson(json['data'] as Map<String, dynamic>) : null,
  );
}
