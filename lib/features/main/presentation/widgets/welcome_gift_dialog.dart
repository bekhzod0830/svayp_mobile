import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_buttons.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Full-screen "Xush kelibsiz!" gift screen shown once right after
/// registration, with a confetti boom. Pushed as an **opaque** route so the
/// (heavy) Closet WebView underneath stops painting — otherwise the confetti
/// janks badly while the WebView composites every frame.
Future<void> showWelcomeGiftDialog(
  BuildContext context, {
  required int coins,
}) {
  AnalyticsService.instance.logEvent(AnalyticsEvents.welcomeGiftPopupViewed);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _WelcomeGiftScreen(coins: coins),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final t = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(t),
            child: child,
          ),
        );
      },
    ),
  );
}

class _WelcomeGiftScreen extends StatefulWidget {
  const _WelcomeGiftScreen({required this.coins});

  final int coins;

  @override
  State<_WelcomeGiftScreen> createState() => _WelcomeGiftScreenState();
}

class _WelcomeGiftScreenState extends State<_WelcomeGiftScreen> {
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: IntroPalette.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Centered hero: diamond + welcome message.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Floaty(
                          child: IntroDiamond(size: 96, withGleam: true),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          l10n.welcomeGiftTitle,
                          textAlign: TextAlign.center,
                          style: IntroPalette.headline(size: 27),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            l10n.welcomeGiftSubtitle(widget.coins),
                            textAlign: TextAlign.center,
                            style: IntroPalette.subtitle(size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // CTA pinned to the bottom (matches the onboarding layout).
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: IntroPrimaryButton(
                    label: l10n.welcomeGiftCta,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          // Confetti boom from the top.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2, // down
              maxBlastForce: 6,
              minBlastForce: 2,
              emissionFrequency: 0.04,
              numberOfParticles: 16,
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
    );
  }
}
