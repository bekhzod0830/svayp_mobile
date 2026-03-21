import 'package:flutter/material.dart';

/// Global navigator key used by [NotificationService] for deep-linking
/// when a push notification is tapped while the app is in background/terminated.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
