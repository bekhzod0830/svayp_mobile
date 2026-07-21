import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// API Client for making HTTP requests
class ApiClient {
  late final Dio _dio;

  /// Separate Dio instance for token refresh & retries.
  /// Has NO interceptors to avoid deadlocks / infinite loops.
  late final Dio _refreshDio;

  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';

  ApiClient(this._prefs) {
    final baseOptions = BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);

    // In debug mode, route traffic through Charles Proxy if configured.
    // Usage: flutter run --dart-define=CHARLES_PROXY=192.168.x.x:8888
    // Replace 192.168.x.x with your Mac's local IP (Charles → Help → Local IP).
    const charlesProxy = String.fromEnvironment('CHARLES_PROXY');
    if (kDebugMode && charlesProxy.isNotEmpty) {
      _applyCharlesProxy(_dio, charlesProxy);
      _applyCharlesProxy(_refreshDio, charlesProxy);
    }

    // Single queued interceptor handles auth headers + automatic 401 refresh
    _dio.interceptors.add(_tokenRefreshInterceptor());

    // Add pretty logger in debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false, // skip verbose auth headers
          requestBody: true,
          responseBody:
              false, // full JSON bodies are too noisy; use Charles or breakpoints instead
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  /// Routes all Dio traffic through a Charles Proxy instance.
  ///
  /// [proxy] must be in the form "host:port", e.g. "192.168.1.5:8888".
  /// The SSL certificate check is disabled so the Charles root cert is
  /// accepted without needing it in the Flutter trust store.
  void _applyCharlesProxy(Dio dio, String proxy) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (client) {
        client.findProxy = (uri) => 'PROXY $proxy';
        // Accept the self-signed Charles root certificate
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
  }

  /// Combined auth + token-refresh interceptor.
  ///
  /// Uses [QueuedInterceptorsWrapper] so that concurrent 401 errors are
  /// serialised – only the first one triggers a refresh, subsequent queued
  /// requests detect the token was already updated and simply retry.
  QueuedInterceptorsWrapper _tokenRefreshInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Auth endpoints handle their own credentials — never attach a
        // stale Bearer token to them or Spring Security will reject the
        // request before the controller is reached.
        final isAuthEndpoint = options.path.startsWith('/auth/') &&
            !options.path.contains('/auth/logout') &&
            !options.path.contains('/auth/me');
        if (isAuthEndpoint) {
          handler.next(options);
          return;
        }

