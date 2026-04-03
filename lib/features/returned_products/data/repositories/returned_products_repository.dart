import 'package:dio/dio.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/returned_products/data/models/returned_product_models.dart';

class ReturnedProductsRepository {
  ReturnedProductsRepository._();

  static final ReturnedProductsRepository instance = ReturnedProductsRepository._();

  final Dio _dio = DioClient.instance;

  /// GET /api/returned-products/
  Future<ApiResult<ReturnedProductListResponse>> fetchReturnedProducts({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? receiptNumber,
    bool? isDefected,
    String ordering = '-created_at',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/returned-products/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (receiptNumber != null && receiptNumber.isNotEmpty) 'receipt_number': receiptNumber,
          if (isDefected != null) 'is_defected': isDefected,
          'ordering': ordering,
        },
      );

      if (response.statusCode == 200) {
        return Success(ReturnedProductListResponse.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// POST /api/returned-products/
  Future<ApiResult<ReturnedProduct>> createReturnedProduct({
    required String returnedProductBarcode,
    required String productUuid,
    required int count,
    required bool isDefected,
    required String receiptNumber,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/returned-products/',
        data: {
          'returned_product_barcode': returnedProductBarcode,
          'product_uuid': productUuid,
          'count': count,
          'is_defected': isDefected,
          'receipt_number': receiptNumber,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(ReturnedProduct.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
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
