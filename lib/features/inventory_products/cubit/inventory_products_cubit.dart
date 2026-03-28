import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_state.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_products_repository.dart';

class InventoryProductsCubit extends Cubit<InventoryProductsState> {
  InventoryProductsCubit({InventoryProductsRepository? repository})
    : _repository = repository ?? InventoryProductsRepository.instance,
      super(const InventoryProductsInitial());

  final InventoryProductsRepository _repository;

  static const int _pageSize = 10;

  /// Fetch the first page of inventory products.
  Future<void> fetchProducts() async {
    emit(const InventoryProductsLoading());

    final result = await _repository.fetchProducts(page: 1, pageSize: _pageSize);

    switch (result) {
      case Success(:final data):
        emit(InventoryProductsLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1));
      case Failure(:final message):
        emit(InventoryProductsError(message));
    }
  }

  /// Load the next page and append results to the existing list.
  Future<void> loadMoreProducts() async {
    final current = state;
    if (current is! InventoryProductsLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchProducts(page: nextPage, pageSize: _pageSize);

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
        emit(InventoryProductsError(message));
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh — re-fetches the first page.
  Future<void> refresh() => fetchProducts();
}
