import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/invoice_ocr/cubit/invoice_ocr_state.dart';
import 'package:inventory/features/invoice_ocr/data/repositories/invoice_ocr_repository.dart';

class InvoiceOcrCubit extends Cubit<InvoiceOcrState> {
  InvoiceOcrCubit({InvoiceOcrRepository? repository}) : _repository = repository ?? InvoiceOcrRepository.instance, super(const InvoiceOcrInitial());

  final InvoiceOcrRepository _repository;

  /// Call this method after the user picks an image file.
  Future<void> uploadInvoice({required List<int> fileBytes, required String fileName}) async {
    // 1. Show uploading indicator
    emit(InvoiceOcrUploading(fileName));

    // 2. Hit the API
    final result = await _repository.uploadInvoiceImage(fileBytes: fileBytes, fileName: fileName);

    // 3. Emit success or failure based on the result
    switch (result) {
      case Success(:final data):
        if (data.success) {
          emit(InvoiceOcrSuccess(data));
        } else {
          emit(InvoiceOcrFailure(data.message));
        }
      case Failure(:final message):
        emit(InvoiceOcrFailure(message));
    }
  }

  /// Reset back to initial so the dialog can be reused.
  void reset() => emit(const InvoiceOcrInitial());
}
