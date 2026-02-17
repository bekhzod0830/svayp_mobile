import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
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

  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(getIt<ApiClient>()),
  );
}
