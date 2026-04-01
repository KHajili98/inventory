import 'package:dio/dio.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/features/loyal_customers/data/models/customer_model.dart';

class CustomersRepository {
  CustomersRepository._();

  static final CustomersRepository instance = CustomersRepository._();

  final Dio _dio = DioClient.instance;

  /// Fetches a paginated + searched list of customers.
  Future<ApiResult<CustomersResponseModel>> fetchCustomers({int page = 1, int pageSize = 10, String? search, String ordering = '-created_at'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.customers,
        queryParameters: {'page': page, 'page_size': pageSize, 'ordering': ordering, if (search != null && search.isNotEmpty) 'search': search},
      );

      if (response.statusCode == 200) {
        final model = CustomersResponseModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Creates a new loyal customer.
  Future<ApiResult<CustomerModel>> createCustomer({
    required String name,
    required String surname,
    required String phoneNumber,
    required String loyaltyId,
    required double discountPercentage,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.customers,
        data: {'name': name, 'surname': surname, 'phone_number': phoneNumber, 'loyalty_id': loyaltyId, 'discount_percentage': discountPercentage},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final model = CustomerModel.fromJson(response.data as Map<String, dynamic>);
        return Success(model);
      }

      return Failure('Unexpected status: ${response.statusCode}', statusCode: response.statusCode);
    } on DioException catch (e) {
      return Failure(_parseDioError(e), statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Updates an existing loyal customer by UUID.
  Future<ApiResult<CustomerModel>> updateCustomer({
    required String id,
    required String name,
    required String surname,
    required String phoneNumber,
    required String loyaltyId,
    required double discountPercentage,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.customerDetail(id),
        data: {'name': name, 'surname': surname, 'phone_number': phoneNumber, 'loyalty_id': loyaltyId, 'discount_percentage': discountPercentage},
      );

      if (response.statusCode == 200) {
        final model = CustomerModel.fromJson(response.data as Map<String, dynamic>);
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
    final data = e.response?.data;
    if (data is Map) {
      final messages = data.values.expand((v) => v is List ? v.map((x) => x.toString()) : [v.toString()]).join(', ');
      if (messages.isNotEmpty) return messages;
    }
    return e.message ?? e.toString();
  }
}
