import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';

class SellingTransactionsRepository {
  SellingTransactionsRepository._();

  static final SellingTransactionsRepository instance = SellingTransactionsRepository._();

  final Dio _dio = DioClient.instance;

  /// POST /api/selling-transactions/complete-payment/
  Future<ApiResult<SellingTransactionResponse>> completePayment(CompletePaymentRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.completePayment, data: request.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(SellingTransactionResponse.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET /api/selling-transactions/
  Future<ApiResult<SellingTransactionListResponse>> fetchTransactions({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? loggedInInventory,
    String? paymentMethod,
    String? priceType,
    String? selectedLoyalCustomer,
    String ordering = '-created_at',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.sellingTransactionsList,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          'ordering': ordering,
          if (loggedInInventory != null) 'logged_in_inventory': loggedInInventory,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (priceType != null) 'price_type': priceType,
          if (selectedLoyalCustomer != null) 'selected_loyal_customer': selectedLoyalCustomer,
        },
      );

      if (response.statusCode == 200) {
        return Success(SellingTransactionListResponse.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET /api/selling-transactions/ with search by receipt number
  Future<ApiResult<SellingTransactionResponse?>> fetchReceiptByNumber(String receiptNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.sellingTransactionsList,
        queryParameters: {'search': receiptNumber, 'page_size': 1},
      );

      if (response.statusCode == 200) {
        final listResponse = SellingTransactionListResponse.fromJson(response.data as Map<String, dynamic>);

        // Find exact match
        final exactMatch = listResponse.results.firstWhere(
          (transaction) => transaction.receiptNumber == receiptNumber,
          orElse: () => throw Exception('Receipt not found'),
        );

        return Success(exactMatch);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      if (e.toString().contains('Receipt not found')) {
        return const Success(null);
      }
      return Failure(e.toString());
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      final details = data['detail'] ?? data['message'] ?? data.values.first;
      return details.toString();
    }
    return e.message ?? e.toString();
  }

  /// POST /api/selling-transactions/pay-nisye/
  Future<ApiResult<void>> payNisye(PayNisyeRequest request) async {
    try {
      final response = await _dio.post<dynamic>(ApiConstants.payNisye, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Success(null);
      }
      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET /api/nisye-payment-history/?selling_transaction={id}
  Future<ApiResult<NisyePaymentHistoryResponse>> fetchNisyeHistory({
    required String sellingTransactionId,
    int page = 1,
    int pageSize = 50,
    String ordering = '-created_at',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.nisyePaymentHistory,
        queryParameters: {'selling_transaction': sellingTransactionId, 'page': page, 'page_size': pageSize, 'ordering': ordering},
      );
      if (response.statusCode == 200) {
        return Success(NisyePaymentHistoryResponse.fromJson(response.data as Map<String, dynamic>));
      }
      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
