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

  /// Whether a token-refresh call is currently in flight.
  /// Used to prevent multiple concurrent refreshes (lock pattern).
  static bool _isRefreshing = false;

  /// Requests that arrived while a refresh was already in-flight are queued
  /// here and replayed once the new access token is available.
  static final List<({RequestOptions options, ErrorInterceptorHandler handler})> _pendingQueue = [];

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
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject Bearer token for all requests except the login / refresh endpoints.
          final isAuthEndpoint = options.path.contains(ApiConstants.login) || options.path.contains(ApiConstants.tokenRefresh);

          if (!isAuthEndpoint) {
            final token = await AuthService.instance.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode != 401) {
            // Not an auth error — pass through unchanged.
            handler.next(e);
            return;
          }

          final failedRequest = e.requestOptions;

          // Don't try to refresh if the 401 itself came from an auth endpoint.
          final isAuthEndpoint = failedRequest.path.contains(ApiConstants.login) || failedRequest.path.contains(ApiConstants.tokenRefresh);

          if (isAuthEndpoint) {
            await AuthService.instance.logout();
            appRouter.go('/login');
            handler.next(e);
            return;
          }

          if (_isRefreshing) {
            // Another refresh is already in flight — queue this request.
            _pendingQueue.add((options: failedRequest, handler: handler));
            return;
          }

          _isRefreshing = true;

          final newAccessToken = await AuthService.instance.refreshTokens();

          _isRefreshing = false;

          if (newAccessToken == null) {
            // Refresh failed — flush queue with the original error, then logout.
            for (final pending in _pendingQueue) {
              pending.handler.next(e);
            }
            _pendingQueue.clear();
            await AuthService.instance.logout();
            appRouter.go('/login');
            handler.next(e);
            return;
          }

          // Replay all queued requests with the new access token.
          for (final pending in _pendingQueue) {
            pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
            try {
              final retryResponse = await dio.fetch(pending.options);
              pending.handler.resolve(retryResponse);
            } catch (retryError) {
              pending.handler.next(retryError as DioException);
            }
          }
          _pendingQueue.clear();

          // Retry the original failed request.
          failedRequest.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final retryResponse = await dio.fetch(failedRequest);
            handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
      // Logger is added AFTER the auth interceptor so it prints the final
      // headers including the Authorization token.
      PrettyDioLogger(requestHeader: true, requestBody: true, responseHeader: false, responseBody: true, error: true, compact: true, maxWidth: 120),
    ]);

    return dio;
  }
}
