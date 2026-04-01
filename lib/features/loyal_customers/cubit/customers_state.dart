import 'package:inventory/features/loyal_customers/data/models/customer_model.dart';

sealed class CustomersState {
  const CustomersState();
}

/// Initial state — no fetch has started yet.
final class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

/// Fetching the list for the first time (shows full-page loader).
final class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

/// List loaded successfully.
final class CustomersLoaded extends CustomersState {
  final List<CustomerModel> customers;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? searchQuery;

  const CustomersLoaded({
    required this.customers,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  CustomersLoaded copyWith({
    List<CustomerModel>? customers,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? searchQuery,
    bool clearSearch = false,
  }) => CustomersLoaded(
    customers: customers ?? this.customers,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
  );
}

/// An error occurred while loading.
final class CustomersError extends CustomersState {
  final String message;
  const CustomersError(this.message);
}
