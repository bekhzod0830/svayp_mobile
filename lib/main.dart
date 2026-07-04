import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_smartlook/flutter_smartlook.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/core/config/env.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/localization/models/language_model.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/features/address/data/models/address_model.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/chat/data/models/chat_cache_model.dart';
import 'package:swipe/features/liked/data/models/liked_product_model.dart';
import 'package:swipe/features/payment/data/models/payment_method_model.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Render behind system bars (status bar + navigation bar) — removes the
  // white/grey line at the bottom on Android and makes both bars transparent.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Initialize Firebase (auto-detects GoogleService-Info.plist / google-services.json)
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(CartItemModelAdapter());
  Hive.registerAdapter(LikedProductModelAdapter());
  Hive.registerAdapter(AddressModelAdapter());
  Hive.registerAdapter(PaymentMethodModelAdapter());
  Hive.registerAdapter(ChatCacheModelAdapter());
  Hive.registerAdapter(LanguageModelAdapter());

  // Initialize dependencies (API client, services, etc.)
  await initializeDependencies();

  // Initialize Smartlook session recording (disabled — re-enable when ready).
  // Set SMARTLOOK_API_KEY in .env and run with: flutter run --dart-define-from-file=.env
  // if (Env.smartlookApiKey.isNotEmpty) {
  //   await Smartlook.instance.preferences.setProjectKey(Env.smartlookApiKey);
  //   await Smartlook.instance.preferences.setRenderingMode(RenderingMode.native);
  //   await Smartlook.instance.start();
  // }

  // Initialize push notifications asynchronously — must NOT be awaited.
  // On iOS, requestPermission() shows a system dialog; awaiting it here
  // would block main() and leave the app frozen on the splash screen.
  NotificationService.instance.initialize().ignore();

  // Limit in-memory image cache to reduce memory pressure on older devices
  // Default is 1000 images / 100MB — reduced to 100 images / 50MB
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  runApp(const SwipeApp());
}
