import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_theme.dart';

/// Оффлайн-оверлей: не белый экран и не ошибка браузера, а вежливое
/// «позовите продавца» (ТЗ, раздел 2). Снимается сам при появлении сети.
class MirrorOfflineScreen extends StatelessWidget {
  const MirrorOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56 * s,
                color: MirrorTheme.gray,
              ),
              SizedBox(height: 24 * s),
              Text(
                l10n.mirrorOfflineTitle,
                textAlign: TextAlign.center,
                style: MirrorTheme.headline(36 * s),
              ),
              SizedBox(height: 12 * s),
              Text(
                l10n.mirrorOfflineHint,
                textAlign: TextAlign.center,
                style: MirrorTheme.subtitle(17 * s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