        final token = getToken();
        if (token != null) {
          // Proactively refresh if expired or within 60-second buffer.
          // This avoids the round-trip 401 for background-resumed sessions.
          if (isTokenExpired(token, clockSkew: const Duration(seconds: 60))) {
            // Proactive refresh failed → fall through and attach the old
            // token; the 401 error interceptor will handle it or clear tokens.
            final newToken = await refreshAccessToken();
            if (newToken != null) {
              options.headers['Authorization'] = 'Bearer $newToken';
              handler.next(options);
              return;
            }
          }
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized and 403 Forbidden – both indicate the
        // access token may be expired on this backend (403 is returned by
        // some endpoints instead of 401 for expired/invalid tokens).
        final responseStatusCode = error.response?.statusCode;
        if (responseStatusCode != 401 && responseStatusCode != 403) {
          handler.next(error);
          return;
        }

        // Prevent infinite retry loops
        if (error.requestOptions.extra['_retried'] == true) {
          await _clearAllTokens();
          handler.next(error);
          return;
        }

        // If another queued request already refreshed the token, just retry
        final originalAuth = error.requestOptions.headers['Authorization'];
        final currentToken = getToken();
        if (currentToken != null && 'Bearer $currentToken' != originalAuth) {
          error.requestOptions.headers['Authorization'] =
              'Bearer $currentToken';
          error.requestOptions.extra['_retried'] = true;
          try {
            final response = await _refreshDio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (_) {
            handler.next(error);
            return;
          }
        }

        // Attempt to refresh the access token
        final refreshTokenValue = getRefreshToken();
        if (refreshTokenValue == null) {
          await _clearAllTokens();
          handler.next(error);
          return;
        }

        final newAccessToken = await refreshAccessToken();
        if (newAccessToken != null) {
          // Retry the original request with the fresh token
          error.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
          error.requestOptions.extra['_retried'] = true;
          try {
            final retryResponse = await _refreshDio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          } catch (_) {
            handler.next(error);
            return;
          }
        }

        // Refresh failed – clear everything and surface the original error.
        await _clearAllTokens();
        handler.next(error);
      },
    );
  }

  /// Convenience method to clear all auth-related tokens.
  Future<void> _clearAllTokens() async {
    await clearToken();
    await clearRefreshToken();
  }

  // ==================== Token Management ====================

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    await _prefs.remove(_refreshTokenKey);
  }

  // ==================== Partner Role Management ====================

  /// Save the authenticated user's role (e.g. 'client', 'admin', 'seller')
  Future<void> saveUserRole(String role) async {
    await _prefs.setString(_userRoleKey, role);
  }

  /// Get the saved user role, or null if not set
  String? getUserRole() {
    return _prefs.getString(_userRoleKey);
  }

  /// Clear saved user role (call on logout)
  Future<void> clearUserRole() async {
    await _prefs.remove(_userRoleKey);
  }

  /// Returns true when the logged-in user is NOT a regular client
  bool isPartnerLogin() {
    final role = getUserRole();
    if (role == null) return false;
    return role.toLowerCase() != 'client';
  }

  // ==================== JWT Helpers ====================

  /// Decode the expiry timestamp from a JWT without verifying the signature.
  /// Returns null if the token is malformed.
  DateTime? _decodeJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // JWT uses base64url encoding without padding
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      // Replace URL-safe characters
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64.decode(payload));
      final Map<String, dynamic> claims = json.decode(decoded);

      final exp = claims['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(
        (exp as int) * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true if [token] is expired or malformed.
  /// Pass a [clockSkew] buffer (default 30 s) to treat near-expiry as expired.
  bool isTokenExpired(
    String token, {
    Duration clockSkew = const Duration(seconds: 30),
  }) {
    final expiry = _decodeJwtExpiry(token);
    if (expiry == null) return true; // treat unparseable token as expired
    return DateTime.now().toUtc().isAfter(expiry.subtract(clockSkew));
  }

  /// Check if user is authenticated AND the stored token is not expired.
  bool isAuthenticated() {
    final token = getToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  // ==================== Token Refresh ====================

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns the new access token on success, or null when there is no refresh
  /// token or the refresh request fails. On success the new access (and
  /// refresh) tokens are persisted. Uses [_refreshDio] (no interceptors) to
  /// avoid re-entrancy. Shared by the interceptor and by out-of-band callers
  /// such as the visual-search upload.
  Future<String?> refreshAccessToken() async {
    final refreshTokenValue = getRefreshToken();
    if (refreshTokenValue == null) return null;
    try {
      final response = await _refreshDio.post(
        ApiConfig.authRefreshToken,
        data: {'refreshToken': refreshTokenValue},
      );
      // The endpoint may wrap data: { "data": { ... } }
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      final newAccessToken = data['access_token'] as String?;
      if (newAccessToken != null) {
        await saveToken(newAccessToken);
        final newRefreshToken = data['refresh_token'] as String?;
        if (newRefreshToken != null) await saveRefreshToken(newRefreshToken);
        return newAccessToken;
      }
    } catch (_) {
      // Caller decides how to handle a failed refresh.
    }
    return null;
  }

  /// Returns a valid (non-expired) access token, refreshing proactively when it
  /// is expired or within the 60-second clock-skew buffer.
  ///
  /// Use this for requests issued outside the Dio client (e.g. the raw
  /// multipart visual-search upload) so they get the same auto-refresh as
  /// interceptor-backed calls. Returns null when there is no usable session.
  Future<String?> getValidToken() async {
    final token = getToken();
    if (token == null) return null;
    if (!isTokenExpired(token, clockSkew: const Duration(seconds: 60))) {
      return token;
    }
    return await refreshAccessToken() ?? token;
  }

  // ==================== HTTP Methods ====================

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  /// Handle Dio errors and convert to custom exceptions
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled', statusCode: 499);

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          statusCode: 503,
        );

      case DioExceptionType.badCertificate:
        return ApiException(message: 'Certificate error', statusCode: 495);

      case DioExceptionType.unknown:
        return ApiException(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: 500,
        );
    }
  }

  /// Handle response errors
  ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return ApiException(message: 'No response from server', statusCode: 500);
    }

    final statusCode = response.statusCode ?? 500;
    String message;

    // For 5xx server errors, always show a user-friendly message
    // (never expose raw HTML / gateway error bodies to the user)
    if (statusCode >= 500) {
      switch (statusCode) {
        case 502:
          message =
              'The server is temporarily unavailable. Please try again in a moment.';
          break;
        case 503:
          message = 'Service is currently unavailable. Please try again later.';
          break;
        case 504:
          message = 'The request timed out. Please try again later.';
          break;
        case 500:
        default:
          message = 'Something went wrong on our end. Please try again later.';
          break;
      }
      return ApiException(
        message: message,
        statusCode: statusCode,
        response: response,
      );
    }

    // Coins paywall (402 INSUFFICIENT_COINS): backend body is
    // { error: { code, message, details:[{field:"required"...},{field:"balance"...}] } }.
    // Surface code + amounts so the UI can open the buy-coins flow.
    String? errorCode;
    int? requiredCoins;
    int? balanceCoins;
    try {
      final data = response.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        errorCode = err['code']?.toString();
        final details = err['details'];
        if (details is List) {
          for (final d in details) {
            if (d is Map) {
              final field = d['field']?.toString();
              final raw = d['rejectedValue'];
              final val = raw is int ? raw : int.tryParse('${raw ?? ''}');
              if (field == 'required') requiredCoins = val;
              if (field == 'balance') balanceCoins = val;
            }
          }
        }
      }
    } catch (_) {/* ignore parse issues */}

    // For 4xx errors, try to extract a meaningful message from the response body
    try {
      if (response.data is Map) {
        final err = response.data['error'];
        message =
            response.data['detail'] ??
            response.data['message'] ??
            (err is Map ? err['message']?.toString() : (err is String ? err : null)) ??
            'An error occurred';
      } else {
        message = response.data?.toString() ?? 'An error occurred';
      }
    } catch (_) {
      message = 'An error occurred';
    }

    // Handle specific 4xx status codes
    switch (statusCode) {
      case 400:
        message = message.isEmpty
            ? 'Invalid request. Please check your input.'
            : message;
        break;
      case 401:
        message = 'Unauthorized. Please login again.';
        break;
      case 403:
        message = 'Access forbidden';
        break;
      case 404:
        message = 'Resource not found';
        break;
      case 402:
        message = message.isEmpty || message == 'An error occurred'
            ? 'Not enough coins for this action.'
            : message;
        break;
      case 429:
        message = 'Too many requests. Please wait a moment and try again.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      response: response,
      code: errorCode,
      requiredCoins: requiredCoins,
      balanceCoins: balanceCoins,
    );
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Response? response;

  /// Machine-readable error code from the backend body (e.g. INSUFFICIENT_COINS).
  final String? code;

  /// Coins paywall context (402 INSUFFICIENT_COINS) — how many coins were needed
  /// and the current balance. Null for other errors.
  final int? requiredCoins;
  final int? balanceCoins;

  ApiException({
    required this.message,
    required this.statusCode,
    this.response,
    this.code,
    this.requiredCoins,
    this.balanceCoins,
  });

  /// True when the action failed because the user has too few coins — the UI
  /// should open the buy-coins flow instead of showing a generic error.
  ///
  /// NB: не любой 402 = нехватка монет. Подписочный лимит (QUOTA_EXCEEDED) тоже
  /// возвращает 402 — раньше он ложно открывал экран «Недостаточно монет» у
  /// премиума. Опираемся на код (или на requiredCoins из details[] как фолбэк).
  bool get isInsufficientCoins =>
      code == 'INSUFFICIENT_COINS' || (statusCode == 402 && requiredCoins != null);

  /// True when a paid action was blocked by a subscription/quota limit
  /// (например, месячный лимит примерок), а не нехваткой монет. Тоже 402 —
  /// поэтому проверять ДО isInsufficientCoins нельзя, различаем по коду.
  bool get isQuotaExceeded => code == 'QUOTA_EXCEEDED';

  @override
  String toString() => message;
}
