/// API Configuration
/// Central place to manage API endpoints and environment settings

class ApiConfig {
  // Environment flag - Change this based on your testing environment
  static const Environment environment = Environment.production;

  // Development mode flags
  /// Set to true to skip OTP verification during testing
  /// When enabled, any 6-digit code will be accepted
  static const bool skipOtpInDev = false;

  /// Development OTP code that will always work when skipOtpInDev is true
  static const String devOtpCode = '123456';

  /// Get base URL based on current environment
  static String get baseUrl {
    switch (environment) {
      case Environment.iosSimulator:
        // iOS Simulator can access host machine via localhost
        return 'http://localhost:8000/api/v1';

      case Environment.androidEmulator:
        // Android Emulator uses special IP to access host machine
        return 'http://10.0.2.2:8000/api/v1';

      case Environment.physicalDevice:
        // Physical device on same network - use your Mac's IP
        // Find your IP: System Preferences → Network → WiFi → Advanced → TCP/IP
        return 'http://10.22.157.154:8000/api/v1';

      case Environment.production:
        // Production server URL - New deployment
        return 'https://app.svaypai.com/api/v1';
    }
  }

  /// API timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Environment types
enum Environment {
  /// iOS Simulator - use localhost
  iosSimulator,

  /// Android Emulator - use 10.0.2.2
  androidEmulator,

  /// Physical device on same WiFi network - use Mac's IP
  physicalDevice,

  /// Production server
  production,
}
