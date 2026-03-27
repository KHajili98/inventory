import 'package:inventory/features/invoice_ocr/data/models/invoice_upload_response_model.dart';

sealed class InvoiceOcrState {
  const InvoiceOcrState();
}

/// Nothing has happened yet.
final class InvoiceOcrInitial extends InvoiceOcrState {
  const InvoiceOcrInitial();
}

/// File has been picked, upload is in progress.
final class InvoiceOcrUploading extends InvoiceOcrState {
  final String fileName;
  const InvoiceOcrUploading(this.fileName);
}

/// Upload done, OCR is running on the server.
final class InvoiceOcrProcessing extends InvoiceOcrState {
  final String fileName;
  const InvoiceOcrProcessing(this.fileName);
}

/// OCR finished successfully.
final class InvoiceOcrSuccess extends InvoiceOcrState {
  final InvoiceUploadResponseModel response;
  const InvoiceOcrSuccess(this.response);
}

/// Something went wrong.
final class InvoiceOcrFailure extends InvoiceOcrState {
  final String message;
  const InvoiceOcrFailure(this.message);
}
