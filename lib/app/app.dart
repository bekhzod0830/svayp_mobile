import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/app/theme.dart';
import 'package:swipe/core/constants/app_constants.dart';
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

class SwipeAppState extends State<SwipeApp> {
  final LanguageService _languageService = LanguageService();
  final ThemeService _themeService = ThemeService();
  Locale _locale = const Locale('ru'); // Default to Russian
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
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
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'SVAYP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingDataManager()),
        ChangeNotifierProvider.value(value: _themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // Set system UI overlay style based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeService.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: themeService.isDarkMode
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              systemNavigationBarIconBrightness: themeService.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,

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

            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler:
                      TextScaler.noScaling, // Prevent system text scaling
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
