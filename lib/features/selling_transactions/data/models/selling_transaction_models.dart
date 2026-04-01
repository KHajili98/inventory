/// Models for POST /api/selling-transactions/complete-payment/
library;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum SellingPriceType {
  retailSale('retail_sale'),
  wholeSale('whole_sale');

  const SellingPriceType(this.value);
  final String value;
}

enum SellingPaymentMethod {
  cash('cash'),
  card('card'),
  transfer('transfer');

  const SellingPaymentMethod(this.value);
  final String value;
}

// ── Request ───────────────────────────────────────────────────────────────────

class SellingTransactionItemRequest {
  final String productUuid;
  final int count;
  final double discountPercentage;
  final double discountAmount;
  final double totalPrice;

  const SellingTransactionItemRequest({
    required this.productUuid,
    required this.count,
    required this.discountPercentage,
    required this.discountAmount,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
    'product_uuid': productUuid,
    'count': count,
    'discount_percentage': discountPercentage,
    'discount_amount': discountAmount,
    'total_price': totalPrice,
  };
}

class CompletePaymentRequest {
  final String loggedInInventoryId;
  final String? selectedLoyalCustomerId;
  final double totalSellingPrice;
  final SellingPriceType priceType;
  final SellingPaymentMethod paymentMethod;
  final double discountAmount;
  final double discountPercentage;
  final List<SellingTransactionItemRequest> items;

  const CompletePaymentRequest({
    required this.loggedInInventoryId,
    this.selectedLoyalCustomerId,
    required this.totalSellingPrice,
    required this.priceType,
    required this.paymentMethod,
    required this.discountAmount,
    required this.discountPercentage,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'logged_in_inventory_id': loggedInInventoryId,
    if (selectedLoyalCustomerId != null) 'selected_loyal_customer_id': selectedLoyalCustomerId,
    'total_selling_price': totalSellingPrice,
    'price_type': priceType.value,
    'payment_method': paymentMethod.value,
    'discount_amount': discountAmount,
    'discount_percentage': discountPercentage,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

// ── Response sub-models ───────────────────────────────────────────────────────

class SellingTransactionSellerInfo {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final bool isStaff;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellingTransactionSellerInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.isStaff,
    this.createdAt,
    this.updatedAt,
  });

  factory SellingTransactionSellerInfo.fromJson(Map<String, dynamic> json) => SellingTransactionSellerInfo(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? false,
    isStaff: json['is_staff'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

class SellingTransactionInventoryInfo {
  final String id;
  final String name;
  final String address;
  final bool isStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellingTransactionInventoryInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.isStock,
    this.createdAt,
    this.updatedAt,
  });

  factory SellingTransactionInventoryInfo.fromJson(Map<String, dynamic> json) => SellingTransactionInventoryInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    isStock: json['is_stock'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

// ── Response ──────────────────────────────────────────────────────────────────

class SellingTransactionItemResponse {
  final String id;
  final String sellingTransaction;
  final String productUuid;
  final int count;
  final double discountPercentage;
  final double discountAmount;
  final double totalPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellingTransactionItemResponse({
    required this.id,
    required this.sellingTransaction,
    required this.productUuid,
    required this.count,
    required this.discountPercentage,
    required this.discountAmount,
    required this.totalPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory SellingTransactionItemResponse.fromJson(Map<String, dynamic> json) => SellingTransactionItemResponse(
    id: json['id'] as String,
    sellingTransaction: json['selling_transaction'] as String,
    productUuid: json['product_uuid'] as String,
    count: (json['count'] as num).toInt(),
    discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
    discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

class SellingTransactionResponse {
  final String id;
  final String receiptNumber;
  final SellingTransactionSellerInfo? sellerDetailedInfo;
  final SellingTransactionInventoryInfo? sellingLocationInventoryDetails;
  final String loggedInInventory;
  final String? selectedLoyalCustomer;
  final double totalSellingPrice;
  final String priceType;
  final String paymentMethod;
  final double discountAmount;
  final double discountPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SellingTransactionItemResponse> items;

  const SellingTransactionResponse({
    required this.id,
    required this.receiptNumber,
    this.sellerDetailedInfo,
    this.sellingLocationInventoryDetails,
    required this.loggedInInventory,
    this.selectedLoyalCustomer,
    required this.totalSellingPrice,
    required this.priceType,
    required this.paymentMethod,
    required this.discountAmount,
    required this.discountPercentage,
    this.createdAt,
    this.updatedAt,
    required this.items,
  });

  factory SellingTransactionResponse.fromJson(Map<String, dynamic> json) => SellingTransactionResponse(
    id: json['id'] as String,
    receiptNumber: json['receipt_number'] as String? ?? '',
    sellerDetailedInfo: json['seller_detailed_info'] is Map
        ? SellingTransactionSellerInfo.fromJson(Map<String, dynamic>.from(json['seller_detailed_info'] as Map))
        : null,
    sellingLocationInventoryDetails: json['selling_location_inventory_details'] is Map
        ? SellingTransactionInventoryInfo.fromJson(Map<String, dynamic>.from(json['selling_location_inventory_details'] as Map))
        : null,
    loggedInInventory: json['logged_in_inventory'] as String,
    selectedLoyalCustomer: json['selected_loyal_customer'] as String?,
    totalSellingPrice: (json['total_selling_price'] as num?)?.toDouble() ?? 0.0,
    priceType: json['price_type'] as String? ?? '',
    paymentMethod: json['payment_method'] as String? ?? '',
    discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
    discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    items: (json['items'] as List<dynamic>? ?? []).map((e) => SellingTransactionItemResponse.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
