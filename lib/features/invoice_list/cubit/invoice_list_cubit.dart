import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/invoice_list/cubit/invoice_list_state.dart';
import 'package:inventory/features/invoice_list/data/models/invoice_list_response_model.dart';
import 'package:inventory/features/invoice_list/data/repositories/invoice_list_repository.dart';

class InvoiceListCubit extends Cubit<InvoiceListState> {
  InvoiceListCubit({InvoiceListRepository? repository})
    : _repository = repository ?? InvoiceListRepository.instance,
      super(const InvoiceListInitial());

  final InvoiceListRepository _repository;

  /// Fetch the first page of invoices.
  Future<void> fetchInvoices() async {
    emit(const InvoiceListLoading());

    final result = await _repository.fetchInvoices(page: 1);

    switch (result) {
      case Success(:final data):
        emit(InvoiceListLoaded(invoices: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1));
      case Failure(:final message):
        emit(InvoiceListError(message));
    }
  }

  /// Load the next page and append results to the existing list.
  Future<void> loadMoreInvoices() async {
    final current = state;
    if (current is! InvoiceListLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchInvoices(page: nextPage);

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            invoices: [...current.invoices, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        // Revert loading flag and surface error via a temporary state
        emit(current.copyWith(isLoadingMore: false));
        emit(InvoiceListError(message));
        // Re-emit the loaded state so the list is still visible
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh — re-fetches the first page and updates the loaded list.
  Future<void> refresh() => fetchInvoices();

  /// Prepend a newly created invoice to the top of the current list.
  void prependInvoice(InvoiceListItemModel invoice) {
    final current = state;
    if (current is InvoiceListLoaded) {
      emit(current.copyWith(invoices: [invoice, ...current.invoices], totalCount: current.totalCount + 1));
    }
  }
}
