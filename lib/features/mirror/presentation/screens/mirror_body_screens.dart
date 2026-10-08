import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';

/// Шаг 01 станции — для кого образ (женщина / мужчина). Дизайн LIBAS 10.2026: две
/// высокие карточки с фото, круглый индикатор; касание карточки сразу ведёт дальше.
class MirrorGenderScreen extends StatelessWidget {
  const MirrorGenderScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);

    Widget card(String gender, String title) => MirrorStationCard(
          title: title,
          description: l10n.mirrorWardrobeDesc,
          photo: kioskGenderPhoto(gender),
          selected: controller.gender == gender,
          onTap: () => controller.setGender(gender),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(
            title: l10n.mirrorWardrobeTitle,
            subtitle: controller.menswearAvailable ? null : l10n.mirrorWomenOnly,
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorStationGrid(
              aspect: 464 / 852,
              children: [
                card('FEMALE', l10n.mirrorWardrobeWomen),
                // Мужской одежды в зале может не быть: без неё мужчина снял бы фото
                // и ждал генерацию ради пустого результата.
                if (controller.menswearAvailable) card('MALE', l10n.mirrorWardrobeMen),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          Center(
            child: Text(
              l10n.mirrorWardrobeFooter,
              style: t.subtitle(15 * s),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32 * s),
        ],
      ),
    );
  }
}

/// Шаг 02 — тип фигуры: четыре силуэта пола сеткой 2×2, один выбор;
/// «Не знаю свой тип фигуры» не угадывает фигуру, а честно отправляет «не знаю».
class MirrorShapeScreen extends StatelessWidget {
  const MirrorShapeScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = mirrorStationScale(context);
    final lang = controller.shopperLang;
    final gender = controller.gender ?? 'FEMALE';
    final shapes = kioskShapes[gender] ?? const <KioskLabeled>[];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(
            kicker: gender == 'MALE' ? l10n.mirrorWardrobeMen : l10n.mirrorWardrobeWomen,
            title: l10n.mirrorShapeTitleStation,
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorStationGrid(
              children: [
                for (final shape in shapes)
                  MirrorStationCard(
                    title: shape.label(lang),
                    description: kioskShapeDescriptions[shape.code]?.label(lang),
                    photo: kioskShapeFigure(gender, shape.code),
                    photoFit: BoxFit.contain,
                    selected: controller.bodyShape == shape.code,
                    onTap: () => controller.setShape(shape.code!),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          Center(
            child: MirrorGhostButton(
              label: l10n.mirrorShapeUnknown,
              height: 52 * s,
              onTap: controller.skipShape,
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorPrimaryButton(
            label: controller.path == MirrorPath.create ? l10n.mirrorContinue : l10n.mirrorCtaCreate,
            height: 64 * s,
            enabled: controller.gender != null &&
                controller.bodyShape != null &&
                controller.bodyShape != kioskShapeUnknown,
            onTap: controller.confirmProfile,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}
