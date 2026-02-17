import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/features/cart/data/models/cart_item_model.dart';
import 'package:swipe/features/liked/data/models/liked_product_model.dart';
import 'package:swipe/features/address/data/models/address_model.dart';
import 'package:swipe/features/payment/data/models/payment_method_model.dart';
import 'package:swipe/features/orders/data/models/order_model.dart';
import 'package:swipe/core/localization/models/language_model.dart';
import 'package:swipe/core/di/service_locator.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(CartItemModelAdapter());
  Hive.registerAdapter(LikedProductModelAdapter());
  Hive.registerAdapter(AddressModelAdapter());
  Hive.registerAdapter(PaymentMethodModelAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  Hive.registerAdapter(LanguageModelAdapter());

  // Initialize dependencies (API client, services, etc.)
  await initializeDependencies();

  runApp(const SwipeApp());
}
