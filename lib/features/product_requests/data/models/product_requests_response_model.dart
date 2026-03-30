/// Response model for GET /api/requests/
library;

// ── Inventory details ─────────────────────────────────────────────────────────

class InventoryDetailModel {
  final String id;
  final String name;
  final String address;
  final bool isStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryDetailModel({required this.id, required this.name, required this.address, required this.isStock, this.createdAt, this.updatedAt});

  factory InventoryDetailModel.fromJson(Map<String, dynamic> json) => InventoryDetailModel(
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

// ── Creator user details ──────────────────────────────────────────────────────

class CreatorUserDetailModel {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final bool isStaff;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CreatorUserDetailModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.isStaff,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory CreatorUserDetailModel.fromJson(Map<String, dynamic> json) => CreatorUserDetailModel(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    isStaff: json['is_staff'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'is_active': isActive,
    'is_staff': isStaff,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

// ── Product details ───────────────────────────────────────────────────────────

class ProductDetailModel {
  final String id;
  final String modelCode;
  final String productCode;
  final String productName;
  final String productGeneratedName;
  final String size;
  final String color;
  final String colorCode;
  final String barcode;
  final int actualQuantity;
  final int invoiceQuantity;
  final double invoiceUnitPriceAzn;

  const ProductDetailModel({
    required this.id,
    required this.modelCode,
    required this.productCode,
    required this.productName,
    required this.productGeneratedName,
    required this.size,
    required this.color,
    required this.colorCode,
    required this.barcode,
    required this.actualQuantity,
    required this.invoiceQuantity,
    required this.invoiceUnitPriceAzn,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) => ProductDetailModel(
    id: json['id'] as String,
    modelCode: json['model_code'] as String? ?? '',
    productCode: json['product_code'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    productGeneratedName: json['product_generated_name'] as String? ?? '',
    size: json['size'] as String? ?? '',
    color: json['color'] as String? ?? '',
    colorCode: json['color_code'] as String? ?? '',
    barcode: json['barcode'] as String? ?? '',
    actualQuantity: (json['actual_quantity'] as num?)?.toInt() ?? 0,
    invoiceQuantity: (json['invoice_quantity'] as num?)?.toInt() ?? 0,
    invoiceUnitPriceAzn: (json['invoice_unit_price_azn'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'model_code': modelCode,
    'product_code': productCode,
    'product_name': productName,
    'product_generated_name': productGeneratedName,
    'size': size,
    'color': color,
    'color_code': colorCode,
    'barcode': barcode,
    'actual_quantity': actualQuantity,
    'invoice_quantity': invoiceQuantity,
    'invoice_unit_price_azn': invoiceUnitPriceAzn,
  };
}

// ── Product with details ──────────────────────────────────────────────────────

class ProductWithDetailsModel {
  final String productUuid;
  final int? creatingCount;
  final int? sendingCount;
  final int? receivingCount;
  final ProductDetailModel? productDetails;

  const ProductWithDetailsModel({required this.productUuid, this.creatingCount, this.sendingCount, this.receivingCount, this.productDetails});

  factory ProductWithDetailsModel.fromJson(Map<String, dynamic> json) => ProductWithDetailsModel(
    productUuid: json['product_uuid'] as String,
    creatingCount: (json['creating_count'] as num?)?.toInt(),
    sendingCount: (json['sending_count'] as num?)?.toInt(),
    receivingCount: (json['receiving_count'] as num?)?.toInt(),
    productDetails: json['product_details'] != null ? ProductDetailModel.fromJson(json['product_details'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'product_uuid': productUuid,
    'creating_count': creatingCount,
    'sending_count': sendingCount,
    'receiving_count': receivingCount,
    'product_details': productDetails?.toJson(),
  };
}

// ── Status changing history entry ─────────────────────────────────────────────

class StatusChangingHistoryModel {
  final String? fromStatus;
  final String? toStatus;
  final String? changedBy;
  final DateTime? changedAt;

  const StatusChangingHistoryModel({this.fromStatus, this.toStatus, this.changedBy, this.changedAt});

  factory StatusChangingHistoryModel.fromJson(Map<String, dynamic> json) => StatusChangingHistoryModel(
    fromStatus: json['from_status'] as String?,
    toStatus: json['to_status'] as String?,
    changedBy: json['changed_by'] as String?,
    changedAt: json['changed_at'] != null ? DateTime.tryParse(json['changed_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'from_status': fromStatus,
    'to_status': toStatus,
    'changed_by': changedBy,
    'changed_at': changedAt?.toIso8601String(),
  };
}

// ── Product request item (raw) ────────────────────────────────────────────────

class ProductRequestItemModel {
  final String productUuid;
  final int? sendingCount;
  final int? creatingCount;
  final int? receivingCount;

  const ProductRequestItemModel({required this.productUuid, this.sendingCount, this.creatingCount, this.receivingCount});

  factory ProductRequestItemModel.fromJson(Map<String, dynamic> json) => ProductRequestItemModel(
    productUuid: json['product_uuid'] as String,
    sendingCount: (json['sending_count'] as num?)?.toInt(),
    creatingCount: (json['creating_count'] as num?)?.toInt(),
    receivingCount: (json['receiving_count'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'product_uuid': productUuid,
    'sending_count': sendingCount,
    'creating_count': creatingCount,
    'receiving_count': receivingCount,
  };
}

// ── Product request ───────────────────────────────────────────────────────────

class ProductRequestModel {
  final String id;
  final List<ProductRequestItemModel> products;
  final String sourceInventory;
  final String destinationInventory;
  final String creatorUserId;
  final String status;
  final List<StatusChangingHistoryModel> statusChangingHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CreatorUserDetailModel? creatorUserDetails;
  final InventoryDetailModel? sourceInventoryDetails;
  final InventoryDetailModel? destinationInventoryDetails;
  final List<ProductWithDetailsModel> productsWithDetails;

  const ProductRequestModel({
    required this.id,
    required this.products,
    required this.sourceInventory,
    required this.destinationInventory,
    required this.creatorUserId,
    required this.status,
    required this.statusChangingHistory,
    this.createdAt,
    this.updatedAt,
    this.creatorUserDetails,
    this.sourceInventoryDetails,
    this.destinationInventoryDetails,
    required this.productsWithDetails,
  });

  /// Convenience: source inventory name (falls back to UUID).
  String get sourceInventoryName => sourceInventoryDetails?.name ?? sourceInventory;

  /// Convenience: destination inventory name (falls back to UUID).
  String get destinationInventoryName => destinationInventoryDetails?.name ?? destinationInventory;

  /// Total requested items count.
  int get totalItems => productsWithDetails.fold(0, (sum, p) => sum + (p.creatingCount ?? 0));

  factory ProductRequestModel.fromJson(Map<String, dynamic> json) => ProductRequestModel(
    id: json['id'] as String,
    products: (json['products'] as List<dynamic>?)?.map((e) => ProductRequestItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    sourceInventory: json['source_inventory'] as String,
    destinationInventory: json['destination_inventory'] as String,
    creatorUserId: json['creator_user_id'] as String,
    status: json['status'] as String? ?? 'pending',
    statusChangingHistory:
        (json['status_changing_history'] as List<dynamic>?)?.map((e) => StatusChangingHistoryModel.fromJson(e as Map<String, dynamic>)).toList() ??
        [],
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    creatorUserDetails: json['creator_user_details'] != null
        ? CreatorUserDetailModel.fromJson(json['creator_user_details'] as Map<String, dynamic>)
        : null,
    sourceInventoryDetails: json['source_inventory_details'] != null
        ? InventoryDetailModel.fromJson(json['source_inventory_details'] as Map<String, dynamic>)
        : null,
    destinationInventoryDetails: json['destination_inventory_details'] != null
        ? InventoryDetailModel.fromJson(json['destination_inventory_details'] as Map<String, dynamic>)
        : null,
    productsWithDetails:
        (json['products_with_details'] as List<dynamic>?)?.map((e) => ProductWithDetailsModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'products': products.map((e) => e.toJson()).toList(),
    'source_inventory': sourceInventory,
    'destination_inventory': destinationInventory,
    'creator_user_id': creatorUserId,
    'status': status,
    'status_changing_history': statusChangingHistory.map((e) => e.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'creator_user_details': creatorUserDetails?.toJson(),
    'source_inventory_details': sourceInventoryDetails?.toJson(),
    'destination_inventory_details': destinationInventoryDetails?.toJson(),
    'products_with_details': productsWithDetails.map((e) => e.toJson()).toList(),
  };
}

// ── Paginated response ────────────────────────────────────────────────────────

class ProductRequestsResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<ProductRequestModel> results;

  const ProductRequestsResponseModel({required this.count, this.next, this.previous, required this.results});

  factory ProductRequestsResponseModel.fromJson(Map<String, dynamic> json) => ProductRequestsResponseModel(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => ProductRequestModel.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {'count': count, 'next': next, 'previous': previous, 'results': results.map((e) => e.toJson()).toList()};
}
