import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';

/// Шаг «Где вы любите покупать?» — один бренд или «Любой бренд» (задача 6 по
/// планшетам). Сетка логотипов в стиле станции; дальше — генерация.
class MirrorShopBrandScreen extends StatelessWidget {
  const MirrorShopBrandScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = mirrorStationScale(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(title: l10n.mirrorBrandTitle, subtitle: l10n.mirrorBrandSubtitle),
          SizedBox(height: 24 * s),
          Expanded(
            child: MirrorBrandGrid(
              selected: controller.shopBrand,
              onPick: controller.chooseShopBrand,
            ),
          ),
          SizedBox(height: 16 * s),
          MirrorPrimaryButton(
            label: l10n.mirrorCtaCreate,
            height: 64 * s,
            enabled: controller.shopBrand != null,
            onTap: controller.confirmShopBrand,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

/// Сетка логотипов: «Любой бренд» первым, затем 12 брендов зала. Общая для шага
/// бренда и кнопки «Другой бренд» при пересборке ([exclude] — текущий бренд).
class MirrorBrandGrid extends StatelessWidget {
  const MirrorBrandGrid({
    super.key,
    required this.selected,
    required this.onPick,
    this.exclude,
    this.shrinkWrap = false,
  });

  final String? selected;
  final ValueChanged<String> onPick;
  final String? exclude;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final tiles = <Widget>[
      if (exclude != kioskAnyBrand)
        _LogoTile(
          selected: selected == kioskAnyBrand,
          onTap: () => onPick(kioskAnyBrand),
          label: l10n.mirrorBrandAny,
          child: Text(
            l10n.mirrorBrandAny,
            textAlign: TextAlign.center,
            style: t.label(18 * s, weight: FontWeight.w700),
          ),
        ),
      for (final b in kioskShopBrands)
        if (b.code != exclude)
          _LogoTile(
            selected: selected == b.code,
            onTap: () => onPick(b.code),
            label: b.name,
            child: Image.asset(
              b.logo,
              fit: BoxFit.contain,
              // Логотипа нет в сборке — название бренда, а не пустая плитка.
              errorBuilder: (_, __, ___) => Text(
                b.name,
                textAlign: TextAlign.center,
                style: t.label(18 * s, weight: FontWeight.w700),
              ),
            ),
          ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      mainAxisSpacing: 14 * s,
      crossAxisSpacing: 14 * s,
      childAspectRatio: 1.45,
      children: tiles,
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.selected, required this.onTap, required this.child, required this.label});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 16 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(t.rCard),
            border: Border.all(color: selected ? t.primary : t.hairline, width: selected ? 3 : 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: Center(child: child)),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 22 * s,
                    height: 22 * s,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: t.primary),
                    child: Icon(Icons.check_rounded, size: 15 * s, color: t.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плитки цветов «Какие цвета не показывать?» — мультивыбор.
class MirrorColorGrid extends StatelessWidget {
  const MirrorColorGrid({super.key, required this.selected, required this.onToggle, required this.lang});

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return GridView.count(
      crossAxisCount: 3,
      physics: const BouncingScrollPhysics(),
      mainAxisSpacing: 14 * s,
      crossAxisSpacing: 14 * s,
      childAspectRatio: 0.95,
      children: [
        for (final color in kioskColors)
          MirrorStationCard(
            title: color.label.label(lang),
            multi: true,
            selected: selected.contains(color.code),
            onTap: () => onToggle(color.code),
            picture: Container(
              margin: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: Color(color.argb),
                borderRadius: BorderRadius.circular(t.rImage),
                border: Border.all(color: t.hairline),
              ),
            ),
          ),
      ],
    );
  }
}
