import 'package:dio/dio.dart';
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

    // Single queued interceptor handles auth headers + automatic 401 refresh
    _dio.interceptors.add(_tokenRefreshInterceptor());

    // Add pretty logger in debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  /// Combined auth + token-refresh interceptor.
  ///
  /// Uses [QueuedInterceptorsWrapper] so that concurrent 401 errors are
  /// serialised – only the first one triggers a refresh, subsequent queued
  /// requests detect the token was already updated and simply retry.
  QueuedInterceptorsWrapper _tokenRefreshInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Only handle 401 Unauthorized
        if (error.response?.statusCode != 401) {
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
          final newRefreshToken = data['refresh_token'] as String?;

          if (newAccessToken != null) {
            await saveToken(newAccessToken);
            if (newRefreshToken != null) {
              await saveRefreshToken(newRefreshToken);
            }

            // Retry the original request with the fresh token
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            error.requestOptions.extra['_retried'] = true;
            final retryResponse = await _refreshDio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        } catch (_) {
          // Refresh itself failed – clear everything
          await _clearAllTokens();
        }

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

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getToken() != null;
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

    // Try to extract error message from response
    try {
      if (response.data is Map) {
        message =
            response.data['detail'] ??
            response.data['message'] ??
            response.data['error'] ??
            'An error occurred';
      } else {
        message = response.data?.toString() ?? 'An error occurred';
      }
    } catch (_) {
      message = 'An error occurred';
    }

    // Handle specific status codes
    switch (statusCode) {
      case 400:
        message = message.isEmpty ? 'Bad request' : message;
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
      case 500:
        message = 'Server error. Please try again later.';
        break;
      case 503:
        message = 'Service unavailable. Please try again later.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      response: response,
    );
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Response? response;

  ApiException({
    required this.message,
    required this.statusCode,
    this.response,
  });

  @override
  String toString() => message;
}
