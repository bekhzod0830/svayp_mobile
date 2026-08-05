import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

/// Экран 3а — пол. Отдельная страница (решение владельца): две крупные
/// карточки, касание сразу ведёт к выбору фигуры.
class MirrorGenderScreen extends StatelessWidget {
  const MirrorGenderScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(
              l10n.mirrorGenderLabel.toUpperCase(),
              style: MirrorTheme.kicker(s),
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorBodyTitle,
              style: MirrorTheme.headline(38 * s),
            ),
          ),
          SizedBox(height: 8 * s),
          MirrorFadeIn(
            delayMs: 110,
            child: Text(
              l10n.mirrorBodySubtitle,
              style: MirrorTheme.subtitle(16 * s),
            ),
          ),
          SizedBox(height: 32 * s),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Высота карточек подстраивается под доступное место —
                // никаких переполнений ни на телефоне, ни на большом зеркале.
                final cardHeight =
                    (260 * s).clamp(120.0, constraints.maxHeight);
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: cardHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: MirrorFadeIn(
                            delayMs: 180,
                            child: _GenderCard(
                              icon: Icons.female_rounded,
                              label: l10n.mirrorFemale,
                              selected: controller.gender == 'FEMALE',
                              onTap: () => controller.setGender('FEMALE'),
                            ),
                          ),
                        ),
                        SizedBox(width: 16 * s),
                        Expanded(
                          child: MirrorFadeIn(
                            delayMs: 250,
                            child: _GenderCard(
                              icon: Icons.male_rounded,
                              label: l10n.mirrorMale,
                              selected: controller.gender == 'MALE',
                              onTap: () => controller.setGender('MALE'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = MirrorTheme.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? MirrorTheme.selectedBg : MirrorTheme.surface,
          borderRadius: BorderRadius.circular(28 * s),
          border: Border.all(
            color: selected ? MirrorTheme.pink : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64 * s,
              color: selected ? MirrorTheme.pink : MirrorTheme.ink,
            ),
            SizedBox(height: 14 * s),
            Text(label, style: MirrorTheme.label(20 * s)),
          ],
        ),
      ),
    );
  }
}

/// Экран 3б — тип фигуры. Список зависит от пола, «Не знаю» есть всегда.
class MirrorShapeScreen extends StatelessWidget {
  const MirrorShapeScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            child: Text(
              l10n.mirrorBodyTitle.toUpperCase(),
              style: MirrorTheme.kicker(s),
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorShapeLabel,
              style: MirrorTheme.headline(38 * s),
            ),
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: GridView.count(
              crossAxisCount: MirrorTheme.gridColumns(context),
              mainAxisSpacing: 14 * s,
              crossAxisSpacing: 14 * s,
              childAspectRatio: 0.92,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final shape in shapes)
                  _ShapeCard(
                    label: shape.label(lang),
                    asset: isFemale
                        ? kioskFemaleShapeAssets[shape.code]
                        : null,
                    selected: controller.bodyShape == shape.code,
                    onTap: () => controller.setShape(shape.code!),
                  ),
                _ShapeCard(
                  label: l10n.mirrorDontKnow,
                  asset: null,
                  isUnknown: true,
                  selected: controller.bodyShape == kioskShapeUnknown,
                  onTap: () => controller.setShape(kioskShapeUnknown),
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

class _ShapeCard extends StatelessWidget {
  const _ShapeCard({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.isUnknown = false,
  });

  final String label;
  final String? asset;
  final bool selected;
  final bool isUnknown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = MirrorTheme.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: selected ? MirrorTheme.selectedBg : MirrorTheme.surface,
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(
            color: selected ? MirrorTheme.pink : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              // Иллюстрации силуэтов — полноцветные PNG на белом фоне:
              // тонировать их нельзя (srcIn заливает всё сплошным цветом).
              child: asset != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14 * s),
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(6 * s),
                        child: Image.asset(asset!, fit: BoxFit.contain),
                      ),
                    )
                  : Center(
                      child: isUnknown
                          ? Container(
                              width: 52 * s,
                              height: 52 * s,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? Colors.white
                                    : MirrorTheme.hairline,
                              ),
                              child: Text(
                                '?',
                                style: MirrorTheme.label(
                                  24 * s,
                                  color: selected
                                      ? MirrorTheme.pink
                                      : MirrorTheme.gray,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.accessibility_new_rounded,
                              size: 52 * s,
                              color: selected
                                  ? MirrorTheme.pink
                                  : MirrorTheme.ink,
                            ),
                    ),
            ),
            SizedBox(height: 8 * s),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: MirrorTheme.label(
                13.5 * s,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
