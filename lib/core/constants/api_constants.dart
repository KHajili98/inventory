abstract class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://13.53.43.184:8000';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login/';
  static const String tokenRefresh = '/api/auth/token/refresh/';

  // ── Inventories ─────────────────────────────────────────────────────────────
  static const String inventories = '/api/inventories/';

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

  // ── Product Requests ──────────────────────────────────────────────────────
  static const String productRequests = '/api/requests/';

  /// Single product request by UUID.
  static String productRequestDetail(String id) => '/api/requests/$id/';

  static String changeRequestStatus(String id) => '/api/requests/$id/change-status/';

  // ── Loyal Customers ──────────────────────────────────────────────────────
  static const String customers = '/api/customers/';

  /// Single loyal customer by UUID.
  static String customerDetail(String id) => '/api/customers/$id/';

  // ── Stocks ────────────────────────────────────────────────────────────────
  static const String stocks = '/api/stocks/';

  // ── Fee Categories ────────────────────────────────────────────────────────
  static const String feeCategories = '/api/fee-categories/';

  /// Single fee-category by UUID.
  static String feeCategoryDetail(String id) => '/api/fee-categories/$id/';

  // ── Selling Transactions ──────────────────────────────────────────────────
  static const String completePayment = '/api/selling-transactions/complete-payment/';

  /// GET /api/selling-transactions/ (paginated list)
  static const String sellingTransactionsList = '/api/selling-transactions/';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 3); // OCR can take ~75 s
  static const Duration sendTimeout = Duration(seconds: 60);
}
