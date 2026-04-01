/// Models for GET/POST/PUT /api/customers/
library;

// ── Single customer ───────────────────────────────────────────────────────────

class CustomerModel {
  final String id;
  final String name;
  final String surname;
  final String phoneNumber;
  final String loyaltyId;
  final double discountPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.phoneNumber,
    required this.loyaltyId,
    required this.discountPercentage,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '${name.trim()} ${surname.trim()}'.trim();

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    surname: json['surname'] as String? ?? '',
    phoneNumber: json['phone_number'] as String? ?? '',
    loyaltyId: json['loyalty_id'] as String? ?? '',
    discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'surname': surname,
    'phone_number': phoneNumber,
    'loyalty_id': loyaltyId,
    'discount_percentage': discountPercentage,
  };

  CustomerModel copyWith({String? name, String? surname, String? phoneNumber, String? loyaltyId, double? discountPercentage}) => CustomerModel(
    id: id,
    name: name ?? this.name,
    surname: surname ?? this.surname,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    loyaltyId: loyaltyId ?? this.loyaltyId,
    discountPercentage: discountPercentage ?? this.discountPercentage,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ── Paginated response ────────────────────────────────────────────────────────

class CustomersResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<CustomerModel> results;

  const CustomersResponseModel({required this.count, this.next, this.previous, required this.results});

  factory CustomersResponseModel.fromJson(Map<String, dynamic> json) => CustomersResponseModel(
    count: json['count'] as int? ?? 0,
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>? ?? []).map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
