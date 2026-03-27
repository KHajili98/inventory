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

  /// Date column header
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get date;

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
