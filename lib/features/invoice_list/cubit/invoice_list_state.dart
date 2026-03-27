import 'package:inventory/features/invoice_list/data/models/invoice_list_response_model.dart';

sealed class InvoiceListState {
  const InvoiceListState();
}

/// Initial state — no fetch has started yet.
final class InvoiceListInitial extends InvoiceListState {
  const InvoiceListInitial();
}

/// Fetching the list for the first time (shows full-page loader).
final class InvoiceListLoading extends InvoiceListState {
  const InvoiceListLoading();
}

/// List loaded successfully.
final class InvoiceListLoaded extends InvoiceListState {
  final List<InvoiceListItemModel> invoices;
  final int totalCount;
  final bool hasMore;

  const InvoiceListLoaded({required this.invoices, required this.totalCount, this.hasMore = false});
}

/// An error occurred while loading.
final class InvoiceListError extends InvoiceListState {
  final String message;
  const InvoiceListError(this.message);
}
