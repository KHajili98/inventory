enum ProductRequestStatus { pending, preparing, readyForDelivery, onWay, waitingForPricing, closed }

extension ProductRequestStatusExtension on ProductRequestStatus {
  String get label {
    switch (this) {
      case ProductRequestStatus.pending:
        return 'Pending';
      case ProductRequestStatus.preparing:
        return 'Preparing';
      case ProductRequestStatus.readyForDelivery:
        return 'Ready for Delivery';
      case ProductRequestStatus.onWay:
        return 'On the Way';
      case ProductRequestStatus.waitingForPricing:
        return 'Waiting for Pricing';
      case ProductRequestStatus.closed:
        return 'Closed';
    }
  }
}

enum AppUserRole { seller, inventoryMan }

class AppUser {
  final String id;
  final String name;
  final AppUserRole role;

  const AppUser({required this.id, required this.name, required this.role});
}

class ProductRequestItem {
  final String productName;
  final String barcode;
  final String productCode;
  final int requestedQuantity;

  /// Set by inventory man when preparing (may differ from requestedQuantity)
  final int? preparedQuantity;

  /// Set by seller when accepting the delivery
  final int? acceptedQuantity;

  const ProductRequestItem({
    required this.productName,
    required this.barcode,
    required this.productCode,
    required this.requestedQuantity,
    this.preparedQuantity,
    this.acceptedQuantity,
  });

  ProductRequestItem copyWith({int? requestedQuantity, int? preparedQuantity, int? acceptedQuantity}) {
    return ProductRequestItem(
      productName: productName,
      barcode: barcode,
      productCode: productCode,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      preparedQuantity: preparedQuantity ?? this.preparedQuantity,
      acceptedQuantity: acceptedQuantity ?? this.acceptedQuantity,
    );
  }
}

class ProductRequest {
  final String id;
  final String fromInventory;
  final String toInventory;
  final List<ProductRequestItem> items;
  final ProductRequestStatus status;
  final DateTime createdAt;
  final AppUser createdBy;
  final String? notes;

  const ProductRequest({
    required this.id,
    required this.fromInventory,
    required this.toInventory,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.notes,
  });

  ProductRequest copyWith({ProductRequestStatus? status, String? notes, List<ProductRequestItem>? items}) {
    return ProductRequest(
      id: id,
      fromInventory: fromInventory,
      toInventory: toInventory,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      notes: notes ?? this.notes,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.requestedQuantity);

  int get totalPrepared => items.fold(0, (sum, item) => sum + (item.preparedQuantity ?? item.requestedQuantity));

  int get totalAccepted => items.fold(0, (sum, item) => sum + (item.acceptedQuantity ?? 0));
}

// ── Mock users ─────────────────────────────────────────────────────────────────

const mockSeller = AppUser(id: 'u1', name: 'Alex (Seller)', role: AppUserRole.seller);
const mockInventoryMan = AppUser(id: 'u2', name: 'Sam (Inventory)', role: AppUserRole.inventoryMan);

// ── Mock data ─────────────────────────────────────────────────────────────────

final List<ProductRequest> mockProductRequests = [
  ProductRequest(
    id: 'REQ-001',
    fromInventory: 'Warehouse B',
    toInventory: 'Warehouse A',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    status: ProductRequestStatus.pending,
    items: const [
      ProductRequestItem(productName: 'Cotton T-Shirt', barcode: '1234567890123', productCode: 'TSH-001', requestedQuantity: 2),
      ProductRequestItem(productName: 'Denim Jeans', barcode: '1234567890124', productCode: 'JNS-002', requestedQuantity: 3),
      ProductRequestItem(productName: 'Sneakers', barcode: '1234567890125', productCode: 'SNK-003', requestedQuantity: 1),
    ],
  ),
  ProductRequest(
    id: 'REQ-002',
    fromInventory: 'Warehouse A',
    toInventory: 'Warehouse C',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    status: ProductRequestStatus.preparing,
    items: const [
      ProductRequestItem(productName: 'Leather Jacket', barcode: '1234567890126', productCode: 'JKT-004', requestedQuantity: 5),
      ProductRequestItem(productName: 'Running Shoes', barcode: '1234567890127', productCode: 'RUN-005', requestedQuantity: 4),
    ],
  ),
  ProductRequest(
    id: 'REQ-003',
    fromInventory: 'Warehouse C',
    toInventory: 'Warehouse B',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    status: ProductRequestStatus.readyForDelivery,
    items: const [ProductRequestItem(productName: 'Cotton T-Shirt', barcode: '1234567890123', productCode: 'TSH-001', requestedQuantity: 10)],
  ),
  ProductRequest(
    id: 'REQ-004',
    fromInventory: 'Warehouse B',
    toInventory: 'Warehouse A',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    status: ProductRequestStatus.onWay,
    items: const [
      ProductRequestItem(productName: 'Denim Jeans', barcode: '1234567890124', productCode: 'JNS-002', requestedQuantity: 8),
      ProductRequestItem(productName: 'Sneakers', barcode: '1234567890125', productCode: 'SNK-003', requestedQuantity: 6),
    ],
  ),
  ProductRequest(
    id: 'REQ-005',
    fromInventory: 'Warehouse A',
    toInventory: 'Warehouse B',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    status: ProductRequestStatus.waitingForPricing,
    items: const [ProductRequestItem(productName: 'Leather Jacket', barcode: '1234567890126', productCode: 'JKT-004', requestedQuantity: 2)],
  ),
  ProductRequest(
    id: 'REQ-006',
    fromInventory: 'Warehouse C',
    toInventory: 'Warehouse A',
    createdBy: mockSeller,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    status: ProductRequestStatus.closed,
    items: const [
      ProductRequestItem(productName: 'Running Shoes', barcode: '1234567890127', productCode: 'RUN-005', requestedQuantity: 12),
      ProductRequestItem(productName: 'Cotton T-Shirt', barcode: '1234567890123', productCode: 'TSH-001', requestedQuantity: 7),
    ],
  ),
];
