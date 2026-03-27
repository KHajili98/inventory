class InvoiceRecord {
  final String id;
  final String invoiceNo;
  final String date;
  final String supplier;
  final String buyer;
  final int totalItems;
  final double totalAmount;
  final InvoiceStatus status;
  final List<InvoiceRow> rows;
  final String? invoiceUrl;

  // Extra fields from OCR result — needed for the confirm POST body
  final String? supplierAddress;
  final String? supplierTaxId;
  final String? contactNumber;
  final String? contractNumber;
  final String? currency;
  final String? processingId; // processing_metadata.id from OCR upload

  InvoiceRecord({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.supplier,
    required this.buyer,
    required this.totalItems,
    required this.totalAmount,
    required this.status,
    required this.rows,
    this.invoiceUrl,
    this.supplierAddress,
    this.supplierTaxId,
    this.contactNumber,
    this.contractNumber,
    this.currency,
    this.processingId,
  });
}

enum InvoiceStatus { pending, confirmed, cancelled }

class InvoiceRow {
  String modelCode;
  String productName;
  String size;
  String color;
  String colorCode;
  int qty;
  double unitPrice;
  double totalPrice;
  int piecesPerCarton;
  double cartonCount;
  double grossWeight;
  double totalWeightKg;
  bool hasWarning;

  InvoiceRow({
    required this.modelCode,
    required this.productName,
    required this.size,
    required this.color,
    required this.colorCode,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
    required this.piecesPerCarton,
    required this.cartonCount,
    required this.grossWeight,
    required this.totalWeightKg,
    this.hasWarning = false,
  });

  // Always computed live so edits to qty or unitPrice are instantly reflected.
  // totalPrice is kept in sync by the edit page via copyWith on every change.
  double get total => totalPrice > 0 ? totalPrice : qty * unitPrice;

  InvoiceRow copyWith({
    String? modelCode,
    String? productName,
    String? size,
    String? color,
    String? colorCode,
    int? qty,
    double? unitPrice,
    double? totalPrice,
    int? piecesPerCarton,
    double? cartonCount,
    double? grossWeight,
    double? totalWeightKg,
    bool? hasWarning,
  }) {
    return InvoiceRow(
      modelCode: modelCode ?? this.modelCode,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      color: color ?? this.color,
      colorCode: colorCode ?? this.colorCode,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      piecesPerCarton: piecesPerCarton ?? this.piecesPerCarton,
      cartonCount: cartonCount ?? this.cartonCount,
      grossWeight: grossWeight ?? this.grossWeight,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      hasWarning: hasWarning ?? this.hasWarning,
    );
  }
}

