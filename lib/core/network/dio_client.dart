import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:inventory/core/constants/api_constants.dart';
import 'package:inventory/features/auth/auth_service.dart';
import 'package:inventory/router/app_router.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  // On web, browser security blocks cross-origin requests to plain HTTP servers
  // that don't respond with CORS headers. During development, run Flutter with:
  //   flutter run -d chrome --web-browser-flag "--disable-web-security"
  //     OR use the VS Code launch config "Flutter Web (CORS disabled)".
  //
  // For production, the backend MUST add the following response headers:
  //   Access-Control-Allow-Origin: *
  //   Access-Control-Allow-Methods: GET, POST, OPTIONS
  //   Access-Control-Allow-Headers: Content-Type, Accept
  //
  // Alternatively, point `_corsProxy` to a local proxy (e.g. nginx, node).
  static const String _corsProxy = ''; // e.g. 'http://localhost:8080/'

  static String get _effectiveBaseUrl {
    if (kIsWeb && _corsProxy.isNotEmpty) {
      return '$_corsProxy${ApiConstants.baseUrl}';
    }
    return ApiConstants.baseUrl;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _effectiveBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      PrettyDioLogger(requestHeader: true, requestBody: true, responseHeader: false, responseBody: true, error: true, compact: true, maxWidth: 120),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject Bearer token for all requests except the login endpoint
          if (!options.path.contains(ApiConstants.login)) {
            final token = await AuthService.instance.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode == 401) {
            // Clear stored session
            await AuthService.instance.logout();
            // Navigate to /login via GoRouter, replacing the entire stack
            appRouter.go('/login');
          }
          handler.next(e);
        },
      ),
    ]);

    return dio;
  }
}
