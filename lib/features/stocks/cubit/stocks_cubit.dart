import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/stocks/cubit/stocks_state.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';

class StocksCubit extends Cubit<StocksState> {
  StocksCubit({StocksRepository? repository}) : _repository = repository ?? StocksRepository.instance, super(const StocksInitial());

  final StocksRepository _repository;

  Future<void> fetchStocks({String? search, String? inventoryId}) async {
    emit(const StocksLoading());
    final result = await _repository.fetchStocks(page: 1, search: search, inventoryId: inventoryId);
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
    final result = await _repository.fetchStocks(page: current.currentPage + 1, search: current.searchQuery, inventoryId: current.inventoryId);
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
}
