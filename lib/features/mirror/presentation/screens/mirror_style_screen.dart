import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран 3 — выбор стиля (только ветка «создать»): плитки из справочника
/// бренда (скрытые стили не показываем, подписи — брендовые), мультивыбор,
/// минимум одна.
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
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14 * s,
              crossAxisSpacing: 14 * s,
              childAspectRatio: 1.5,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final style in kioskStylesFor(controller.gender))
                  _StyleTile(
                    label: brand.styleLabel(style, lang),
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

/// Редакционная плитка: серифная подпись внизу, квадратный чек сверху;
/// выбранная — залита цветом бренда.
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
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: selected ? t.primary : t.surface,
          borderRadius: BorderRadius.circular(t.rCard),
          border: Border.all(color: selected ? t.primary : t.hairline),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: MirrorCheck(
                selected: selected,
                size: 24 * s,
                onDark: selected,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.headline(
                  21 * s,
                  color: selected ? t.onPrimary : t.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
