import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/selling_transactions/cubit/transaction_list_state.dart';
import 'package:inventory/features/selling_transactions/data/repositories/selling_transactions_repository.dart';

class TransactionListCubit extends Cubit<TransactionListState> {
  TransactionListCubit({SellingTransactionsRepository? repository})
    : _repository = repository ?? SellingTransactionsRepository.instance,
      super(const TransactionListInitial());

  final SellingTransactionsRepository _repository;

  // Active filter state — kept here so cubit can re-fetch with same filters
  String? _search;
  String? _loggedInInventory;
  String? _paymentMethod;
  String? _priceType;

  /// Fetch the first page with optional filters.
  Future<void> fetchTransactions({String? search, String? loggedInInventory, String? paymentMethod, String? priceType}) async {
    _search = search;
    _loggedInInventory = loggedInInventory;
    _paymentMethod = paymentMethod;
    _priceType = priceType;

    emit(const TransactionListLoading());

    final result = await _repository.fetchTransactions(
      page: 1,
      search: _search,
      loggedInInventory: _loggedInInventory,
      paymentMethod: _paymentMethod,
      priceType: _priceType,
    );

    switch (result) {
      case Success(:final data):
        emit(TransactionListLoaded(transactions: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1));
      case Failure(:final message):
        emit(TransactionListError(message));
    }
  }

  /// Load the next page and append results.
  Future<void> loadMore() async {
    final current = state;
    if (current is! TransactionListLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchTransactions(
      page: nextPage,
      search: _search,
      loggedInInventory: _loggedInInventory,
      paymentMethod: _paymentMethod,
      priceType: _priceType,
    );

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            transactions: [...current.transactions, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        emit(current.copyWith(isLoadingMore: false));
        emit(TransactionListError(message));
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh — re-fetch with current filters.
  Future<void> refresh() =>
      fetchTransactions(search: _search, loggedInInventory: _loggedInInventory, paymentMethod: _paymentMethod, priceType: _priceType);
}
