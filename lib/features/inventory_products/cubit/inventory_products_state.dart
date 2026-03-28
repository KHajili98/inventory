import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';

sealed class InventoryProductsState {
  const InventoryProductsState();
}

/// Initial state — no fetch has started yet.
final class InventoryProductsInitial extends InventoryProductsState {
  const InventoryProductsInitial();
}

/// Fetching the list for the first time (shows full-page loader).
final class InventoryProductsLoading extends InventoryProductsState {
  const InventoryProductsLoading();
}

/// List loaded successfully.
final class InventoryProductsLoaded extends InventoryProductsState {
  final List<InventoryProductItemModel> products;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const InventoryProductsLoaded({
    required this.products,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  InventoryProductsLoaded copyWith({
    List<InventoryProductItemModel>? products,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) => InventoryProductsLoaded(
    products: products ?? this.products,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// An error occurred while loading.
final class InventoryProductsError extends InventoryProductsState {
  final String message;
  const InventoryProductsError(this.message);
}
