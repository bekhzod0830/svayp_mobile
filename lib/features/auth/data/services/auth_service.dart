import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';

/// Authentication Service
/// Handles all authentication-related API calls
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Normalize phone number by removing spaces, dashes, and parentheses
  String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Send OTP to phone number
  ///
  /// Sends a 6-digit OTP code to the provided phone number
  /// Returns a message confirming the OTP was sent
  ///
  /// Example:
  /// ```dart
  /// await authService.sendOTP('+998901234567');
  /// ```
  Future<MessageResponse> sendOTP(String phoneNumber) async {
    try {
      // Normalize phone number to remove spaces
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      final response = await _apiClient.post(
        ApiConfig.authSendOtp,
        data: {'phoneNumber': normalizedPhone},
      );

      return MessageResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP code and get authentication token
  ///
  /// Verifies the OTP code and returns a JWT token along with user information
  /// Also saves the token and refresh token in local storage for subsequent authenticated requests
  ///
  /// Example:
  /// ```dart
  /// final tokenResponse = await authService.verifyOTP(
  ///   phoneNumber: '+998901234567',
  ///   otpCode: '123456',
  /// );
  /// ```
  Future<TokenResponse> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      // Normalize phone number to remove spaces
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      final response = await _apiClient.post(
        ApiConfig.authVerifyOtp,
        data: {'phoneNumber': normalizedPhone, 'otpCode': otpCode},
      );

      final tokenResponse = TokenResponse.fromJson(response.data);

      // Save access token for future requests
      await _apiClient.saveToken(tokenResponse.accessToken);

      // Save refresh token if available
      if (tokenResponse.refreshToken != null) {
        await _apiClient.saveRefreshToken(tokenResponse.refreshToken!);
      }

      // Debug: Verify token was saved
      final savedToken = _apiClient.getToken();

      return tokenResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current authenticated user
  ///
  /// Fetches the current user's information using the saved token
  /// Requires user to be authenticated
  ///
  /// Example:
  /// ```dart
  /// final user = await authService.getCurrentUser();
  /// ```
  Future<UserResponse> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConfig.authMe);

      // Handle wrapped response
      final data = response.data['data'] ?? response.data;

      final userResponse = UserResponse.fromJson(data);

      return userResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token
  ///
  /// Uses the refresh token to get a new access token
  /// Returns a new TokenResponse with updated tokens
  ///
  /// Example:
  /// ```dart
  /// final newTokenResponse = await authService.refreshToken();
  /// ```
  Future<TokenResponse> refreshToken() async {
    try {
      final refreshToken = _apiClient.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiClient.post(
        ApiConfig.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );

      final tokenResponse = TokenResponse.fromJson(response.data);

      // Save new tokens
      await _apiClient.saveToken(tokenResponse.accessToken);
      if (tokenResponse.refreshToken != null) {
        await _apiClient.saveRefreshToken(tokenResponse.refreshToken!);
      }

      return tokenResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  ///
  /// Calls the logout endpoint and clears authentication tokens from local storage
  ///
  /// Example:
  /// ```dart
  /// await authService.logout();
  /// ```
  Future<void> logout() async {
    try {
      // Call logout endpoint if user is authenticated
      if (isAuthenticated()) {
        try {
          final refreshToken = _apiClient.getRefreshToken();
          if (refreshToken != null) {
            await _apiClient.post(
              ApiConfig.authLogout,
              data: {'refreshToken': refreshToken},
            );
          }
        } catch (e) {
          // Continue with local logout even if API call fails
        }
      }

      // Clear tokens and role from local storage
      await _apiClient.clearToken();
      await _apiClient.clearRefreshToken();
      await _apiClient.clearUserRole();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is authenticated
  ///
  /// Returns true if a valid token exists in local storage
  ///
  /// Example:
  /// ```dart
  /// if (authService.isAuthenticated()) {
  ///   // User is logged in
  /// }
  /// ```
  bool isAuthenticated() {
    return _apiClient.isAuthenticated();
  }

  /// Admin / Partner Login
  ///
  /// Authenticates a partner (seller / sales rep / admin) with username + password.
  /// Saves the returned access token and refresh token for subsequent requests.
  ///
  /// Endpoint: POST /api/v1/auth/admin/login
  /// Body: { "username": "...", "password": "..." }
  Future<AdminLoginResponse> adminLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.authAdminLogin,
        data: {'username': username.trim(), 'password': password},
      );

      final loginResponse = AdminLoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (loginResponse.accessToken.isEmpty) {
        throw ApiException(
          message: 'Invalid response from server. Please try again.',
          statusCode: 500,
        );
      }

      // Persist tokens and role
      await _apiClient.saveToken(loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await _apiClient.saveRefreshToken(loginResponse.refreshToken!);
      }
      await _apiClient.saveUserRole(loginResponse.user.role);

      return loginResponse;
    } catch (e) {
      rethrow;
    }
  }
}
