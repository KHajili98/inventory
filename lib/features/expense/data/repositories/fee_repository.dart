import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/expense/data/models/fee_model.dart';

class FeeRepository {
  FeeRepository._();

  static final FeeRepository instance = FeeRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches a paginated list of fees with optional filters.
  Future<ApiResult<FeeListResponse>> fetchFees({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created_at',
    String search = '',
    String paymentType = '',
    String paymentDateGte = '',
    String paymentDateLte = '',
    String paymentDate = '',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.fees,
        queryParameters: {
          'ordering': ordering,
          'page': page,
          'page_size': pageSize,
          'search': search,
          'payment_type': paymentType,
          'payment_date__gte': paymentDateGte,
          'payment_date__lte': paymentDateLte,
          'payment_date': paymentDate,
        },
      );

      if (response.statusCode == 200) {
        final model = FeeListResponse.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Creates a new fee. Optionally attaches a file.
  Future<ApiResult<Fee>> createFee({
    required String feeCategoryId,
    required String paymentType,
    required double paymentAmount,
    required DateTime paymentDate,
    String note = '',
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(paymentDate);
      final data = FormData.fromMap({
        'fee_category': feeCategoryId,
        'payment_type': paymentType,
        'payment_amount': paymentAmount.toString(),
        'payment_date': dateStr,
        'note': note,
        if (fileBytes != null && fileName != null) 'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.fees, data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final model = Fee.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Updates an existing fee by UUID (multipart).
  Future<ApiResult<Fee>> updateFee({
    required String id,
    required String feeCategoryId,
    required String paymentType,
    required double paymentAmount,
    required DateTime paymentDate,
    String note = '',
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(paymentDate);
      final data = FormData.fromMap({
        'fee_category': feeCategoryId,
        'payment_type': paymentType,
        'payment_amount': paymentAmount.toString(),
        'payment_date': dateStr,
        'note': note,
        if (fileBytes != null && fileName != null) 'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.patch<Map<String, dynamic>>(ApiConstants.feeDetail(id), data: data);

      if (response.statusCode == 200) {
        final model = Fee.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Deletes a fee by UUID.
  Future<ApiResult<void>> deleteFee(String id) async {
    try {
      final response = await _dio.delete<dynamic>(ApiConstants.feeDetail(id));
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
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final msg = data['detail'] ?? data['message'] ?? data['error'];
        if (msg != null) return msg.toString();
        // Return first field error
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String) return v;
        }
      }
    }
    return e.message ?? 'Network error';
  }
}
