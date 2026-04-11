import 'package:json_annotation/json_annotation.dart';

part 'returned_product_models.g.dart';

// ── API Response (paginated list) ────────────────────────────────────────────

@JsonSerializable()
class ReturnedProductListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ReturnedProduct> results;

  const ReturnedProductListResponse({required this.count, this.next, this.previous, required this.results});

  factory ReturnedProductListResponse.fromJson(Map<String, dynamic> json) => _$ReturnedProductListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReturnedProductListResponseToJson(this);
}

// ── Single returned product ───────────────────────────────────────────────────

@JsonSerializable()
class ReturnedProduct {
  final String id;
  @JsonKey(name: 'returned_product_barcode')
  final String returnedProductBarcode;
  @JsonKey(name: 'product_uuid')
  final String productUuid;
  final int count;
  @JsonKey(name: 'is_defected')
  final bool isDefected;
  @JsonKey(name: 'receipt_number')
  final String receiptNumber;
  @JsonKey(name: 'refund_amount')
  final double? refundAmount;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ReturnedProduct({
    required this.id,
    required this.returnedProductBarcode,
    required this.productUuid,
    required this.count,
    required this.isDefected,
    required this.receiptNumber,
    this.refundAmount,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReturnedProduct.fromJson(Map<String, dynamic> json) => _$ReturnedProductFromJson(json);
  Map<String, dynamic> toJson() => _$ReturnedProductToJson(this);
}
