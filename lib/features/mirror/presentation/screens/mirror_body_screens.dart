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

/// Шаг 02 — тип фигуры: четыре силуэта пола сеткой 2×2, касание сразу ведёт дальше;
/// «Не знаю свой тип фигуры» не угадывает фигуру, а честно отправляет «не знаю».
class MirrorShapeScreen extends StatelessWidget {
  const MirrorShapeScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
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
            // Карточки выше обычных: иллюстрации — человек в полный рост (2:3),
            // в приземистой карточке он выходил мелким. Сетка сама ужмёт их
            // по высоте, если места меньше.
            child: MirrorStationGrid(
              aspect: 0.6,
              children: [
                for (final shape in shapes)
                  MirrorStationCard(
                    title: shape.label(lang),
                    description: kioskShapeDescriptions[shape.code]?.label(lang),
                    picture: _ShapeFigure(
                      asset: kioskShapeFigure(gender, shape.code),
                      dark: t.dark,
                    ),
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
          SizedBox(height: 32 * s),
        ],
      ),
    );
  }
}

/// Иллюстрация фигуры в карточке (комплект LIBAS, 10.2026): человек целиком,
/// от макушки до стоп — по `contain`, без обрезки, на мягком градиенте макета
/// (светлый или графитовый по теме). Иллюстрации на прозрачном фоне, одни и те
/// же для обеих тем.
class _ShapeFigure extends StatelessWidget {
  const _ShapeFigure({required this.asset, required this.dark});

  final String? asset;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = mirrorStationScale(context);
    final asset = this.asset;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF292C31), Color(0xFF202226)]
              : const [Color(0xFFF7F6F2), Color(0xFFEDECE7)],
        ),
      ),
      child: asset == null
          ? const SizedBox.expand()
          : Padding(
              padding: EdgeInsets.fromLTRB(8 * s, 10 * s, 8 * s, 6 * s),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
            ),
    );
  }
}
