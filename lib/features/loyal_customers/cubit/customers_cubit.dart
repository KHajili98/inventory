import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/loyal_customers/cubit/customers_state.dart';
import 'package:inventory/features/loyal_customers/data/models/customer_model.dart';
import 'package:inventory/features/loyal_customers/data/repositories/customers_repository.dart';

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit({CustomersRepository? repository}) : _repository = repository ?? CustomersRepository.instance, super(const CustomersInitial());

  final CustomersRepository _repository;

  Timer? _debounce;

  /// Fetches the first page, optionally filtered by [search].
  Future<void> fetchCustomers({String? search}) async {
    emit(const CustomersLoading());

    final result = await _repository.fetchCustomers(page: 1, search: search);

    switch (result) {
      case Success(:final data):
        emit(CustomersLoaded(customers: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1, searchQuery: search));
      case Failure(:final message):
        emit(CustomersError(message));
    }
  }

  /// Debounced search — waits 400 ms after the user stops typing.
  void searchDebounced(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchCustomers(search: query.isEmpty ? null : query);
    });
  }

  /// Load the next page and append to the existing list.
  Future<void> loadMore() async {
    final current = state;
    if (current is! CustomersLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchCustomers(page: nextPage, search: current.searchQuery);

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            customers: [...current.customers, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure():
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Create a new customer and prepend to the loaded list.
  Future<ApiResult<CustomerModel>> createCustomer({
    required String name,
    required String surname,
    required String phoneNumber,
    required String loyaltyId,
    required double discountPercentage,
  }) async {
    final result = await _repository.createCustomer(
      name: name,
      surname: surname,
      phoneNumber: phoneNumber,
      loyaltyId: loyaltyId,
      discountPercentage: discountPercentage,
    );

    if (result is Success<CustomerModel>) {
      final current = state;
      if (current is CustomersLoaded) {
        emit(current.copyWith(customers: [result.data, ...current.customers], totalCount: current.totalCount + 1));
      }
    }

    return result;
  }

  /// Update an existing customer and refresh the item in the list.
  Future<ApiResult<CustomerModel>> updateCustomer({
    required String id,
    required String name,
    required String surname,
    required String phoneNumber,
    required String loyaltyId,
    required double discountPercentage,
  }) async {
    final result = await _repository.updateCustomer(
      id: id,
      name: name,
      surname: surname,
      phoneNumber: phoneNumber,
      loyaltyId: loyaltyId,
      discountPercentage: discountPercentage,
    );

    if (result is Success<CustomerModel>) {
      final current = state;
      if (current is CustomersLoaded) {
        final updated = current.customers.map((c) => c.id == id ? result.data : c).toList();
        emit(current.copyWith(customers: updated));
      }
    }

    return result;
  }

  /// Refresh — re-fetches the first page keeping the current search query.
  Future<void> refresh() async {
    final currentSearch = state is CustomersLoaded ? (state as CustomersLoaded).searchQuery : null;
    await fetchCustomers(search: currentSearch);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
