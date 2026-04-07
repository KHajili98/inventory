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

  /// Point of Sale navigation label
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// Sell module parent navigation label
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellModule;

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

  /// Product addition method prompt
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
  /// **'Search name, barcode, location…'**
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

  /// No description provided for @expenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get expenseAdded;

  /// No description provided for @expenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated'**
  String get expenseUpdated;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @expenseAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add expense: {error}'**
  String expenseAddFailed(String error);

  /// No description provided for @expenseUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update expense: {error}'**
  String expenseUpdateFailed(String error);

  /// No description provided for @expenseDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete expense: {error}'**
  String expenseDeleteFailed(String error);

  /// No description provided for @expenseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expenses: {error}'**
  String expenseLoadFailed(String error);

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories…'**
  String get loadingCategories;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses…'**
  String get searchExpenses;

  /// No description provided for @expenseFilterPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment type'**
  String get expenseFilterPaymentType;

  /// No description provided for @expenseFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get expenseFilterAll;

  /// No description provided for @expenseFilterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get expenseFilterByCategory;

  /// No description provided for @expenseFilterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get expenseFilterAllCategories;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get expenseCategories;

  /// No description provided for @expenseCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get expenseCategoriesTitle;

  /// No description provided for @expenseCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage expense categories'**
  String get expenseCategoriesSubtitle;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get categoryNameHint;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @addFirstCategory.
  ///
  /// In en, this message translates to:
  /// **'Press the button to add the first category'**
  String get addFirstCategory;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get categoryDeleteConfirm;

  /// No description provided for @categoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully'**
  String get categoryAdded;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get categoryUpdated;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add category: {error}'**
  String categoryAddFailed(String error);

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category: {error}'**
  String categoryDeleteFailed(String error);

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

  /// Create stock request button
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createStockRequest;

  /// From dropdown label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// To dropdown label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// Search products placeholder
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// Requested quantity label
  ///
  /// In en, this message translates to:
  /// **'Requested Quantity'**
  String get requestedQuantity;

  /// Add to request button
  ///
  /// In en, this message translates to:
  /// **'Add to Request'**
  String get addToRequest;

  /// Submit request button
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Stock request created'**
  String get stockRequestCreated;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Please select \'From\' and \'To\''**
  String get pleaseSelectFromAndTo;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Please add at least one product'**
  String get pleaseAddProducts;

  /// Select inventory placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Inventory'**
  String get selectInventory;

  /// Empty search result message
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// Requested items section title
  ///
  /// In en, this message translates to:
  /// **'Requested Items'**
  String get requestedItems;

  /// Subtitle for price calculation page
  ///
  /// In en, this message translates to:
  /// **'Price calculation requests'**
  String get priceRequestsSubtitle;

  /// Total requests label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalRequests;

  /// Approved status label
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// On review status label
  ///
  /// In en, this message translates to:
  /// **'On Review'**
  String get onReviewStatus;

  /// Rejected status label
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// Pending status label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// Request name column header
  ///
  /// In en, this message translates to:
  /// **'Request name'**
  String get requestName;

  /// Source column header
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceColumn;

  /// User column header
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userColumn;

  /// Creation date column header
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get creationDate;

  /// Status column header
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusColumn;

  /// Search input placeholder
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmationTitle;

  /// Confirmation dialog message for calculations
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm the calculations?'**
  String get confirmCalculationMessage;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Yes confirm button text
  ///
  /// In en, this message translates to:
  /// **'Yes, confirm'**
  String get yesConfirm;

  /// Product name column header
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameColumn;

  /// Barcode column header
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeColumn;

  /// Quantity column header
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityColumn;

  /// Invoice price column header
  ///
  /// In en, this message translates to:
  /// **'Invoice price (AZN)'**
  String get invoicePriceAzn;

  /// Color column header
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorColumn;

  /// Price calculation section title
  ///
  /// In en, this message translates to:
  /// **'Price Calculation'**
  String get priceCalculationTitle;

  /// Cost price step label
  ///
  /// In en, this message translates to:
  /// **'1. Cost Price'**
  String get costPriceStep;

  /// Cost price result label
  ///
  /// In en, this message translates to:
  /// **'AZN  cost price'**
  String get costPriceLabel;

  /// Wholesale price step label
  ///
  /// In en, this message translates to:
  /// **'2. Wholesale Price'**
  String get wholesalePriceStep;

  /// Wholesale price result label
  ///
  /// In en, this message translates to:
  /// **'AZN  wholesale price'**
  String get wholesalePriceLabel;

  /// Retail price step label
  ///
  /// In en, this message translates to:
  /// **'3. Retail Price'**
  String get retailPriceStep;

  /// No description provided for @retailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'AZN  retail price'**
  String get retailPriceLabel;

  /// No description provided for @confirmCalculation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Calculation'**
  String get confirmCalculation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Button label to adjust prices
  ///
  /// In en, this message translates to:
  /// **'Adjust Prices'**
  String get adjustPrices;

  /// Page title for editing product prices
  ///
  /// In en, this message translates to:
  /// **'Edit Product Prices'**
  String get editProductPrices;

  /// Label for stock selection
  ///
  /// In en, this message translates to:
  /// **'Select Stock'**
  String get selectStock;

  /// Hint text for stock dropdown
  ///
  /// In en, this message translates to:
  /// **'Select stock...'**
  String get selectStockHint;

  /// Title for top 5 products section
  ///
  /// In en, this message translates to:
  /// **'Top 5 Products'**
  String get top5Products;

  /// Button label to edit prices
  ///
  /// In en, this message translates to:
  /// **'Edit Prices'**
  String get editPrices;

  /// Product Requests navigation label
  ///
  /// In en, this message translates to:
  /// **'Product Requests'**
  String get productRequests;

  /// Subtitle for product requests page
  ///
  /// In en, this message translates to:
  /// **'Track and manage stock transfer requests'**
  String get productRequestsSubtitle;

  /// Button to create a new request
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequest;

  /// All requests filter chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allRequests;

  /// Search requests placeholder
  ///
  /// In en, this message translates to:
  /// **'Search requests…'**
  String get searchRequests;

  /// No requests found message
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get noRequestsFound;

  /// Status pending label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Status preparing label
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// Status ready for delivery label
  ///
  /// In en, this message translates to:
  /// **'Ready for Delivery'**
  String get statusReadyForDelivery;

  /// Status on the way label
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get statusOnWay;

  /// Status waiting for pricing label
  ///
  /// In en, this message translates to:
  /// **'Waiting for Pricing'**
  String get statusWaitingForPricing;

  /// Status closed label
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// Created by label
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// Update status section label
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No actions available message
  ///
  /// In en, this message translates to:
  /// **'No actions available for your role at this stage'**
  String get noActionsAvailable;

  /// Prepared quantity column header
  ///
  /// In en, this message translates to:
  /// **'Prepared Qty'**
  String get preparedQty;

  /// Accepted quantity column header
  ///
  /// In en, this message translates to:
  /// **'Accepted Qty'**
  String get acceptedQty;

  /// Requested quantity column header
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requestedQty;

  /// Sent quantity column header
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentQty;

  /// Received quantity column header
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedQty;

  /// Badge shown next to the locked destination inventory field
  ///
  /// In en, this message translates to:
  /// **'Your inventory'**
  String get yourInventory;

  /// Label above the product search field when source is a stock
  ///
  /// In en, this message translates to:
  /// **'Search Stock Products ({name})'**
  String searchStockProducts(String name);

  /// Label above the product search field when source is an inventory
  ///
  /// In en, this message translates to:
  /// **'Search Inventory Products ({name})'**
  String searchInventoryProducts(String name);

  /// Button to mark request as ready for delivery
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready for Delivery'**
  String get markAsReady;

  /// Button for seller to accept delivery
  ///
  /// In en, this message translates to:
  /// **'Accept Delivery'**
  String get acceptDelivery;

  /// Hint for inventory man when preparing
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity you can actually send (may be less than requested)'**
  String get preparingHint;

  /// Hint for seller when accepting delivery
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity you physically received'**
  String get acceptingHint;

  /// Title for delete request dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// Confirmation text for deleting a request
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this request? This action cannot be undone.'**
  String get deleteRequestConfirm;

  /// Button / dialog title for adding a stock item manually
  ///
  /// In en, this message translates to:
  /// **'Add Stock Item'**
  String get addStockItem;

  /// Title for delete stock item dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Stock Item'**
  String get deleteStockItem;

  /// Confirmation text for deleting a stock item
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this stock item? This action cannot be undone.'**
  String get deleteStockItemConfirm;

  /// Snackbar message after successful stock item deletion
  ///
  /// In en, this message translates to:
  /// **'Stock item deleted'**
  String get stockItemDeleted;

  /// Snackbar message when stock item deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String stockItemDeleteFailed(String error);

  /// Snackbar message after successful stock item creation
  ///
  /// In en, this message translates to:
  /// **'Stock item created successfully'**
  String get stockItemCreated;

  /// Snackbar message when stock item creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create: {error}'**
  String stockItemCreateFailed(String error);

  /// Invoice price AZN field label in add stock dialog
  ///
  /// In en, this message translates to:
  /// **'Invoice Price (AZN)'**
  String get invoicePriceAznLabel;

  /// Label shown when loading more items
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get loadingMore;

  /// Loading inventories placeholder
  ///
  /// In en, this message translates to:
  /// **'Loading inventories…'**
  String get loadingInventories;

  /// Section title for all products in selected stock
  ///
  /// In en, this message translates to:
  /// **'All Stock Products'**
  String get allStockProducts;

  /// Empty state when no inventories are returned
  ///
  /// In en, this message translates to:
  /// **'No stock inventories found'**
  String get noInventoriesFound;

  /// Snackbar when price update succeeds
  ///
  /// In en, this message translates to:
  /// **'Price updated successfully'**
  String get priceSavedSuccess;

  /// Snackbar when price update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update price: {error}'**
  String priceSaveFailed(String error);

  /// Button label while saving price
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingPrice;

  /// Loyal Customers navigation label
  ///
  /// In en, this message translates to:
  /// **'Loyal Customers'**
  String get loyalCustomers;

  /// Loyal Customers page subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your loyal customers and their discounts'**
  String get loyalCustomersSubtitle;

  /// Button label for adding a customer
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// Dialog title for editing a customer
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// Total customers stat label
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// Search bar hint for customers
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or loyalty ID…'**
  String get searchCustomers;

  /// Empty state when no customers are found
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// Discount label
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Loyalty ID field label
  ///
  /// In en, this message translates to:
  /// **'Loyalty ID'**
  String get loyaltyId;

  /// Snackbar when customer is created
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerCreated;

  /// Snackbar when customer is updated
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdated;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// First name field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. John'**
  String get firstNameHint;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Last name field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Doe'**
  String get lastNameHint;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Discount percentage field label
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountPercentage;

  /// Validation error for required fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Validation error for invalid numbers
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// Validation error for discount range
  ///
  /// In en, this message translates to:
  /// **'Discount must be between 0 and 100'**
  String get discountRange;

  /// Selling transactions navigation label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get sellingTransactions;

  /// Selling transactions page subtitle
  ///
  /// In en, this message translates to:
  /// **'View and filter sales transaction history'**
  String get sellingTransactionsSubtitle;

  /// Empty state for transaction list
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// Hint when no transactions match filters
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search query'**
  String get adjustFiltersOrSearch;

  /// Receipt number column header
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptNumber;

  /// Seller column header
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// Payment method column header
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentMethod;

  /// Price type column header
  ///
  /// In en, this message translates to:
  /// **'Price Type'**
  String get priceType;

  /// Discount amount column header
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountAmount;

  /// All payment methods filter option
  ///
  /// In en, this message translates to:
  /// **'All Payments'**
  String get allPaymentMethods;

  /// All price types filter option
  ///
  /// In en, this message translates to:
  /// **'All Price Types'**
  String get allPriceTypes;

  /// Cash payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// Card payment method
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// Transfer payment method
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get paymentTransfer;

  /// Retail sale price type
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get priceRetailSale;

  /// Wholesale price type
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get priceWholeSale;

  /// Transaction detail popup title
  ///
  /// In en, this message translates to:
  /// **'Transaction Detail'**
  String get transactionDetail;

  /// Store label in transaction detail
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// Customer label in transaction detail
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No customer label
  ///
  /// In en, this message translates to:
  /// **'No customer'**
  String get noCustomer;

  /// Transaction items section header
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get transactionItems;

  /// Product ID label in transaction item
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get productId;

  /// Count label in transaction item
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// Total transactions stat label
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// Total revenue summary label
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Transaction search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by receipt, seller…'**
  String get searchTransactions;

  /// Returned products navigation label
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returnedProducts;

  /// Returned products page subtitle
  ///
  /// In en, this message translates to:
  /// **'View and filter returned product history'**
  String get returnedProductsSubtitle;

  /// Returned product detail popup title
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get returnedProductDetails;

  /// Label for defected returned product
  ///
  /// In en, this message translates to:
  /// **'Defected Product'**
  String get defectedProduct;

  /// Label for normal returned product
  ///
  /// In en, this message translates to:
  /// **'Normal Return'**
  String get normalReturn;

  /// Defected status label
  ///
  /// In en, this message translates to:
  /// **'Defected'**
  String get defected;

  /// Normal status label
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// Total returns summary label
  ///
  /// In en, this message translates to:
  /// **'Total Returns'**
  String get totalReturns;

  /// All products filter option
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// Defected products filter option
  ///
  /// In en, this message translates to:
  /// **'Defected Only'**
  String get defectedOnly;

  /// Normal products filter option
  ///
  /// In en, this message translates to:
  /// **'Normal Only'**
  String get normalOnly;

  /// Empty state for returned products list
  ///
  /// In en, this message translates to:
  /// **'No returned products found'**
  String get noReturnedProducts;

  /// Product UUID label
  ///
  /// In en, this message translates to:
  /// **'Product UUID'**
  String get productUUID;

  /// Updated at timestamp label
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Add returned product dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Returned Product'**
  String get addReturnedProduct;

  /// Validation message for product selection
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProduct;

  /// Success message after adding returned product
  ///
  /// In en, this message translates to:
  /// **'Returned product added successfully'**
  String get returnedProductAdded;

  /// Receipt number input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter receipt number'**
  String get enterReceiptNumber;

  /// Label showing number of found transactions
  ///
  /// In en, this message translates to:
  /// **'Found transactions'**
  String get foundTransactions;

  /// Product selection label
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// Barcode input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter barcode'**
  String get enterBarcode;

  /// Quantity input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// Defect checkbox description
  ///
  /// In en, this message translates to:
  /// **'Mark this product as defected'**
  String get markAsDefected;

  /// Confirmation dialog title for returned product
  ///
  /// In en, this message translates to:
  /// **'Confirm Return'**
  String get confirmReturn;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Error message when barcode is not in receipt
  ///
  /// In en, this message translates to:
  /// **'Barcode not found in this receipt'**
  String get barcodeNotFoundInReceipt;

  /// Error message when quantity exceeds receipt quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds receipt amount. Available: {available}'**
  String quantityExceedsReceipt(int available);

  /// Error message when receipt is not found
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// Loading message when validating receipt
  ///
  /// In en, this message translates to:
  /// **'Validating receipt...'**
  String get validatingReceipt;

  /// Info label showing how many products are in the found receipt
  ///
  /// In en, this message translates to:
  /// **'{count} product(s) in receipt'**
  String productsInReceipt(int count);

  /// Info label showing available quantity for a barcode in the receipt
  ///
  /// In en, this message translates to:
  /// **'Available in receipt: {count}'**
  String availableInReceipt(int count);

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// Price history page title
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get priceHistory;

  /// History button label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Empty state message for price history
  ///
  /// In en, this message translates to:
  /// **'No price change history available.'**
  String get noHistory;

  /// Label for who made the price change
  ///
  /// In en, this message translates to:
  /// **'Changed by'**
  String get changedBy;

  /// Label for when the price change was made
  ///
  /// In en, this message translates to:
  /// **'Changed at'**
  String get changedAt;

  /// Label for the old price value
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get oldValue;

  /// Label for the new price value
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newValue;

  /// Label for cost unit price field
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costUnitPriceLabel;

  /// Label for wholesale unit sales price field
  ///
  /// In en, this message translates to:
  /// **'Wholesale Price'**
  String get wholeUnitSalesPriceLabel;

  /// Label for retail unit price field
  ///
  /// In en, this message translates to:
  /// **'Retail Price'**
  String get retailUnitPriceLabel;

  /// Label for a price change history entry
  ///
  /// In en, this message translates to:
  /// **'Price Change'**
  String get priceChange;

  /// Subtitle for the price history action button
  ///
  /// In en, this message translates to:
  /// **'View all price changes'**
  String get viewPriceHistory;

  /// No description provided for @posKassa.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get posKassa;

  /// No description provided for @posScanOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or search product...'**
  String get posScanOrSearch;

  /// No description provided for @posSelectFromList.
  ///
  /// In en, this message translates to:
  /// **'Select from list...'**
  String get posSelectFromList;

  /// No description provided for @posSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get posSearching;

  /// No description provided for @posNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get posNoResults;

  /// No description provided for @posBarcodeStockInfo.
  ///
  /// In en, this message translates to:
  /// **'Barcode: {barcode}  •  Stock: {qty}'**
  String posBarcodeStockInfo(String barcode, int qty);

  /// No description provided for @posProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get posProduct;

  /// No description provided for @posQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get posQuantity;

  /// No description provided for @posUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get posUnitPrice;

  /// No description provided for @posDiscountCol.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posDiscountCol;

  /// No description provided for @posTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posTotal;

  /// No description provided for @posDeleteCol.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get posDeleteCol;

  /// No description provided for @posCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get posCartEmpty;

  /// No description provided for @posCartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search to add products'**
  String get posCartEmptyHint;

  /// No description provided for @posClearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get posClearCart;

  /// No description provided for @posPriceType.
  ///
  /// In en, this message translates to:
  /// **'Price Type'**
  String get posPriceType;

  /// No description provided for @posRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get posRetail;

  /// No description provided for @posWholesale.
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get posWholesale;

  /// No description provided for @posPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get posPaymentMethod;

  /// No description provided for @posCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get posCash;

  /// No description provided for @posCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get posCard;

  /// No description provided for @posTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get posTransfer;

  /// No description provided for @posSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get posSubtotal;

  /// No description provided for @posDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount ({percent}%):'**
  String posDiscountLabel(String percent);

  /// No description provided for @posDiscountAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount ({amount} AZN):'**
  String posDiscountAmountLabel(String amount);

  /// No description provided for @posCustomerDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Discount ({percent}%):'**
  String posCustomerDiscountLabel(String percent);

  /// No description provided for @posTotalDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Discount ({percent}%):'**
  String posTotalDiscountLabel(String percent);

  /// No description provided for @posAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due:'**
  String get posAmountDue;

  /// No description provided for @posCompleteSale.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE SALE'**
  String get posCompleteSale;

  /// No description provided for @posSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get posSelectCustomer;

  /// No description provided for @posCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String posCustomerLabel(String name);

  /// No description provided for @posSaleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale Completed Successfully!'**
  String get posSaleSuccess;

  /// No description provided for @posPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get posPaymentLabel;

  /// No description provided for @posPriceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get posPriceTypeLabel;

  /// No description provided for @posProductCount.
  ///
  /// In en, this message translates to:
  /// **'Product count'**
  String get posProductCount;

  /// No description provided for @posProductCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String posProductCountValue(int count);

  /// No description provided for @posSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get posSeller;

  /// No description provided for @posStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get posStoreLabel;

  /// No description provided for @posDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt PDF'**
  String get posDownloadPdf;

  /// No description provided for @posNewSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get posNewSale;

  /// No description provided for @posErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String posErrorPrefix(String message);

  /// No description provided for @posPdfError.
  ///
  /// In en, this message translates to:
  /// **'Error creating PDF: {error}'**
  String posPdfError(String error);

  /// No description provided for @posDiscountBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot go below cost price ({price} AZN)!'**
  String posDiscountBelowCost(String price);

  /// No description provided for @posMaxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Maximum discount: {max} AZN (Cost: {cost} AZN)'**
  String posMaxDiscount(String max, String cost);

  /// No description provided for @posCustomerSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Search'**
  String get posCustomerSearchTitle;

  /// No description provided for @posCustomerSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search by name, surname, phone or card number'**
  String get posCustomerSearchSubtitle;

  /// No description provided for @posCustomerSearchField.
  ///
  /// In en, this message translates to:
  /// **'Name, surname, phone or card number...'**
  String get posCustomerSearchField;

  /// No description provided for @posStartSearch.
  ///
  /// In en, this message translates to:
  /// **'Start searching'**
  String get posStartSearch;

  /// No description provided for @posStartSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name, surname, phone or loyalty card number'**
  String get posStartSearchHint;

  /// No description provided for @posCustomerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get posCustomerNotFound;

  /// No description provided for @posCustomerNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try again with a different keyword'**
  String get posCustomerNotFoundHint;

  /// No description provided for @posNoCustomerSelected.
  ///
  /// In en, this message translates to:
  /// **'No customer selected'**
  String get posNoCustomerSelected;

  /// No description provided for @posConfirmSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get posConfirmSelect;

  /// No description provided for @posPdfFrom.
  ///
  /// In en, this message translates to:
  /// **'From: '**
  String get posPdfFrom;

  /// No description provided for @posPdfTo.
  ///
  /// In en, this message translates to:
  /// **'To: '**
  String get posPdfTo;

  /// No description provided for @posPdfSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller: '**
  String get posPdfSeller;

  /// No description provided for @posPdfPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment: '**
  String get posPdfPayment;

  /// No description provided for @posPdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get posPdfDate;

  /// No description provided for @posPdfReceiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt No. {number}'**
  String posPdfReceiptNo(String number);

  /// No description provided for @posPdfItemName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get posPdfItemName;

  /// No description provided for @posPdfUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get posPdfUnit;

  /// No description provided for @posPdfQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get posPdfQty;

  /// No description provided for @posPdfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get posPdfPrice;

  /// No description provided for @posPdfAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get posPdfAmount;

  /// No description provided for @posPdfSubtotal.
  ///
  /// In en, this message translates to:
  /// **'SUBTOTAL'**
  String get posPdfSubtotal;

  /// No description provided for @posPdfDiscount.
  ///
  /// In en, this message translates to:
  /// **'DISCOUNT ({percent}%)'**
  String posPdfDiscount(String percent);

  /// No description provided for @posPdfCustomerDiscount.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER DISCOUNT ({percent}%)'**
  String posPdfCustomerDiscount(String percent);

  /// No description provided for @posPdfBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get posPdfBalance;

  /// No description provided for @posPdfDeliveredBy.
  ///
  /// In en, this message translates to:
  /// **'Delivered by'**
  String get posPdfDeliveredBy;

  /// No description provided for @posPdfReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get posPdfReceivedBy;

  /// No description provided for @posPdfUnitPcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get posPdfUnitPcs;

  /// No description provided for @posPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get posPaymentCash;

  /// No description provided for @posPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get posPaymentCard;

  /// No description provided for @posPaymentTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get posPaymentTransfer;

  /// No description provided for @posPriceRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get posPriceRetail;

  /// No description provided for @posPriceWholesale.
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get posPriceWholesale;

  /// No description provided for @posNisye.
  ///
  /// In en, this message translates to:
  /// **'Credit (Nisye)'**
  String get posNisye;

  /// No description provided for @posNisyeToggle.
  ///
  /// In en, this message translates to:
  /// **'Credit Sale'**
  String get posNisyeToggle;

  /// No description provided for @posNisyeSection.
  ///
  /// In en, this message translates to:
  /// **'Credit Details'**
  String get posNisyeSection;

  /// No description provided for @posNisyeCustomerFullname.
  ///
  /// In en, this message translates to:
  /// **'Customer Full Name'**
  String get posNisyeCustomerFullname;

  /// No description provided for @posNisyeCustomerFullnameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name...'**
  String get posNisyeCustomerFullnameHint;

  /// No description provided for @posNisyeCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get posNisyeCustomerPhone;

  /// No description provided for @posNisyeCustomerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+994XXXXXXXXX'**
  String get posNisyeCustomerPhoneHint;

  /// No description provided for @posNisyeAmount.
  ///
  /// In en, this message translates to:
  /// **'Credit Amount (AZN)'**
  String get posNisyeAmount;

  /// No description provided for @posNisyePaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount (AZN)'**
  String get posNisyePaidAmount;

  /// No description provided for @posNisyeDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get posNisyeDate;

  /// No description provided for @posNisyeDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get posNisyeDateHint;

  /// No description provided for @posNisyeFullnameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required for credit sale'**
  String get posNisyeFullnameRequired;

  /// No description provided for @posNisyePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for credit sale'**
  String get posNisyePhoneRequired;

  /// No description provided for @posNisyeDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Due date is required for credit sale'**
  String get posNisyeDateRequired;

  /// Login page heading
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Login page subheading
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInSubtitle;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Username field label on login page
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Password field label on login page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Inventory field label on login page
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryLabel;

  /// Username hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// Validation error when username is empty
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Validation error when password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Validation error when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Hint text for inventory dropdown on login page
  ///
  /// In en, this message translates to:
  /// **'Select an inventory'**
  String get selectAnInventory;

  /// Validation error when no inventory is selected on login
  ///
  /// In en, this message translates to:
  /// **'Please select an inventory'**
  String get pleaseSelectAnInventory;

  /// Security label at bottom of login page
  ///
  /// In en, this message translates to:
  /// **'Secured connection'**
  String get securedConnection;

  /// Go back button label
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Tooltip for opening image in new browser tab
  ///
  /// In en, this message translates to:
  /// **'Open in new tab'**
  String get openInNewTab;

  /// Tooltip for closing the image viewer
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeImageViewer;

  /// Title in image viewer when there is one image
  ///
  /// In en, this message translates to:
  /// **'Invoice Image'**
  String get invoiceImageTitle;

  /// Title in image viewer when there are multiple images
  ///
  /// In en, this message translates to:
  /// **'Image {current} of {total}'**
  String invoiceImageOf(int current, int total);

  /// Snackbar error when invoice deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete invoice: {error}'**
  String failedToDeleteInvoice(String error);

  /// Tooltip for the delete invoice icon button
  ///
  /// In en, this message translates to:
  /// **'Delete invoice'**
  String get deleteInvoiceTooltip;

  /// Hint text for invoice number inline field
  ///
  /// In en, this message translates to:
  /// **'Invoice No.'**
  String get invoiceNoHint;

  /// Hint text for supplier name inline field
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierNameHint;

  /// Yes button label in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No button label in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// OK button label in dialogs
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// Title for generic error dialogs
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Print button label
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabel;

  /// Tooltip for print icon button
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printTooltip;

  /// Snackbar shown after successfully printing barcode labels
  ///
  /// In en, this message translates to:
  /// **'Printed {count} label(s) for {name}'**
  String printedLabelsSuccess(int count, String name);

  /// Snackbar error when printing fails
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String printFailed(String error);

  /// Title for delete product confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductTitle;

  /// Body text for delete product confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product? This action cannot be undone.'**
  String get deleteProductConfirm;

  /// Snackbar when a product is deleted successfully
  ///
  /// In en, this message translates to:
  /// **'{name} deleted successfully.'**
  String productDeletedSuccess(String name);

  /// Snackbar when a delete operation fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// Label on bulk delete button showing count
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String deleteCount(int count);

  /// Snackbar after bulk delete success
  ///
  /// In en, this message translates to:
  /// **'{count} product(s) deleted successfully.'**
  String productsDeletedSuccess(int count);

  /// Number of items with parenthetical suffix, e.g. in transaction list
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String nItemsParens(int count);

  /// Pagination info text
  ///
  /// In en, this message translates to:
  /// **'Showing {start}–{end} of {total}'**
  String paginationShowing(int start, int end, int total);

  /// Error message in dropdown when inventory list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load — tap to retry'**
  String get failedToLoadRetry;

  /// None option in inventory dropdown
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get inventoryDropdownNone;

  /// Label shown when processing additional pages of an invoice OCR
  ///
  /// In en, this message translates to:
  /// **'Processing additional page...'**
  String get processingAdditionalPage;

  /// Error message when an image fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Placeholder text while a page is initializing
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializingLabel;

  /// Footer text showing total item count
  ///
  /// In en, this message translates to:
  /// **'{count} items total'**
  String itemsTotal(int count);

  /// Title of the delete invoice confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoiceTitle;

  /// Body text of the delete invoice confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this invoice? This action cannot be undone.'**
  String get deleteInvoiceConfirm;

  /// Title of the bulk delete products dialog
  ///
  /// In en, this message translates to:
  /// **'Delete {count} Product(s)'**
  String bulkDeleteProductsTitle(int count);

  /// Body text of the bulk delete products confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the following products? This action cannot be undone.'**
  String get bulkDeleteProductsConfirm;

  /// Title for the print barcode dialog
  ///
  /// In en, this message translates to:
  /// **'Print Barcode'**
  String get printBarcode;

  /// Label for barcode field in print dialog
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// Generic product label
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// Label for count/quantity field
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get countLabel;

  /// Body text of the confirm and save invoice dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm and save this invoice? This action cannot be undone.'**
  String get confirmAndSaveDialogBody;

  /// Button label to load more items
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Tooltip for adding another invoice page
  ///
  /// In en, this message translates to:
  /// **'Add another page'**
  String get addAnotherPage;

  /// Tooltip for viewing the original invoice image
  ///
  /// In en, this message translates to:
  /// **'View original invoice image'**
  String get viewOriginalImage;

  /// Button label to view the original invoice
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get viewOriginal;

  /// Button label to view a single image
  ///
  /// In en, this message translates to:
  /// **'View Image'**
  String get viewImage;

  /// Button label to view multiple images
  ///
  /// In en, this message translates to:
  /// **'View Images ({count})'**
  String viewImages(int count);

  /// Label for tax ID field
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxIdLabel;

  /// Label for invoice date field
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get invoiceDateLabel;

  /// Label for address field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Label for contact field
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// Label for model field
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// Label for color field
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// Label for size field
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// Short label for invoice quantity
  ///
  /// In en, this message translates to:
  /// **'Invoice Qty'**
  String get invoiceQtyShort;

  /// Label for unit price in USD
  ///
  /// In en, this message translates to:
  /// **'Unit Price (USD)'**
  String get unitPriceUsdLabel;

  /// Label for exchange rate field
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRateLabel;

  /// Label for product code field
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCodeLabel;

  /// Fallback message when printer raises an error
  ///
  /// In en, this message translates to:
  /// **'Printer error'**
  String get printerError;

  /// Label for a numbered page
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pageN(int n);

  /// Label for supplier address field
  ///
  /// In en, this message translates to:
  /// **'Supplier Address'**
  String get supplierAddress;

  /// Label for contact number field
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// Label for contract number field
  ///
  /// In en, this message translates to:
  /// **'Contract Number'**
  String get contractNumber;

  /// Label for the inventory warehouse dropdown
  ///
  /// In en, this message translates to:
  /// **'Inventory (Warehouse)'**
  String get inventoryWarehouse;

  /// Title for editing an invoice-sourced product dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice Product'**
  String get editInvoiceProduct;

  /// Section header for read-only invoice details
  ///
  /// In en, this message translates to:
  /// **'Invoice Details (read-only)'**
  String get invoiceDetailsReadOnly;

  /// Label for the unit price in AZN
  ///
  /// In en, this message translates to:
  /// **'Unit Price (AZN)'**
  String get unitPriceAzn;

  /// Short badge label for stock-type inventory
  ///
  /// In en, this message translates to:
  /// **'STOCK'**
  String get stockTypeBadge;

  /// Short badge label for inventory type (full)
  ///
  /// In en, this message translates to:
  /// **'INVENTORY'**
  String get inventoryTypeBadge;

  /// Short abbreviated badge label for inventory type
  ///
  /// In en, this message translates to:
  /// **'INV'**
  String get invTypeBadge;

  /// Credit/nisye label
  ///
  /// In en, this message translates to:
  /// **'Credit (Nisye)'**
  String get nisye;

  /// Nisye section header in transaction detail
  ///
  /// In en, this message translates to:
  /// **'Credit Details'**
  String get nisyeDetails;

  /// Nisye customer label
  ///
  /// In en, this message translates to:
  /// **'Credit Customer'**
  String get nisyeCustomer;

  /// Nisye customer phone label
  ///
  /// In en, this message translates to:
  /// **'Credit Customer Phone'**
  String get nisyePhone;

  /// Nisye amount label
  ///
  /// In en, this message translates to:
  /// **'Credit Amount'**
  String get nisyeAmount;

  /// Nisye paid amount label
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get nisyePaidAmount;

  /// Nisye remaining amount label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get nisyeRemainingAmount;

  /// Button label to pay a nisye (credit) transaction
  ///
  /// In en, this message translates to:
  /// **'Pay Credit'**
  String get payNisye;

  /// Title of the pay nisye dialog
  ///
  /// In en, this message translates to:
  /// **'Make Credit Payment'**
  String get payNisyeTitle;

  /// Label for payment amount field in pay nisye dialog
  ///
  /// In en, this message translates to:
  /// **'Payment Amount (AZN)'**
  String get payNisyeAmount;

  /// Hint for payment amount field
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get payNisyeAmountHint;

  /// Label for note field in pay nisye dialog
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get payNisyeNote;

  /// Hint for note field in pay nisye dialog
  ///
  /// In en, this message translates to:
  /// **'e.g. First installment...'**
  String get payNisyeNoteHint;

  /// Validation error when amount is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a payment amount'**
  String get payNisyeAmountRequired;

  /// Validation error when amount is not a number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get payNisyeAmountInvalid;

  /// Validation error when amount exceeds remaining
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds remaining balance'**
  String get payNisyeAmountExceeds;

  /// Success message after nisye payment
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get payNisyeSuccess;

  /// Label for payment date field in pay nisye dialog
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get payNisyeDate;

  /// Hint for payment date field
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get payNisyeDateHint;

  /// Validation error when date is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a payment date'**
  String get payNisyeDateRequired;

  /// Section title for nisye payment history
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get nisyeHistory;

  /// Shown when nisye payment history is empty
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get nisyeHistoryEmpty;

  /// Loading state for nisye history
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get nisyeHistoryLoading;

  /// Error state for nisye history
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get nisyeHistoryError;

  /// Label for payment date in history row
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get nisyeHistoryPaymentDate;

  /// Label for who made the payment in history row
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get nisyeHistoryPaidBy;

  /// Loading label while paying
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get paying;

  /// Kassa module navigation label
  ///
  /// In en, this message translates to:
  /// **'Kassa'**
  String get kassa;

  /// Kassa page title
  ///
  /// In en, this message translates to:
  /// **'Kassa & Shift Management'**
  String get kassaManagement;

  /// Kassa page subtitle
  ///
  /// In en, this message translates to:
  /// **'Open the kassa, track the day, close at end of shift'**
  String get kassaSubtitle;

  /// Active kassa session badge label
  ///
  /// In en, this message translates to:
  /// **'ACTIVE SHIFT: LIVE MODE'**
  String get activeSession;

  /// No active session badge label
  ///
  /// In en, this message translates to:
  /// **'SHIFT CLOSED'**
  String get noActiveSession;

  /// Button to open kassa
  ///
  /// In en, this message translates to:
  /// **'Open Kassa'**
  String get openKassa;

  /// Button to close kassa
  ///
  /// In en, this message translates to:
  /// **'[Close Shift / Z-Report]'**
  String get closeKassaBtn;

  /// Kassa history table title
  ///
  /// In en, this message translates to:
  /// **'KASSA HISTORY'**
  String get kassaHistory;

  /// Opening cash amount field label
  ///
  /// In en, this message translates to:
  /// **'Opening Cash Amount (₼)'**
  String get openedCashAmount;

  /// Opening card amount field label
  ///
  /// In en, this message translates to:
  /// **'Opening Card Amount (₼)'**
  String get openedCardAmount;

  /// Closed cash amount field label
  ///
  /// In en, this message translates to:
  /// **'Physical Cash Amount (₼)'**
  String get closedCashAmount;

  /// Closed card amount field label
  ///
  /// In en, this message translates to:
  /// **'Card Amount (₼)'**
  String get closedCardAmount;

  /// Cutted cash amount field label
  ///
  /// In en, this message translates to:
  /// **'Deducted Cash (₼)'**
  String get cuttedCashAmount;

  /// Cutted card amount field label
  ///
  /// In en, this message translates to:
  /// **'Deducted Card (₼)'**
  String get cuttedCardAmount;
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
