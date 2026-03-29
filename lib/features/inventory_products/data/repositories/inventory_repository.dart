import 'package:dio/dio.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';

class InventoryRepository {
  InventoryRepository._();

  static final InventoryRepository instance = InventoryRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches paginated inventories from GET /api/inventories/
  Future<ApiResult<InventoryListResponse>> fetchInventories({
    int page = 1,
    int pageSize = 100,
    String ordering = '-created_at',
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': ordering,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _dio.get<Map<String, dynamic>>('/api/inventories/', queryParameters: queryParameters);

      if (response.statusCode == 200) {
        final model = InventoryListResponse.fromJson(response.data as Map<String, dynamic>);
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
