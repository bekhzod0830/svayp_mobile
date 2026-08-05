import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_theme.dart';
import 'mirror_buttons.dart';

/// «Вы ещё здесь?» — предупреждение перед сбросом по бездействию.
/// Касание в любом месте равнозначно «Я здесь».
class MirrorIdleWarning extends StatelessWidget {
  const MirrorIdleWarning({
    super.key,
    required this.secondsLeft,
    required this.onStay,
  });

  final int secondsLeft;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStay,
      child: ColoredBox(
        color: MirrorTheme.ink.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32 * s),
            padding: EdgeInsets.all(32 * s),
            constraints: BoxConstraints(maxWidth: 420 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32 * s),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mirrorStillHere,
                  textAlign: TextAlign.center,
                  style: MirrorTheme.headline(28 * s),
                ),
                SizedBox(height: 12 * s),
                Text(
                  l10n.mirrorStillHereHint(secondsLeft),
                  textAlign: TextAlign.center,
                  style: MirrorTheme.subtitle(15 * s),
                ),
                SizedBox(height: 24 * s),
                MirrorPrimaryButton(
                  label: l10n.mirrorImHere,
                  height: 56 * s,
                  onTap: onStay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
