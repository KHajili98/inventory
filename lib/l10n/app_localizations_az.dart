// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appTitle => 'İnventar';

  @override
  String get pos => 'Satış';

  @override
  String get sellModule => 'Satış Modulu';

  @override
  String get invoices => 'Qaimələr';

  @override
  String get inventoryProducts => 'İnventar Məhsulları';

  @override
  String get finance => 'Maliyyə';

  @override
  String get priceCalculation => 'Qiymət Hesablaması';

  @override
  String get expenseTracking => 'Xərc İzləmə';

  @override
  String get expandSidebar => 'Yan paneli genişləndir';

  @override
  String get collapseSidebar => 'Yan paneli yığ';

  @override
  String get versionInfo => 'v1.0.0 · İnventar Tətbiqi';

  @override
  String get manageInvoices =>
      'Kommersiya qaimələrinizi idarə edin və nəzərdən keçirin';

  @override
  String get addInvoiceFromImage => 'Şəkildən Qaimə Əlavə Et';

  @override
  String get totalInvoices => 'Ümumi Qaimələr';

  @override
  String get totalValue => 'Ümumi Dəyər';

  @override
  String get pending => 'Gözləyir';

  @override
  String get confirmed => 'Təsdiq edilib';

  @override
  String get cancelled => 'Ləğv edilib';

  @override
  String get invoiceNumber => 'QAİMƏ №';

  @override
  String get supplier => 'TƏCHİZATÇI';

  @override
  String get invoiceDate => 'QAİMƏ TARİXİ';

  @override
  String get createdAt => 'YARADILMA TARİXİ';

  @override
  String get items => 'ƏŞYALAR';

  @override
  String get amount => 'MƏBLƏĞ';

  @override
  String get status => 'STATUS';

  @override
  String get actions => 'ƏMƏLİYYATLAR';

  @override
  String get view => 'Bax';

  @override
  String get export => 'İxrac';

  @override
  String get delete => 'Sil';

  @override
  String get noInvoicesYet => 'Hələ qaimə yoxdur';

  @override
  String get uploadInvoiceToStart =>
      'OCR çıxarılması ilə başlamaq üçün qaimə şəklini yükləyin';

  @override
  String get processingInvoiceImage => 'Qaimə Şəkli İşlənir';

  @override
  String get uploadingImage => 'Şəkil yüklənir…';

  @override
  String get runningOCR => 'OCR işləyir…';

  @override
  String get ocrComplete => 'OCR Tamamlandı!';

  @override
  String get reviewExtractedData =>
      'Aşağıda çıxarılmış məlumatları nəzərdən keçirin';

  @override
  String get model => 'Model';

  @override
  String get sku => 'SKU';

  @override
  String get qty => 'Say';

  @override
  String get totalUSD => 'Cəmi (USD)';

  @override
  String get rowsWithMissingData => 'çəki/ölçü məlumatı olmayan sətrlər';

  @override
  String get cancel => 'Ləğv et';

  @override
  String get openAndEditTable => 'Cədvəli Aç və Redaktə Et';

  @override
  String get pcs => 'ədəd';

  @override
  String invoiceDetail(String number) {
    return 'Qaimə №$number';
  }

  @override
  String get totalItems => 'Ümumi Əşyalar';

  @override
  String get totalAmount => 'Ümumi Məbləğ';

  @override
  String get skuLines => 'SKU Sətirləri';

  @override
  String get rows => 'sətir';

  @override
  String get warnings => 'Xəbərdarlıqlar';

  @override
  String get edit => 'Redaktə et';

  @override
  String get done => 'Hazır';

  @override
  String get ocrResultEditableTable =>
      'OCR Nəticəsi — Redaktə Edilə Bilən Cədvəl';

  @override
  String get addRow => 'Sətir Əlavə Et';

  @override
  String get deleteSelected => 'Seçilmiş Sətirləri Sil';

  @override
  String get confirmInvoice => 'Qaiməni Təsdiq Et';

  @override
  String get size => 'Ölçü';

  @override
  String get color => 'Rəng';

  @override
  String get unit => 'Vahid';

  @override
  String get total => 'Cəmi';

  @override
  String get boxDimensions => 'Qutu Ölçüləri';

  @override
  String get cbm => 'CBM';

  @override
  String get netWeight => 'Xalis (kq)';

  @override
  String get grossWeight => 'Ümumi (kq)';

  @override
  String get notes => 'Qeydlər';

  @override
  String get productName => 'Məhsul Adı';

  @override
  String get generatedName => 'Yaradılmış Ad';

  @override
  String get colorCode => 'Rəng Kodu';

  @override
  String get pcsPerCarton => 'Əd/Karton';

  @override
  String get cartons => 'Karton';

  @override
  String get totalWeightKg => 'Cəmi Çəki (kq)';

  @override
  String get selectAll => 'Hamısını seç';

  @override
  String get search => 'Axtar';

  @override
  String get filterByStatus => 'Statusa görə filtr';

  @override
  String get allStatuses => 'Bütün Statuslar';

  @override
  String get inStock => 'Stokda';

  @override
  String get lowStock => 'Az Stokda';

  @override
  String get outOfStock => 'Stokda Yoxdur';

  @override
  String get totalProducts => 'Ümumi Məhsullar';

  @override
  String get totalQuantity => 'Ümumi Say';

  @override
  String get lowStockItems => 'Az Stoklu Məhsullar';

  @override
  String get outOfStockItems => 'Stokda Olmayan Məhsullar';

  @override
  String get name => 'Ad';

  @override
  String get actualQty => 'Faktiki Say';

  @override
  String get invoiceQty => 'Qaimədə Say';

  @override
  String get unitPrice => 'Vahid Qiyməti';

  @override
  String get invoiceTotal => 'Qaimə Cəmi';

  @override
  String get actualTotal => 'Faktiki Cəmi';

  @override
  String get barcode => 'Barkod';

  @override
  String get coordinate => 'Koordinat';

  @override
  String get source => 'Mənbə';

  @override
  String get noProducts => 'Məhsul tapılmadı';

  @override
  String get adjustFilters => 'Filtrlər və ya axtarış sorğusunu tənzimlə';

  @override
  String get selected => 'seçildi';

  @override
  String get totals => 'CƏMLƏR';

  @override
  String get totalQty => 'Ümumi Say';

  @override
  String get grandTotal => 'Ümumi Məbləğ';

  @override
  String get confirmAndSave => 'Təsdiq Et və Saxla';

  @override
  String get trackStockLevels =>
      'Stok səviyyələrini, yerləşmələri və qiymətləndirmələri izləyin';

  @override
  String get addProduct => 'Məhsul Əlavə Et';

  @override
  String get chooseHowToAddProduct =>
      'Məhsulu necə əlavə etmək istədiyinizi seçin';

  @override
  String get manualEntry => 'Manual Giriş';

  @override
  String get fillProductDetails =>
      'Bütün məhsul məlumatlarını\nəl ilə doldurun';

  @override
  String get fromInvoice => 'Qaimədən';

  @override
  String get importFromInvoice => 'Təsdiqlənmiş qaimədən\nidxal edin';

  @override
  String get totalSKUs => 'Ümumi SKU-lar';

  @override
  String get totalUnits => 'Ümumi Vahidlər';

  @override
  String get searchSKUNameBarcode => 'Ad, barkod, yerləşmə axtarın…';

  @override
  String get noProductsMatchSearch => 'Axtarışa uyğun məhsul tapılmadı.';

  @override
  String get all => 'Hamısı';

  @override
  String get scrollToStart => 'Əvvələ get';

  @override
  String get scrollToEnd => 'Sona get';

  @override
  String get scrollToTop => 'Yuxarıya get';

  @override
  String get scrollToBottom => 'Aşağıya get';

  @override
  String get scrollLeft => 'Sola sürüşdür';

  @override
  String get scrollRight => 'Sağa sürüşdür';

  @override
  String get scrollUp => 'Yuxarı sürüşdür';

  @override
  String get scrollDown => 'Aşağı sürüşdür';

  @override
  String get horizontal => 'Üfüqi';

  @override
  String get vertical => 'Şaquli';

  @override
  String get location => 'Yer';

  @override
  String nOfMProducts(int n, int m) {
    return '$n/$m məhsul';
  }

  @override
  String get selectInvoice => 'Qaimə Seçin';

  @override
  String get chooseInvoiceToImport => 'Məhsulları idxal etmək üçün qaimə seçin';

  @override
  String get noInvoicesAvailable => 'Qaimə mövcud deyil';

  @override
  String get addInvoicesFirst => 'Əvvəlcə Qaimələr modulunda qaimə əlavə edin';

  @override
  String importFromInvoiceNo(String invoiceNo) {
    return '$invoiceNo qaiməsindən idxal';
  }

  @override
  String get selectProducts => 'Məhsulları Seçin';

  @override
  String get enterDetails => 'Məlumatları Daxil Et';

  @override
  String nUniqueSkusFromInvoice(int n) {
    return 'Qaimədən $n unikal SKU';
  }

  @override
  String get deselectAll => 'Hamısını Ləğv Et';

  @override
  String get selectAllLabel => 'Hamısını Seç';

  @override
  String get invQty => 'Qaim. Say';

  @override
  String get invTotal => 'Qaim. Cəmi';

  @override
  String fillWarehouseDetails(int count) {
    return '$count seçilmiş məhsul üçün anbar məlumatlarını doldurun';
  }

  @override
  String invoiceQtyLabel(int qty) {
    return 'Qaimə say: $qty';
  }

  @override
  String get actualQtyReceived => 'Faktiki Qəbul Edilən Say';

  @override
  String vsInvoice(String diff) {
    return '$diff qaiməyə nisbətən';
  }

  @override
  String get warehouseLocation => 'Anbar Yeri';

  @override
  String get zone => 'Zona';

  @override
  String get row => 'Sıra';

  @override
  String get shelf => 'Rəf';

  @override
  String get codeLabel => 'Kod';

  @override
  String get back => 'Geri';

  @override
  String get nextEnterDetails => 'Növbəti: Məlumatları Daxil Et';

  @override
  String nOfMSelected(int n, int m) {
    return '$n/$m seçildi';
  }

  @override
  String importNProducts(int n) {
    return '$n Məhsul İdxal Et';
  }

  @override
  String nProductsImported(int n, String invoiceNo) {
    return '$n məhsul $invoiceNo qaiməsindən idxal edildi';
  }

  @override
  String get editProduct => 'Məhsulu Redaktə Et';

  @override
  String get addNewProduct => 'Yeni Məhsul Əlavə Et';

  @override
  String get skuField => 'SKU';

  @override
  String get modelField => 'Model';

  @override
  String get colorField => 'Rəng';

  @override
  String get barcodeField => 'Barkod';

  @override
  String get quantityField => 'Miqdar';

  @override
  String get unitPriceUSD => 'Vahid Qiymət (USD)';

  @override
  String get zoneLetter => 'Zona hərfi (A–Z)';

  @override
  String locationCode(String code) {
    return 'Yer kodu: $code';
  }

  @override
  String get saveChanges => 'Dəyişiklikləri Saxla';

  @override
  String get required => 'Tələb olunur';

  @override
  String discrepancyTooltip(String diff) {
    return 'Uyğunsuzluq: $diff qaiməyə nisbətən';
  }

  @override
  String get colorCodeField => 'Rəng Kodu';

  @override
  String get sizeField => 'Ölçü';

  @override
  String get actualPcsPerCarton => 'Faktiki Əd/Karton';

  @override
  String get actualCartonCount => 'Faktiki Karton Sayı';

  @override
  String get productInfoSection => 'Məhsul Məlumatları';

  @override
  String get packagingSection => 'Qablaşdırma';

  @override
  String get savingProduct => 'Məhsul saxlanılır…';

  @override
  String get productSavedSuccess => 'Məhsul uğurla əlavə edildi!';

  @override
  String productSaveFailed(String error) {
    return 'Məhsulu saxlamaq mümkün olmadı: $error';
  }

  @override
  String get loadingInvoices => 'Qaimələr yüklənir…';

  @override
  String fetchInvoicesFailed(String error) {
    return 'Qaimələri yükləmək alınmadı: $error';
  }

  @override
  String get retry => 'Yenidən cəhd et';

  @override
  String get loadingInvoiceDetail => 'Qaimə məlumatları yüklənir…';

  @override
  String fetchInvoiceDetailFailed(String error) {
    return 'Qaiməni yükləmək alınmadı: $error';
  }

  @override
  String nItemsInInvoice(int n) {
    return 'Qaimədə $n məhsul';
  }

  @override
  String get invoicePcsPerCarton => 'Qaim. Əd/Karton';

  @override
  String get invoiceCartonCount => 'Qaim. Karton Sayı';

  @override
  String importingProducts(int current, int total) {
    return '$current/$total idxal edilir…';
  }

  @override
  String importSuccessN(int n) {
    return '$n məhsul uğurla idxal edildi!';
  }

  @override
  String importFailedN(int n) {
    return '$n məhsul idxal edilə bilmədi.';
  }

  @override
  String estimatedTotalPrice(String total, String unitPrice) {
    return 'Təxmini cəm: \$$total  (miq. × \$$unitPrice/vahid)';
  }

  @override
  String get generateBarcode => 'Yarat';

  @override
  String get generatingBarcode => 'Yaradılır…';

  @override
  String get barcodeGeneratedSuccess => 'Barkod uğurla yaradıldı';

  @override
  String barcodeGenerateFailed(String error) {
    return 'Barkod yaradıla bilmədi: $error';
  }

  @override
  String get addExpense => 'Xərc Əlavə Et';

  @override
  String get expenseCategory => 'Kateqoriya';

  @override
  String get expensePaymentType => 'Ödəniş Növü';

  @override
  String get expenseAmount => 'Məbləğ';

  @override
  String get expenseDate => 'Tarix';

  @override
  String get expenseDocument => 'Sənəd';

  @override
  String get expenseNote => 'Qeyd';

  @override
  String get expenseCategoryRent => 'İcarə';

  @override
  String get expenseCategoryCommunal => 'Kommunal';

  @override
  String get expenseCategorySalary => 'Maaş';

  @override
  String get expenseCategoryTransport => 'Daşınma';

  @override
  String get expenseCategoryCustoms => 'Gömrük';

  @override
  String get expenseCategoryOther => 'Digər';

  @override
  String get expensePaymentCash => 'Nəqd';

  @override
  String get expensePaymentCard => 'Kart';

  @override
  String get expensePaymentTransfer => 'Köçürmə';

  @override
  String get expenseSelectCategory => 'Kateqoriya seçin';

  @override
  String get expenseSelectPaymentType => 'Ödəniş növünü seçin';

  @override
  String get expenseAmountHint => '0.00';

  @override
  String get expenseNoteHint => 'Qeyd daxil edin…';

  @override
  String get expenseDocumentHint => 'Fayl seçin (şəkil, PDF)';

  @override
  String expenseDocumentSelected(Object name) {
    return 'Seçildi: $name';
  }

  @override
  String get expenseDocumentChoose => 'Fayl seçin';

  @override
  String get noExpensesYet => 'Hələ xərc yoxdur';

  @override
  String get addFirstExpense => 'İlk xərci əlavə etmək üçün düyməni basın';

  @override
  String get totalExpenses => 'Ümumi Xərclər';

  @override
  String get expenseCount => 'Xərc sayı';

  @override
  String get save => 'Saxla';

  @override
  String get expenseFilterByDate => 'Tarixə görə filter';

  @override
  String get expenseClearFilter => 'Filtri təmizlə';

  @override
  String get expenseFilterApply => 'Tətbiq et';

  @override
  String get expenseNoResults => 'Seçilmiş tarix aralığında xərc tapılmadı';

  @override
  String get expenseEditTitle => 'Xərci Redaktə Et';

  @override
  String get expenseDeleteTitle => 'Xərci Sil';

  @override
  String get expenseDeleteConfirm => 'Bu xərci silmək istədiyinizə əminsiniz?';

  @override
  String get analytics => 'Analitika';

  @override
  String get analyticsSubtitle => 'Seçilmiş dövr üzrə maliyyə göstəriciləri';

  @override
  String get dateRange => 'Tarix aralığı';

  @override
  String get thisWeek => 'Bu həftə';

  @override
  String get revenue => 'Dövriyyə';

  @override
  String get totalExpensesCard => 'Cəmi Xərc';

  @override
  String get tax => 'Vergi';

  @override
  String get netProfit => 'Xalis Mənfəət';

  @override
  String get revenueByStore => 'Mağazaya görə dövriyyə';

  @override
  String get expensesByCategory => 'Xərclərin kateqoriyası';

  @override
  String get netProfitOverTime => 'Xalis mənfəət dinamikası';

  @override
  String get sedErekStore => 'Sədərək mağazası';

  @override
  String get abseronStore => 'Abşeron mağazası';

  @override
  String get storeLabel => 'Mağaza';

  @override
  String get amountLabel => 'Məbləğ (₼)';

  @override
  String get colDate => 'Tarix';

  @override
  String get colTotalSales => 'Ümumi Satış';

  @override
  String get colCostOfGoods => 'Ümumi Maya Dəyəri';

  @override
  String get colTotalExpenses => 'Ümumi Xərc';

  @override
  String get colTax => 'Vergi';

  @override
  String get colMargin => 'Marja Faizi';

  @override
  String get colNetProfit => 'Xalis Mənfəət';

  @override
  String get grandTotalRow => 'Ümumi Cəm';

  @override
  String get dailyBreakdown => 'Günlük Cədvəl';

  @override
  String get exportData => 'İxrac Et';

  @override
  String get exportToPdf => 'PDF olaraq İxrac Et';

  @override
  String get exportToExcel => 'Excel olaraq İxrac Et';

  @override
  String get exportSuccess => 'Uğurla ixrac edildi';

  @override
  String get exportError => 'İxrac xətası';

  @override
  String get stock => 'Stok';

  @override
  String get activeStockAmount => 'Aktiv Stok Miqdarı';

  @override
  String get activeProducts => 'Aktiv Məhsullar';

  @override
  String get pricePending => 'Qiymət Gözlənilir';

  @override
  String get allInventories => 'Bütün İnventarlar';

  @override
  String get searchStock => 'Məhsul, model, barkod axtar…';

  @override
  String get modelCode => 'Model Kodu';

  @override
  String get productCode => 'Məhsul Kodu';

  @override
  String get quantity => 'Miqdar';

  @override
  String get sourceInventory => 'Mənbə İnventar';

  @override
  String get invoicePriceUsd => 'Qaimə Qiyməti (USD)';

  @override
  String get costPrice => 'Maya Qiyməti';

  @override
  String get wholesalePrice => 'Topdan Qiymət';

  @override
  String get retailPrice => 'Pərakəndə Qiymət';

  @override
  String get activeStatus => 'Aktiv';

  @override
  String get createStockRequest => 'Sorğu Yarat';

  @override
  String get from => 'Hardan';

  @override
  String get to => 'Hara';

  @override
  String get searchProducts => 'Məhsul Axtar';

  @override
  String get requestedQuantity => 'Tələb Olunan Say';

  @override
  String get addToRequest => 'Sorğuya Əlavə Et';

  @override
  String get submitRequest => 'Sorğunu Təsdiq Et';

  @override
  String get stockRequestCreated => 'Stok sorğusu yaradıldı';

  @override
  String get pleaseSelectFromAndTo =>
      'Zəhmət olmasa \'Hardan\' və \'Hara\' seçin';

  @override
  String get pleaseAddProducts => 'Zəhmət olmasa ən azı bir məhsul əlavə edin';

  @override
  String get selectInventory => 'Anbar seçin';

  @override
  String get noProductsFound => 'Məhsul tapılmadı';

  @override
  String get requestedItems => 'Tələb Olunan Məhsullar';

  @override
  String get priceRequestsSubtitle => 'Qiymət hesablama sorğuları';

  @override
  String get totalRequests => 'Ümumi';

  @override
  String get approvedStatus => 'Təsdiqləndi';

  @override
  String get onReviewStatus => 'Gözləmədə';

  @override
  String get rejectedStatus => 'Rədd edildi';

  @override
  String get pendingStatus => 'Gözləyir';

  @override
  String get requestName => 'Request adı';

  @override
  String get sourceColumn => 'Mənbə';

  @override
  String get userColumn => 'İstifadəçi';

  @override
  String get creationDate => 'Yaradılma tarixi';

  @override
  String get statusColumn => 'Status';

  @override
  String get searchPlaceholder => 'Axtar...';

  @override
  String get noResultsFound => 'Nəticə tapılmadı';

  @override
  String get confirmationTitle => 'Təsdiqləmə';

  @override
  String get confirmCalculationMessage =>
      'Hesablamaları təsdiqləmək istədiyinizə əminsiniz?';

  @override
  String get no => 'Xeyr';

  @override
  String get yesConfirm => 'Bəli, təsdiqlə';

  @override
  String get productNameColumn => 'Məhsul adı';

  @override
  String get barcodeColumn => 'Barkod';

  @override
  String get quantityColumn => 'Miqdar';

  @override
  String get invoicePriceAzn => 'Faktura qiyməti (AZN)';

  @override
  String get colorColumn => 'Rəng';

  @override
  String get priceCalculationTitle => 'Qiymət Hesablaması';

  @override
  String get costPriceStep => '1. Maya Qiymət';

  @override
  String get costPriceLabel => 'AZN  maya qiymət';

  @override
  String get wholesalePriceStep => '2. Topdan Qiymət';

  @override
  String get wholesalePriceLabel => 'AZN  topdan qiymət';

  @override
  String get retailPriceStep => '3. Pərakəndə Qiymət';

  @override
  String get retailPriceLabel => 'AZN  pərakəndə qiymət';

  @override
  String get confirmCalculation => 'Hesablamanı Təsdiqlə';

  @override
  String get confirm => 'Təsdiqlə';

  @override
  String get adjustPrices => 'Qiymətləri Tənzimlə';

  @override
  String get editProductPrices => 'Məhsul Qiymətlerini Redaktə Et';

  @override
  String get selectStock => 'Stock seçin';

  @override
  String get selectStockHint => 'Stock seçin...';

  @override
  String get top5Products => 'Ən çox olan 5 məhsul';

  @override
  String get editPrices => 'Qiymətləri Redaktə Et';

  @override
  String get productRequests => 'Məhsul Sorğuları';

  @override
  String get productRequestsSubtitle => 'Stok köçürmə sorğularını izləyin';

  @override
  String get createRequest => 'Sorğu Yarat';

  @override
  String get allRequests => 'Hamısı';

  @override
  String get searchRequests => 'Sorğularda axtar…';

  @override
  String get noRequestsFound => 'Sorğu tapılmadı';

  @override
  String get statusPending => 'Gözləyir';

  @override
  String get statusPreparing => 'Hazırlanır';

  @override
  String get statusReadyForDelivery => 'Çatdırılmağa Hazır';

  @override
  String get statusOnWay => 'Yoldadır';

  @override
  String get statusWaitingForPricing => 'Qiymət Gözlənilir';

  @override
  String get statusClosed => 'Bağlandı';

  @override
  String get createdBy => 'Yaradan';

  @override
  String get updateStatus => 'Statusu Yenilə';

  @override
  String get noActionsAvailable =>
      'Bu mərhələdə rolunuz üçün heç bir əməliyyat yoxdur';

  @override
  String get preparedQty => 'Hazırlanan Miqdar';

  @override
  String get acceptedQty => 'Qəbul Edilən Miqdar';

  @override
  String get requestedQty => 'Tələb Edilən';

  @override
  String get sentQty => 'Göndərilən';

  @override
  String get markAsReady => 'Çatdırılmağa Hazır Kimi İşarələ';

  @override
  String get acceptDelivery => 'Çatdırılmanı Qəbul Et';

  @override
  String get preparingHint =>
      'Göndərə biləcəyiniz miqdarı daxil edin (tələb ediləndən az ola bilər)';

  @override
  String get acceptingHint => 'Fiziki olaraq aldığınız miqdarı daxil edin';

  @override
  String get deleteRequest => 'Sorğunu Sil';

  @override
  String get deleteRequestConfirm =>
      'Bu sorğunu silmək istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.';

  @override
  String get addStockItem => 'Stok Məhsulu Əlavə Et';

  @override
  String get deleteStockItem => 'Stok Məhsulunu Sil';

  @override
  String get deleteStockItemConfirm =>
      'Bu stok məhsulunu silmək istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.';

  @override
  String get stockItemDeleted => 'Stok məhsulu silindi';

  @override
  String stockItemDeleteFailed(String error) {
    return 'Silmək mümkün olmadı: $error';
  }

  @override
  String get stockItemCreated => 'Stok məhsulu uğurla yaradıldı';

  @override
  String stockItemCreateFailed(String error) {
    return 'Yaratmaq mümkün olmadı: $error';
  }

  @override
  String get invoicePriceAznLabel => 'Qaimə Qiyməti (AZN)';

  @override
  String get loadingMore => 'Daha çox yüklənir…';

  @override
  String get loadingInventories => 'Anbarlar yüklənir…';

  @override
  String get allStockProducts => 'Bütün Stok Məhsulları';

  @override
  String get noInventoriesFound => 'Stok anbarı tapılmadı';

  @override
  String get priceSavedSuccess => 'Qiymət uğurla yeniləndi';

  @override
  String priceSaveFailed(String error) {
    return 'Qiyməti yeniləmək mümkün olmadı: $error';
  }

  @override
  String get savingPrice => 'Saxlanılır…';

  @override
  String get loyalCustomers => 'Sadiq Müştərilər';

  @override
  String get loyalCustomersSubtitle =>
      'Sadiq müştərilərinizi və endirimləri idarə edin';

  @override
  String get addCustomer => 'Müştəri Əlavə Et';

  @override
  String get editCustomer => 'Müştərini Redaktə Et';

  @override
  String get totalCustomers => 'Ümumi Müştərilər';

  @override
  String get searchCustomers => 'Ad, telefon və ya sadiqlik ID ilə axtar…';

  @override
  String get noCustomersFound => 'Müştəri tapılmadı';

  @override
  String get discount => 'Endirim';

  @override
  String get loyaltyId => 'Sadiqlik ID';

  @override
  String get customerCreated => 'Müştəri uğurla əlavə edildi';

  @override
  String get customerUpdated => 'Müştəri uğurla yeniləndi';

  @override
  String get firstName => 'Ad';

  @override
  String get firstNameHint => 'məs. Kamran';

  @override
  String get lastName => 'Soyad';

  @override
  String get lastNameHint => 'məs. Hacılı';

  @override
  String get phoneNumber => 'Telefon Nömrəsi';

  @override
  String get discountPercentage => 'Endirim (%)';

  @override
  String get fieldRequired => 'Bu sahə məcburidir';

  @override
  String get invalidNumber => 'Zəhmət olmasa düzgün rəqəm daxil edin';

  @override
  String get discountRange => 'Endirim 0 ilə 100 arasında olmalıdır';

  @override
  String get sellingTransactions => 'Əməliyyatlar';

  @override
  String get sellingTransactionsSubtitle =>
      'Satış əməliyyatlarının tarixçəsini görün və filtrləyin';

  @override
  String get noTransactionsFound => 'Əməliyyat tapılmadı';

  @override
  String get adjustFiltersOrSearch =>
      'Filtr və ya axtarış sorğusunu dəyişməyə çalışın';

  @override
  String get receiptNumber => 'Qəbz';

  @override
  String get seller => 'Satıcı';

  @override
  String get paymentMethod => 'Ödəniş';

  @override
  String get priceType => 'Qiymət Növü';

  @override
  String get discountAmount => 'Endirim';

  @override
  String get allPaymentMethods => 'Bütün Ödənişlər';

  @override
  String get allPriceTypes => 'Bütün Qiymət Növləri';

  @override
  String get paymentCash => 'Nağd';

  @override
  String get paymentCard => 'Kart';

  @override
  String get paymentTransfer => 'Köçürmə';

  @override
  String get priceRetailSale => 'Pərakəndə';

  @override
  String get priceWholeSale => 'Topdansatış';

  @override
  String get transactionDetail => 'Əməliyyat Təfərrüatı';

  @override
  String get store => 'Mağaza';

  @override
  String get customer => 'Müştəri';

  @override
  String get noCustomer => 'Müştəri yoxdur';

  @override
  String get transactionItems => 'Məhsullar';

  @override
  String get productId => 'Məhsul ID';

  @override
  String get count => 'Say';

  @override
  String get totalTransactions => 'Ümumi Əməliyyatlar';

  @override
  String get totalRevenue => 'Ümumi Gəlir';

  @override
  String get searchTransactions => 'Qəbz, satıcı ilə axtar…';

  @override
  String get returnedProducts => 'Geri Qaytarma';

  @override
  String get returnedProductsSubtitle =>
      'Geri qaytarılmış məhsulları görün və filtrləyin';

  @override
  String get returnedProductDetails => 'Məhsul Təfərrüatı';

  @override
  String get defectedProduct => 'Qüsurlu Məhsul';

  @override
  String get normalReturn => 'Normal Qaytarma';

  @override
  String get defected => 'Qüsurlu';

  @override
  String get normal => 'Normal';

  @override
  String get totalReturns => 'Ümumi Qaytarmalar';

  @override
  String get allProducts => 'Bütün Məhsullar';

  @override
  String get defectedOnly => 'Yalnız Qüsurlu';

  @override
  String get normalOnly => 'Yalnız Normal';

  @override
  String get noReturnedProducts => 'Geri qaytarılmış məhsul tapılmadı';

  @override
  String get productUUID => 'Məhsul UUID';

  @override
  String get updatedAt => 'Yenilənmə Tarixi';

  @override
  String get refresh => 'Yenilə';

  @override
  String get close => 'Bağla';

  @override
  String get addReturnedProduct => 'Geri Qaytarma Əlavə Et';

  @override
  String get pleaseSelectProduct => 'Zəhmət olmasa məhsul seçin';

  @override
  String get returnedProductAdded => 'Geri qaytarma uğurla əlavə edildi';

  @override
  String get enterReceiptNumber => 'Qəbz nömrəsini daxil edin';

  @override
  String get foundTransactions => 'Tapılmış əməliyyatlar';

  @override
  String get selectProduct => 'Məhsul seçin';

  @override
  String get enterBarcode => 'Barkod daxil edin';

  @override
  String get enterQuantity => 'Miqdarı daxil edin';

  @override
  String get markAsDefected => 'Qüsurlu kimi qeyd edin';

  @override
  String get confirmReturn => 'Geri Qaytarmanı Təsdiqləyin';

  @override
  String get add => 'Əlavə et';
}
