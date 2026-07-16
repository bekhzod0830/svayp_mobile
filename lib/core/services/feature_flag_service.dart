import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';

/// Fetches global feature flags from the backend and caches the ones the
/// native app cares about into [LocalStorageHelper].
///
/// Backend response (GET /app/feature-flags) is a `feature.*` key → string map
/// wrapped in `{"data": {...}}`. Values are "true" / "false" strings.
class FeatureFlagService {
  final ApiClient _apiClient;

  const FeatureFlagService(this._apiClient);

  static const String _guestLoginKey = 'feature.guest_login.enabled';
  static const String _smsOtpKey = 'feature.sms_otp_enabled';
  // BACKEND TODO: flag not created yet — until then the app falls back to
  // AppConstants.defaultSignupGiftCoins. Must match the real coin grant.
  static const String _signupGiftKey = 'feature.signup_gift.coins';

  /// Pulls the latest flags and persists them. Never throws — on any failure
  /// the previously cached values are kept (so the app degrades gracefully).
  Future<void> refresh() async {
    try {
      final response = await _apiClient.get(ApiConfig.appFeatureFlags);
      final data = response.data;
      if (data is! Map<String, dynamic>) return;

      final flags = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final storage = await LocalStorageHelper.getInstance();

      if (flags.containsKey(_guestLoginKey)) {
        final enabled = _asBool(flags[_guestLoginKey]);
        await storage.setGuestLoginEnabled(enabled);
      }

      if (flags.containsKey(_smsOtpKey)) {
        final enabled = _asBool(flags[_smsOtpKey]);
        await storage.setSmsOtpEnabled(enabled);
      }

      if (flags.containsKey(_signupGiftKey)) {
        final coins = int.tryParse(flags[_signupGiftKey].toString());
        if (coins != null && coins > 0) {
          await storage.setSignupGiftCoins(coins);
        }
      }
    } catch (_) {
      // Keep cached flags on failure — never block startup.
    }
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}
