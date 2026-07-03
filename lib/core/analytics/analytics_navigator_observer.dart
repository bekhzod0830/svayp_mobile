import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smartlook/flutter_smartlook.dart';

import 'analytics_service.dart';

/// Automatically tracks screen views in Firebase Analytics, Smartlook AND our backend
/// dispatcher (app_events screen_view + current-screen enrichment) on every navigation.
///
/// Add to MaterialApp:
///   navigatorObservers: [AnalyticsNavigatorObserver()],
class AnalyticsNavigatorObserver extends RouteObserver<ModalRoute<Object?>> {
  final FirebaseAnalyticsObserver _firebaseObserver;
  final SmartlookObserver _smartlookObserver;

  AnalyticsNavigatorObserver()
      : _firebaseObserver = FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        ),
        _smartlookObserver = SmartlookObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _firebaseObserver.didPush(route, previousRoute);
    _smartlookObserver.didPush(route, previousRoute);
    _trackScreen(route);
  }

  void _trackScreen(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      AnalyticsService.instance.setScreen(name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _firebaseObserver.didPop(route, previousRoute);
    _smartlookObserver.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _firebaseObserver.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _smartlookObserver.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _trackScreen(newRoute);
  }
}
