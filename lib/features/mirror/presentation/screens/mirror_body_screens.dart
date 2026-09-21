import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран 2а — пол. Отдельная страница (решение владельца): две крупные
/// типографские карточки, касание сразу ведёт к выбору фигуры.
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
            child: Text(
              l10n.mirrorBodyTitle,
              style: t.headline(36 * s),
            ),
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
          SizedBox(height: 32 * s),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Высота карточек подстраивается под доступное место —
                // никаких переполнений ни на телефоне, ни на большом зеркале.
                final cardHeight =
                    (190 * s).clamp(120.0, constraints.maxHeight);
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
                              label: l10n.mirrorFemale,
                              selected: controller.gender == 'FEMALE',
                              onTap: () => controller.setGender('FEMALE'),
                            ),
                          ),
                        ),
                        // Мужская одежда в зале есть не всегда: без неё мужчина
                        // снял бы фото и ждал генерацию ради пустого результата.
                        if (controller.menswearAvailable) ...[
                          SizedBox(width: 14 * s),
                          Expanded(
                            child: MirrorFadeIn(
                              delayMs: 250,
                              child: _GenderCard(
                                label: l10n.mirrorMale,
                                selected: controller.gender == 'MALE',
                                onTap: () => controller.setGender('MALE'),
                              ),
                            ),
                          ),
                        ],
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

/// Типографская карточка выбора: тонкая линейка цветом бренда и серифная
/// подпись; выбранная — залита цветом бренда.
class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final fg = selected ? t.onPrimary : t.ink;

    return Material(
      color: selected ? t.primary : t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.rCard),
        side: BorderSide(color: selected ? t.primary : t.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(20 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28 * s,
                height: 1.5,
                color: selected ? t.onPrimary : t.primary,
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                style: t.headline(26 * s, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Экран 2б — тип фигуры. Список зависит от пола, «Не знаю» есть всегда.
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
            child: Text(
              t.kickerCase(l10n.mirrorBodyTitle),
              style: t.kicker(s),
            ),
          ),
          SizedBox(height: 14 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorShapeLabel,
              style: t.headline(36 * s),
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
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(10 * s),
        decoration: BoxDecoration(
          color: selected ? t.selectedBg : t.surface,
          borderRadius: BorderRadius.circular(t.rCard),
          border: Border.all(
            color: selected ? t.primary : t.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Иллюстрации силуэтов — полноцветные PNG на белом фоне:
                  // тонировать их нельзя (srcIn заливает всё сплошным цветом).
                  if (asset != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(t.rImage),
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(6 * s),
                        child: Image.asset(asset!, fit: BoxFit.contain),
                      ),
                    )
                  else
                    Center(
                      child: isUnknown
                          ? Text(
                              '?',
                              style: t.display(
                                40 * s,
                                color: selected ? t.primary : t.muted,
                              ),
                            )
                          : Icon(
                              Icons.accessibility_new_rounded,
                              size: 52 * s,
                              color: selected ? t.primary : t.ink,
                            ),
                    ),
                  Positioned(
                    top: 6 * s,
                    right: 6 * s,
                    child: MirrorCheck(selected: selected, size: 22 * s),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: t.label(13.5 * s, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
