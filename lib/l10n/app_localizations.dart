import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get appTitle;

  /// Invoices navigation label
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// Inventory Products navigation label
  ///
  /// In en, this message translates to:
  /// **'Inventory Products'**
  String get inventoryProducts;

  /// Finance navigation label
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// Price Calculation submenu label
  ///
  /// In en, this message translates to:
  /// **'Price Calculation'**
  String get priceCalculation;

  /// Expense Tracking submenu label
  ///
  /// In en, this message translates to:
  /// **'Expense Tracking'**
  String get expenseTracking;

  /// Tooltip for expanding sidebar
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// Tooltip for collapsing sidebar
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// Version information text
  ///
  /// In en, this message translates to:
  /// **'v1.0.0 · Inventory App'**
  String get versionInfo;

  /// Invoices page subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage and review your commercial invoices'**
  String get manageInvoices;

  /// Button to add invoice from image
  ///
  /// In en, this message translates to:
  /// **'Add Invoice from Image'**
  String get addInvoiceFromImage;

  /// Total invoices stat label
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get totalInvoices;

  /// Total value stat label
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// Pending status label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Confirmed status label
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Cancelled status label
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Invoice number column header
  ///
  /// In en, this message translates to:
  /// **'INVOICE #'**
  String get invoiceNumber;

  /// Supplier column header
  ///
  /// In en, this message translates to:
  /// **'SUPPLIER'**
  String get supplier;

  /// Invoice date column header
  ///
  /// In en, this message translates to:
  /// **'INVOICE DATE'**
  String get invoiceDate;

  /// Created at column header
  ///
  /// In en, this message translates to:
  /// **'CREATED AT'**
  String get createdAt;

  /// Items column header
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get items;

  /// Amount column header
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get amount;

  /// Status column header
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get status;

  /// Actions column header
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get actions;

  /// View tooltip
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Export tooltip/button
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Delete tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoicesYet;

  /// Empty state description
  ///
  /// In en, this message translates to:
  /// **'Upload an invoice image to get started with OCR extraction'**
  String get uploadInvoiceToStart;

  /// OCR processing dialog title
  ///
  /// In en, this message translates to:
  /// **'Processing Invoice Image'**
  String get processingInvoiceImage;

  /// OCR stage: uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading image…'**
  String get uploadingImage;

  /// OCR stage: processing
  ///
  /// In en, this message translates to:
  /// **'Running OCR…'**
  String get runningOCR;

  /// OCR completion title
  ///
  /// In en, this message translates to:
  /// **'OCR Complete!'**
  String get ocrComplete;

  /// OCR completion subtitle
  ///
  /// In en, this message translates to:
  /// **'Review the extracted data below'**
  String get reviewExtractedData;

  /// Model column header
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// SKU column header
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// Quantity column header
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// Total in USD column header
  ///
  /// In en, this message translates to:
  /// **'Total (USD)'**
  String get totalUSD;

  /// Warning message for missing data
  ///
  /// In en, this message translates to:
  /// **'rows with missing weight/dimension data'**
  String get rowsWithMissingData;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button to open and edit table
  ///
  /// In en, this message translates to:
  /// **'Open & Edit Table'**
  String get openAndEditTable;

  /// Pieces unit
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pcs;

  /// Invoice detail page title
  ///
  /// In en, this message translates to:
  /// **'Invoice #{number}'**
  String invoiceDetail(String number);

  /// Total items label
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// SKU lines label
  ///
  /// In en, this message translates to:
  /// **'SKU Lines'**
  String get skuLines;

  /// Rows label
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get rows;

  /// Warnings label
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Table toolbar title
  ///
  /// In en, this message translates to:
  /// **'OCR Result — Editable Table'**
  String get ocrResultEditableTable;

  /// Add row button
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get addRow;

  /// Delete selected button
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// Confirm invoice button
  ///
  /// In en, this message translates to:
  /// **'Confirm Invoice'**
  String get confirmInvoice;

  /// Size column header
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Color column header
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Unit column header
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Total column header
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Box dimensions column header
  ///
  /// In en, this message translates to:
  /// **'Box Dimensions'**
  String get boxDimensions;

  /// CBM column header
  ///
  /// In en, this message translates to:
  /// **'CBM'**
  String get cbm;

  /// Net weight column header
  ///
  /// In en, this message translates to:
  /// **'Net (kg)'**
  String get netWeight;

  /// Gross weight column header
  ///
  /// In en, this message translates to:
  /// **'Gross (kg)'**
  String get grossWeight;

  /// Notes column header
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Product name column header
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// AI-generated product name column header
  ///
  /// In en, this message translates to:
  /// **'Generated Name'**
  String get generatedName;

  /// Color code column header
  ///
  /// In en, this message translates to:
  /// **'Color Code'**
  String get colorCode;

  /// Pieces per carton column header
  ///
  /// In en, this message translates to:
  /// **'Pcs/Carton'**
  String get pcsPerCarton;

  /// Carton count column header
  ///
  /// In en, this message translates to:
  /// **'Cartons'**
  String get cartons;

  /// Total weight in kg column header
  ///
  /// In en, this message translates to:
  /// **'Total Wt (kg)'**
  String get totalWeightKg;

  /// Select all checkbox label
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter by status dropdown
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// All statuses filter option
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// In stock status
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// Low stock status
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// Out of stock status
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Total products stat
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// Total quantity stat
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get totalQuantity;

  /// Low stock items stat
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStockItems;

  /// Out of stock items stat
  ///
  /// In en, this message translates to:
  /// **'Out of Stock Items'**
  String get outOfStockItems;

  /// Name column header
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Actual quantity column header
  ///
  /// In en, this message translates to:
  /// **'Actual Qty'**
  String get actualQty;

  /// Invoice quantity column header
  ///
  /// In en, this message translates to:
  /// **'Invoice Qty'**
  String get invoiceQty;

  /// Unit price column header
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// Invoice total column header
  ///
  /// In en, this message translates to:
  /// **'Invoice Total'**
  String get invoiceTotal;

  /// Actual total column header
  ///
  /// In en, this message translates to:
  /// **'Actual Total'**
  String get actualTotal;

  /// Barcode column header
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// Coordinate column header
  ///
  /// In en, this message translates to:
  /// **'Coordinate'**
  String get coordinate;

  /// Source column header
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No products message
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProducts;

  /// Adjust filters message
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search query'**
  String get adjustFilters;

  /// Selected label
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// Totals label
  ///
  /// In en, this message translates to:
  /// **'TOTALS'**
  String get totals;

  /// Total quantity label
  ///
  /// In en, this message translates to:
  /// **'Total Qty'**
  String get totalQty;

  /// Grand total label
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// Confirm and save button
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save'**
  String get confirmAndSave;

  /// Inventory products subtitle
  ///
  /// In en, this message translates to:
  /// **'Track stock levels, locations and valuations'**
  String get trackStockLevels;

  /// Add product button
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// Add product dialog subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add the product'**
  String get chooseHowToAddProduct;

  /// Manual entry option
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// Manual entry description
  ///
  /// In en, this message translates to:
  /// **'Fill in all product\ndetails by hand'**
  String get fillProductDetails;

  /// From invoice option
  ///
  /// In en, this message translates to:
  /// **'From Invoice'**
  String get fromInvoice;

  /// From invoice description
  ///
  /// In en, this message translates to:
  /// **'Import from a\nconfirmed invoice'**
  String get importFromInvoice;

  /// Total SKUs stat
  ///
  /// In en, this message translates to:
  /// **'Total SKUs'**
  String get totalSKUs;

  /// Total units stat
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get totalUnits;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search SKU, name, barcode, location…'**
  String get searchSKUNameBarcode;

  /// No products found message
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noProductsMatchSearch;

  /// Filter chip: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to start'**
  String get scrollToStart;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to end'**
  String get scrollToEnd;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollToTop;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollToBottom;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll left'**
  String get scrollLeft;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll right'**
  String get scrollRight;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll up'**
  String get scrollUp;

  /// Nav button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll down'**
  String get scrollDown;

  /// Scroll direction label
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// Scroll direction label
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// Location column header
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Filter bar count
  ///
  /// In en, this message translates to:
  /// **'{n} of {m} products'**
  String nOfMProducts(int n, int m);

  /// Invoice picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Invoice'**
  String get selectInvoice;

  /// Invoice picker dialog subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose an invoice to import products from'**
  String get chooseInvoiceToImport;

  /// Empty invoices list
  ///
  /// In en, this message translates to:
  /// **'No invoices available'**
  String get noInvoicesAvailable;

  /// Empty invoices hint
  ///
  /// In en, this message translates to:
  /// **'Add invoices in the Invoices module first'**
  String get addInvoicesFirst;

  /// Invoice rows dialog title
  ///
  /// In en, this message translates to:
  /// **'Import from {invoiceNo}'**
  String importFromInvoiceNo(String invoiceNo);

  /// Step 1 label
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get selectProducts;

  /// Step 2 label
  ///
  /// In en, this message translates to:
  /// **'Enter Details'**
  String get enterDetails;

  /// Step 1 header
  ///
  /// In en, this message translates to:
  /// **'{n} unique SKUs from invoice'**
  String nUniqueSkusFromInvoice(int n);

  /// Deselect all button
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Select all button
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllLabel;

  /// Invoice quantity short header
  ///
  /// In en, this message translates to:
  /// **'Inv. Qty'**
  String get invQty;

  /// Invoice total short header
  ///
  /// In en, this message translates to:
  /// **'Inv. Total'**
  String get invTotal;

  /// Step 2 info text
  ///
  /// In en, this message translates to:
  /// **'Fill in warehouse details for {count} selected product(s)'**
  String fillWarehouseDetails(int count);

  /// Invoice qty badge
  ///
  /// In en, this message translates to:
  /// **'Invoice qty: {qty}'**
  String invoiceQtyLabel(int qty);

  /// Actual qty received field label
  ///
  /// In en, this message translates to:
  /// **'Actual Qty Received'**
  String get actualQtyReceived;

  /// Discrepancy label
  ///
  /// In en, this message translates to:
  /// **'{diff} vs invoice'**
  String vsInvoice(String diff);

  /// Warehouse location section header
  ///
  /// In en, this message translates to:
  /// **'Warehouse Location'**
  String get warehouseLocation;

  /// Zone field label
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// Row field label
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// Shelf field label
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get shelf;

  /// Location code preview label
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next step button
  ///
  /// In en, this message translates to:
  /// **'Next: Enter Details'**
  String get nextEnterDetails;

  /// Selected count in step footer
  ///
  /// In en, this message translates to:
  /// **'{n} of {m} selected'**
  String nOfMSelected(int n, int m);

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import {n} Product(s)'**
  String importNProducts(int n);

  /// Snackbar message after import
  ///
  /// In en, this message translates to:
  /// **'{n} product(s) imported from invoice {invoiceNo}'**
  String nProductsImported(int n, String invoiceNo);

  /// Edit product dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// Add product dialog title
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// SKU field label in dialog
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get skuField;

  /// Model field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelField;

  /// Color field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorField;

  /// Barcode field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeField;

  /// Quantity field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityField;

  /// Unit price field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Unit Price (USD)'**
  String get unitPriceUSD;

  /// Zone field hint
  ///
  /// In en, this message translates to:
  /// **'Zone letter (A–Z)'**
  String get zoneLetter;

  /// Location code preview
  ///
  /// In en, this message translates to:
  /// **'Location code: {code}'**
  String locationCode(String code);

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Discrepancy tooltip on actual qty cell
  ///
  /// In en, this message translates to:
  /// **'Discrepancy: {diff} vs invoice'**
  String discrepancyTooltip(String diff);

  /// Color code field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Color Code'**
  String get colorCodeField;

  /// Size field label in dialog
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeField;

  /// Actual pieces per carton field label
  ///
  /// In en, this message translates to:
  /// **'Actual Pcs/Carton'**
  String get actualPcsPerCarton;

  /// Actual carton count field label
  ///
  /// In en, this message translates to:
  /// **'Actual Carton Count'**
  String get actualCartonCount;

  /// Product info section header in dialog
  ///
  /// In en, this message translates to:
  /// **'Product Info'**
  String get productInfoSection;

  /// Packaging section header in dialog
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packagingSection;

  /// Saving product progress message
  ///
  /// In en, this message translates to:
  /// **'Saving product…'**
  String get savingProduct;

  /// Snackbar message on successful product creation
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productSavedSuccess;

  /// Snackbar message on failed product creation
  ///
  /// In en, this message translates to:
  /// **'Failed to save product: {error}'**
  String productSaveFailed(String error);

  /// Loading state for invoice picker
  ///
  /// In en, this message translates to:
  /// **'Loading invoices…'**
  String get loadingInvoices;

  /// Error message when invoice list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoices: {error}'**
  String fetchInvoicesFailed(String error);

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Loading state for invoice detail
  ///
  /// In en, this message translates to:
  /// **'Loading invoice details…'**
  String get loadingInvoiceDetail;

  /// Error message when invoice detail fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoice: {error}'**
  String fetchInvoiceDetailFailed(String error);

  /// Invoice item count label
  ///
  /// In en, this message translates to:
  /// **'{n} item(s) in invoice'**
  String nItemsInInvoice(int n);

  /// Invoice pieces per carton field label
  ///
  /// In en, this message translates to:
  /// **'Inv. Pcs/Carton'**
  String get invoicePcsPerCarton;

  /// Invoice carton count field label
  ///
  /// In en, this message translates to:
  /// **'Inv. Carton Count'**
  String get invoiceCartonCount;

  /// Progress message while importing products from invoice
  ///
  /// In en, this message translates to:
  /// **'Importing {current} of {total}…'**
  String importingProducts(int current, int total);

  /// Snackbar message after successful import
  ///
  /// In en, this message translates to:
  /// **'{n} product(s) imported successfully!'**
  String importSuccessN(int n);

  /// Snackbar message when some imports fail
  ///
  /// In en, this message translates to:
  /// **'{n} product(s) failed to import.'**
  String importFailedN(int n);

  /// Live preview of estimated actual total price (actual_qty × invoice_unit_price)
  ///
  /// In en, this message translates to:
  /// **'Est. Total: \${total}  (qty × \${unitPrice}/unit)'**
  String estimatedTotalPrice(String total, String unitPrice);

  /// Button label to auto-generate a barcode
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateBarcode;

  /// Button label while barcode is being generated
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generatingBarcode;

  /// Snackbar message when barcode is generated
  ///
  /// In en, this message translates to:
  /// **'Barcode generated successfully'**
  String get barcodeGeneratedSuccess;

  /// Snackbar message when barcode generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate barcode: {error}'**
  String barcodeGenerateFailed(String error);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @expensePaymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get expensePaymentType;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmount;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @expenseDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get expenseDocument;

  /// No description provided for @expenseNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expenseNote;

  /// No description provided for @expenseCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get expenseCategoryRent;

  /// No description provided for @expenseCategoryCommunal.
  ///
  /// In en, this message translates to:
  /// **'Communal'**
  String get expenseCategoryCommunal;

  /// No description provided for @expenseCategorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get expenseCategorySalary;

  /// No description provided for @expenseCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseCategoryTransport;

  /// No description provided for @expenseCategoryCustoms.
  ///
  /// In en, this message translates to:
  /// **'Customs'**
  String get expenseCategoryCustoms;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCategoryOther;

  /// No description provided for @expensePaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get expensePaymentCash;

  /// No description provided for @expensePaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get expensePaymentCard;

  /// No description provided for @expensePaymentTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get expensePaymentTransfer;

  /// No description provided for @expenseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get expenseSelectCategory;

  /// No description provided for @expenseSelectPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Select payment type'**
  String get expenseSelectPaymentType;

  /// No description provided for @expenseAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get expenseAmountHint;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a note…'**
  String get expenseNoteHint;

  /// No description provided for @expenseDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Select file (image, PDF)'**
  String get expenseDocumentHint;

  /// No description provided for @expenseDocumentSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String expenseDocumentSelected(Object name);

  /// No description provided for @expenseDocumentChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get expenseDocumentChoose;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @addFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Press the button to add your first expense'**
  String get addFirstExpense;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @expenseCount.
  ///
  /// In en, this message translates to:
  /// **'Expense Count'**
  String get expenseCount;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @expenseFilterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get expenseFilterByDate;

  /// No description provided for @expenseClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get expenseClearFilter;

  /// No description provided for @expenseFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get expenseFilterApply;

  /// No description provided for @expenseNoResults.
  ///
  /// In en, this message translates to:
  /// **'No expenses found in selected date range'**
  String get expenseNoResults;

  /// No description provided for @expenseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get expenseEditTitle;

  /// No description provided for @expenseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get expenseDeleteTitle;

  /// No description provided for @expenseDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get expenseDeleteConfirm;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Financial indicators for selected period'**
  String get analyticsSubtitle;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @totalExpensesCard.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpensesCard;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @revenueByStore.
  ///
  /// In en, this message translates to:
  /// **'Revenue by store'**
  String get revenueByStore;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expensesByCategory;

  /// No description provided for @netProfitOverTime.
  ///
  /// In en, this message translates to:
  /// **'Net profit over time'**
  String get netProfitOverTime;

  /// No description provided for @sedErekStore.
  ///
  /// In en, this message translates to:
  /// **'Sədərək store'**
  String get sedErekStore;

  /// No description provided for @abseronStore.
  ///
  /// In en, this message translates to:
  /// **'Abşeron store'**
  String get abseronStore;

  /// No description provided for @storeLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (₼)'**
  String get amountLabel;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get colTotalSales;

  /// No description provided for @colCostOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of Goods'**
  String get colCostOfGoods;

  /// No description provided for @colTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get colTotalExpenses;

  /// No description provided for @colTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get colTax;

  /// No description provided for @colMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get colMargin;

  /// No description provided for @colNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get colNetProfit;

  /// No description provided for @grandTotalRow.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotalRow;

  /// No description provided for @dailyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily Breakdown'**
  String get dailyBreakdown;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportToPdf;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get exportToExcel;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// Stock navigation label
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// Active stock amount stat label
  ///
  /// In en, this message translates to:
  /// **'Active Stock Amount'**
  String get activeStockAmount;

  /// Active products stat label
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// Price pending status label
  ///
  /// In en, this message translates to:
  /// **'Price Pending'**
  String get pricePending;

  /// All inventories filter option
  ///
  /// In en, this message translates to:
  /// **'All Inventories'**
  String get allInventories;

  /// Search stock placeholder
  ///
  /// In en, this message translates to:
  /// **'Search product, model, barcode…'**
  String get searchStock;

  /// Model code column header
  ///
  /// In en, this message translates to:
  /// **'Model Code'**
  String get modelCode;

  /// Product code column header
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// Quantity column header
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Source inventory column header
  ///
  /// In en, this message translates to:
  /// **'Source Inventory'**
  String get sourceInventory;

  /// Invoice price USD column header
  ///
  /// In en, this message translates to:
  /// **'Invoice Price (USD)'**
  String get invoicePriceUsd;

  /// Cost price column header
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// Wholesale price column header
  ///
  /// In en, this message translates to:
  /// **'Wholesale Price'**
  String get wholesalePrice;

  /// Retail price column header
  ///
  /// In en, this message translates to:
  /// **'Retail Price'**
  String get retailPrice;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
