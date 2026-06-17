import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/app/theme.dart';
import 'package:swipe/core/analytics/analytics_navigator_observer.dart';
import 'package:swipe/core/constants/app_constants.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/core/services/theme_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/features/auth/data/services/telegram_auth_service.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Main App Widget
class SwipeApp extends StatefulWidget {
  const SwipeApp({super.key});

  @override
  State<SwipeApp> createState() => SwipeAppState();
}

class SwipeAppState extends State<SwipeApp>
    with SingleTickerProviderStateMixin {
  final LanguageService _languageService = LanguageService();
  final ThemeService _themeService = ThemeService();
  Locale _locale = const Locale('ru'); // Default to Russian
  bool _isInitialized = false;

  // Overlay animation for smooth theme transitions (avoids gray interpolation)
  late final AnimationController _themeOverlayController;
  Color _overlayColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _themeOverlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _themeService.addListener(_onThemeChanged);
    _initialize();
    _handleColdStartTelegramLink();
  }

  /// Cold-start safety net for Telegram OIDC: if the app was killed while the
  /// user was in the external browser/Telegram, the deep-link relaunch lands
  /// here. We read the persisted PKCE, exchange the code for tokens, and go to
  /// /main. (The warm path is handled by TelegramAuthService's stream listener.)
  Future<void> _handleColdStartTelegramLink() async {
    try {
      final uri = await AppLinks().getInitialLink();
      if (uri == null) return;

      final result =
          await TelegramAuthService.instance.completePendingFromUri(uri);
      if (result is! TelegramAuthSuccess) return;

      await getIt<AuthService>().telegramOidcLogin(
        code: result.code,
        codeVerifier: result.codeVerifier,
        redirectUri: result.redirectUri,
        nonce: result.nonce,
        phoneNumber: result.enteredPhone,
      );

      // Tokens are saved by telegramOidcLogin. Finish the session.
      final storage = await LocalStorageHelper.getInstance();
      await storage.clearGuestMode();
      NotificationService.instance.registerTokenWithBackend().ignore();

      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/main', (_) => false);
    } catch (e) {
      // Surface the error so blockers (503 config / 400 phone) are visible.
      final messenger = navigatorKey.currentState != null
          ? ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
          : null;
      messenger?.showSnackBar(
        SnackBar(content: Text('Telegram: $e')),
      );
    }
  }

  void _onThemeChanged() {
    // Destination bg covers the instant snap, then fades away revealing new theme
    setState(() {
      _overlayColor = _themeService.isDarkMode ? Colors.black : Colors.white;
    });
    _themeOverlayController.value = 1.0;
    _themeOverlayController.animateTo(0.0, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _themeOverlayController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.wait([_loadLanguage(), _themeService.init()]);
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadLanguage() async {
    final locale = await _languageService.getCurrentLanguage();
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }

  /// Public method to change language from anywhere in the app
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      final bg = _themeService.isDarkMode
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: bg, body: const SizedBox.shrink()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingDataManager()),
        ChangeNotifierProvider.value(value: _themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            // Instant switch — our custom fade overlay handles the visual transition
            themeAnimationDuration: Duration.zero,

            // Localization
            locale: _locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ru'), // Russian
              Locale('uz'), // Uzbek
            ],

            navigatorKey: navigatorKey,
            navigatorObservers: [AnalyticsNavigatorObserver()],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              final isDark = brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler:
                        TextScaler.noScaling, // Prevent system text scaling
                  ),
                  // Overlay is inside MaterialApp so Directionality is available
                  child: Stack(
                    children: [
                      child!,
                      // Fade overlay — covers instant theme snap, fades out revealing new theme
                      AnimatedBuilder(
                        animation: _themeOverlayController,
                        builder: (context, _) {
                          if (_themeOverlayController.value == 0) {
                            return const SizedBox.shrink();
                          }
                          return IgnorePointer(
                            child: Opacity(
                              opacity: _themeOverlayController.value,
                              child: Container(color: _overlayColor),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
