import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/product_requests/cubit/product_requests_state.dart';
import 'package:inventory/features/product_requests/data/models/product_requests_response_model.dart';
import 'package:inventory/features/product_requests/data/repositories/product_requests_repository.dart';

class ProductRequestsCubit extends Cubit<ProductRequestsState> {
  ProductRequestsCubit({ProductRequestsRepository? repository})
    : _repository = repository ?? ProductRequestsRepository.instance,
      super(const ProductRequestsInitial());

  final ProductRequestsRepository _repository;

  /// Fetches the first page, optionally filtered by [status].
  Future<void> fetchRequests({String? status}) async {
    emit(const ProductRequestsLoading());

    final result = await _repository.fetchRequests(page: 1, status: status);

    switch (result) {
      case Success(:final data):
        emit(ProductRequestsLoaded(requests: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1, statusFilter: status));
      case Failure(:final message):
        emit(ProductRequestsError(message));
    }
  }

  /// Load the next page and append to the existing list.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductRequestsLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchRequests(page: nextPage, status: current.statusFilter);

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            requests: [...current.requests, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        emit(current.copyWith(isLoadingMore: false));
        emit(ProductRequestsError(message));
        // Restore the loaded state so the list remains visible
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh — re-fetches the first page keeping the current status filter.
  Future<void> refresh() async {
    final currentFilter = state is ProductRequestsLoaded ? (state as ProductRequestsLoaded).statusFilter : null;
    await fetchRequests(status: currentFilter);
  }

  /// Update the status of a request optimistically, then confirm via API.
  Future<ApiResult<ProductRequestModel>> updateStatus(String id, String newStatus) async {
    final result = await _repository.updateStatus(id, newStatus);

    if (result is Success<ProductRequestModel>) {
      final current = state;
      if (current is ProductRequestsLoaded) {
        final updated = current.requests.map((r) => r.id == id ? result.data : r).toList();
        emit(current.copyWith(requests: updated));
      }
    }

    return result;
  }

  /// Delete a request and remove it from the loaded list.
  Future<ApiResult<void>> deleteRequest(String id) async {
    final result = await _repository.deleteRequest(id);

    if (result is Success) {
      final current = state;
      if (current is ProductRequestsLoaded) {
        final updated = current.requests.where((r) => r.id != id).toList();
        emit(current.copyWith(requests: updated, totalCount: (current.totalCount - 1).clamp(0, current.totalCount)));
      }
    }

    return result;
  }
}
