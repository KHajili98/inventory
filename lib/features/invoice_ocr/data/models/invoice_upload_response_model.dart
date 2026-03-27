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
  final double? weightKg; // present in v1 response (weight_kg)
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

// ── Extracted Data (was ocr_result_json, now extracted_data) ──────────────────

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

// ── Processing Metadata ───────────────────────────────────────────────────────

class ProcessingMetadataModel {
  final String id;
  final String? status;
  final String? ocrModel;
  final int? processingDurationMs;
  final String? processingStartedAt;
  final String? processingCompletedAt;
  final String? originalFilename;
  final int? fileSizeBytes;
  final String? fileType;

  const ProcessingMetadataModel({
    required this.id,
    this.status,
    this.ocrModel,
    this.processingDurationMs,
    this.processingStartedAt,
    this.processingCompletedAt,
    this.originalFilename,
    this.fileSizeBytes,
    this.fileType,
  });

  factory ProcessingMetadataModel.fromJson(Map<String, dynamic> json) => ProcessingMetadataModel(
    id: json['id'] as String? ?? '',
    status: json['status'] as String?,
    ocrModel: json['ocr_model'] as String?,
    processingDurationMs: (json['processing_duration_ms'] as num?)?.toInt(),
    processingStartedAt: json['processing_started_at'] as String?,
    processingCompletedAt: json['processing_completed_at'] as String?,
    originalFilename: json['original_filename'] as String?,
    fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
    fileType: json['file_type'] as String?,
  );
}

// ── Top-level API Response ────────────────────────────────────────────────────
//
// New shape (v2):
// {
//   "success": true,
//   "message": "...",
//   "extracted_data": { ...OcrResultModel... },
//   "invoice_url": "https://...",
//   "processing_metadata": { ...ProcessingMetadataModel... }
// }
//
// Legacy shape (v1) had a "data" key with nested "ocr_result_json".
// Both shapes are handled transparently via [InvoiceUploadResponseModel.fromJson].

class InvoiceUploadResponseModel {
  final bool success;
  final String message;
  final OcrResultModel? extractedData;
  final String? invoiceUrl;
  final ProcessingMetadataModel? processingMetadata;

  const InvoiceUploadResponseModel({required this.success, required this.message, this.extractedData, this.invoiceUrl, this.processingMetadata});

  factory InvoiceUploadResponseModel.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    // ── v2 shape ─────────────────────────────────────────────────────────────
    if (json.containsKey('extracted_data')) {
      return InvoiceUploadResponseModel(
        success: success,
        message: message,
        extractedData: json['extracted_data'] != null ? OcrResultModel.fromJson(json['extracted_data'] as Map<String, dynamic>) : null,
        invoiceUrl: json['invoice_url'] as String?,
        processingMetadata: json['processing_metadata'] != null
            ? ProcessingMetadataModel.fromJson(json['processing_metadata'] as Map<String, dynamic>)
            : null,
      );
    }

    // ── v1 legacy shape (data.ocr_result_json) ────────────────────────────────
    final dataMap = json['data'] as Map<String, dynamic>?;
    return InvoiceUploadResponseModel(
      success: success,
      message: message,
      extractedData: dataMap?['ocr_result_json'] != null ? OcrResultModel.fromJson(dataMap!['ocr_result_json'] as Map<String, dynamic>) : null,
      invoiceUrl: dataMap?['public_url'] as String?,
      processingMetadata: dataMap != null
          ? ProcessingMetadataModel.fromJson({
              'id': dataMap['id'],
              'status': dataMap['status'],
              'ocr_model': dataMap['ocr_model_used'],
              'processing_duration_ms': dataMap['processing_duration_ms'],
              'processing_started_at': dataMap['processing_started_at'],
              'processing_completed_at': dataMap['processing_completed_at'],
              'original_filename': dataMap['original_filename'],
              'file_size_bytes': dataMap['file_size_bytes'],
              'file_type': dataMap['file_type'],
            })
          : null,
    );
  }

  // Convenience getters so the rest of the app doesn't care about the version.
  String? get invoiceNumber => extractedData?.invoiceNumber;
  String? get supplierName => extractedData?.supplierName;
  double? get totalAmount => extractedData?.totalAmount;
  String? get invoiceDate => extractedData?.invoiceDate;
}
