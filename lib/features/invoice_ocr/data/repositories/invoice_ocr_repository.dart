import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/invoice_ocr/data/models/invoice_upload_response_model.dart';

class InvoiceOcrRepository {
  InvoiceOcrRepository._();

  static final InvoiceOcrRepository instance = InvoiceOcrRepository._();

  final Dio _dio = DioClient.instance;

  /// Uploads an image [fileBytes] with the given [fileName] to the OCR endpoint.
  /// Returns [Success] with the parsed response or [Failure] with an error message.
  Future<ApiResult<InvoiceUploadResponseModel>> uploadInvoiceImage({required List<int> fileBytes, required String fileName}) async {
    try {
      final formData = FormData.fromMap({'file': MultipartFile.fromBytes(fileBytes, filename: fileName)});

      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.uploadInvoice, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final model = InvoiceUploadResponseModel.fromJson(response.data as Map<String, dynamic>);
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
