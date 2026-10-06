import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_body_figure.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_choice.dart';
import '../widgets/mirror_style_figure.dart';

/// Экран 2а — пол. Отдельная страница (решение владельца): две карточки
/// той же сетки, что фигура и стиль; касание сразу ведёт к выбору фигуры.
class MirrorGenderScreen extends StatelessWidget {
  const MirrorGenderScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(
              t.kickerCase(l10n.mirrorGenderLabel),
              style: t.kicker(s),
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(l10n.mirrorBodyTitle, style: t.headline(36 * s)),
          ),
          SizedBox(height: 8 * s),
          MirrorFadeIn(
            delayMs: 110,
            child: Text(
              controller.menswearAvailable
                  ? l10n.mirrorBodySubtitle
                  : l10n.mirrorWomenOnly,
              style: t.subtitle(16 * s),
            ),
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorChoiceGrid(
              alignment: WrapAlignment.center,
              children: [
                MirrorChoiceCard(
                  label: l10n.mirrorFemale,
                  figure: const MirrorGenderFigure(gender: 'FEMALE'),
                  selected: controller.gender == 'FEMALE',
                  fadeInDelayMs: 180,
                  onTap: () => controller.setGender('FEMALE'),
                ),
                // Мужская одежда в зале есть не всегда: без неё мужчина
                // снял бы фото и ждал генерацию ради пустого результата.
                if (controller.menswearAvailable)
                  MirrorChoiceCard(
                    label: l10n.mirrorMale,
                    figure: const MirrorGenderFigure(gender: 'MALE'),
                    selected: controller.gender == 'MALE',
                    fadeInDelayMs: 250,
                    onTap: () => controller.setGender('MALE'),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

/// Экран 2б — тип фигуры. Список зависит от пола; варианта «не знаю» нет.
class MirrorShapeScreen extends StatelessWidget {
  const MirrorShapeScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final lang = controller.shopperLang;
    final gender = controller.gender ?? 'FEMALE';
    final shapes = kioskShapes[gender] ?? const <KioskLabeled>[];
    final isFemale = gender == 'FEMALE';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(t.kickerCase(l10n.mirrorBodyTitle), style: t.kicker(s)),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(l10n.mirrorShapeLabel, style: t.headline(36 * s)),
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorChoiceGrid(
              children: [
                for (var i = 0; i < shapes.length; i++)
                  MirrorChoiceCard(
                    label: shapes[i].label(lang),
                    asset: isFemale
                        ? kioskFemaleShapeAssets[shapes[i].code]
                        : null,
                    // Мужские силуэты рисуются кодом: готовых картинок нет.
                    figure: !isFemale &&
                            MirrorMaleBodyFigure.supports(shapes[i].code)
                        ? MirrorMaleBodyFigure(shape: shapes[i].code!)
                        : null,
                    glyph: Icons.accessibility_new_rounded,
                    selected: controller.bodyShape == shapes[i].code,
                    fadeInDelayMs: 120 + 50 * i,
                    onTap: () => controller.setShape(shapes[i].code!),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16 * s),
          MirrorPrimaryButton(
            label: controller.path == MirrorPath.create
                ? l10n.mirrorNext
                : l10n.mirrorCtaCreate,
            height: 64 * s,
            enabled: controller.gender != null && controller.bodyShape != null,
            onTap: controller.confirmProfile,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}
