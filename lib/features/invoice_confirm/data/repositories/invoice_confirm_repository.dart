import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/models/invoice_models.dart';

class InvoiceConfirmRepository {
  InvoiceConfirmRepository._();

  static final InvoiceConfirmRepository instance = InvoiceConfirmRepository._();

  final Dio _dio = DioClient.instance;

  /// POSTs the confirmed invoice rows to the server.
  /// Returns [Success] with the raw response map or [Failure] with an error message.
  Future<ApiResult<Map<String, dynamic>>> confirmInvoice({
    required String invoiceId,
    required List<InvoiceRow> rows,
    required InvoiceRecord invoice,
  }) async {
    try {
      final body = {
        'supplier_name': invoice.supplier,
        'supplier_address': invoice.supplierAddress,
        'supplier_tax_id': invoice.supplierTaxId,
        'contact_number': invoice.contactNumber,
        'invoice_number': invoice.invoiceNo,
        'invoice_date': invoice.date,
        'contract_number': invoice.contractNumber,
        'total_amount': invoice.totalAmount,
        'currency': invoice.currency ?? 'USD',
        if (invoice.invoiceUrl != null) 'invoice_image_url': invoice.invoiceUrl,
        if (invoice.processingId != null) 'invoice_processing': [invoice.processingId],
        'items': rows
            .map(
              (r) => {
                'model_code': r.modelCode.isEmpty ? null : r.modelCode,
                'product_name': r.productName,
                'size': r.size.isEmpty ? null : r.size,
                'color': r.color.isEmpty ? null : r.color,
                'color_code': r.colorCode.isEmpty ? null : r.colorCode,
                'quantity': r.qty,
                'unit_price_usd': r.unitPrice,
                'total_price': r.total,
                'pieces_per_carton': r.piecesPerCarton,
                'carton_count': r.cartonCount,
                'gross_weight_kg': r.grossWeight,
                'total_weight_kg': r.totalWeightKg,
              },
            )
            .toList(),
      };

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.invoiceConfirm(invoiceId),
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return Success(response.data ?? {});
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
