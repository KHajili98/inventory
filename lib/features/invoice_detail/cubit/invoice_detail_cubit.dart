import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/invoice_detail/cubit/invoice_detail_state.dart';
import 'package:inventory/features/invoice_detail/data/repositories/invoice_detail_repository.dart';

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  InvoiceDetailCubit({InvoiceDetailRepository? repository})
    : _repository = repository ?? InvoiceDetailRepository.instance,
      super(const InvoiceDetailInitial());

  final InvoiceDetailRepository _repository;

  Future<void> fetchDetail(String id) async {
    emit(const InvoiceDetailLoading());
    final result = await _repository.fetchInvoiceDetail(id);
    switch (result) {
      case Success(:final data):
        emit(InvoiceDetailLoaded(data));
      case Failure(:final message):
        emit(InvoiceDetailError(message));
    }
  }

  void retry(String id) => fetchDetail(id);
}
