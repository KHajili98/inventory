import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/kassa/data/models/kassa_models.dart';

class KassaRepository {
  KassaRepository._();

  static final KassaRepository instance = KassaRepository._();

  final Dio _dio = DioClient.instance;

  /// GET /api/kassa/ — paginated list of all kassa records
  Future<ApiResult<KassaListResponse>> fetchKassaList({int page = 1, int pageSize = 20, String ordering = '-created_at'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.kassaList,
        queryParameters: {'page': page, 'page_size': pageSize, 'ordering': ordering},
      );

      if (response.statusCode == 200) {
        return Success(KassaListResponse.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET /api/kassa/{id}/ — single kassa detail
  Future<ApiResult<Kassa>> fetchKassaDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.kassaDetail(id));

      if (response.statusCode == 200) {
        return Success(Kassa.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// POST /api/kassa/change-kassa/ — open kassa
  Future<ApiResult<Kassa>> openKassa({required double openedCashAmount, required double openedCardAmount, required DateTime openedDate}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.changeKassa,
        data: {
          'kassa_state': 'open',
          'opened_cash_amount': openedCashAmount.toStringAsFixed(2),
          'opened_card_amount': openedCardAmount.toStringAsFixed(2),
          'opened_date': openedDate.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Kassa.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// POST /api/kassa/change-kassa/ — close kassa
  Future<ApiResult<Kassa>> closeKassa({
    required double closedCashAmount,
    required double closedCardAmount,
    required DateTime closedDate,
    double cuttedCashAmount = 0,
    double cuttedCardAmount = 0,
    String? cuttedAmountDescription,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.changeKassa,
        data: {
          'kassa_state': 'close',
          'closed_cash_amount': closedCashAmount.toStringAsFixed(2),
          'closed_card_amount': closedCardAmount.toStringAsFixed(2),
          'closed_date': closedDate.toUtc().toIso8601String(),
          'cutted_cash_amount': cuttedCashAmount.toStringAsFixed(2),
          'cutted_card_amount': cuttedCardAmount.toStringAsFixed(2),
          if (cuttedAmountDescription != null && cuttedAmountDescription.isNotEmpty) 'cutted_amount_description': cuttedAmountDescription,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Kassa.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET /api/kassa/current-session-summary/ — live session summary
  Future<ApiResult<KassaSessionSummary>> fetchCurrentSessionSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.kassaCurrentSession);

      if (response.statusCode == 200) {
        return Success(KassaSessionSummary.fromJson(response.data as Map<String, dynamic>));
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
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String) return v;
        }
      }
    }
    return e.message ?? 'Network error';
  }
}
