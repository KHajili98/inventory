abstract class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://13.53.43.184:8000';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login/';

  // ── Endpoints ───────────────────────────────────────────────────────────────
  static const String uploadInvoice = '/api/invoices/upload/';
  static const String invoicesList = '/api/invoices-list/';

  /// Append `{id}/` to get a single invoice detail.
  static String invoiceDetail(String id) => '/api/invoices-list/$id/';

  /// Confirm (submit) an invoice by UUID — sends the edited rows as JSON body.
  static String invoiceConfirm(String id) => '/api/invoices-list/';

  /// Delete an invoice by UUID.
  static String invoiceDelete(String id) => '/api/invoices-list/$id';

  // ── Inventory Products ───────────────────────────────────────────────────────
  static const String inventoryProducts = '/api/inventory-products/';

  // ── Barcode Generation ────────────────────────────────────────────────────────
  static const String generateBarcode = '/api/generate-barcode/';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 3); // OCR can take ~75 s
  static const Duration sendTimeout = Duration(seconds: 60);
}
