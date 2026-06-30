import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/force_update_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/server_maintenance_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:swipe/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:swipe/features/auth/presentation/screens/verify_method_screen.dart';
import 'package:swipe/features/auth/presentation/screens/otp_verification_screen.dart';
// WebView auth flow — kept for mini-app embedding; no longer the default entry.
import 'package:swipe/features/auth/presentation/screens/auth_web_view_screen.dart';
import 'package:swipe/features/auth/presentation/screens/partner_login_screen.dart'; // kept — not used in new flow
import 'package:swipe/features/partner/presentation/screens/partner_main_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/basic_info_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/hijab_preference_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/primary_objective_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/fit_preference_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/modesty_level_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/size_profile_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/body_type_screen.dart'; // REMOVED FROM FLOW
// import 'package:swipe/features/onboarding/presentation/screens/sizes_screen.dart'; // REMOVED FROM FLOW
// import 'package:swipe/features/onboarding/presentation/screens/budget_preference_screen.dart'; // REMOVED FROM FLOW
import 'package:swipe/features/onboarding/presentation/screens/style_quiz_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/tutorial_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/avoided_items_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/avoided_shoes_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/avoided_colors_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/avoided_prints_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/budget_by_items_screen.dart'; // REMOVED FROM FLOW
// import 'package:swipe/features/onboarding/presentation/screens/style_categories_screen.dart'; // REMOVED FROM FLOW
// import 'package:swipe/features/onboarding/presentation/screens/brand_preferences_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/onboarding_completion_screen.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:swipe/features/profile/presentation/screens/notifications_screen.dart';
import 'package:swipe/features/profile/presentation/screens/notification_preferences_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';

