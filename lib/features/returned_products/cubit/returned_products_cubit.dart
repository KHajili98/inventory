import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/returned_products/cubit/returned_products_state.dart';
import 'package:inventory/features/returned_products/data/repositories/returned_products_repository.dart';

class ReturnedProductsCubit extends Cubit<ReturnedProductsState> {
  ReturnedProductsCubit({ReturnedProductsRepository? repository})
    : _repository = repository ?? ReturnedProductsRepository.instance,
      super(const ReturnedProductsInitial());

  final ReturnedProductsRepository _repository;

  // Active filter state
  String? _search;
  String? _receiptNumber;
  bool? _isDefected;

  /// Fetch the first page with optional filters.
  Future<void> fetchReturnedProducts({String? search, String? receiptNumber, bool? isDefected}) async {
    _search = search;
    _receiptNumber = receiptNumber;
    _isDefected = isDefected;

    emit(const ReturnedProductsLoading());

    final result = await _repository.fetchReturnedProducts(page: 1, search: _search, receiptNumber: _receiptNumber, isDefected: _isDefected);

    switch (result) {
      case Success(:final data):
        emit(ReturnedProductsLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1));
      case Failure(:final message):
        emit(ReturnedProductsError(message));
    }
  }

  /// Load the next page and append results.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ReturnedProductsLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchReturnedProducts(page: nextPage, search: _search, receiptNumber: _receiptNumber, isDefected: _isDefected);

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            products: [...current.products, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        emit(current.copyWith(isLoadingMore: false));
        emit(ReturnedProductsError(message));
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh — re-fetch with current filters.
  Future<void> refresh() => fetchReturnedProducts(search: _search, receiptNumber: _receiptNumber, isDefected: _isDefected);
}
