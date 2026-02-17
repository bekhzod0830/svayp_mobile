import 'package:flutter/material.dart';

/// Mixin for onboarding screens to handle state reset when navigating back
/// This ensures that loading states and other UI states are properly reset
/// when the user returns to a screen via the back button
mixin OnboardingScreenMixin<T extends StatefulWidget> on State<T>, RouteAware {
  /// Reset the loading state - must be implemented by each screen
  void resetLoadingState();

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up again
    super.didPopNext();
    // Reset loading state when user comes back to this screen
    resetLoadingState();
  }

  @override
  void didPush() {
    // Route was pushed onto navigator and is now topmost route
    super.didPush();
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and this route is no longer visible
    super.didPushNext();
  }

  @override
  void didPop() {
    // Route was popped off the navigator
    super.didPop();
  }
}
