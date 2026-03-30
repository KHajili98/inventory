import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/product_requests/data/models/product_requests_response_model.dart';

class ProductRequestsRepository {
  ProductRequestsRepository._();

  static final ProductRequestsRepository instance = ProductRequestsRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches a paginated list of product requests.
  ///
  /// [status] — optional filter (e.g. `'pending'`). Pass `null` or empty
  /// string to fetch all statuses.
  Future<ApiResult<ProductRequestsResponseModel>> fetchRequests({int page = 1, int pageSize = 10, String? status}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.productRequests,
        queryParameters: {'page': page, 'page_size': pageSize, if (status != null) 'status': status},
      );

      if (response.statusCode == 200) {
        final model = ProductRequestsResponseModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Creates a new product request via POST /api/requests/
  Future<ApiResult<ProductRequestModel>> createRequest({
    required String sourceInventory,
    required String destinationInventory,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.productRequests,
        data: {'source_inventory': sourceInventory, 'destination_inventory': destinationInventory, 'products': products},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final model = ProductRequestModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Updates the status of a product request by UUID.
  Future<ApiResult<ProductRequestModel>> updateStatus(String id, String newStatus) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(ApiConstants.productRequestDetail(id), data: {'status': newStatus});

      if (response.statusCode == 200) {
        final model = ProductRequestModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Deletes a product request by UUID.
  Future<ApiResult<void>> deleteRequest(String id) async {
    try {
      final response = await _dio.delete<dynamic>(ApiConstants.productRequestDetail(id));

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
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
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
