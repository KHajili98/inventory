import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';

sealed class TransactionListState {
  const TransactionListState();
}

final class TransactionListInitial extends TransactionListState {
  const TransactionListInitial();
}

final class TransactionListLoading extends TransactionListState {
  const TransactionListLoading();
}

final class TransactionListLoaded extends TransactionListState {
  final List<SellingTransactionResponse> transactions;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const TransactionListLoaded({
    required this.transactions,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  TransactionListLoaded copyWith({
    List<SellingTransactionResponse>? transactions,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) => TransactionListLoaded(
    transactions: transactions ?? this.transactions,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

final class TransactionListError extends TransactionListState {
  final String message;
  const TransactionListError(this.message);
}
