import 'package:inventory/features/returned_products/data/models/returned_product_models.dart';

sealed class ReturnedProductsState {
  const ReturnedProductsState();
}

class ReturnedProductsInitial extends ReturnedProductsState {
  const ReturnedProductsInitial();
}

class ReturnedProductsLoading extends ReturnedProductsState {
  const ReturnedProductsLoading();
}

class ReturnedProductsLoaded extends ReturnedProductsState {
  final List<ReturnedProduct> products;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const ReturnedProductsLoaded({
    required this.products,
    required this.totalCount,
    required this.hasMore,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  ReturnedProductsLoaded copyWith({List<ReturnedProduct>? products, int? totalCount, bool? hasMore, int? currentPage, bool? isLoadingMore}) {
    return ReturnedProductsLoaded(
      products: products ?? this.products,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ReturnedProductsError extends ReturnedProductsState {
  final String message;

  const ReturnedProductsError(this.message);
}
