import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/app/theme.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/kiosk_api.dart';
import '../data/kiosk_demo.dart';
import 'mirror_session_controller.dart';
import 'mirror_theme.dart';
import 'screens/mirror_body_screens.dart';
import 'screens/mirror_camera_screen.dart';
import 'screens/mirror_catalog_screen.dart';
import 'screens/mirror_generating_screen.dart';
import 'screens/mirror_idle_screen.dart';
import 'screens/mirror_intro_screen.dart';
import 'screens/mirror_result_screen.dart';
import 'screens/mirror_style_screen.dart';
import 'widgets/mirror_chrome.dart';
import 'widgets/mirror_idle_warning.dart';
import 'widgets/mirror_offline_screen.dart';
import 'widgets/mirror_setup_sheet.dart';

/// Корень вкладки «Зеркало» в партнёрском шелле (таб 0).
///
/// Без внутреннего Navigator'а: экраны переключает AnimatedSwitcher по
/// controller.screen — hardReset физически не может оставить «застрявших»
/// роутов. Пока таб активен, экран не гаснет (wakelock) и горит на максимум;
/// при уходе с таба обе блокировки снимаются, а сессия покупателя живёт.
class MirrorTab extends StatefulWidget {
  const MirrorTab({
    super.key,
    required this.isActive,
    this.onFullscreenChanged,
  });

  final bool isActive;

  /// Шелл прячет нижнюю навигацию, когда киоск в полноэкранном режиме.
  final ValueChanged<bool>? onFullscreenChanged;

  @override
  State<MirrorTab> createState() => _MirrorTabState();
}

class _MirrorTabState extends State<MirrorTab> with WidgetsBindingObserver {
  /// Полноэкранный режим переживает перезапуск: планшет в зале должен
  /// вернуться в киоск сам, без продавца.
  static const _fullscreenPref = 'kiosk_fullscreen';

  late final MirrorSessionController _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  double? _originalBrightness;
  bool _brightnessChanged = false;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MirrorSessionController(
      api: getIt<KioskApi>(),
      demo: getIt<KioskDemoService>(),
      prefs: getIt<SharedPreferences>(),
    );
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    if (widget.isActive) _enterKioskMode();
    if (getIt<SharedPreferences>().getBool(_fullscreenPref) ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setFullscreen(true);
      });
    }
  }

  void _setFullscreen(bool value) {
    if (_fullscreen == value) return;
    setState(() => _fullscreen = value);
    getIt<SharedPreferences>().setBool(_fullscreenPref, value);
    widget.onFullscreenChanged?.call(value);
    if (value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void didUpdateWidget(covariant MirrorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      widget.isActive ? _enterKioskMode() : _exitKioskMode();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.resumed) {
      _enterKioskMode();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _exitKioskMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _exitKioskMode();
    _controller.dispose();
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    _controller.setOffline(offline);
  }

  Future<void> _enterKioskMode() async {
    _controller.setActive(true);
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    try {
      final brightness = ScreenBrightness();
      _originalBrightness ??= await brightness.current;
      await brightness.setScreenBrightness(1.0);
      _brightnessChanged = true;
    } catch (_) {/* яркость недоступна — не мешаем работе */}
  }

  Future<void> _exitKioskMode() async {
    _controller.setActive(false);
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    if (_brightnessChanged && _originalBrightness != null) {
      try {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } catch (_) {}
      _brightnessChanged = false;
      _originalBrightness = null;
    }
  }

  void _openSetup() {
    MirrorSetupSheet.show(
      context,
      api: getIt<KioskApi>(),
      demo: getIt<KioskDemoService>(),
      fullscreen: _fullscreen,
      onFullscreenChanged: _setFullscreen,
    );
  }

  Widget _buildScreen() {
    switch (_controller.screen) {
      case MirrorScreen.idle:
        return MirrorIdleScreen(
          key: const ValueKey('idle'),
          controller: _controller,
          onOpenSetup: _openSetup,
          active: widget.isActive,
          fullscreen: _fullscreen,
          onEnterFullscreen: () => _setFullscreen(true),
        );
      case MirrorScreen.intro:
        return MirrorIntroScreen(
          key: const ValueKey('intro'),
          controller: _controller,
        );
      case MirrorScreen.camera:
        return MirrorCameraScreen(
          key: const ValueKey('camera'),
          controller: _controller,
          cameraAllowed: widget.isActive,
        );
      case MirrorScreen.gender:
        return MirrorGenderScreen(
          key: const ValueKey('gender'),
          controller: _controller,
        );
      case MirrorScreen.shape:
        return MirrorShapeScreen(
          key: const ValueKey('shape'),
          controller: _controller,
        );
      case MirrorScreen.style:
        return MirrorStyleScreen(
          key: const ValueKey('style'),
          controller: _controller,
        );
      case MirrorScreen.catalog:
        return MirrorCatalogScreen(
          key: const ValueKey('catalog'),
          controller: _controller,
        );
      case MirrorScreen.generating:
        return MirrorGeneratingScreen(
          key: const ValueKey('generating'),
          controller: _controller,
        );
      case MirrorScreen.result:
        return MirrorResultScreen(
          key: const ValueKey('result'),
          controller: _controller,
        );
      case MirrorScreen.buy:
        return MirrorBuyScreen(
          key: const ValueKey('buy'),
          controller: _controller,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Киоск всегда светлый: тёмная тема приложения продавца сюда не протекает.
    return Theme(
      data: AppTheme.lightTheme,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          // Язык покупателя локален для поддерева киоска.
          return Localizations.override(
            context: context,
            locale: Locale(_controller.shopperLang),
            child: Builder(
              builder: (context) {
                final screen = _controller.screen;
                final isIdle = screen == MirrorScreen.idle;
                final showChrome = !isIdle;

                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _controller.touch(),
                  child: ColoredBox(
                    color: isIdle ? MirrorTheme.ink : Colors.white,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: [
                              if (showChrome)
                                SafeArea(
                                  bottom: false,
                                  child: Column(
                                    children: [
                                      MirrorTopBar(
                                        onBack: _controller.goBack,
                                        langCode:
                                            screen == MirrorScreen.intro
                                                ? _controller.shopperLang
                                                : null,
                                        onLangChanged:
                                            _controller.setShopperLang,
                                      ),
                                      MirrorSteps(
                                        current: _controller.stepIndex,
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.015),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                  child: _buildScreen(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_controller.demoActive && !isIdle)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _DemoBadge(),
                          ),
                        if (_controller.idleWarning)
                          Positioned.fill(
                            child: MirrorIdleWarning(
                              secondsLeft: _controller.idleLeft,
                              onStay: _controller.touch,
                            ),
                          ),
                        if (_controller.offline)
                          const Positioned.fill(child: MirrorOfflineScreen()),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Бейдж честности: имитацию нельзя выдавать за работающую примерку.
class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      child: Container(
        color: MirrorTheme.ink.withValues(alpha: 0.85),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 2,
          bottom: 4,
        ),
        child: Text(
          l10n.mirrorDemoBadge,
          textAlign: TextAlign.center,
          style: MirrorTheme.label(
            11,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
