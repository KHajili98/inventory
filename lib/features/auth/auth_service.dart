import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/network/dio_client.dart';
import 'package:inventory/models/auth_models.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUser = 'auth_user';

  // ── Token accessors ──────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  Future<ApiResult<LoginResponse>> login({required String username, required String password, required String loggedInInventoryId}) async {
    try {
      final response = await DioClient.instance.post(
        ApiConstants.login,
        data: {'username': username, 'password': password, 'logged_in_inventory_id': loggedInInventoryId},
      );

      final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);

      await _saveSession(loginResponse);
      return Success(loginResponse);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      String message = 'Login failed. Please try again.';
      if (statusCode == 400 || statusCode == 401) {
        if (data is Map) {
          final detail = data['detail'] ?? data['non_field_errors'];
          if (detail != null) {
            message = detail is List ? detail.first.toString() : detail.toString();
          } else {
            message = 'Invalid username or password.';
          }
        } else {
          message = 'Invalid username or password.';
        }
      } else if (statusCode != null) {
        message = 'Server error ($statusCode). Please try again.';
      } else {
        message = 'Network error. Check your connection.';
      }

      return Failure(message, statusCode: statusCode);
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<void> _saveSession(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, response.access);
    await prefs.setString(_keyRefreshToken, response.refresh);
    await prefs.setString(_keyUser, jsonEncode(response.user.toJson()));
  }
}
