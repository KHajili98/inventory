class FeeCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeeCategory({required this.id, required this.name, required this.createdAt, required this.updatedAt});

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class FeeCategoryListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FeeCategory> results;

  const FeeCategoryListResponse({required this.count, this.next, this.previous, required this.results});

  factory FeeCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return FeeCategoryListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>).map((e) => FeeCategory.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
