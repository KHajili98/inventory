import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/inventory_products/cubit/inventory_products_state.dart';
import 'package:inventory/features/inventory_products/data/models/create_inventory_product_request_model.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';
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
        emit(
          InventoryProductsLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1, pageSize: _pageSize),
        );
      case Failure(:final message):
        emit(InventoryProductsError(message));
    }
  }

  /// Fetch a specific page.
  Future<void> goToPage(int page) async {
    emit(const InventoryProductsLoading());

    final result = await _repository.fetchProducts(page: page, pageSize: _pageSize);

    switch (result) {
      case Success(:final data):
        emit(
          InventoryProductsLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: page, pageSize: _pageSize),
        );
      case Failure(:final message):
        // Restore count context if available
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

  /// Refresh — re-fetches the current page (or page 1 if not loaded).
  Future<void> refresh() async {
    final current = state;
    final page = current is InventoryProductsLoaded ? current.currentPage : 1;
    // If we're on page > 1 and some deletion happened, stay on the same page
    // (backend will return fewer items; that's fine)
    final result = await _repository.fetchProducts(page: page, pageSize: _pageSize);

    switch (result) {
      case Success(:final data):
        // If the page is now empty and it's not page 1, go back one page
        if (data.results.isEmpty && page > 1) {
          return goToPage(page - 1);
        }
        emit(
          InventoryProductsLoaded(products: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: page, pageSize: _pageSize),
        );
      case Failure(:final message):
        emit(InventoryProductsError(message));
    }
  }

  /// Creates a new product via POST /api/inventory-products/
  /// Emits [InventoryProductCreating] → [InventoryProductCreated] or [InventoryProductCreateError].
  /// Returns the [ApiResult] so callers can inspect success/failure directly.
  /// On success, the list is refreshed so the new item appears.
  Future<ApiResult<InventoryProductItemModel>> createProduct(CreateInventoryProductRequestModel request) async {
    // Keep a snapshot of the current loaded state so we can restore it on error.
    final previousState = state;

    emit(const InventoryProductCreating());

    final result = await _repository.createProduct(request);

    switch (result) {
      case Success(:final data):
        emit(InventoryProductCreated(data));
        // Refresh the list to include the newly created product.
        await refresh();
      case Failure(:final message):
        emit(InventoryProductCreateError(message));
        // Restore previous state so the table still shows data.
        if (previousState is InventoryProductsLoaded) {
          emit(previousState);
        }
    }

    return result;
  }

  /// Deletes a product by [id] via DELETE /api/inventory-products/{id}/
  /// On success the list is refreshed. Returns the [ApiResult] for callers.
  Future<ApiResult<void>> deleteProduct(String id) async {
    final result = await _repository.deleteProduct(id);

    if (result is Success) {
      await refresh();
    }

    return result;
  }

  /// Updates a product by [id] via PATCH /api/inventory-products/{id}/
  /// On success the list is refreshed. Returns the [ApiResult] for callers.
  Future<ApiResult<InventoryProductItemModel>> updateProduct(String id, Map<String, dynamic> data) async {
    final result = await _repository.updateProduct(id, data);

    if (result is Success) {
      await refresh();
    }

    return result;
  }
}
