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
  String get date => 'TARİX';

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
}
