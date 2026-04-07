// ── Kassa Models ──────────────────────────────────────────────────────────────

class KassaUserDetails {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;

  const KassaUserDetails({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory KassaUserDetails.fromJson(Map<String, dynamic> json) {
    return KassaUserDetails(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  String get fullName {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isNotEmpty ? name : username;
  }
}

class KassaSellingTransaction {
  final String id;
  final String receiptNumber;
  final double totalSellingPrice;
  final String paymentMethod; // cash | card | transfer
  final double discountAmount;
  final DateTime createdAt;

  const KassaSellingTransaction({
    required this.id,
    required this.receiptNumber,
    required this.totalSellingPrice,
    required this.paymentMethod,
    required this.discountAmount,
    required this.createdAt,
  });

  factory KassaSellingTransaction.fromJson(Map<String, dynamic> json) {
    return KassaSellingTransaction(
      id: json['id'] as String,
      receiptNumber: json['receipt_number'] as String? ?? '',
      totalSellingPrice: _toDouble(json['total_selling_price']),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      discountAmount: _toDouble(json['discount_amount']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class KassaFee {
  final String id;
  final String feeCategory;
  final double paymentAmount;
  final String paymentType; // cash | card | transfer
  final String paymentDate;

  const KassaFee({required this.id, required this.feeCategory, required this.paymentAmount, required this.paymentType, required this.paymentDate});

  factory KassaFee.fromJson(Map<String, dynamic> json) {
    return KassaFee(
      id: json['id'] as String,
      feeCategory: json['fee_category'] as String? ?? '',
      paymentAmount: _toDouble(json['payment_amount']),
      paymentType: json['payment_type'] as String? ?? 'cash',
      paymentDate: json['payment_date'] as String? ?? '',
    );
  }
}

class Kassa {
  final String id;
  final String kassaState; // opened | closed
  final double openedCashAmount;
  final double openedCardAmount;
  final DateTime? openedDate;
  final KassaUserDetails? openedUserDetails;
  final double? closedCashAmount;
  final double? closedCardAmount;
  final DateTime? closedDate;
  final double cuttedCashAmount;
  final double cuttedCardAmount;
  final String? cuttedAmountDescription;
  final KassaUserDetails? closedByUserDetails;
  final List<KassaSellingTransaction>? closeKassaSellingTransactions;
  final List<KassaFee>? closeKassaFees;
  final double totalSellingTransactionCashSum;
  final double totalSellingTransactionCardSum;
  final double totalSellingTransactionInvoiceSum;
  final double totalFeeTransactionCashSum;
  final double totalFeeTransactionCardSum;
  final double totalFeeTransactionInvoiceSum;
  final double totalDiscountAmountSum;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Kassa({
    required this.id,
    required this.kassaState,
    required this.openedCashAmount,
    required this.openedCardAmount,
    this.openedDate,
    this.openedUserDetails,
    this.closedCashAmount,
    this.closedCardAmount,
    this.closedDate,
    required this.cuttedCashAmount,
    required this.cuttedCardAmount,
    this.cuttedAmountDescription,
    this.closedByUserDetails,
    this.closeKassaSellingTransactions,
    this.closeKassaFees,
    required this.totalSellingTransactionCashSum,
    required this.totalSellingTransactionCardSum,
    required this.totalSellingTransactionInvoiceSum,
    required this.totalFeeTransactionCashSum,
    required this.totalFeeTransactionCardSum,
    required this.totalFeeTransactionInvoiceSum,
    required this.totalDiscountAmountSum,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => kassaState == 'opened';

  factory Kassa.fromJson(Map<String, dynamic> json) {
    return Kassa(
      id: json['id'] as String,
      kassaState: json['kassa_state'] as String? ?? 'closed',
      openedCashAmount: _toDouble(json['opened_cash_amount']),
      openedCardAmount: _toDouble(json['opened_card_amount']),
      openedDate: json['opened_date'] != null ? DateTime.tryParse(json['opened_date'] as String) : null,
      openedUserDetails: json['opened_user_details'] != null ? KassaUserDetails.fromJson(json['opened_user_details'] as Map<String, dynamic>) : null,
      closedCashAmount: json['closed_cash_amount'] != null ? _toDouble(json['closed_cash_amount']) : null,
      closedCardAmount: json['closed_card_amount'] != null ? _toDouble(json['closed_card_amount']) : null,
      closedDate: json['closed_date'] != null ? DateTime.tryParse(json['closed_date'] as String) : null,
      cuttedCashAmount: _toDouble(json['cutted_cash_amount']),
      cuttedCardAmount: _toDouble(json['cutted_card_amount']),
      cuttedAmountDescription: json['cutted_amount_description'] as String?,
      closedByUserDetails: json['closed_by_user_details'] != null
          ? KassaUserDetails.fromJson(json['closed_by_user_details'] as Map<String, dynamic>)
          : null,
      closeKassaSellingTransactions: json['close_kassa_selling_transactions'] != null
          ? (json['close_kassa_selling_transactions'] as List<dynamic>)
                .map((e) => KassaSellingTransaction.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      closeKassaFees: json['close_kassa_fees'] != null
          ? (json['close_kassa_fees'] as List<dynamic>).map((e) => KassaFee.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      totalSellingTransactionCashSum: _toDouble(json['total_selling_transaction_cash_sum']),
      totalSellingTransactionCardSum: _toDouble(json['total_selling_transaction_card_sum']),
      totalSellingTransactionInvoiceSum: _toDouble(json['total_selling_transaction_invoice_sum']),
      totalFeeTransactionCashSum: _toDouble(json['total_fee_transaction_cash_sum']),
      totalFeeTransactionCardSum: _toDouble(json['total_fee_transaction_card_sum']),
      totalFeeTransactionInvoiceSum: _toDouble(json['total_fee_transaction_invoice_sum']),
      totalDiscountAmountSum: _toDouble(json['total_discount_amount_sum']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }
}

class KassaListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Kassa> results;

  const KassaListResponse({required this.count, this.next, this.previous, required this.results});

  factory KassaListResponse.fromJson(Map<String, dynamic> json) {
    return KassaListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>).map((e) => Kassa.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// ── Current Session Summary ────────────────────────────────────────────────────

class KassaSessionSummary {
  final String openedKassaId;
  final DateTime? openedDate;
  final double openedCashAmount;
  final double openedCardAmount;
  final List<KassaSellingTransaction> sellingTransactions;
  final List<KassaFee> fees;
  final double totalSellingTransactionCashSum;
  final double totalSellingTransactionCardSum;
  final double totalSellingTransactionInvoiceSum;
  final double totalFeeTransactionCashSum;
  final double totalFeeTransactionCardSum;
  final double totalFeeTransactionInvoiceSum;
  final double totalDiscountAmountSum;

  const KassaSessionSummary({
    required this.openedKassaId,
    this.openedDate,
    required this.openedCashAmount,
    required this.openedCardAmount,
    required this.sellingTransactions,
    required this.fees,
    required this.totalSellingTransactionCashSum,
    required this.totalSellingTransactionCardSum,
    required this.totalSellingTransactionInvoiceSum,
    required this.totalFeeTransactionCashSum,
    required this.totalFeeTransactionCardSum,
    required this.totalFeeTransactionInvoiceSum,
    required this.totalDiscountAmountSum,
  });

  double get totalSalesCash => totalSellingTransactionCashSum;
  double get totalSalesCard => totalSellingTransactionCardSum;
  double get totalSalesTransfer => totalSellingTransactionInvoiceSum;
  double get totalSales => totalSalesCash + totalSalesCard + totalSalesTransfer;

  double get totalExpensesCash => totalFeeTransactionCashSum;
  double get totalExpensesCard => totalFeeTransactionCardSum;
  double get totalExpensesTransfer => totalFeeTransactionInvoiceSum;
  double get totalExpenses => totalExpensesCash + totalExpensesCard + totalExpensesTransfer;

  factory KassaSessionSummary.fromJson(Map<String, dynamic> json) {
    return KassaSessionSummary(
      openedKassaId: json['opened_kassa_id'] as String? ?? '',
      openedDate: json['opened_date'] != null ? DateTime.tryParse(json['opened_date'] as String) : null,
      openedCashAmount: _toDouble(json['opened_cash_amount']),
      openedCardAmount: _toDouble(json['opened_card_amount']),
      sellingTransactions: json['selling_transactions'] != null
          ? (json['selling_transactions'] as List<dynamic>).map((e) => KassaSellingTransaction.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      fees: json['fees'] != null ? (json['fees'] as List<dynamic>).map((e) => KassaFee.fromJson(e as Map<String, dynamic>)).toList() : [],
      totalSellingTransactionCashSum: _toDouble(json['total_selling_transaction_cash_sum']),
      totalSellingTransactionCardSum: _toDouble(json['total_selling_transaction_card_sum']),
      totalSellingTransactionInvoiceSum: _toDouble(json['total_selling_transaction_invoice_sum']),
      totalFeeTransactionCashSum: _toDouble(json['total_fee_transaction_cash_sum']),
      totalFeeTransactionCardSum: _toDouble(json['total_fee_transaction_card_sum']),
      totalFeeTransactionInvoiceSum: _toDouble(json['total_fee_transaction_invoice_sum']),
      totalDiscountAmountSum: _toDouble(json['total_discount_amount_sum']),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
