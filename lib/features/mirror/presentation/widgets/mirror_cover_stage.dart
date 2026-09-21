import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';

import '../../data/kiosk_cover_looks.dart';
import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_theme.dart';
import 'mirror_stage_parts.dart';

/// Сцена постера — «примерочная»: арочное зеркало в глиняной раме на
/// зелёной стене бутика. Вещи зала влетают с боков с наклоном, парят, затем
/// по одной уезжают в зеркало и складываются в образ; следом выскакивает
/// бейдж «AI ✦», поднимается ярлык с суммой, по стеклу пробегает блик.
/// Один проход [cycle] (0→1) = один образ; [ambient] качает вещи, пока они
/// «висят на рейле». Артборд фиксированный — вызывающий кладёт сцену в
/// FittedBox, как сцены онбординга.
class MirrorCoverStage extends StatelessWidget {
  const MirrorCoverStage({
    super.key,
    required this.cycle,
    required this.ambient,
    required this.look,
    required this.fallbackLabels,
    required this.lang,
    required this.kicker,
    this.wide = true,
  });

  /// Широкая сцена (планшет: стена шире, чем выше) или компактная (телефон):
  /// меняются ширина артборда и размер/положение вещей на «рейле».
  final bool wide;

  final Animation<double> cycle;
  final Animation<double> ambient;

  /// Образ из каталога зала; null — каталога ещё нет, вещи заменяются
  /// типографскими карточками [fallbackLabels] (верх, низ, обувь).
  final KioskCoverLook? look;
  final List<String> fallbackLabels;
  final String lang;
  final String kicker;

  /// Подмена загрузчика фото в тестах: сетевые картинки в виджет-тестах
  /// тянут за собой кэш-менеджер с таймерами и плагинами.
  @visibleForTesting
  static Widget Function(String url)? debugImageBuilder;

  Size get artboard => Size(wide ? 560 : 392, 470);

  double get _centerX => artboard.width / 2;

  Rect get _mirror => MirrorFigureLayout.mirrorRect(_centerX);

  /// «Рейл» по бокам зеркала: откуда вещи стартуют и с каким наклоном.
  List<Rect> get _rack => wide
      ? const [
          Rect.fromLTWH(10, 82, 124, 158),
          Rect.fromLTWH(426, 166, 124, 158),
          Rect.fromLTWH(28, 294, 112, 112),
        ]
      : const [
          Rect.fromLTWH(2, 92, 100, 128),
          Rect.fromLTWH(290, 178, 100, 128),
          Rect.fromLTWH(10, 304, 92, 92),
        ];
  static const List<double> _tilt = [-8, 7, -5];

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final pieces = _pieces(t);
    final slots = _slots(pieces);

