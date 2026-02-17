import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:swipe/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:swipe/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/basic_info_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/hijab_preference_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/primary_objective_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/fit_preference_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/modesty_level_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/size_profile_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/body_type_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/sizes_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/budget_preference_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/style_quiz_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/tutorial_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/avoided_items_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/avoided_shoes_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/avoided_colors_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/avoided_prints_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/budget_by_items_screen.dart';
import 'package:swipe/features/onboarding/presentation/screens/style_categories_screen.dart';
// import 'package:swipe/features/onboarding/presentation/screens/occasions_screen.dart'; // DISABLED
// import 'package:swipe/features/onboarding/presentation/screens/brand_preferences_screen.dart'; // DISABLED
import 'package:swipe/features/onboarding/presentation/screens/onboarding_completion_screen.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';

/// App Routes
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String phoneAuth = '/phone-auth';
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

  /// Generate routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case phoneAuth:
        return MaterialPageRoute(builder: (_) => const PhoneAuthScreen());

      case otpVerification:
        final phoneNumber = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(phoneNumber: phoneNumber),
        );

      case basicInfo:
        return MaterialPageRoute(builder: (_) => const BasicInfoScreen());

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

      case bodyType:
        return MaterialPageRoute(
          builder: (_) => const BodyTypeScreen(),
          settings: settings,
        );

      case sizes:
        return MaterialPageRoute(
          builder: (_) => const SizesScreen(),
          settings: settings,
        );

      case budgetPreference:
        return MaterialPageRoute(
          builder: (_) => const BudgetPreferenceScreen(),
        );

      case styleQuiz:
        return MaterialPageRoute(
          builder: (_) => const StyleQuizScreen(),
          settings: settings,
        );

      case styleCategories:
        return MaterialPageRoute(builder: (_) => const StyleCategoriesScreen());

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

      case budgetByItems:
        return MaterialPageRoute(builder: (_) => const BudgetByItemsScreen());

      case main:
        return MaterialPageRoute(builder: (_) => MainScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
