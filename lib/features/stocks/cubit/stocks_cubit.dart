import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/stocks/cubit/stocks_state.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';

class StocksCubit extends Cubit<StocksState> {
  StocksCubit({StocksRepository? repository}) : _repository = repository ?? StocksRepository.instance, super(const StocksInitial());

  final StocksRepository _repository;

  static const int _pageSize = 20;

  Future<void> fetchStocks({String? search, String? inventoryId}) async {
    emit(const StocksLoading());
    final result = await _repository.fetchStocks(page: 1, pageSize: _pageSize, search: search, inventoryId: inventoryId);
    switch (result) {
      case Success(:final data):
        emit(
          StocksLoaded(
            products: data.results,
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: 1,
            searchQuery: search,
            inventoryId: inventoryId,
          ),
        );
      case Failure(:final message):
        emit(StocksError(message));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! StocksLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final result = await _repository.fetchStocks(
      page: current.currentPage + 1,
      pageSize: _pageSize,
      search: current.searchQuery,
      inventoryId: current.inventoryId,
    );
    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            products: [...current.products, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: current.currentPage + 1,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        emit(current.copyWith(isLoadingMore: false));
        emit(StocksError(message));
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Creates a new stock item and re-fetches page 1.
  Future<ApiResult<StockProductItemModel>> createStock(CreateStockItemRequest request) async {
    final result = await _repository.createStock(request);
    if (result is Success) {
      final current = state;
      final search = current is StocksLoaded ? current.searchQuery : null;
      final inventoryId = current is StocksLoaded ? current.inventoryId : null;
      await fetchStocks(search: search, inventoryId: inventoryId);
    }
    return result;
  }

  /// Deletes a stock item and removes it from the loaded list.
  Future<ApiResult<void>> deleteStock(String id) async {
    final result = await _repository.deleteStock(id);
    if (result is Success) {
      final current = state;
      if (current is StocksLoaded) {
        final updated = current.products.where((p) => p.id != id).toList();
        emit(current.copyWith(products: updated, totalCount: current.totalCount - 1));
      }
    }
    return result;
  }
}
