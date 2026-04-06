/// A single price field change within a history entry.
class PriceChangeDetail {
  final double? oldValue;
  final double? newValue;

  const PriceChangeDetail({this.oldValue, this.newValue});

  factory PriceChangeDetail.fromJson(Map<String, dynamic> json) =>
      PriceChangeDetail(oldValue: (json['old'] as num?)?.toDouble(), newValue: (json['new'] as num?)?.toDouble());
}

/// A single entry in the change_history list.
class PriceChangeHistoryEntry {
  final Map<String, PriceChangeDetail> changes;
  final DateTime? changedAt;
  final String? changedByUsername;
  final String? changedByEmail;

  const PriceChangeHistoryEntry({required this.changes, this.changedAt, this.changedByUsername, this.changedByEmail});

  factory PriceChangeHistoryEntry.fromJson(Map<String, dynamic> json) {
    final changesRaw = json['changes'] as Map<String, dynamic>? ?? {};
    final changes = changesRaw.map((key, value) => MapEntry(key, PriceChangeDetail.fromJson(value as Map<String, dynamic>)));
    final changedBy = json['changed_by'] as Map<String, dynamic>?;
    return PriceChangeHistoryEntry(
      changes: changes,
      changedAt: json['changed_at'] != null ? DateTime.tryParse(json['changed_at'] as String) : null,
      changedByUsername: changedBy?['username'] as String?,
      changedByEmail: changedBy?['email'] as String?,
    );
  }
}

/// Response model for GET /api/stocks/
class StockProductResponseModel {
  final int count;
  final String? next;
  final String? previous;
  final List<StockProductItemModel> results;

  const StockProductResponseModel({required this.count, this.next, this.previous, required this.results});

  factory StockProductResponseModel.fromJson(Map<String, dynamic> json) => StockProductResponseModel(
    count: (json['count'] as num).toInt(),
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>).map((e) => StockProductItemModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

/// Nested inventory details returned within each stock item.
class StockInventoryDetails {
  final String id;
  final String name;
  final String address;
  final bool isStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockInventoryDetails({required this.id, required this.name, required this.address, required this.isStock, this.createdAt, this.updatedAt});

  factory StockInventoryDetails.fromJson(Map<String, dynamic> json) => StockInventoryDetails(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    isStock: json['is_stock'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

class StockProductItemModel {
  final String id;
  final String? modelCode;
  final String? productCode;
  final String? productName;
  final String? productGeneratedName;
  final String? size;
  final String? color;
  final String? colorCode;
  final int quantity;
  final String? barcode;
  final String? inventory;
  final String? sourceProductUuid;
  final String? sourceInventory;
  final double? invoiceUnitPriceAzn;
  final double? costUnitPrice;
  final double? wholeUnitSalesPrice;
  final double? retailUnitPrice;
  final bool priced;
  final List<PriceChangeHistoryEntry> changeHistory;
  final StockInventoryDetails? inventoryDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockProductItemModel({
    required this.id,
    this.modelCode,
    this.productCode,
    this.productName,
    this.productGeneratedName,
    this.size,
    this.color,
    this.colorCode,
    required this.quantity,
    this.barcode,
    this.inventory,
    this.sourceProductUuid,
    this.sourceInventory,
    this.invoiceUnitPriceAzn,
    this.costUnitPrice,
    this.wholeUnitSalesPrice,
    this.retailUnitPrice,
    required this.priced,
    this.changeHistory = const [],
    this.inventoryDetails,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => productGeneratedName?.isNotEmpty == true ? productGeneratedName! : (productName ?? id);
  String get inventoryName => inventoryDetails?.name ?? '';

  factory StockProductItemModel.fromJson(Map<String, dynamic> json) => StockProductItemModel(
    id: json['id'] as String,
    modelCode: json['model_code'] as String?,
    productCode: json['product_code'] as String?,
    productName: json['product_name'] as String?,
    productGeneratedName: json['product_generated_name'] as String?,
    size: json['size'] as String?,
    color: json['color'] as String?,
    colorCode: json['color_code'] as String?,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    barcode: json['barcode'] as String?,
    inventory: json['inventory'] as String?,
    sourceProductUuid: json['source_product_uuid'] as String?,
    sourceInventory: json['source_inventory'] as String?,
    invoiceUnitPriceAzn: (json['invoice_unit_price_azn'] as num?)?.toDouble(),
    costUnitPrice: (json['cost_unit_price'] as num?)?.toDouble(),
    wholeUnitSalesPrice: (json['whole_unit_sales_price'] as num?)?.toDouble(),
    retailUnitPrice: (json['retail_unit_price'] as num?)?.toDouble(),
    priced: json['priced'] as bool? ?? false,
    changeHistory:
        (json['change_history'] as List<dynamic>?)?.map((e) => PriceChangeHistoryEntry.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    inventoryDetails: json['inventory_details'] != null ? StockInventoryDetails.fromJson(json['inventory_details'] as Map<String, dynamic>) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );
}

/// Request model for POST /api/stocks/
class CreateStockItemRequest {
  final String? modelCode;
  final String? productCode;
  final String productName;
  final String? size;
  final String? color;
  final String? colorCode;
  final int quantity;
  final String barcode;
  final String inventory;
  final double? invoiceUnitPriceAzn;

  const CreateStockItemRequest({
    this.modelCode,
    this.productCode,
    required this.productName,
    this.size,
    this.color,
    this.colorCode,
    required this.quantity,
    required this.barcode,
    required this.inventory,
    this.invoiceUnitPriceAzn,
  });

  Map<String, dynamic> toJson() => {
    'model_code': modelCode ?? '',
    'product_code': productCode ?? '',
    'product_name': productName,
    'size': size ?? '',
    'color': color ?? '',
    'color_code': colorCode ?? '',
    'quantity': quantity,
    'barcode': barcode,
    'inventory': inventory,
    'source_product_uuid': '',
    'source_inventory': '',
    'invoice_unit_price_azn': invoiceUnitPriceAzn ?? 0,
    'cost_unit_price': null,
    'whole_unit_sales_price': null,
    'retail_unit_price': null,
    'priced': false,
  };
}
