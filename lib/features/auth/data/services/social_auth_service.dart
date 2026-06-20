import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';

/// Result of a successful social sign-in.
///
/// `null` is returned from the sign-in methods when the user cancels the
/// native dialog (or no token was produced) — callers should treat `null`
/// as "do nothing".
class SocialAuthResult {
  final bool hasProfile;
  const SocialAuthResult({required this.hasProfile});
}

/// Native Google / Apple sign-in, decoupled from any UI.
///
/// Wraps the platform SDKs, exchanges the provider token for app tokens via
/// [AuthService] (which persists them), runs the shared post-login cleanup,
/// and returns whether the user already has a profile so the caller can route
/// to `/main` or onboarding.
class SocialAuthService {
  final AuthService _authService;

  SocialAuthService(this._authService);

  /// Native Google Sign-In → exchange `idToken` for app tokens.
  /// Returns `null` if the user cancels or no id token is returned.
  Future<SocialAuthResult?> signInWithGoogle({String? phoneNumber}) async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      // When set, the returned idToken's audience is this web client id —
      // it MUST match the backend GOOGLE_CLIENT_ID. Left empty when the
      // audience is already configured via google-services.json.
      serverClientId: ApiConfig.googleServerClientId.isEmpty
          ? null
          : ApiConfig.googleServerClientId,
    );

    // Make sure a stale session doesn't silently reuse a different account.
    await googleSignIn.signOut();

    final account = await googleSignIn.signIn();
    if (account == null) return null; // user cancelled

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) return null;

    final token = await _authService.googleLogin(
      idToken: idToken,
      phoneNumber: phoneNumber,
    );
    return _finalize(token);
  }

  /// Native Sign in with Apple → exchange `identityToken` for app tokens.
  /// Returns `null` if no identity token is returned.
  Future<SocialAuthResult?> signInWithApple({String? phoneNumber}) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null) return null;

    final token = await _authService.appleLogin(
      identityToken: identityToken,
      phoneNumber: phoneNumber,
    );
    return _finalize(token);
  }

  /// Shared post-login work. Tokens are already saved inside
  /// [AuthService.googleLogin] / [AuthService.appleLogin].
  Future<SocialAuthResult> _finalize(TokenResponse token) async {
    final isNewUser = !token.user.hasProfile;

    final apiClient = getIt<ApiClient>();
    // Clear any leftover partner role from a previous admin session.
    await apiClient.clearUserRole();

    // Leaving guest mode behind on successful login.
    final storage = await LocalStorageHelper.getInstance();
    await storage.clearGuestMode();

    // Reset the swipe history if a different account is logging in.
    await SeenProductsService.clearIfUserChanged(token.user.id);

    // Register FCM token (fire-and-forget — non-critical).
    unawaited(NotificationService.instance.registerTokenWithBackend());

    AnalyticsService.instance.logEvent(
      isNewUser
          ? AnalyticsEvents.registrationCompleted
          : AnalyticsEvents.loginCompleted,
    );
    await AnalyticsService.instance.setUser(
      userId: token.user.id,
      phone: token.user.phoneNumber,
      username: token.user.username,
    );

    return SocialAuthResult(hasProfile: token.user.hasProfile);
  }
}
