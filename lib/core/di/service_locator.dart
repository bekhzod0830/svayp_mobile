import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/notification_preferences_service.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/features/auth/data/services/social_auth_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/closet/data/services/closet_service.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Register SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Register API Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<SharedPreferences>()),
  );

  // Register Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<ApiClient>()),
  );

  // Native Google / Apple sign-in
  getIt.registerLazySingleton<SocialAuthService>(
    () => SocialAuthService(getIt<AuthService>()),
  );

  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(getIt<ApiClient>()),
  );

  // Notification preferences (persisted toggles per type)
  await NotificationPreferencesService.instance.init();

  // Chat WebSocket service (singleton — keeps user online across screens)
  getIt.registerLazySingleton<ChatWebSocketService>(
    () => ChatWebSocketService(),
  );

  // Closet service (local Hive-backed wardrobe)
  getIt.registerLazySingleton<ClosetService>(() => ClosetService());

  // Analytics service (Firebase Analytics + Smartlook)
  getIt.registerSingleton<AnalyticsService>(AnalyticsService.instance);
  await AnalyticsService.instance.init();
}
