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
  String get priceCalculation => 'Price Calculation';

  @override
  String get expenseTracking => 'Expense Tracking';

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
  String get invoiceDate => 'INVOICE DATE';

  @override
  String get createdAt => 'CREATED AT';

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
  String get productName => 'Product Name';

  @override
  String get generatedName => 'Generated Name';

  @override
  String get colorCode => 'Color Code';

  @override
  String get pcsPerCarton => 'Pcs/Carton';

  @override
  String get cartons => 'Cartons';

  @override
  String get totalWeightKg => 'Total Wt (kg)';

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

  @override
  String get selected => 'selected';

  @override
  String get totals => 'TOTALS';

  @override
  String get totalQty => 'Total Qty';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get confirmAndSave => 'Confirm & Save';

  @override
  String get trackStockLevels => 'Track stock levels, locations and valuations';

  @override
  String get addProduct => 'Add Product';

  @override
  String get chooseHowToAddProduct => 'Choose how you want to add the product';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get fillProductDetails => 'Fill in all product\ndetails by hand';

  @override
  String get fromInvoice => 'From Invoice';

  @override
  String get importFromInvoice => 'Import from a\nconfirmed invoice';

  @override
  String get totalSKUs => 'Total SKUs';

  @override
  String get totalUnits => 'Total Units';

  @override
  String get searchSKUNameBarcode => 'Search SKU, name, barcode, location…';

  @override
  String get noProductsMatchSearch => 'No products match your search.';

  @override
  String get all => 'All';

  @override
  String get scrollToStart => 'Scroll to start';

  @override
  String get scrollToEnd => 'Scroll to end';

  @override
  String get scrollToTop => 'Scroll to top';

  @override
  String get scrollToBottom => 'Scroll to bottom';

  @override
  String get scrollLeft => 'Scroll left';

  @override
  String get scrollRight => 'Scroll right';

  @override
  String get scrollUp => 'Scroll up';

  @override
  String get scrollDown => 'Scroll down';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get location => 'Location';

  @override
  String nOfMProducts(int n, int m) {
    return '$n of $m products';
  }

  @override
  String get selectInvoice => 'Select Invoice';

  @override
  String get chooseInvoiceToImport =>
      'Choose an invoice to import products from';

  @override
  String get noInvoicesAvailable => 'No invoices available';

  @override
  String get addInvoicesFirst => 'Add invoices in the Invoices module first';

  @override
  String importFromInvoiceNo(String invoiceNo) {
    return 'Import from $invoiceNo';
  }

  @override
  String get selectProducts => 'Select Products';

  @override
  String get enterDetails => 'Enter Details';

  @override
  String nUniqueSkusFromInvoice(int n) {
    return '$n unique SKUs from invoice';
  }

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selectAllLabel => 'Select All';

  @override
  String get invQty => 'Inv. Qty';

  @override
  String get invTotal => 'Inv. Total';

  @override
  String fillWarehouseDetails(int count) {
    return 'Fill in warehouse details for $count selected product(s)';
  }

  @override
  String invoiceQtyLabel(int qty) {
    return 'Invoice qty: $qty';
  }

  @override
  String get actualQtyReceived => 'Actual Qty Received';

  @override
  String vsInvoice(String diff) {
    return '$diff vs invoice';
  }

  @override
  String get warehouseLocation => 'Warehouse Location';

  @override
  String get zone => 'Zone';

  @override
  String get row => 'Row';

  @override
  String get shelf => 'Shelf';

  @override
  String get codeLabel => 'Code';

  @override
  String get back => 'Back';

  @override
  String get nextEnterDetails => 'Next: Enter Details';

  @override
  String nOfMSelected(int n, int m) {
    return '$n of $m selected';
  }

  @override
  String importNProducts(int n) {
    return 'Import $n Product(s)';
  }

  @override
  String nProductsImported(int n, String invoiceNo) {
    return '$n product(s) imported from invoice $invoiceNo';
  }

  @override
  String get editProduct => 'Edit Product';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get skuField => 'SKU';

  @override
  String get modelField => 'Model';

  @override
  String get colorField => 'Color';

  @override
  String get barcodeField => 'Barcode';

  @override
  String get quantityField => 'Quantity';

  @override
  String get unitPriceUSD => 'Unit Price (USD)';

  @override
  String get zoneLetter => 'Zone letter (A–Z)';

  @override
  String locationCode(String code) {
    return 'Location code: $code';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get required => 'Required';

  @override
  String discrepancyTooltip(String diff) {
    return 'Discrepancy: $diff vs invoice';
  }

  @override
  String get colorCodeField => 'Color Code';

  @override
  String get sizeField => 'Size';

  @override
  String get actualPcsPerCarton => 'Actual Pcs/Carton';

  @override
  String get actualCartonCount => 'Actual Carton Count';

  @override
  String get productInfoSection => 'Product Info';

  @override
  String get packagingSection => 'Packaging';

  @override
  String get savingProduct => 'Saving product…';

  @override
  String get productSavedSuccess => 'Product added successfully!';

  @override
  String productSaveFailed(String error) {
    return 'Failed to save product: $error';
  }

  @override
  String get loadingInvoices => 'Loading invoices…';

  @override
  String fetchInvoicesFailed(String error) {
    return 'Failed to load invoices: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get loadingInvoiceDetail => 'Loading invoice details…';

  @override
  String fetchInvoiceDetailFailed(String error) {
    return 'Failed to load invoice: $error';
  }

  @override
  String nItemsInInvoice(int n) {
    return '$n item(s) in invoice';
  }

  @override
  String get invoicePcsPerCarton => 'Inv. Pcs/Carton';

  @override
  String get invoiceCartonCount => 'Inv. Carton Count';

  @override
  String importingProducts(int current, int total) {
    return 'Importing $current of $total…';
  }

  @override
  String importSuccessN(int n) {
    return '$n product(s) imported successfully!';
  }

  @override
  String importFailedN(int n) {
    return '$n product(s) failed to import.';
  }

  @override
  String estimatedTotalPrice(String total, String unitPrice) {
    return 'Est. Total: \$$total  (qty × \$$unitPrice/unit)';
  }
}
