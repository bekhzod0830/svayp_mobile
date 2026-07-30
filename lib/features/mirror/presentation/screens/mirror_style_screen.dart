import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

/// Экран 4 — выбор стиля (только ветка «создать»): 6 плиток, мультивыбор,
/// минимум одна.
class MirrorStyleScreen extends StatelessWidget {
  const MirrorStyleScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);
    final lang = controller.shopperLang;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 28 * s),
          MirrorFadeIn(
            child: Text(
              l10n.mirrorStyleTitle,
              style: MirrorTheme.headline(38 * s),
            ),
          ),
          SizedBox(height: 8 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(
              l10n.mirrorStyleSubtitle,
              style: MirrorTheme.subtitle(16 * s),
            ),
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14 * s,
              crossAxisSpacing: 14 * s,
              childAspectRatio: 1.7,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final style in kioskStyles)
                  _StyleTile(
                    label: style.label(lang),
                    selected: controller.styles.contains(style.code),
                    onTap: () => controller.toggleStyle(style.code!),
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

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: selected ? MirrorTheme.selectedBg : MirrorTheme.surface,
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(
            color: selected ? MirrorTheme.pink : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26 * s,
                height: 26 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? MirrorTheme.pink : Colors.white,
                  border: Border.all(
                    color: selected ? MirrorTheme.pink : MirrorTheme.hairline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 17 * s, color: Colors.white)
                    : null,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(label, style: MirrorTheme.headline(21 * s)),
            ),
          ],
        ),
      ),
    );
  }
}
