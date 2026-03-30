import 'package:inventory/features/product_requests/data/models/product_requests_response_model.dart';

sealed class ProductRequestsState {
  const ProductRequestsState();
}

/// Initial state — no fetch has started yet.
final class ProductRequestsInitial extends ProductRequestsState {
  const ProductRequestsInitial();
}

/// Fetching the list for the first time (shows full-page loader).
final class ProductRequestsLoading extends ProductRequestsState {
  const ProductRequestsLoading();
}

/// List loaded successfully.
final class ProductRequestsLoaded extends ProductRequestsState {
  final List<ProductRequestModel> requests;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? statusFilter;

  const ProductRequestsLoaded({
    required this.requests,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.statusFilter,
  });

  ProductRequestsLoaded copyWith({
    List<ProductRequestModel>? requests,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) => ProductRequestsLoaded(
    requests: requests ?? this.requests,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
  );
}

/// An error occurred while loading.
final class ProductRequestsError extends ProductRequestsState {
  final String message;
  const ProductRequestsError(this.message);
}
