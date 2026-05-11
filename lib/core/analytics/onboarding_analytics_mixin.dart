import 'package:flutter/widgets.dart';
import 'package:swipe/core/analytics/analytics_service.dart';

/// Mixin for onboarding screens that tracks step viewed / completed events.
///
/// Usage:
///   class _BasicInfoScreenState extends State<BasicInfoScreen>
///       with OnboardingAnalyticsMixin {
///     @override
///     String get viewedEvent => AnalyticsEvents.onboardingBasicInfoViewed;
///     @override
///     String get completedEvent => AnalyticsEvents.onboardingBasicInfoCompleted;
///     ...
///     // In initState call: trackStepViewed();
///     // Before Navigator.pushNamed call: trackStepCompleted();
///   }
mixin OnboardingAnalyticsMixin<T extends StatefulWidget> on State<T> {
  /// Unique event name fired when this screen is viewed.
  String get viewedEvent;

  /// Unique event name fired when user taps Continue/Next.
  String get completedEvent;

  void trackStepViewed() {
    AnalyticsService.instance.logEvent(viewedEvent);
  }

  void trackStepCompleted() {
    AnalyticsService.instance.logEvent(completedEvent);
  }
}
