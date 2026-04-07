import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/expense/data/models/fee_category_model.dart';

class FeeCategoryRepository {
  FeeCategoryRepository._();

  static final FeeCategoryRepository instance = FeeCategoryRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches the paginated list of fee categories.
  Future<ApiResult<FeeCategoryListResponse>> fetchCategories({
    int page = 1,
    int pageSize = 100,
    String ordering = '-created_at',
    String search = '',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.feeCategories,
        queryParameters: {'ordering': ordering, 'page': page, 'page_size': pageSize, 'search': search},
      );

      if (response.statusCode == 200) {
        final model = FeeCategoryListResponse.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Creates a new fee category.
  Future<ApiResult<FeeCategory>> createCategory(String name) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.feeCategories, data: {'name': name});

      if (response.statusCode == 201 || response.statusCode == 200) {
        final model = FeeCategory.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Updates an existing fee category by UUID.
  Future<ApiResult<FeeCategory>> updateCategory(String id, String name) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(ApiConstants.feeCategoryDetail(id), data: {'name': name});
      if (response.statusCode == 200) {
        return Success(FeeCategory.fromJson(response.data as Map<String, dynamic>));
      }
      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Deletes a fee category by UUID.
  Future<ApiResult<void>> deleteCategory(String id) async {
    try {
      final response = await _dio.delete<dynamic>(ApiConstants.feeCategoryDetail(id));
      if (response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 202) {
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
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
