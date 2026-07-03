import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/app/theme.dart';
import 'package:swipe/core/analytics/analytics_navigator_observer.dart';
import 'package:swipe/core/constants/app_constants.dart';
import 'package:swipe/core/analytics/analytics_navigator_observer.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/analytics/session_manager.dart';
import 'package:swipe/core/constants/app_constants.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/services/theme_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Main App Widget
class SwipeApp extends StatefulWidget {
  const SwipeApp({super.key});

  @override
  State<SwipeApp> createState() => SwipeAppState();
}

class SwipeAppState extends State<SwipeApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final LanguageService _languageService = LanguageService();
  final ThemeService _themeService = ThemeService();
  // Seed with the device locale (Uzbek fallback); replaced by any saved choice
  // once [_loadLanguage] completes.
  Locale _locale = Locale(LanguageService.resolveDeviceLanguageCode());
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
    WidgetsBinding.instance.addObserver(this);
    // First launch of this process — start a session and record the app open.
    AnalyticsService.instance.logSessionStart();
    AnalyticsService.instance.logAppOpen();
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // New session only if the app was idle past the session timeout.
        if (SessionManager.instance.isExpired) {
          AnalyticsService.instance.logSessionStart();
        }
        AnalyticsService.instance.logAppOpen();
        break;
      case AppLifecycleState.paused:
        AnalyticsService.instance.logSessionEnd();
        AnalyticsService.instance.flush();
        break;
      default:
        break;
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
    WidgetsBinding.instance.removeObserver(this);
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
