import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';

class BarcodeRepository {
  BarcodeRepository._();
  static final BarcodeRepository instance = BarcodeRepository._();

  /// Calls POST /api/generate-barcode/ and returns the generated barcode string.
  Future<ApiResult<String>> generateBarcode() async {
    try {
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        ApiConstants.generateBarcode,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      if (data == null) {
        return const Failure('Empty response from server');
      }
      final barcode = data['barcode'] as String?;
      if (barcode == null || barcode.isEmpty) {
        return const Failure('Invalid barcode in response');
      }
      return Success(barcode);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      return Failure(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
