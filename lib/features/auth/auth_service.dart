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
  static const _loginResponse = 'login_response';

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

  Future<LoginResponse?> getLoginResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_loginResponse);
    if (raw == null) return null;
    try {
      // Debug: Print raw JSON
      print('🔍 [AuthService] Raw stored JSON: $raw');

      final jsonData = jsonDecode(raw) as Map<String, dynamic>;
      final response = LoginResponse.fromJson(jsonData);

      // Debug: Print parsed values
      print('🔍 [AuthService] Logged in inventory: ${response.loggedInInventory?.name}');
      print('🔍 [AuthService] Is stock inventory: ${response.loggedInInventory?.isStock}');

      // Migration: If we successfully loaded a response, re-save it to ensure
      // inventory details are in both locations (for old cached data)
      if (response.loggedInInventory != null) {
        final userJson = jsonData['user'] as Map<String, dynamic>?;

        // Check if inventory_details is missing from user object (old format)
        if (userJson != null && !userJson.containsKey('logged_in_inventory_details')) {
          print('🔄 [AuthService] Migrating old format to new format');
          // Re-save with the new format
          final newJson = jsonEncode(response.toJson());
          await prefs.setString(_loginResponse, newJson);
          print('✅ [AuthService] Migration complete. New JSON: $newJson');
        } else {
          print('✅ [AuthService] Already in new format');
        }
      }

      return response;
    } catch (e) {
      print('❌ [AuthService] Error loading login response: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Token Refresh ────────────────────────────────────────────────────────────

  /// Calls the refresh endpoint with the stored refresh token.
  /// On success, persists the new access & refresh tokens and returns the new
  /// access token string.  Returns null if the refresh token is missing or the
  /// request fails (caller should treat this as a full logout).
  Future<String?> refreshTokens() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      // Use a plain Dio instance (no auth interceptor) to avoid recursion.
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 3),
          headers: {'Accept': 'application/json'},
        ),
      );

      final response = await dio.post(ApiConstants.tokenRefresh, data: {'refresh': refreshToken});

      final data = response.data as Map<String, dynamic>;
      final newAccess = data['access'] as String;
      final newRefresh = data['refresh'] as String? ?? refreshToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, newAccess);
      await prefs.setString(_keyRefreshToken, newRefresh);

      // Also update the cached LoginResponse so getLoginResponse() stays fresh.
      final cached = await getLoginResponse();
      if (cached != null) {
        final updated = LoginResponse(user: cached.user, access: newAccess, refresh: newRefresh, loggedInInventory: cached.loggedInInventory);
        await prefs.setString(_loginResponse, jsonEncode(updated.toJson()));
      }

      return newAccess;
    } catch (_) {
      return null;
    }
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
    await prefs.remove(_loginResponse);
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<void> _saveSession(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, response.access);
    await prefs.setString(_keyRefreshToken, response.refresh);
    await prefs.setString(_keyUser, jsonEncode(response.user.toJson()));
    await prefs.setString(_loginResponse, jsonEncode(response.toJson()));
  }
}
