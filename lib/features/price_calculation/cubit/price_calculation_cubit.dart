import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/price_calculation/cubit/price_calculation_state.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';

class PriceCalculationCubit extends Cubit<PriceCalculationState> {
  PriceCalculationCubit({StocksRepository? repository})
    : _repository = repository ?? StocksRepository.instance,
      super(const PriceCalculationInitial());

  final StocksRepository _repository;

  static const int _pageSize = 20;

  Future<void> fetchItems({String? search}) async {
    emit(const PriceCalculationLoading());
    final result = await _repository.fetchStocks(page: 1, pageSize: _pageSize, search: search, priced: false);
    switch (result) {
      case Success(:final data):
        emit(PriceCalculationLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1, searchQuery: search));
      case Failure(:final message):
        emit(PriceCalculationError(message));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PriceCalculationLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final result = await _repository.fetchStocks(page: current.currentPage + 1, pageSize: _pageSize, search: current.searchQuery, priced: false);
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
      case Failure():
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  void removeItem(String id) {
    final current = state;
    if (current is! PriceCalculationLoaded) return;
    emit(current.copyWith(products: current.products.where((p) => p.id != id).toList(), totalCount: current.totalCount - 1));
  }
}
