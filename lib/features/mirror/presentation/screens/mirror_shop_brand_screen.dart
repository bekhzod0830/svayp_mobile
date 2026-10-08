import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';

/// Шаг «Где вы любите покупать?» — один или несколько брендов, либо «Все бренды»
/// (задача 6 по планшетам). Сетка логотипов в стиле станции; дальше — цвета,
/// которых не должно быть в образе.
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
              selected: controller.shopBrands,
              onPick: controller.toggleShopBrand,
            ),
          ),
          SizedBox(height: 16 * s),
          MirrorPrimaryButton(
            label: l10n.mirrorContinue,
            height: 64 * s,
            enabled: controller.shopBrands.isNotEmpty,
            onTap: controller.confirmShopBrand,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

/// Плитки логотипов всегда белые (логотипы — тёмные на белом), поэтому текст и
/// отметки на них — фиксированным тёмным, а не цветом темы: в тёмной теме
/// ink и primary светлые и пропадали на белом.
const Color _tileInk = Color(0xFF111111);

/// Сетка логотипов: «Все бренды» первым, затем 12 брендов зала. Общая для шага
/// бренда (мультивыбор, [selected] — отмеченные) и кнопки «Другой бренд» при
/// пересборке ([exclude] — текущий бренд).
class MirrorBrandGrid extends StatelessWidget {
  const MirrorBrandGrid({
    super.key,
    required this.selected,
    required this.onPick,
    this.exclude,
    this.shrinkWrap = false,
  });

  final Set<String> selected;
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
          selected: selected.contains(kioskAnyBrand),
          onTap: () => onPick(kioskAnyBrand),
          label: l10n.mirrorBrandAny,
          child: Text(
            l10n.mirrorBrandAny,
            textAlign: TextAlign.center,
            style: t.label(18 * s, weight: FontWeight.w700, color: _tileInk),
          ),
        ),
      for (final b in kioskShopBrands)
        if (b.code != exclude)
          _LogoTile(
            selected: selected.contains(b.code),
            onTap: () => onPick(b.code),
            label: b.name,
            child: Image.asset(
              b.logo,
              fit: BoxFit.contain,
              // Логотипа нет в сборке — название бренда, а не пустая плитка.
              errorBuilder: (_, __, ___) => Text(
                b.name,
                textAlign: TextAlign.center,
                style: t.label(18 * s, weight: FontWeight.w700, color: _tileInk),
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
    // На белой плитке отметка должна быть тёмной: светлый primary тёмной темы
    // на ней не виден.
    final mark = t.dark ? _tileInk : t.primary;
    final onMark = t.dark ? Colors.white : t.onPrimary;
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
            border: Border.all(color: selected ? mark : t.hairline, width: selected ? 3 : 1),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: Center(child: child)),
              Positioned(
                top: -6 * s,
                right: -8 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 26 * s,
                    height: 26 * s,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: mark),
                    child: Icon(Icons.check_rounded, size: 18 * s, color: onMark),
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

/// Плитки цветов «Какие цвета не показывать?» — мультивыбор. Отмеченный цвет —
/// исключённый, поэтому он выглядит запрещённым (красная рамка, перечёркнутый
/// образец, знак «нет»), а не выбранным: человек не должен решить, что отмечает
/// любимые цвета.
class MirrorColorGrid extends StatelessWidget {
  const MirrorColorGrid({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.lang,
    this.shrinkWrap = false,
    this.columns = 3,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String lang;

  /// Внутри прокручиваемого списка (панель «Другой цвет» на «Что изменить?»).
  final bool shrinkWrap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final s = mirrorStationScale(context);
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      mainAxisSpacing: 14 * s,
      crossAxisSpacing: 14 * s,
      childAspectRatio: 0.95,
      children: [
        for (final color in kioskColors)
          _AvoidColorTile(
            label: color.label.label(lang),
            color: Color(color.argb),
            excluded: selected.contains(color.code),
            onTap: () => onToggle(color.code),
          ),
      ],
    );
  }
}

class _AvoidColorTile extends StatelessWidget {
  const _AvoidColorTile({
    required this.label,
    required this.color,
    required this.excluded,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool excluded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Semantics(
      button: true,
      selected: excluded,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: excluded ? t.danger.withValues(alpha: 0.08) : t.surface,
            borderRadius: BorderRadius.circular(t.rCard),
            border: Border.all(
              color: excluded ? t.danger : t.hairline,
              width: excluded ? 3 : 1,
            ),
          ),
          padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 10 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: excluded ? 0.45 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(t.rImage),
                          border: Border.all(color: t.hairline),
                        ),
                      ),
                    ),
                    if (excluded) ...[
                      CustomPaint(painter: _StrikePainter(t.danger, 3 * s)),
                      Center(
                        child: Container(
                          width: 40 * s,
                          height: 40 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.danger,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.block_rounded, size: 24 * s, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 8 * s),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t
                    .label(15 * s, weight: FontWeight.w600, color: excluded ? t.danger : t.ink)
                    .copyWith(
                      decoration: excluded ? TextDecoration.lineThrough : null,
                      decorationColor: t.danger,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Диагональ «перечёркнуто» поверх образца цвета.
class _StrikePainter extends CustomPainter {
  _StrikePainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.88),
      Offset(size.width * 0.88, size.height * 0.12),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.color != color || old.width != width;
}
