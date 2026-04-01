import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/selling_transactions/data/models/selling_transaction_models.dart';

class SellingTransactionsRepository {
  SellingTransactionsRepository._();

  static final SellingTransactionsRepository instance =
      SellingTransactionsRepository._();

  final Dio _dio = DioClient.instance;

  /// POST /api/selling-transactions/complete-payment/
  Future<ApiResult<SellingTransactionResponse>> completePayment(
      CompletePaymentRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.completePayment,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(
            SellingTransactionResponse.fromJson(
                response.data as Map<String, dynamic>));
      }

      return Failure(
        'Unexpected status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
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
}
