// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inventory';

  @override
  String get invoices => 'Invoices';

  @override
  String get inventoryProducts => 'Inventory Products';

  @override
  String get finance => 'Finance';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get versionInfo => 'v1.0.0 · Inventory App';

  @override
  String get manageInvoices => 'Manage and review your commercial invoices';

  @override
  String get addInvoiceFromImage => 'Add Invoice from Image';

  @override
  String get totalInvoices => 'Total Invoices';

  @override
  String get totalValue => 'Total Value';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get invoiceNumber => 'INVOICE #';

  @override
  String get supplier => 'SUPPLIER';

  @override
  String get date => 'DATE';

  @override
  String get items => 'ITEMS';

  @override
  String get amount => 'AMOUNT';

  @override
  String get status => 'STATUS';

  @override
  String get actions => 'ACTIONS';

  @override
  String get view => 'View';

  @override
  String get export => 'Export';

  @override
  String get delete => 'Delete';

  @override
  String get noInvoicesYet => 'No invoices yet';

  @override
  String get uploadInvoiceToStart =>
      'Upload an invoice image to get started with OCR extraction';

  @override
  String get processingInvoiceImage => 'Processing Invoice Image';

  @override
  String get uploadingImage => 'Uploading image…';

  @override
  String get runningOCR => 'Running OCR…';

  @override
  String get ocrComplete => 'OCR Complete!';

  @override
  String get reviewExtractedData => 'Review the extracted data below';

  @override
  String get model => 'Model';

  @override
  String get sku => 'SKU';

  @override
  String get qty => 'Qty';

  @override
  String get totalUSD => 'Total (USD)';

  @override
  String get rowsWithMissingData => 'rows with missing weight/dimension data';

  @override
  String get cancel => 'Cancel';

  @override
  String get openAndEditTable => 'Open & Edit Table';

  @override
  String get pcs => 'pcs';

  @override
  String invoiceDetail(String number) {
    return 'Invoice #$number';
  }

  @override
  String get totalItems => 'Total Items';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get skuLines => 'SKU Lines';

  @override
  String get rows => 'rows';

  @override
  String get warnings => 'Warnings';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get ocrResultEditableTable => 'OCR Result — Editable Table';

  @override
  String get addRow => 'Add Row';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get confirmInvoice => 'Confirm Invoice';

  @override
  String get size => 'Size';

  @override
  String get color => 'Color';

  @override
  String get unit => 'Unit';

  @override
  String get total => 'Total';

  @override
  String get boxDimensions => 'Box Dimensions';

  @override
  String get cbm => 'CBM';

  @override
  String get netWeight => 'Net (kg)';

  @override
  String get grossWeight => 'Gross (kg)';

  @override
  String get notes => 'Notes';

  @override
  String get selectAll => 'Select all';

  @override
  String get search => 'Search';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get inStock => 'In Stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get totalQuantity => 'Total Quantity';

  @override
  String get lowStockItems => 'Low Stock Items';

  @override
  String get outOfStockItems => 'Out of Stock Items';

  @override
  String get name => 'Name';

  @override
  String get actualQty => 'Actual Qty';

  @override
  String get invoiceQty => 'Invoice Qty';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get invoiceTotal => 'Invoice Total';

  @override
  String get actualTotal => 'Actual Total';

  @override
  String get barcode => 'Barcode';

  @override
  String get coordinate => 'Coordinate';

  @override
  String get source => 'Source';

  @override
  String get noProducts => 'No products found';

  @override
  String get adjustFilters => 'Try adjusting your filters or search query';
}
