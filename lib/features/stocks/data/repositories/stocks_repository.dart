import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';

class StocksRepository {
  StocksRepository._();

  static final StocksRepository instance = StocksRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches paginated stock products from GET /api/stocks/
  Future<ApiResult<StockProductResponseModel>> fetchStocks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? inventoryId,
    String? status,
    bool? priced,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.stocks,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (inventoryId != null && inventoryId.isNotEmpty) 'inventory': inventoryId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (priced != null) 'priced': priced,
        },
      );

      if (response.statusCode == 200) {
        return Success(StockProductResponseModel.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Creates a new stock item via POST /api/stocks/
  Future<ApiResult<StockProductItemModel>> createStock(CreateStockItemRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiConstants.stocks, data: request.toJson());

      if (response.statusCode == 201) {
        return Success(StockProductItemModel.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Updates prices for a stock item via PUT /api/stocks/{id}/
  Future<ApiResult<StockProductItemModel>> pricingStock({
    required StockProductItemModel item,
    required double costUnitPrice,
    required double wholeUnitSalesPrice,
    required double retailUnitPrice,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.stocks}${item.id}/',
        data: {
          'model_code': item.modelCode ?? '',
          'product_code': item.productCode ?? '',
          'product_name': item.productName ?? '',
          'size': item.size ?? '',
          'color': item.color ?? '',
          'color_code': item.colorCode ?? '',
          'quantity': item.quantity,
          'barcode': item.barcode ?? '',
          'inventory': item.inventory ?? '',
          'source_product_uuid': item.sourceProductUuid ?? '',
          'source_inventory': item.sourceInventory ?? '',
          'invoice_unit_price_azn': item.invoiceUnitPriceAzn ?? 0,
          'cost_unit_price': costUnitPrice,
          'whole_unit_sales_price': wholeUnitSalesPrice,
          'retail_unit_price': retailUnitPrice,
          'priced': true,
        },
      );

      if (response.statusCode == 200) {
        return Success(StockProductItemModel.fromJson(response.data as Map<String, dynamic>));
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Deletes a stock item via DELETE /api/stocks/{id}/
  Future<ApiResult<void>> deleteStock(String id) async {
    try {
      final response = await _dio.delete('${ApiConstants.stocks}$id/');

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
          if (data['detail'] != null) return data['detail'].toString();
          if (data['message'] != null) return data['message'].toString();
        }
        return 'Server error (${e.response?.statusCode}).';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
