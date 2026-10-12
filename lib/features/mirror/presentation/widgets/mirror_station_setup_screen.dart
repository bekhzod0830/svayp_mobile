import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_theme.dart';
import 'mirror_buttons.dart';
import 'mirror_chrome.dart';

/// Оверлей «станция не настроена»: оформление магазина без принятого ключа
/// станции. Без него киоск молча работал бы по каталогу всех магазинов под
/// вывеской этого — поэтому закрываем его целиком, пока продавец не введёт
/// ключ. Снимается сам, как только бэкенд подтвердит привязку к магазину.
class MirrorStationSetupScreen extends StatelessWidget {
  const MirrorStationSetupScreen({
    super.key,
    required this.keyRejected,
    required this.onOpenSetup,
  });

  /// Ключ введён, но бэкенд его не принял (false — ключа нет вовсе).
  final bool keyRejected;
  final VoidCallback onOpenSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return ColoredBox(
      color: t.bg,
      child: Center(
        // Низкий экран (планшет на боку): текст длинный — даём прокрутку, а не
        // обрезаем кнопку.
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 40 * s, vertical: 24 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MirrorBrandMark(height: 22 * s),
              SizedBox(height: 40 * s),
              Icon(Icons.key_rounded, size: 56 * s, color: t.muted),
              SizedBox(height: 24 * s),
              Text(
                l10n.mirrorStationSetupTitle,
                textAlign: TextAlign.center,
                style: t.headline(36 * s),
              ),
              SizedBox(height: 12 * s),
              Text(
                keyRejected
                    ? l10n.mirrorStationSetupRejected
                    : l10n.mirrorStationSetupNoKey,
                textAlign: TextAlign.center,
                style: t.subtitle(17 * s),
              ),
              SizedBox(height: 32 * s),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360 * s),
                child: MirrorPrimaryButton(
                  label: l10n.mirrorStationSetupAction,
                  height: 56 * s,
                  onTap: onOpenSetup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
