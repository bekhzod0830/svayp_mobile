import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';

/// Manual test for authentication flow
/// 
/// This test helps verify the API integration with the new backend.
/// Run with: flutter test test/auth_api_test.dart
/// 
/// NOTE: This requires a valid phone number and OTP for testing.
/// You can use the test OTP "000000" if the backend is in test mode.
void main() {
  group('Authentication API Tests', () {
    late AuthService authService;
    late ApiClient apiClient;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      apiClient = ApiClient(prefs);
      authService = AuthService(apiClient);
    });

    test('API Configuration Check', () {
      // Just verify the imports and setup work
      expect(authService, isNotNull);
      expect(apiClient, isNotNull);
      print('✅ Auth service initialized successfully');
      print('📡 API Base URL: https://app.svaypai.com/api/v1');
      print('🔗 Auth endpoints configured:');
      print('   - Send OTP: /auth/otp/send');
      print('   - Verify OTP: /auth/otp/verify');
      print('   - Refresh Token: /auth/token/refresh');
      print('   - Logout: /auth/logout');
    });

    // Manual integration test - uncomment and add real phone number to test
    /*
    test('Send OTP Flow', () async {
      const testPhoneNumber = '+998901234567'; // Replace with test number
      
      try {
        final response = await authService.sendOTP(testPhoneNumber);
        print('✅ OTP sent successfully');
        print('📱 Message: ${response.message}');
        expect(response.message, isNotEmpty);
      } catch (e) {
        print('❌ OTP send failed: $e');
        rethrow;
      }
    }, skip: true); // Remove skip to enable test
    */

    // Manual integration test - uncomment and add real data to test
    /*
    test('Verify OTP Flow', () async {
      const testPhoneNumber = '+998901234567'; // Replace with test number
      const testOtp = '000000'; // Use real OTP or test OTP
      
      try {
        final response = await authService.verifyOTP(
          phoneNumber: testPhoneNumber,
          otpCode: testOtp,
        );
        
        print('✅ OTP verified successfully');
        print('🔐 Access Token: ${response.accessToken.substring(0, 20)}...');
        print('🔄 Refresh Token: ${response.refreshToken?.substring(0, 20)}...');
        print('⏰ Expires In: ${response.expiresIn} seconds');
        print('👤 User ID: ${response.user.id}');
        print('📱 Phone: ${response.user.phoneNumber}');
        print('👔 Role: ${response.user.role}');
        print('📋 Has Profile: ${response.user.hasProfile}');
        
        expect(response.accessToken, isNotEmpty);
        expect(response.user.phoneNumber, equals(testPhoneNumber));
      } catch (e) {
        print('❌ OTP verification failed: $e');
        rethrow;
      }
    }, skip: true); // Remove skip to enable test
    */
  });
}
