import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/constants/app_constants.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_buttons.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_dots.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_calendar.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_closet.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_coins.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_gift.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_market.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_shop.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_tryon.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/scenes/scene_wardrobe_funnel.dart';

/// Pre-auth marketing onboarding: a 7-slide animated carousel introducing the
/// product (closet, boards, try-on, calendar, market, coins, signup gift).
/// Shown once per install before phone auth; "Начать" (or Skip → last slide →
/// Начать) marks it seen and replaces itself with /phone-auth.
///
/// Deliberately forced-light — it's brand marketing, identical in dark mode.
class IntroOnboardingScreen extends StatefulWidget {
  const IntroOnboardingScreen({super.key});

  static const int slideCount = 8;

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  final PageController _controller = PageController();
  final LanguageService _languageService = LanguageService();
  // Shared between the try-on stage image and its toggle (below the text).
  // 0 = mannequin, 1 = own photo, 2 = own photo (covered).
  final ValueNotifier<int> _tryOnMode = ValueNotifier(0);
  // Fired once when the user reaches the final gift slide.
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  int _index = 0;
  int _giftCoins = AppConstants.defaultSignupGiftCoins;

  bool get _isLast => _index == IntroOnboardingScreen.slideCount - 1;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent(AnalyticsEvents.introViewed);
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.introSlideViewed,
      parameters: {'slide': '1'},
    );
    _loadGiftCoins();
  }

  Future<void> _loadGiftCoins() async {
    final storage = await LocalStorageHelper.getInstance();
    if (!mounted) return;
    setState(() => _giftCoins = storage.getSignupGiftCoins());
  }

  @override
  void dispose() {
    _controller.dispose();
    _tryOnMode.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 550),
      curve: const Cubic(0.7, 0, 0.2, 1),
    );
  }

  void _onPageChanged(int page) {
    setState(() => _index = page);
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.introSlideViewed,
      parameters: {'slide': '${page + 1}'},
    );
    // Celebrate when the gift slide comes into view.
    if (_isLast) _confetti.play();
  }

  Future<void> _finish() async {
    AnalyticsService.instance.logEvent(AnalyticsEvents.introCompleted);
    final storage = await LocalStorageHelper.getInstance();
    await storage.setSeenIntro(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/phone-auth');
  }

  /// Bottom sheet to change the app language from the first slide. The default
  /// is already the device/system language (Uzbek fallback) — this just lets
  /// the user override it before signing up.
  Future<void> _showLanguageSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: IntroPalette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: IntroPalette.dotInactive,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.selectLanguage,
                  style: IntroPalette.headline(size: 20),
                ),
              ),
              for (final lang in LanguageService.availableLanguages)
                _LanguageTile(
                  nativeName: lang['nativeName']!,
                  selected: lang['code'] == current,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _changeLanguage(lang['code']!);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String code) async {
    await _languageService.saveLanguage(code);
    if (!mounted) return;
    context.findAncestorStateOfType<SwipeAppState>()?.setLocale(Locale(code));
  }

  IntroSlide _buildSlide(BuildContext context, int i) {
    final l10n = AppLocalizations.of(context)!;
    final active = i == _index;
    switch (i) {
      case 0:
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stagePink,
          kicker: AppConstants.appName, // brand mark, not translated
          title: l10n.introSlide1Title,
          subtitle: l10n.introSlide1Subtitle,
          titleSize: 33,
          stageBuilder: (context, entrance) =>
              IntroSceneCloset(entrance: entrance, coins: _giftCoins),
        );
      case 1:
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stagePinkDeep,
          kicker: l10n.introSlide2Kicker,
          title: l10n.introSlide2Title,
          subtitle: l10n.introSlide2Subtitle,
          subtitleSize: 15,
          stageBuilder: (context, entrance) =>
              IntroSceneWardrobeFunnel(entrance: entrance),
        );
      case 2:
        return IntroSlide(
          active: active,
          // Slightly shorter stage: this slide uniquely carries the toggle
          // above the text, so it needs a little more room for the copy.
          stageFlex: 53,
          stageGradient: IntroPalette.stageNeutral,
          kicker: l10n.introSlide3Kicker,
          title: l10n.introSlide3Title,
          subtitle: l10n.introSlide3Subtitle,
          titleSize: 27,
          subtitleSize: 14,
          stageBuilder: (context, entrance) => IntroSceneTryOn(
            entrance: entrance,
            mode: _tryOnMode,
            active: active,
          ),
          aboveTextBuilder: (context, entrance) =>
              IntroTryOnToggle(entrance: entrance, mode: _tryOnMode),
        );
      case 3:
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stageNeutral,
          kicker: l10n.introSlide4Kicker,
          title: l10n.introSlide4Title,
          subtitle: l10n.introSlide4Subtitle,
          stageBuilder: (context, entrance) =>
              IntroSceneCalendar(entrance: entrance),
        );
      case 4:
        // Shop — B2B brand catalog, swipe deck (matches the Discover feed).
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stageNeutral,
          kicker: l10n.introShopKicker,
          title: l10n.introShopTitle,
          subtitle: l10n.introShopSubtitle,
          subtitleSize: 15,
          stageBuilder: (context, entrance) =>
              IntroSceneShop(entrance: entrance),
        );
      case 5:
        // Market — C2C second-hand, scrolling feed.
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stagePinkDeep,
          kicker: l10n.introSlide5Kicker,
          title: l10n.introSlide5Title,
          subtitle: l10n.introSlide5Subtitle,
          stageBuilder: (context, entrance) =>
              IntroSceneMarket(entrance: entrance),
        );
      case 6:
        // Diamonds explainer. Full-height stage like every other slide; the
        // paragraph itself reassures that adding clothes is free, so no extra
        // price card is needed.
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stageGem,
          kicker: l10n.introSlide6Kicker,
          title: l10n.introSlide6Title,
          subtitle: l10n.introSlide6Subtitle,
          subtitleHighlight: l10n.introSlide6FreeHighlight,
          titleSize: 27,
          subtitleSize: 14,
          stageBuilder: (context, entrance) =>
              IntroSceneCoins(entrance: entrance),
        );
      default:
        return IntroSlide(
          active: active,
          stageGradient: IntroPalette.stageGemWarm,
          kicker: l10n.introSlide7Kicker,
          title: l10n.introSlide7Title(_giftCoins),
          subtitle: l10n.introSlide7Subtitle(_giftCoins),
          subtitleSize: 15,
          centerText: true,
          stageBuilder: (context, entrance) =>
              IntroSceneGift(entrance: entrance, coins: _giftCoins),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang =
        Localizations.localeOf(context).languageCode.toUpperCase();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Forced-light page → dark status-bar icons even in dark mode.
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          // System back steps one slide back instead of leaving the app.
          if (!didPop) _goTo(_index - 1);
        },
        child: Scaffold(
          backgroundColor: IntroPalette.bg,
          body: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: IntroOnboardingScreen.slideCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => TickerMode(
                  // Mute ambient loop tickers on off-screen slides.
                  enabled: i == _index,
                  child: _buildSlide(context, i),
                ),
              ),

              // ── Top overlay: back / language + skip ─────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Slide 1 shows a language chooser where the back button
                      // would otherwise be; later slides show back.
                      if (_index == 0)
                        IntroFrostedButton(
                          visible: true,
                          onTap: _showLanguageSheet,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  size: 17,
                                  color: IntroPalette.ink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentLang,
                                  style: IntroPalette.label(
                                    size: 13,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        IntroFrostedButton(
                          visible: true,
                          onTap: () => _goTo(_index - 1),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: IntroPalette.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Bottom overlay: white fade + dots + CTA ─────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.70, 0.88, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntroDots(
                            count: IntroOnboardingScreen.slideCount,
                            index: _index,
                            onTap: _goTo,
                          ),
                          const SizedBox(height: 18),
                          IntroPrimaryButton(
                            label: _isLast ? l10n.introStart : l10n.introNext,
                            onTap: _isLast ? _finish : () => _goTo(_index + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Confetti boom on the final gift slide, blasting downward from
              // the top of the screen (brand gem + pink).
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi / 2, // down
                  maxBlastForce: 6,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 22,
                  gravity: 0.28,
                  shouldLoop: false,
                  colors: const [
                    IntroPalette.gem,
                    IntroPalette.pink,
                    IntroPalette.gemLight,
                    IntroPalette.pinkLight,
                    Colors.white,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the language bottom sheet.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.nativeName,
    required this.selected,
    required this.onTap,
  });

  final String nativeName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? IntroPalette.chipBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? IntroPalette.pink : IntroPalette.dotInactive,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  nativeName,
                  style: IntroPalette.label(
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: IntroPalette.pink,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