/// App Routes
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String phoneAuth = '/phone-auth';
  static const String verifyMethod = '/verify-method';
  static const String authWebView = '/auth-webview';
  static const String otpVerification = '/otp-verification';
  static const String basicInfo = '/basic-info';
  static const String hijabPreference = '/hijab-preference';
  static const String primaryObjective = '/primary-objective';
  static const String fitPreference = '/fit-preference';
  static const String modestyLevel = '/modesty-level';
  static const String sizeProfile = '/size-profile';
  static const String bodyType = '/body-type';
  static const String sizes = '/sizes';
  static const String budgetPreference = '/budget-preference';
  static const String styleQuiz = '/style-quiz';
  static const String styleCategories = '/style-categories';
  static const String occasions = '/occasions';
  static const String brandPreferences = '/brand-preferences';
  static const String styleAnalysis = '/style-analysis';
  static const String onboardingCompletion = '/onboarding-completion';
  static const String tutorial = '/tutorial';
  static const String avoidedItems = '/avoided-items';
  static const String avoidedShoes = '/avoided-shoes';
  static const String avoidedColors = '/avoided-colors';
  static const String avoidedPrints = '/avoided-prints';
  static const String budgetByItems = '/budget-by-items';
  static const String main = '/main';
  static const String discover = '/discover';
  static const String productDetail = '/product-detail';
  static const String liked = '/liked';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notification-preferences';
  static const String forceUpdate = '/force-update';
  static const String serverMaintenance = '/server-maintenance';
  static const String partnerLogin = '/partner-login';
  static const String partnerMain = '/partner-main';
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';

  /// Generate routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case forceUpdate:
        final args = settings.arguments as Map<String, String>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(
            latestVersion: args['version'] ?? '',
            storeUrl: args['storeUrl'] ?? '',
          ),
        );

      case serverMaintenance:
        return MaterialPageRoute(
          builder: (_) => const ServerMaintenanceScreen(),
        );

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case phoneAuth:
        return MaterialPageRoute(builder: (_) => const PhoneAuthScreen());

      case verifyMethod:
        final args = settings.arguments;
        if (args is VerifyMethodArgs) {
          return MaterialPageRoute(
            builder: (_) => VerifyMethodScreen(
              phoneNumber: args.phoneNumber,
              isNew: args.isNew,
              isLinking: args.isLinking,
            ),
          );
        }
        // Legacy string argument (e.g. from OTP screen linking flow)
        final phone = args as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => VerifyMethodScreen(phoneNumber: phone, isLinking: true),
        );

      // WebView auth — retained for mini-app embedding (not the default entry).
      case authWebView:
        return MaterialPageRoute(builder: (_) => const AuthWebViewScreen());

      case otpVerification:
        final phone = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(phoneNumber: phone),
        );

      case basicInfo:
        return MaterialPageRoute(
          builder: (_) => const BasicInfoScreen(),
          settings: settings,
        );

      case hijabPreference:
        return MaterialPageRoute(
          builder: (_) => const HijabPreferenceScreen(),
          settings: settings,
        );

      // case primaryObjective: // DISABLED
      //   return MaterialPageRoute(
      //     builder: (_) => const PrimaryObjectiveScreen(),
      //     settings: settings,
      //   );

      case fitPreference:
        return MaterialPageRoute(
          builder: (_) => const FitPreferenceScreen(),
          settings: settings,
        );

      case modestyLevel:
        return MaterialPageRoute(
          builder: (_) => const ModestyLevelScreen(),
          settings: settings,
        );

      case sizeProfile:
        return MaterialPageRoute(
          builder: (_) => const SizeProfileScreen(),
          settings: settings,
        );

      // case bodyType: // REMOVED FROM FLOW
      //   return MaterialPageRoute(
      //     builder: (_) => const BodyTypeScreen(),
      //     settings: settings,
      //   );

      // case sizes: // REMOVED FROM FLOW
      //   return MaterialPageRoute(
      //     builder: (_) => const SizesScreen(),
      //     settings: settings,
      //   );

      // case budgetPreference: // REMOVED FROM FLOW
      //   return MaterialPageRoute(
      //     builder: (_) => const BudgetPreferenceScreen(),
      //   );

      case styleQuiz:
        return MaterialPageRoute(
          builder: (_) => const StyleQuizScreen(),
          settings: settings,
        );

      // case styleCategories: // REMOVED FROM FLOW
      //   return MaterialPageRoute(builder: (_) => const StyleCategoriesScreen());

      // case occasions: // DISABLED
      //   return MaterialPageRoute(builder: (_) => const OccasionsScreen());

      // case brandPreferences: // DISABLED
      //   return MaterialPageRoute(
      //     builder: (_) => const BrandPreferencesScreen(),
      //   );

      case onboardingCompletion:
        return MaterialPageRoute(
          builder: (_) => const OnboardingCompletionScreen(),
        );

      case tutorial:
        return MaterialPageRoute(
          builder: (_) => const TutorialScreen(),
          settings: settings,
        );

      case avoidedItems:
        return MaterialPageRoute(builder: (_) => const AvoidedItemsScreen());

      case avoidedShoes:
        return MaterialPageRoute(builder: (_) => const AvoidedShoesScreen());

      // case avoidedColors: // DISABLED
      //   return MaterialPageRoute(builder: (_) => const AvoidedColorsScreen());

      case avoidedPrints:
        return MaterialPageRoute(builder: (_) => const AvoidedPrintsScreen());

      // case budgetByItems: // REMOVED FROM FLOW
      //   return MaterialPageRoute(builder: (_) => const BudgetByItemsScreen());

      case partnerLogin:
        return MaterialPageRoute(builder: (_) => const PartnerLoginScreen());

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case notificationPreferences:
        return MaterialPageRoute(
          builder: (_) => const NotificationPreferencesScreen(),
        );

      case partnerMain:
        return MaterialPageRoute(builder: (_) => const PartnerMainScreen());

      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case chatDetail:
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(chatId: args, fromNotification: true),
          );
        }
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case main:
        final mainArgs = settings.arguments as Map<String, dynamic>?;
        // Default landing tab = Feed (Лента, index 0) — see Feed plan: it is the
        // first screen users see after registration/login to drive engagement.
        final initialIndex = mainArgs?['initialIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainScreen(initialIndex: initialIndex),
        );

      case orderDetail:
        final args = settings.arguments;
        if (args is String) {
          final isPartner = getIt<ApiClient>().isPartnerLogin();
          return MaterialPageRoute(
            builder: (_) =>
                OrderDetailScreen(orderId: args, isPartner: isPartner),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
