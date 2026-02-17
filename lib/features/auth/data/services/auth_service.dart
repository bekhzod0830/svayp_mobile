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

      print('🔍 Verifying OTP - Phone: $normalizedPhone, OTP: $otpCode');

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
      print('💾 Token saved to storage');
      final savedToken = _apiClient.getToken();
      print(
        '✓ Verified token in storage: ${savedToken != null ? "YES" : "NO"}',
      );

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
      return UserResponse.fromJson(data);
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
          print('⚠️ Logout API call failed: $e');
        }
      }
      
      // Clear tokens from local storage
      await _apiClient.clearToken();
      await _apiClient.clearRefreshToken();
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
}
