/// Response model for GET /api/invoices-list/
class InvoiceListResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<InvoiceListItemModel> results;

  const InvoiceListResponseModel({required this.count, this.next, this.previous, required this.results});

  factory InvoiceListResponseModel.fromJson(Map<String, dynamic> json) => InvoiceListResponseModel(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => InvoiceListItemModel.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {'count': count, 'next': next, 'previous': previous, 'results': results.map((e) => e.toJson()).toList()};
}

class InvoiceListItemModel {
  final String id;
  final String? supplierName;
  final String? invoiceNumber;
  final String? invoiceDate;
  final double? totalAmount;
  final String? currency;
  final String? invoiceImageUrl;
  final List<String> invoiceProcessing;
  final int totalItemsCount;
  final DateTime? createdAt;

  const InvoiceListItemModel({
    required this.id,
    this.supplierName,
    this.invoiceNumber,
    this.invoiceDate,
    this.totalAmount,
    this.currency,
    this.invoiceImageUrl,
    this.invoiceProcessing = const [],
    required this.totalItemsCount,
    this.createdAt,
  });

  factory InvoiceListItemModel.fromJson(Map<String, dynamic> json) => InvoiceListItemModel(
    id: json['id'] as String,
    supplierName: json['supplier_name'] as String?,
    invoiceNumber: json['invoice_number'] as String?,
    invoiceDate: json['invoice_date'] as String?,
    totalAmount: (json['total_amount'] as String?) != null ? double.tryParse(json['total_amount'] as String) : null,
    currency: json['currency'] as String?,
    invoiceImageUrl: json['invoice_image_url'] as String?,
    invoiceProcessing: (json['invoice_processing'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    totalItemsCount: (json['total_items_count'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'supplier_name': supplierName,
    'invoice_number': invoiceNumber,
    'invoice_date': invoiceDate,
    'total_amount': totalAmount?.toString(),
    'currency': currency,
    'invoice_image_url': invoiceImageUrl,
    'invoice_processing': invoiceProcessing,
    'total_items_count': totalItemsCount,
    'created_at': createdAt?.toIso8601String(),
  };
}
