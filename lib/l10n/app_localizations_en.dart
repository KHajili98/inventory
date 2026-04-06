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
  String get pos => 'POS';

  @override
  String get sellModule => 'Sell';

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
  String get searchSKUNameBarcode => 'Search name, barcode, location…';

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

  @override
  String get generateBarcode => 'Generate';

  @override
  String get generatingBarcode => 'Generating…';

  @override
  String get barcodeGeneratedSuccess => 'Barcode generated successfully';

  @override
  String barcodeGenerateFailed(String error) {
    return 'Failed to generate barcode: $error';
  }

  @override
  String get addExpense => 'Add Expense';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expensePaymentType => 'Payment Type';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get expenseDate => 'Date';

  @override
  String get expenseDocument => 'Document';

  @override
  String get expenseNote => 'Note';

  @override
  String get expenseCategoryRent => 'Rent';

  @override
  String get expenseCategoryCommunal => 'Communal';

  @override
  String get expenseCategorySalary => 'Salary';

  @override
  String get expenseCategoryTransport => 'Transport';

  @override
  String get expenseCategoryCustoms => 'Customs';

  @override
  String get expenseCategoryOther => 'Other';

  @override
  String get expensePaymentCash => 'Cash';

  @override
  String get expensePaymentCard => 'Card';

  @override
  String get expensePaymentTransfer => 'Transfer';

  @override
  String get expenseSelectCategory => 'Select category';

  @override
  String get expenseSelectPaymentType => 'Select payment type';

  @override
  String get expenseAmountHint => '0.00';

  @override
  String get expenseNoteHint => 'Enter a note…';

  @override
  String get expenseDocumentHint => 'Select file (image, PDF)';

  @override
  String expenseDocumentSelected(Object name) {
    return 'Selected: $name';
  }

  @override
  String get expenseDocumentChoose => 'Choose File';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get addFirstExpense => 'Press the button to add your first expense';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get expenseCount => 'Expense Count';

  @override
  String get save => 'Save';

  @override
  String get expenseFilterByDate => 'Filter by date';

  @override
  String get expenseClearFilter => 'Clear filter';

  @override
  String get expenseFilterApply => 'Apply';

  @override
  String get expenseNoResults => 'No expenses found in selected date range';

  @override
  String get expenseEditTitle => 'Edit Expense';

  @override
  String get expenseDeleteTitle => 'Delete Expense';

  @override
  String get expenseDeleteConfirm =>
      'Are you sure you want to delete this expense?';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle => 'Financial indicators for selected period';

  @override
  String get dateRange => 'Date range';

  @override
  String get thisWeek => 'This week';

  @override
  String get revenue => 'Revenue';

  @override
  String get totalExpensesCard => 'Total Expenses';

  @override
  String get tax => 'Tax';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get revenueByStore => 'Revenue by store';

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get netProfitOverTime => 'Net profit over time';

  @override
  String get sedErekStore => 'Sədərək store';

  @override
  String get abseronStore => 'Abşeron store';

  @override
  String get storeLabel => 'Store';

  @override
  String get amountLabel => 'Amount (₼)';

  @override
  String get colDate => 'Date';

  @override
  String get colTotalSales => 'Total Sales';

  @override
  String get colCostOfGoods => 'Cost of Goods';

  @override
  String get colTotalExpenses => 'Total Expenses';

  @override
  String get colTax => 'Tax';

  @override
  String get colMargin => 'Margin %';

  @override
  String get colNetProfit => 'Net Profit';

  @override
  String get grandTotalRow => 'Grand Total';

  @override
  String get dailyBreakdown => 'Daily Breakdown';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportToPdf => 'Export as PDF';

  @override
  String get exportToExcel => 'Export as Excel';

  @override
  String get exportSuccess => 'Exported successfully';

  @override
  String get exportError => 'Export error';

  @override
  String get stock => 'Stock';

  @override
  String get activeStockAmount => 'Active Stock Amount';

  @override
  String get activeProducts => 'Active Products';

  @override
  String get pricePending => 'Price Pending';

  @override
  String get allInventories => 'All Inventories';

  @override
  String get searchStock => 'Search product, model, barcode…';

  @override
  String get modelCode => 'Model Code';

  @override
  String get productCode => 'Product Code';

  @override
  String get quantity => 'Quantity';

  @override
  String get sourceInventory => 'Source Inventory';

  @override
  String get invoicePriceUsd => 'Invoice Price (USD)';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get wholesalePrice => 'Wholesale Price';

  @override
  String get retailPrice => 'Retail Price';

  @override
  String get activeStatus => 'Active';

  @override
  String get createStockRequest => 'Create Request';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get searchProducts => 'Search Products';

  @override
  String get requestedQuantity => 'Requested Quantity';

  @override
  String get addToRequest => 'Add to Request';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get stockRequestCreated => 'Stock request created';

  @override
  String get pleaseSelectFromAndTo => 'Please select \'From\' and \'To\'';

  @override
  String get pleaseAddProducts => 'Please add at least one product';

  @override
  String get selectInventory => 'Select Inventory';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get requestedItems => 'Requested Items';

  @override
  String get priceRequestsSubtitle => 'Price calculation requests';

  @override
  String get totalRequests => 'Total';

  @override
  String get approvedStatus => 'Approved';

  @override
  String get onReviewStatus => 'On Review';

  @override
  String get rejectedStatus => 'Rejected';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get requestName => 'Request name';

  @override
  String get sourceColumn => 'Source';

  @override
  String get userColumn => 'User';

  @override
  String get creationDate => 'Creation date';

  @override
  String get statusColumn => 'Status';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get confirmationTitle => 'Confirmation';

  @override
  String get confirmCalculationMessage =>
      'Are you sure you want to confirm the calculations?';

  @override
  String get no => 'No';

  @override
  String get yesConfirm => 'Yes, confirm';

  @override
  String get productNameColumn => 'Product name';

  @override
  String get barcodeColumn => 'Barcode';

  @override
  String get quantityColumn => 'Quantity';

  @override
  String get invoicePriceAzn => 'Invoice price (AZN)';

  @override
  String get colorColumn => 'Color';

  @override
  String get priceCalculationTitle => 'Price Calculation';

  @override
  String get costPriceStep => '1. Cost Price';

  @override
  String get costPriceLabel => 'AZN  cost price';

  @override
  String get wholesalePriceStep => '2. Wholesale Price';

  @override
  String get wholesalePriceLabel => 'AZN  wholesale price';

  @override
  String get retailPriceStep => '3. Retail Price';

  @override
  String get retailPriceLabel => 'AZN  retail price';

  @override
  String get confirmCalculation => 'Confirm Calculation';

  @override
  String get confirm => 'Confirm';

  @override
  String get adjustPrices => 'Adjust Prices';

  @override
  String get editProductPrices => 'Edit Product Prices';

  @override
  String get selectStock => 'Select Stock';

  @override
  String get selectStockHint => 'Select stock...';

  @override
  String get top5Products => 'Top 5 Products';

  @override
  String get editPrices => 'Edit Prices';

  @override
  String get productRequests => 'Product Requests';

  @override
  String get productRequestsSubtitle =>
      'Track and manage stock transfer requests';

  @override
  String get createRequest => 'Create Request';

  @override
  String get allRequests => 'All';

  @override
  String get searchRequests => 'Search requests…';

  @override
  String get noRequestsFound => 'No requests found';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReadyForDelivery => 'Ready for Delivery';

  @override
  String get statusOnWay => 'On the Way';

  @override
  String get statusWaitingForPricing => 'Waiting for Pricing';

  @override
  String get statusClosed => 'Closed';

  @override
  String get createdBy => 'Created by';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get noActionsAvailable =>
      'No actions available for your role at this stage';

  @override
  String get preparedQty => 'Prepared Qty';

  @override
  String get acceptedQty => 'Accepted Qty';

  @override
  String get requestedQty => 'Requested';

  @override
  String get sentQty => 'Sent';

  @override
  String get receivedQty => 'Received';

  @override
  String get yourInventory => 'Your inventory';

  @override
  String searchStockProducts(String name) {
    return 'Search Stock Products ($name)';
  }

  @override
  String searchInventoryProducts(String name) {
    return 'Search Inventory Products ($name)';
  }

  @override
  String get markAsReady => 'Mark as Ready for Delivery';

  @override
  String get acceptDelivery => 'Accept Delivery';

  @override
  String get preparingHint =>
      'Enter the quantity you can actually send (may be less than requested)';

  @override
  String get acceptingHint => 'Enter the quantity you physically received';

  @override
  String get deleteRequest => 'Delete Request';

  @override
  String get deleteRequestConfirm =>
      'Are you sure you want to delete this request? This action cannot be undone.';

  @override
  String get addStockItem => 'Add Stock Item';

  @override
  String get deleteStockItem => 'Delete Stock Item';

  @override
  String get deleteStockItemConfirm =>
      'Are you sure you want to delete this stock item? This action cannot be undone.';

  @override
  String get stockItemDeleted => 'Stock item deleted';

  @override
  String stockItemDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get stockItemCreated => 'Stock item created successfully';

  @override
  String stockItemCreateFailed(String error) {
    return 'Failed to create: $error';
  }

  @override
  String get invoicePriceAznLabel => 'Invoice Price (AZN)';

  @override
  String get loadingMore => 'Loading more…';

  @override
  String get loadingInventories => 'Loading inventories…';

  @override
  String get allStockProducts => 'All Stock Products';

  @override
  String get noInventoriesFound => 'No stock inventories found';

  @override
  String get priceSavedSuccess => 'Price updated successfully';

  @override
  String priceSaveFailed(String error) {
    return 'Failed to update price: $error';
  }

  @override
  String get savingPrice => 'Saving…';

  @override
  String get loyalCustomers => 'Loyal Customers';

  @override
  String get loyalCustomersSubtitle =>
      'Manage your loyal customers and their discounts';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get searchCustomers => 'Search by name, phone or loyalty ID…';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get discount => 'Discount';

  @override
  String get loyaltyId => 'Loyalty ID';

  @override
  String get customerCreated => 'Customer added successfully';

  @override
  String get customerUpdated => 'Customer updated successfully';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameHint => 'e.g. John';

  @override
  String get lastName => 'Last Name';

  @override
  String get lastNameHint => 'e.g. Doe';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get discountPercentage => 'Discount (%)';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get discountRange => 'Discount must be between 0 and 100';

  @override
  String get sellingTransactions => 'Transactions';

  @override
  String get sellingTransactionsSubtitle =>
      'View and filter sales transaction history';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get adjustFiltersOrSearch =>
      'Try adjusting your filters or search query';

  @override
  String get receiptNumber => 'Receipt';

  @override
  String get seller => 'Seller';

  @override
  String get paymentMethod => 'Payment';

  @override
  String get priceType => 'Price Type';

  @override
  String get discountAmount => 'Discount';

  @override
  String get allPaymentMethods => 'All Payments';

  @override
  String get allPriceTypes => 'All Price Types';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentTransfer => 'Transfer';

  @override
  String get priceRetailSale => 'Retail';

  @override
  String get priceWholeSale => 'Wholesale';

  @override
  String get transactionDetail => 'Transaction Detail';

  @override
  String get store => 'Store';

  @override
  String get customer => 'Customer';

  @override
  String get noCustomer => 'No customer';

  @override
  String get transactionItems => 'Items';

  @override
  String get productId => 'Product ID';

  @override
  String get count => 'Count';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get searchTransactions => 'Search by receipt, seller…';

  @override
  String get returnedProducts => 'Returns';

  @override
  String get returnedProductsSubtitle =>
      'View and filter returned product history';

  @override
  String get returnedProductDetails => 'Product Details';

  @override
  String get defectedProduct => 'Defected Product';

  @override
  String get normalReturn => 'Normal Return';

  @override
  String get defected => 'Defected';

  @override
  String get normal => 'Normal';

  @override
  String get totalReturns => 'Total Returns';

  @override
  String get allProducts => 'All Products';

  @override
  String get defectedOnly => 'Defected Only';

  @override
  String get normalOnly => 'Normal Only';

  @override
  String get noReturnedProducts => 'No returned products found';

  @override
  String get productUUID => 'Product UUID';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get refresh => 'Refresh';

  @override
  String get close => 'Close';

  @override
  String get addReturnedProduct => 'Add Returned Product';

  @override
  String get pleaseSelectProduct => 'Please select a product';

  @override
  String get returnedProductAdded => 'Returned product added successfully';

  @override
  String get enterReceiptNumber => 'Enter receipt number';

  @override
  String get foundTransactions => 'Found transactions';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get enterBarcode => 'Enter barcode';

  @override
  String get enterQuantity => 'Enter quantity';

  @override
  String get markAsDefected => 'Mark this product as defected';

  @override
  String get confirmReturn => 'Confirm Return';

  @override
  String get add => 'Add';

  @override
  String get barcodeNotFoundInReceipt => 'Barcode not found in this receipt';

  @override
  String quantityExceedsReceipt(int available) {
    return 'Quantity exceeds receipt amount. Available: $available';
  }

  @override
  String get receiptNotFound => 'Receipt not found';

  @override
  String get validatingReceipt => 'Validating receipt...';

  @override
  String productsInReceipt(int count) {
    return '$count product(s) in receipt';
  }

  @override
  String availableInReceipt(int count) {
    return 'Available in receipt: $count';
  }

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get priceHistory => 'Price History';

  @override
  String get history => 'History';

  @override
  String get noHistory => 'No price change history available.';

  @override
  String get changedBy => 'Changed by';

  @override
  String get changedAt => 'Changed at';

  @override
  String get oldValue => 'Old';

  @override
  String get newValue => 'New';

  @override
  String get costUnitPriceLabel => 'Cost Price';

  @override
  String get wholeUnitSalesPriceLabel => 'Wholesale Price';

  @override
  String get retailUnitPriceLabel => 'Retail Price';

  @override
  String get priceChange => 'Price Change';

  @override
  String get viewPriceHistory => 'View all price changes';

  @override
  String get posKassa => 'Cashier';

  @override
  String get posScanOrSearch => 'Scan barcode or search product...';

  @override
  String get posSelectFromList => 'Select from list...';

  @override
  String get posSearching => 'Searching...';

  @override
  String get posNoResults => 'No results found';

  @override
  String posBarcodeStockInfo(String barcode, int qty) {
    return 'Barcode: $barcode  •  Stock: $qty';
  }

  @override
  String get posProduct => 'Product';

  @override
  String get posQuantity => 'Quantity';

  @override
  String get posUnitPrice => 'Unit Price';

  @override
  String get posDiscountCol => 'Discount';

  @override
  String get posTotal => 'Total';

  @override
  String get posDeleteCol => 'Delete';

  @override
  String get posCartEmpty => 'Cart is empty';

  @override
  String get posCartEmptyHint => 'Search to add products';

  @override
  String get posClearCart => 'Clear Cart';

  @override
  String get posPriceType => 'Price Type';

  @override
  String get posRetail => 'Retail';

  @override
  String get posWholesale => 'Wholesale';

  @override
  String get posPaymentMethod => 'Payment Method';

  @override
  String get posCash => 'Cash';

  @override
  String get posCard => 'Card';

  @override
  String get posTransfer => 'Transfer';

  @override
  String get posSubtotal => 'Subtotal:';

  @override
  String posDiscountLabel(String percent) {
    return 'Discount ($percent%):';
  }

  @override
  String posDiscountAmountLabel(String amount) {
    return 'Discount ($amount AZN):';
  }

  @override
  String posCustomerDiscountLabel(String percent) {
    return 'Customer Discount ($percent%):';
  }

  @override
  String posTotalDiscountLabel(String percent) {
    return 'Total Discount ($percent%):';
  }

  @override
  String get posAmountDue => 'Amount Due:';

  @override
  String get posCompleteSale => 'COMPLETE SALE';

  @override
  String get posSelectCustomer => 'Select Customer';

  @override
  String posCustomerLabel(String name) {
    return 'Customer: $name';
  }

  @override
  String get posSaleSuccess => 'Sale Completed Successfully!';

  @override
  String get posPaymentLabel => 'Payment';

  @override
  String get posPriceTypeLabel => 'Price type';

  @override
  String get posProductCount => 'Product count';

  @override
  String posProductCountValue(int count) {
    return '$count pcs';
  }

  @override
  String get posSeller => 'Seller';

  @override
  String get posStoreLabel => 'Store';

  @override
  String get posDownloadPdf => 'Download Receipt PDF';

  @override
  String get posNewSale => 'New Sale';

  @override
  String posErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String posPdfError(String error) {
    return 'Error creating PDF: $error';
  }

  @override
  String posDiscountBelowCost(String price) {
    return 'Discount cannot go below cost price ($price AZN)!';
  }

  @override
  String posMaxDiscount(String max, String cost) {
    return 'Maximum discount: $max AZN (Cost: $cost AZN)';
  }

  @override
  String get posCustomerSearchTitle => 'Customer Search';

  @override
  String get posCustomerSearchSubtitle =>
      'Search by name, surname, phone or card number';

  @override
  String get posCustomerSearchField => 'Name, surname, phone or card number...';

  @override
  String get posStartSearch => 'Start searching';

  @override
  String get posStartSearchHint =>
      'Enter name, surname, phone or loyalty card number';

  @override
  String get posCustomerNotFound => 'Customer not found';

  @override
  String get posCustomerNotFoundHint => 'Try again with a different keyword';

  @override
  String get posNoCustomerSelected => 'No customer selected';

  @override
  String get posConfirmSelect => 'Select';

  @override
  String get posPdfFrom => 'From: ';

  @override
  String get posPdfTo => 'To: ';

  @override
  String get posPdfSeller => 'Seller: ';

  @override
  String get posPdfPayment => 'Payment: ';

  @override
  String get posPdfDate => 'Date: ';

  @override
  String posPdfReceiptNo(String number) {
    return 'Receipt No. $number';
  }

  @override
  String get posPdfItemName => 'Product Name';

  @override
  String get posPdfUnit => 'Unit';

  @override
  String get posPdfQty => 'Quantity';

  @override
  String get posPdfPrice => 'Price';

  @override
  String get posPdfAmount => 'Amount';

  @override
  String get posPdfSubtotal => 'SUBTOTAL';

  @override
  String posPdfDiscount(String percent) {
    return 'DISCOUNT ($percent%)';
  }

  @override
  String posPdfCustomerDiscount(String percent) {
    return 'CUSTOMER DISCOUNT ($percent%)';
  }

  @override
  String get posPdfBalance => 'BALANCE';

  @override
  String get posPdfDeliveredBy => 'Delivered by';

  @override
  String get posPdfReceivedBy => 'Received by';

  @override
  String get posPdfUnitPcs => 'pcs';

  @override
  String get posPaymentCash => 'Cash';

  @override
  String get posPaymentCard => 'Card';

  @override
  String get posPaymentTransfer => 'Transfer';

  @override
  String get posPriceRetail => 'Retail';

  @override
  String get posPriceWholesale => 'Wholesale';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to your account to continue';

  @override
  String get signIn => 'Sign in';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get inventoryLabel => 'Inventory';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get selectAnInventory => 'Select an inventory';

  @override
  String get pleaseSelectAnInventory => 'Please select an inventory';

  @override
  String get securedConnection => 'Secured connection';

  @override
  String get goBack => 'Go Back';

  @override
  String get openInNewTab => 'Open in new tab';

  @override
  String get closeImageViewer => 'Close';

  @override
  String get invoiceImageTitle => 'Invoice Image';

  @override
  String invoiceImageOf(int current, int total) {
    return 'Image $current of $total';
  }

  @override
  String failedToDeleteInvoice(String error) {
    return 'Failed to delete invoice: $error';
  }

  @override
  String get deleteInvoiceTooltip => 'Delete invoice';

  @override
  String get invoiceNoHint => 'Invoice No.';

  @override
  String get supplierNameHint => 'Supplier Name';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get okLabel => 'OK';

  @override
  String get errorTitle => 'Error';

  @override
  String get printLabel => 'Print';

  @override
  String get printTooltip => 'Print';

  @override
  String printedLabelsSuccess(int count, String name) {
    return 'Printed $count label(s) for $name';
  }

  @override
  String printFailed(String error) {
    return 'Print failed: $error';
  }

  @override
  String get deleteProductTitle => 'Delete Product';

  @override
  String get deleteProductConfirm =>
      'Are you sure you want to delete this product? This action cannot be undone.';

  @override
  String productDeletedSuccess(String name) {
    return '$name deleted successfully.';
  }

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String deleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String productsDeletedSuccess(int count) {
    return '$count product(s) deleted successfully.';
  }

  @override
  String nItemsParens(int count) {
    return '$count item(s)';
  }

  @override
  String paginationShowing(int start, int end, int total) {
    return 'Showing $start–$end of $total';
  }

  @override
  String get failedToLoadRetry => 'Failed to load — tap to retry';

  @override
  String get inventoryDropdownNone => '— None —';

  @override
  String get processingAdditionalPage => 'Processing additional page...';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get initializingLabel => 'Initializing...';

  @override
  String itemsTotal(int count) {
    return '$count items total';
  }

  @override
  String get deleteInvoiceTitle => 'Delete Invoice';

  @override
  String get deleteInvoiceConfirm =>
      'Are you sure you want to delete this invoice? This action cannot be undone.';

  @override
  String bulkDeleteProductsTitle(int count) {
    return 'Delete $count Product(s)';
  }

  @override
  String get bulkDeleteProductsConfirm =>
      'Are you sure you want to delete the following products? This action cannot be undone.';

  @override
  String get printBarcode => 'Print Barcode';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get productLabel => 'Product';

  @override
  String get countLabel => 'Count';

  @override
  String get confirmAndSaveDialogBody =>
      'Are you sure you want to confirm and save this invoice? This action cannot be undone.';

  @override
  String get loadMore => 'Load more';

  @override
  String get addAnotherPage => 'Add another page';

  @override
  String get viewOriginalImage => 'View original invoice image';

  @override
  String get viewOriginal => 'View original';

  @override
  String get viewImage => 'View Image';

  @override
  String viewImages(int count) {
    return 'View Images ($count)';
  }

  @override
  String get taxIdLabel => 'Tax ID';

  @override
  String get invoiceDateLabel => 'Invoice Date';

  @override
  String get addressLabel => 'Address';

  @override
  String get contactLabel => 'Contact';

  @override
  String get modelLabel => 'Model';

  @override
  String get colorLabel => 'Color';

  @override
  String get sizeLabel => 'Size';

  @override
  String get invoiceQtyShort => 'Invoice Qty';

  @override
  String get unitPriceUsdLabel => 'Unit Price (USD)';

  @override
  String get exchangeRateLabel => 'Exchange Rate';

  @override
  String get productCodeLabel => 'Product Code';

  @override
  String get printerError => 'Printer error';

  @override
  String pageN(int n) {
    return 'Page $n';
  }

  @override
  String get supplierAddress => 'Supplier Address';

  @override
  String get contactNumber => 'Contact Number';

  @override
  String get contractNumber => 'Contract Number';

  @override
  String get inventoryWarehouse => 'Inventory (Warehouse)';

  @override
  String get editInvoiceProduct => 'Edit Invoice Product';

  @override
  String get invoiceDetailsReadOnly => 'Invoice Details (read-only)';

  @override
  String get unitPriceAzn => 'Unit Price (AZN)';

  @override
  String get stockTypeBadge => 'STOCK';

  @override
  String get inventoryTypeBadge => 'INVENTORY';

  @override
  String get invTypeBadge => 'INV';
}