// ── Mock data matching the invoice image ──────────────────────────────────────
final List<InvoiceRow> mockOcrRows = [
  InvoiceRow(
    modelCode: 'X-1',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 26,
    unitPrice: 2.1306,
    totalPrice: 55.396,
    piecesPerCarton: 26,
    cartonCount: 1.0,
    grossWeight: 10.97,
    totalWeightKg: 10.97,
  ),
  InvoiceRow(
    modelCode: 'X-34',
    productName: '',
    size: 'ø300',
    color: '',
    colorCode: '',
    qty: 26,
    unitPrice: 1.1363,
    totalPrice: 29.544,
    piecesPerCarton: 26,
    cartonCount: 1.0,
    grossWeight: 10.97,
    totalWeightKg: 10.97,
  ),
  InvoiceRow(
    modelCode: 'X-1',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 12,
    unitPrice: 2.1305,
    totalPrice: 25.566,
    piecesPerCarton: 24,
    cartonCount: 0.5,
    grossWeight: 10.97,
    totalWeightKg: 5.485,
  ),
  InvoiceRow(
    modelCode: 'X-34',
    productName: '',
    size: 'ø300',
    color: '',
    colorCode: '',
    qty: 12,
    unitPrice: 1.1363,
    totalPrice: 13.636,
    piecesPerCarton: 24,
    cartonCount: 0.5,
    grossWeight: 10.97,
    totalWeightKg: 5.485,
  ),
  InvoiceRow(
    modelCode: 'X-2',
    productName: '',
    size: 'ø500',
    color: 'SL',
    colorCode: '',
    qty: 48,
    unitPrice: 2.1306,
    totalPrice: 102.27,
    piecesPerCarton: 16,
    cartonCount: 3.0,
    grossWeight: 8.65,
    totalWeightKg: 25.95,
  ),
  InvoiceRow(
    modelCode: 'X-3',
    productName: '',
    size: 'ø500',
    color: 'GD',
    colorCode: '',
    qty: 30,
    unitPrice: 2.1306,
    totalPrice: 63.918,
    piecesPerCarton: 30,
    cartonCount: 1.0,
    grossWeight: 19.12,
    totalWeightKg: 19.12,
  ),
  InvoiceRow(
    modelCode: 'X-24',
    productName: '',
    size: 'ø400',
    color: '',
    colorCode: '',
    qty: 30,
    unitPrice: 1.7044,
    totalPrice: 51.132,
    piecesPerCarton: 30,
    cartonCount: 1.0,
    grossWeight: 19.12,
    totalWeightKg: 19.12,
  ),
  InvoiceRow(
    modelCode: 'X-3',
    productName: '',
    size: 'ø500',
    color: 'WH',
    colorCode: '',
    qty: 28,
    unitPrice: 2.1306,
    totalPrice: 59.657,
    piecesPerCarton: 14,
    cartonCount: 2.0,
    grossWeight: 19.1,
    totalWeightKg: 38.2,
  ),
  InvoiceRow(
    modelCode: 'X-4',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 34,
    unitPrice: 2.1306,
    totalPrice: 72.44,
    piecesPerCarton: 17,
    cartonCount: 2.0,
    grossWeight: 18.64,
    totalWeightKg: 37.28,
  ),
  InvoiceRow(
    modelCode: 'X-5',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 60,
    unitPrice: 2.1306,
    totalPrice: 127.84,
    piecesPerCarton: 15,
    cartonCount: 4.0,
    grossWeight: 8.0,
    totalWeightKg: 32.0,
  ),
  InvoiceRow(
    modelCode: 'X-6',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 16,
    unitPrice: 2.1306,
    totalPrice: 34.09,
    piecesPerCarton: 16,
    cartonCount: 1.0,
    grossWeight: 8.0,
    totalWeightKg: 8.0,
  ),
  InvoiceRow(
    modelCode: 'X-5',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 10,
    unitPrice: 2.1306,
    totalPrice: 21.306,
    piecesPerCarton: 13,
    cartonCount: 0.77,
    grossWeight: 8.23,
    totalWeightKg: 6.33,
    hasWarning: true,
  ),
  InvoiceRow(
    modelCode: 'X-2',
    productName: '',
    size: 'ø500',
    color: 'SL',
    colorCode: '',
    qty: 2,
    unitPrice: 2.1306,
    totalPrice: 4.2612,
    piecesPerCarton: 13,
    cartonCount: 0.15,
    grossWeight: 8.23,
    totalWeightKg: 1.27,
  ),
  InvoiceRow(
    modelCode: 'X-3',
    productName: '',
    size: 'ø500',
    color: 'WH',
    colorCode: '',
    qty: 1,
    unitPrice: 2.1306,
    totalPrice: 2.1306,
    piecesPerCarton: 15,
    cartonCount: 0.07,
    grossWeight: 8.8,
    totalWeightKg: 0.59,
    hasWarning: true,
  ),
  InvoiceRow(
    modelCode: 'X-7',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 45,
    unitPrice: 2.1306,
    totalPrice: 95.877,
    piecesPerCarton: 15,
    cartonCount: 3.0,
    grossWeight: 8.8,
    totalWeightKg: 26.4,
  ),
  InvoiceRow(
    modelCode: 'X-6',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 10,
    unitPrice: 2.1306,
    totalPrice: 21.306,
    piecesPerCarton: 15,
    cartonCount: 0.67,
    grossWeight: 8.0,
    totalWeightKg: 5.33,
  ),
  InvoiceRow(
    modelCode: 'X-7',
    productName: '',
    size: 'ø500',
    color: '',
    colorCode: '',
    qty: 5,
    unitPrice: 2.1306,
    totalPrice: 10.653,
    piecesPerCarton: 15,
    cartonCount: 0.33,
    grossWeight: 8.0,
    totalWeightKg: 2.67,
    hasWarning: true,
  ),
  InvoiceRow(
    modelCode: 'X-8',
    productName: '',
    size: 'ø000',
    color: '',
    colorCode: '',
    qty: 7,
    unitPrice: 2.1306,
    totalPrice: 14.914,
    piecesPerCarton: 15,
    cartonCount: 0.47,
    grossWeight: 8.0,
    totalWeightKg: 3.73,
    hasWarning: true,
  ),
];

final List<InvoiceRecord> mockInvoices = [
  InvoiceRecord(
    id: '1',
    invoiceNo: 'Az251111',
    date: '2025-11-11',
    supplier: 'Zhongshan Lanzi Lighting Co., LTD',
    buyer: 'Aydinoglu Trend NO.1LLC',
    totalItems: 372,
    totalAmount: 712.54,
    status: InvoiceStatus.pending,
    rows: mockOcrRows,
  ),
];
