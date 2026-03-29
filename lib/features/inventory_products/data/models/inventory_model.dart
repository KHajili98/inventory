/// Model for a single inventory (warehouse) from GET /api/inventories/
class InventoryModel {
  final String id;
  final String name;
  final String address;
  final bool isStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryModel({required this.id, required this.name, required this.address, required this.isStock, this.createdAt, this.updatedAt});

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    isStock: json['is_stock'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'is_stock': isStock,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Paginated response for GET /api/inventories/
class InventoryListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<InventoryModel> results;

  const InventoryListResponse({required this.count, this.next, this.previous, required this.results});

  factory InventoryListResponse.fromJson(Map<String, dynamic> json) => InventoryListResponse(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => InventoryModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
