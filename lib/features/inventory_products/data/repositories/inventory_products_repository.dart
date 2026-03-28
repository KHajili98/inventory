import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';

class InventoryProductsRepository {
  InventoryProductsRepository._();

  static final InventoryProductsRepository instance = InventoryProductsRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches the paginated list of inventory products.
  Future<ApiResult<InventoryProductResponseModel>> fetchProducts({int page = 1, int pageSize = 10, String ordering = '-created_at'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.inventoryProducts,
        queryParameters: {'page': page, 'page_size': pageSize, 'ordering': ordering},
      );

      if (response.statusCode == 200) {
        final model = InventoryProductResponseModel.fromJson(response.data as Map<String, dynamic>);
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
