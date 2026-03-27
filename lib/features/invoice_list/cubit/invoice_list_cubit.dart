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

    final result = await _repository.fetchInvoices();

    switch (result) {
      case Success(:final data):
        emit(InvoiceListLoaded(invoices: data.results, totalCount: data.count, hasMore: data.next != null));
      case Failure(:final message):
        emit(InvoiceListError(message));
    }
  }

  /// Refresh — re-fetches the first page and updates the loaded list.
  Future<void> refresh() => fetchInvoices();

  /// Prepend a newly created invoice to the top of the current list.
  void prependInvoice(InvoiceListItemModel invoice) {
    final current = state;
    if (current is InvoiceListLoaded) {
      emit(InvoiceListLoaded(invoices: [invoice, ...current.invoices], totalCount: current.totalCount + 1, hasMore: current.hasMore));
    }
  }
}
