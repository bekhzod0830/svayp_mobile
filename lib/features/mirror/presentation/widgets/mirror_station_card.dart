import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mirror_theme.dart';
import 'mirror_chrome.dart';

/// Масштаб экранов станции: как [MirrorTheme.scale], но и по высоте — макет
/// рассчитан на вертикальные 1080×1920; на экране ниже всё ужимается пропорционально,
/// а не вылезает за край.
double mirrorStationScale(BuildContext context) =>
    math.min(MirrorTheme.scale(context), MediaQuery.sizeOf(context).height / 960);

/// Сетка карточек станции (дизайн LIBAS 10.2026): две колонки, зазор 24 из 1080.
/// [aspect] — ширина / высота карточки; макет: 464×578 (фото 1:1 + подпись) и
/// 464×852 для гардероба.
class MirrorStationGrid extends StatelessWidget {
  const MirrorStationGrid({
    super.key,
    required this.children,
    this.aspect = 464 / 578,
    this.columns = 2,
  });

  final List<Widget> children;
  final double aspect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final s = mirrorStationScale(context);
    final gap = 18 * s;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        // Карточки не выше доступного места: на низком экране всё видно без прокрутки.
        final rows = (children.length / columns).ceil();
        final fitH = rows == 0 ? 0.0 : (box.maxHeight - gap * (rows - 1)) / rows;
        final h = box.maxHeight.isFinite ? (w / aspect).clamp(0.0, fitH) : w / aspect;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children) SizedBox(width: w, height: h, child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Карточка выбора станции: картинка сверху, название и описание снизу, индикатор в
/// углу. Вся карточка — одна цель касания. Выбранная — толстая рамка и подпись на
/// плашке цвета бренда (в макете LIBAS — чёрной).
class MirrorStationCard extends StatelessWidget {
  const MirrorStationCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.photo,
    this.picture,
    this.multi = false,
    this.photoFit = BoxFit.cover,
    this.captionHeight,
  });

  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  /// Ассет-картинка карточки (фото или силуэт).
  final String? photo;

  /// Своя картинка вместо [photo] (логотип, образец цвета).
  final Widget? picture;

  /// Множественный выбор (стили, цвета): квадратный индикатор; иначе — круглый.
  final bool multi;
  final BoxFit photoFit;

  /// Высота подписи; по умолчанию — под название в две строки и описание. Подпись
  /// фиксированной высоты, картинка забирает остальное: в плотной сетке доля высоты
  /// не вмещала текст.
  final double? captionHeight;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final onSelected = t.onPrimary;

    final Widget image = picture ??
        (photo != null
            ? Image.asset(
                photo!,
                fit: photoFit,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => ColoredBox(color: t.bg),
              )
            : ColoredBox(color: t.bg));

    return Semantics(
      button: true,
      selected: selected,
      label: description == null ? title : '$title. $description',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.rCard),
            border: Border.all(
              color: selected ? t.primary : t.hairline,
              width: selected ? 3 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    Positioned(
                      top: 12 * s,
                      right: 12 * s,
                      child: multi
                          ? MirrorCheck(selected: selected, size: 26 * s)
                          : _RadioDot(selected: selected, size: 26 * s),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: captionHeight ?? (description == null ? 58 : 92) * s,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  color: selected ? t.primary : t.surface,
                  padding: EdgeInsets.fromLTRB(18 * s, 10 * s, 14 * s, 8 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.label(
                          17 * s,
                          weight: FontWeight.w700,
                          color: selected ? onSelected : t.ink,
                        ),
                      ),
                      if (description != null) ...[
                        SizedBox(height: 4 * s),
                        Text(
                          description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.subtitle(
                            12.5 * s,
                            color: selected ? onSelected.withValues(alpha: 0.8) : t.muted,
                          ),
                        ),
                      ],
                    ],
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.size});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? t.primary : Colors.white,
        border: Border.all(color: selected ? t.primary : t.hairline, width: 1.5),
      ),
      child: selected ? Icon(Icons.check_rounded, size: size * 0.7, color: t.onPrimary) : null,
    );
  }
}

/// Шапка шага станции: надзаголовок, заголовок, подзаголовок.
class MirrorStationHeading extends StatelessWidget {
  const MirrorStationHeading({
    super.key,
    required this.title,
    this.kicker,
    this.subtitle,
  });

  final String? kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) ...[
          MirrorFadeIn(child: Text(t.kickerCase(kicker!), style: t.kicker(s))),
          SizedBox(height: 12 * s),
        ],
        MirrorFadeIn(delayMs: 60, child: Text(title, style: t.headline(34 * s))),
        if (subtitle != null) ...[
          SizedBox(height: 8 * s),
          MirrorFadeIn(delayMs: 110, child: Text(subtitle!, style: t.subtitle(16 * s))),
        ],
      ],
    );
  }
}
