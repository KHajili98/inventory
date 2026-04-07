import 'package:inventory/features/expense/data/models/fee_category_model.dart';

class FeeCreatorDetails {
  final String id;
  final String username;
  final String email;
  final String phone;

  const FeeCreatorDetails({required this.id, required this.username, required this.email, required this.phone});

  factory FeeCreatorDetails.fromJson(Map<String, dynamic> json) {
    return FeeCreatorDetails(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class Fee {
  final String id;
  final String feeCategoryId;
  final FeeCategory feeCategoryDetails;
  final String paymentType; // "cash" | "card" | "transfer"
  final double paymentAmount;
  final DateTime paymentDate;
  final String? fileUrl;
  final String note;
  final FeeCreatorDetails? creatorDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fee({
    required this.id,
    required this.feeCategoryId,
    required this.feeCategoryDetails,
    required this.paymentType,
    required this.paymentAmount,
    required this.paymentDate,
    this.fileUrl,
    required this.note,
    this.creatorDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as String,
      feeCategoryId: json['fee_category'] as String,
      feeCategoryDetails: FeeCategory.fromJson(json['fee_category_details'] as Map<String, dynamic>),
      paymentType: json['payment_type'] as String,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      fileUrl: json['file_url'] as String?,
      note: json['note'] as String? ?? '',
      creatorDetails: json['creator_details'] != null ? FeeCreatorDetails.fromJson(json['creator_details'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class FeeListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Fee> results;

  const FeeListResponse({required this.count, this.next, this.previous, required this.results});

  factory FeeListResponse.fromJson(Map<String, dynamic> json) {
    return FeeListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>).map((e) => Fee.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
