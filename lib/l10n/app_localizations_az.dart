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
  String get searchSKUNameBarcode => 'SKU, ad, barkod, yerləşmə axtarın…';

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
}