    return SizedBox(
      width: artboard.width,
      height: artboard.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([cycle, ambient]),
        builder: (context, _) {
          final v = cycle.value;
          final fade = 1 - _interval(v, 0.93, 1.0, Curves.easeIn);
          final bob = Curves.easeInOut.transform(ambient.value);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Искры вокруг зеркала.
              Positioned(
                left: wide ? 156 : 70,
                top: 22,
                child: Twinkle(color: t.accent, size: 17),
              ),
              Positioned(
                right: wide ? 104 : 44,
                top: 92,
                child: Twinkle(
                  color: t.onPrimary,
                  size: 14,
                  delaySeconds: 0.8,
                ),
              ),
              if (wide)
                Positioned(
                  right: 30,
                  top: 40,
                  child:
                      Twinkle(color: t.accent, size: 11, delaySeconds: 1.9),
                ),
              Positioned(
                right: wide ? 118 : 56,
                bottom: 36,
                child: Twinkle(color: t.accent, size: 13, delaySeconds: 1.4),
              ),
              Positioned(
                left: wide ? 150 : 50,
                bottom: 22,
                child: Twinkle(
                  color: t.onPrimary,
                  size: 12,
                  delaySeconds: 0.4,
                ),
              ),

              Positioned.fromRect(rect: _mirror, child: const MirrorArch()),

              for (var i = 0; i < pieces.length; i++)
                _buildPiece(pieces[i], slots[i], i, v, fade, bob),

              // Бейдж «AI ✦» у верхнего угла зеркала.
              Positioned(
                left: _centerX + 42,
                top: 16,
                child: _Pop(
                  t: _interval(v, 0.60, 0.72, Curves.easeOutBack),
                  opacity: _interval(v, 0.60, 0.66) * fade,
                  child: const MirrorAiBadge(),
                ),
              ),

              // Ярлык образа на нижней кромке зеркала.
              Positioned(
                left: wide ? 130 : 60,
                right: wide ? 130 : 60,
                top: 420,
                child: _Rise(
                  t: _interval(v, 0.64, 0.78),
                  opacity: _interval(v, 0.64, 0.74) * fade,
                  child: _LookTag(
                    kicker: kicker,
                    price: look == null
                        ? null
                        : kioskMoney(look!.totalPrice, lang),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPiece(
    _Piece piece,
    Rect slot,
    int index,
    double v,
    double fade,
    double bob,
  ) {
    final rackIndex = index.clamp(0, _rack.length - 1);
    final rack = _rack[rackIndex];
    final fromLeft = rackIndex != 1;

    final fly = _interval(v, 0.02 + 0.05 * index, 0.16 + 0.05 * index);
    final travelStart = 0.24 + 0.11 * index;
    final travelEnd = travelStart + 0.14;
    final travel =
        _interval(v, travelStart, travelEnd, Curves.easeInOutCubic);
    // Лёгкий «щелчок» при посадке в зеркало.
    final snap = math.sin(
      math.pi * _interval(v, travelEnd - 0.02, travelEnd + 0.07, Curves.linear),
    );

    final rect = Rect.lerp(rack, slot, travel)!.shift(
      Offset(
        (fromLeft ? -46 : 46) * (1 - fly),
        -7 * bob * (1 - travel) * (index.isEven ? 1 : -1),
      ),
    );
    final angle = _tilt[rackIndex] * (1 - travel) * math.pi / 180;

    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: (fly * fade).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 1 + 0.045 * snap,
            child: _PieceCard(piece: piece, settle: travel),
          ),
        ),
      ),
    );
  }

  List<_Piece> _pieces(MirrorTheme t) {
    final current = look;
    if (current != null) {
      return [
        for (final item in current.items) _Piece(item: item),
      ];
    }
    final tints = [t.surface, t.selectedBg, Color.lerp(t.surface, t.accent, 0.16)!];
    return [
      for (var i = 0; i < fallbackLabels.length && i < 3; i++)
        _Piece(label: fallbackLabels[i], tint: tints[i]),
    ];
  }

  /// Раскладка вещей внутри зеркала фигурой (см. [MirrorFigureLayout]):
  /// голова-намёк, верх, низ, обувь — плитки читаются как человек.
  List<Rect> _slots(List<_Piece> pieces) {
    final current = look;
    final hasShoes =
        current == null ? pieces.length > 2 : current.shoes != null;
    final slots = MirrorFigureLayout.slots(
      centerX: _centerX,
      bodyCount: pieces.length - (hasShoes ? 1 : 0),
      hasShoes: hasShoes,
    );
    while (slots.length < pieces.length) {
      slots.add(slots.last);
    }
    return slots;
  }

  static double _interval(
    double v,
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) =>
      curve.transform(((v - begin) / (end - begin)).clamp(0.0, 1.0));
}

/// Вещь на сцене: фото из каталога либо типографская карточка-заглушка.
class _Piece {
  const _Piece({this.item, this.label, this.tint});

  final KioskCatalogItem? item;
  final String? label;
  final Color? tint;
}

/// Карточка вещи. На «рейле» — белая рамка-полароид с тенью; по мере посадки
/// в зеркало ([settle] → 1) рамка и тень тают, чтобы фото слилось со стеклом.
class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.piece, required this.settle});

  final _Piece piece;
  final double settle;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final frame = 5.0 * (1 - settle);
    final radius = 12 - 6 * settle;
    final url = piece.item?.imageUrl;

    Widget content;
    if (url != null && url.isNotEmpty) {
      final debugBuilder = MirrorCoverStage.debugImageBuilder;
      content = debugBuilder != null
          ? debugBuilder(url)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              // Артборд масштабируется FittedBox'ом: 2.5× хватает и планшету.
              memCacheWidth: 420,
              fadeInDuration: const Duration(milliseconds: 250),
              placeholder: (_, __) => ColoredBox(color: t.surface),
              errorWidget: (_, __, ___) => ColoredBox(color: t.surface),
            );
    } else {
      content = ColoredBox(
        color: piece.tint ?? t.surface,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 18, height: 1.5, color: t.primary),
              const Spacer(),
              Text(
                piece.label ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.headline(13, color: t.primaryDeep),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30 * (1 - settle)),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(frame),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(math.max(2, radius - frame)),
          child: SizedBox.expand(child: content),
        ),
      ),
    );
  }
}

/// Ярлык на кромке зеркала: красная точка «live», кикер и сумма образа.
class _LookTag extends StatelessWidget {
  const _LookTag({required this.kicker, required this.price});

  final String kicker;
  final String? price;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.rChip + 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.danger,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                t.kickerCase(kicker),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.kicker(0.78),
              ),
            ),
            if (price != null) ...[
              const SizedBox(width: 10),
              Text(price!, style: t.price(11.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Масштаб с «перелётом» (кривая задаётся снаружи) + прозрачность.
class _Pop extends StatelessWidget {
  const _Pop({required this.t, required this.opacity, required this.child});

  final double t;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.3 + 0.7 * t, child: child),
      );
}

/// Подъём на 14px + прозрачность.
class _Rise extends StatelessWidget {
  const _Rise({required this.t, required this.opacity, required this.child});

  final double t;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      );
}
