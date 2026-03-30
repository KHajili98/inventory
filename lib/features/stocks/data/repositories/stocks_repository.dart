import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';

class StocksRepository {
  StocksRepository._();

  static final StocksRepository instance = StocksRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches paginated stock products from GET /api/stocks/
  Future<ApiResult<StockProductResponseModel>> fetchStocks({int page = 1, int pageSize = 10, String? search, String? inventoryId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.stocks,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (inventoryId != null && inventoryId.isNotEmpty) 'inventory': inventoryId,
        },
      );

      if (response.statusCode == 200) {
        return Success(StockProductResponseModel.fromJson(response.data as Map<String, dynamic>));
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
        if (data is Map) {
          if (data['detail'] != null) return data['detail'].toString();
          if (data['message'] != null) return data['message'].toString();
        }
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
