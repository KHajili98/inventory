import 'package:json_annotation/json_annotation.dart';

part 'returned_product_models.g.dart';

// ── Creator Details ───────────────────────────────────────────────────────────

@JsonSerializable()
class ReturnedProductCreatorDetails {
  final String id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? role;

  const ReturnedProductCreatorDetails({required this.id, required this.username, required this.email, this.firstName, this.lastName, this.role});

  factory ReturnedProductCreatorDetails.fromJson(Map<String, dynamic> json) => _$ReturnedProductCreatorDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$ReturnedProductCreatorDetailsToJson(this);
}

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
  @JsonKey(name: 'returned_by_user_details')
  final ReturnedProductCreatorDetails? creatorDetails;
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
    this.creatorDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReturnedProduct.fromJson(Map<String, dynamic> json) => _$ReturnedProductFromJson(json);
  Map<String, dynamic> toJson() => _$ReturnedProductToJson(this);
}
