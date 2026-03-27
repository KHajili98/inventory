import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/invoice_list/data/models/invoice_list_response_model.dart';

class InvoiceListRepository {
  InvoiceListRepository._();

  static final InvoiceListRepository instance = InvoiceListRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches the paginated list of invoices.
  Future<ApiResult<InvoiceListResponseModel>> fetchInvoices({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.invoicesList, queryParameters: page > 1 ? {'page': page} : null);

      if (response.statusCode == 200) {
        final model = InvoiceListResponseModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  String _parseDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
