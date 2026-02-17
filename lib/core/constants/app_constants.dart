/// App Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Swipe';
  static const String appTagline = 'Discover Your Style';

  // API Configuration
  static const String baseUrl =
      'https://swipee.azurewebsites.net'; // Azure production backend
  static const String apiVersion = 'v1';
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String isOnboardedKey = 'is_onboarded';
  static const String userProfileKey = 'user_profile';
  static const String themeKey = 'theme_mode';

  // Onboarding
  static const int styleQuizItemCount = 20;
  static const int minimumAge = 13;
  static const int maximumAge = 100;

  // Swipe Configuration
  static const double swipeThresholdHorizontal = 100.0; // pixels
  static const double swipeThresholdVertical = 150.0; // pixels for super like
  static const int cardsPerLoad = 10;
  static const int prefetchCardCount = 5;

  // Animation Durations (milliseconds)
  static const int splashDuration = 2000;
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Pagination
  static const int pageSize = 20;
  static const int initialLoadSize = 10;

  // Cache
  static const int imageCacheDays = 7;
  static const int dataCacheHours = 24;

  // Uzbekistan Specific
  static const String defaultCountryCode = '+998';
  static const String defaultCurrency = 'UZS';
  static const double usdToUzsRate = 12500.0; // Approximate rate

  // Size Ranges
  static const List<String> shirtSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const int minPantsSize = 26;
  static const int maxPantsSize = 44;
  static const int minDressSize = 36;
  static const int maxDressSize = 52;
  static const int minShoeSize = 35;
  static const int maxShoeSize = 48;
  static const int minHeight = 140;
  static const int maxHeight = 210;
  static const int minWeight = 40;
  static const int maxWeight = 150;

  // Budget Ranges (in UZS)
  static const int budgetMin = 50000;
  static const int budgetMax = 300000;
  static const int midRangeMin = 300000;
  static const int midRangeMax = 1000000;
  static const int premiumMin = 1000000;
  static const int premiumMax = 5000000;

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Something went wrong. Please try again';
  static const String timeoutError = 'Request timeout. Please try again';
  static const String unknownError = 'An unexpected error occurred';

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int otpLength = 4;
  static const int otpResendSeconds = 60;
}
