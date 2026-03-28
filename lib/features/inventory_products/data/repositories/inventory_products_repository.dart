import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/inventory_products/data/models/create_inventory_product_request_model.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_product_response_model.dart';

class InventoryProductsRepository {
  InventoryProductsRepository._();

  static final InventoryProductsRepository instance = InventoryProductsRepository._();

  final Dio _dio = DioClient.instance;

  /// Creates a new inventory product via POST /api/inventory-products/
  Future<ApiResult<InventoryProductItemModel>> createProduct(CreateInventoryProductRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.inventoryProducts, data: request.toJson());

      if (response.statusCode == 201) {
        final model = InventoryProductItemModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

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

  /// Deletes an inventory product via DELETE /api/inventory-products/{id}/
  Future<ApiResult<void>> deleteProduct(String id) async {
    try {
      final response = await _dio.delete<void>('${ApiConstants.inventoryProducts}$id/');

      // 204 No Content is the expected success response
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
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
          if (data['message'] != null) {
            return data['message'].toString();
          }
          if (data['detail'] != null) {
            return data['detail'].toString();
          }
          // Field-level validation errors: {"barcode": ["already exists."], ...}
          final fieldErrors = <String>[];
          data.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              fieldErrors.add('$key: ${value.first}');
            } else if (value is String) {
              fieldErrors.add('$key: $value');
            }
          });
          if (fieldErrors.isNotEmpty) return fieldErrors.join('\n');
        }
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
