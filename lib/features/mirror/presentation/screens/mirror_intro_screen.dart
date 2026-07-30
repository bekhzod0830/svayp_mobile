import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

/// Экран 1 — «Как это работает» (только ветка «создать»): три шага,
/// обещание приватности, «Начать».
class MirrorIntroScreen extends StatelessWidget {
  const MirrorIntroScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);

    final steps = [
      (l10n.mirrorStep1Title, l10n.mirrorStep1Text),
      (l10n.mirrorStep2Title, l10n.mirrorStep2Text),
      (l10n.mirrorStep3Title, l10n.mirrorStep3Text),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Контент скроллится: на планшете/зеркале всё помещается, но на
          // низких экранах колонка не должна переполняться.
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(
              l10n.mirrorIntroEyebrow.toUpperCase(),
              style: MirrorTheme.kicker(s),
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorIntroTitle,
              style: MirrorTheme.headline(38 * s),
            ),
          ),
          SizedBox(height: 26 * s),
          for (var i = 0; i < steps.length; i++)
            MirrorFadeIn(
              delayMs: 140 + i * 90,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20 * s),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: MirrorTheme.hairline),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52 * s,
                      height: 52 * s,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MirrorTheme.selectedBg,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: MirrorTheme.label(
                          20 * s,
                          color: MirrorTheme.pink,
                        ),
                      ),
                    ),
                    SizedBox(width: 18 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: MirrorTheme.label(18 * s),
                          ),
                          SizedBox(height: 5 * s),
                          Text(
                            steps[i].$2,
                            style: MirrorTheme.subtitle(14 * s),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 24 * s),
          MirrorFadeIn(
            delayMs: 430,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18 * s),
              decoration: BoxDecoration(
                color: MirrorTheme.selectedBg,
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: IntroPalette.gemChipBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20 * s,
                    color: IntroPalette.gemText,
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Text(
                      l10n.mirrorPrivacyLong,
                      style: MirrorTheme.subtitle(
                        13.5 * s,
                        color: IntroPalette.gemText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
                  SizedBox(height: 16 * s),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * s),
          MirrorPrimaryButton(
            label: l10n.mirrorIntroCta,
            height: 64 * s,
            onTap: controller.proceedToCamera,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}
