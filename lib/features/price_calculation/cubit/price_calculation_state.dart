import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';

sealed class PriceCalculationState {
  const PriceCalculationState();
}

final class PriceCalculationInitial extends PriceCalculationState {
  const PriceCalculationInitial();
}

final class PriceCalculationLoading extends PriceCalculationState {
  const PriceCalculationLoading();
}

final class PriceCalculationLoaded extends PriceCalculationState {
  final List<StockProductItemModel> products;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? searchQuery;

  const PriceCalculationLoaded({
    required this.products,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  PriceCalculationLoaded copyWith({
    List<StockProductItemModel>? products,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? searchQuery,
  }) => PriceCalculationLoaded(
    products: products ?? this.products,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

final class PriceCalculationError extends PriceCalculationState {
  final String message;
  const PriceCalculationError(this.message);
}
