import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_choice.dart';
import '../widgets/mirror_style_figure.dart';

/// Экран 3 — выбор стиля (только ветка «создать»): карточки из справочника
/// бренда (скрытые стили не показываем, подписи — брендовые) с
/// иллюстрацией образа, мультивыбор, минимум одна. Карточки — той же
/// сетки и размера, что на экранах пола и фигуры.
class MirrorStyleScreen extends StatelessWidget {
  const MirrorStyleScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final lang = controller.shopperLang;
    final brand = t.brand;
    // Стили бренда, но только подходящие полу покупателя.
    final styles = brand.stylesFor(controller.gender);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(
              l10n.mirrorStyleTitle,
              style: t.headline(36 * s),
            ),
          ),
          SizedBox(height: 8 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorStyleSubtitle,
              style: t.subtitle(16 * s),
            ),
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorChoiceGrid(
              children: [
                for (var i = 0; i < styles.length; i++)
                  MirrorChoiceCard(
                    label: brand.styleLabel(styles[i], lang),
                    // Раскладка вещей стиля рисуется кодом, как мужские
                    // силуэты фигуры.
                    figure: MirrorStyleFigure.supports(
                      styles[i].code,
                      controller.gender,
                    )
                        ? MirrorStyleFigure(
                            style: styles[i].code!,
                            gender: controller.gender,
                          )
                        : null,
                    selected: controller.styles.contains(styles[i].code),
                    fadeInDelayMs: 120 + 50 * i,
                    onTap: () => controller.toggleStyle(styles[i].code!),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16 * s),
          MirrorPrimaryButton(
            label: l10n.mirrorCtaCreate,
            height: 64 * s,
            enabled: controller.styles.isNotEmpty,
            onTap: controller.confirmStyles,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}
