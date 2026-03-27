import 'package:inventory/features/invoice_detail/data/models/invoice_detail_model.dart';

sealed class InvoiceDetailState {
  const InvoiceDetailState();
}

final class InvoiceDetailInitial extends InvoiceDetailState {
  const InvoiceDetailInitial();
}

final class InvoiceDetailLoading extends InvoiceDetailState {
  const InvoiceDetailLoading();
}

final class InvoiceDetailLoaded extends InvoiceDetailState {
  final InvoiceDetailModel invoice;
  const InvoiceDetailLoaded(this.invoice);
}

final class InvoiceDetailError extends InvoiceDetailState {
  final String message;
  const InvoiceDetailError(this.message);
}
