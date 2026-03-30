import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';

sealed class StocksState {
  const StocksState();
}

final class StocksInitial extends StocksState {
  const StocksInitial();
}

final class StocksLoading extends StocksState {
  const StocksLoading();
}

final class StocksLoaded extends StocksState {
  final List<StockProductItemModel> products;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? searchQuery;
  final String? inventoryId;

  const StocksLoaded({
    required this.products,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.searchQuery,
    this.inventoryId,
  });

  StocksLoaded copyWith({
    List<StockProductItemModel>? products,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? searchQuery,
    String? inventoryId,
  }) => StocksLoaded(
    products: products ?? this.products,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchQuery: searchQuery ?? this.searchQuery,
    inventoryId: inventoryId ?? this.inventoryId,
  );
}

final class StocksError extends StocksState {
  final String message;
  const StocksError(this.message);
}
