import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_theme.dart';
import 'mirror_chrome.dart';
import 'mirror_stage_parts.dart';

/// Сцена генерации — то же арочное зеркало, что на постере, но в нём уже
/// сам покупатель: его фото на месте головы, под ним — слоты верха, низа и
/// обуви. Визуал идёт за этапами работы ([stage] 0..3):
///   0 — скан лица (дуга вокруг фото, луч по голове);
///   1 — скан фигуры (луч идёт по слотам, они подсвечиваются);
///   2 — подбор: в слотах перелистываются реальные вещи зала, рядом с
///       зеркалом парят ещё вещи «с рейла»;
///   3 — сборка: перелистывание замедляется, рама зеркала светится.
/// Вещи, выбранные покупателем в каталоге ([pinned]), стоят в слотах сразу и
/// не листаются — это правда о будущем образе; остальное — иллюстрация
/// подбора, поэтому ничего «не защёлкивается» насовсем. Без каталога слоты
/// остаются типографскими карточками. Артборд фиксированный — вызывающий
/// кладёт сцену в FittedBox.
class MirrorFittingStage extends StatefulWidget {
  const MirrorFittingStage({
    super.key,
    required this.stage,
    required this.pool,
    required this.pinned,
    required this.slotLabels,
    this.facePhoto,
    this.wide = true,
  });

  final int stage;

  /// Каталог зала (может быть пустым).
  final List<KioskCatalogItem> pool;

  /// Вещи, выбранные покупателем (ветка «каталог»).
  final List<KioskCatalogItem> pinned;

  /// Подписи слотов-заглушек: верх, низ, обувь.
  final List<String> slotLabels;

  /// Снятое фото лица — «голова» отражения.
  final File? facePhoto;

  /// Широкая сцена (планшет) или компактная (телефон).
  final bool wide;

  /// Подмена загрузчика фото в тестах: сетевые картинки в виджет-тестах
  /// тянут за собой кэш-менеджер с таймерами и плагинами.
  @visibleForTesting
  static Widget Function(String url)? debugImageBuilder;

  @override
  State<MirrorFittingStage> createState() => _MirrorFittingStageState();
}

class _MirrorFittingStageState extends State<MirrorFittingStage>
    with SingleTickerProviderStateMixin {
  static const _beat = Duration(milliseconds: 650);

  /// Луч скана, дуга вокруг лица, пульс рамы.
  late final AnimationController _loop;
  Timer? _timer;
  int _tick = 0;
  bool _reduceMotion = false;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!_synced || reduce != _reduceMotion) {
      _synced = true;
      _reduceMotion = reduce;
      _sync();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (_reduceMotion) {
      _loop
        ..stop()
        ..value = 0;
      return;
    }
    if (!_loop.isAnimating) _loop.repeat();
    _timer = Timer.periodic(_beat, (_) {
      // Листаем только на этапах подбора и пока вкладка видна.
      if (!mounted || widget.stage < 2) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      setState(() => _tick++);
    });
  }

  double get _width => widget.wide ? 560 : 392;
  double get _centerX => _width / 2;

  bool get _hasFace => widget.facePhoto != null;

  /// С фото покупателя голова крупнее намёка — тело начинается ниже.
  double get _bodyTop => _hasFace ? 102 : MirrorFigureLayout.bodyTop;

  /// Лицо: на скане — крупно посреди зеркала, дальше — на месте головы.
  Rect get _faceRect => widget.stage == 0
      ? Rect.fromCenter(center: Offset(_centerX, 170), width: 128, height: 128)
      : Rect.fromCenter(center: Offset(_centerX, 68), width: 60, height: 60);

  List<KioskCatalogItem> _bucket(Set<String> slots) => widget.pool
      .where((i) =>
          (i.imageUrl?.isNotEmpty ?? false) &&
          slots.contains(kioskSlotOf(i.category)))
      .toList();

  KioskCatalogItem? _pinnedFor(Set<String> slots) {
    for (final item in widget.pinned) {
      if ((item.imageUrl?.isNotEmpty ?? false) &&
          slots.contains(kioskSlotOf(item.category))) {
        return item;
      }
    }
    return null;
  }

  List<_Slot> _slots() {
    String label(int i) =>
        i < widget.slotLabels.length ? widget.slotLabels[i] : '';

    // Выбрана цельная вещь (платье, комплект) — она занимает верх и низ.
    final pinnedFull = _pinnedFor(const {'FULL'});
    final rects = MirrorFigureLayout.slots(
      centerX: _centerX,
      bodyCount: pinnedFull != null ? 1 : 2,
      hasShoes: true,
      bodyTop: _bodyTop,
    );

    if (pinnedFull != null) {
      return [
        _Slot(rects[0], label(0), const [], pinnedFull),
        _Slot(
          rects[1],
          label(2),
          _bucket(const {'SHOES'}),
          _pinnedFor(const {'SHOES'}),
        ),
      ];
    }
    return [
      _Slot(
        rects[0],
        label(0),
        _bucket(const {'TOP', 'FULL'}),
        _pinnedFor(const {'TOP'}),
      ),
      _Slot(
        rects[1],
        label(1),
        _bucket(const {'BOTTOM'}),
        _pinnedFor(const {'BOTTOM'}),
      ),
      _Slot(
        rects[2],
        label(2),
        _bucket(const {'SHOES'}),
        _pinnedFor(const {'SHOES'}),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final stage = widget.stage;
    final slots = _slots();
    final wide = widget.wide;

    // На сборке листаем вдвое реже — образ «успокаивается».
    final shuffle = stage >= 3 ? _tick ~/ 2 : _tick;

    final rail = widget.pool
        .where((i) => i.imageUrl?.isNotEmpty ?? false)
        .toList();
    final showRail = stage >= 2 && rail.isNotEmpty;
    final railIndex = _tick ~/ 2;
    KioskCatalogItem? railItem(int k) =>
        rail.isEmpty ? null : rail[(railIndex + k * 5 + 2) % rail.length];

    final sideCards = wide
        ? const [
            (Rect.fromLTWH(14, 92, 112, 142), -7.0, 1),
            (Rect.fromLTWH(434, 116, 112, 142), 6.0, 2),
            (Rect.fromLTWH(36, 290, 96, 96), 5.0, 3),
            (Rect.fromLTWH(440, 304, 96, 96), -5.0, 1),
          ]
        : const [
            (Rect.fromLTWH(2, 110, 94, 120), -7.0, 1),
            (Rect.fromLTWH(296, 214, 94, 120), 6.0, 2),
          ];

    return SizedBox(
      width: _width,
      height: 470,
      child: Stack(
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
            child: Twinkle(color: t.onPrimary, size: 14, delaySeconds: 0.8),
          ),
          Positioned(
            right: wide ? 118 : 56,
            bottom: 36,
            child: Twinkle(color: t.accent, size: 13, delaySeconds: 1.4),
          ),
          Positioned(
            left: wide ? 150 : 50,
            bottom: 22,
            child: Twinkle(color: t.onPrimary, size: 12, delaySeconds: 0.4),
          ),

          // Вещи «с рейла» по бокам — появляются на этапе подбора.
          for (var k = 0; k < sideCards.length; k++)
            Positioned.fromRect(
              rect: sideCards[k].$1,
              child: AnimatedOpacity(
                opacity: showRail ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Floaty(
                  variant: sideCards[k].$3,
                  child: Transform.rotate(
                    angle: sideCards[k].$2 * math.pi / 180,
                    child: _RailCard(
                      item: railItem(k),
                      still: _reduceMotion,
                    ),
                  ),
                ),
              ),
            ),

          // Зеркало: фото покупателя на месте головы, на сборке рама светится.
          AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final pulse = 0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi);
              final glow = _reduceMotion
                  ? (stage >= 2 ? 0.4 : 0.0)
                  : stage >= 3
                      ? 0.45 + 0.55 * pulse
                      : stage == 2
                          ? 0.25
                          : 0.0;
              return Positioned.fromRect(
                rect: MirrorFigureLayout.mirrorRect(_centerX),
                // С фото покупателя намёк на голову не нужен — лицо рисуем
                // поверх зеркала отдельным слоем, оно умеет переезжать.
                child: MirrorArch(
                  glow: glow,
                  head: _hasFace ? const SizedBox.shrink() : null,
                ),
              );
            },
          ),

          // Пока идёт скан лица, слоты фигуры скрыты — всё внимание на лицо.
          for (var i = 0; i < slots.length; i++)
            Positioned.fromRect(
              rect: slots[i].rect,
              child: AnimatedOpacity(
                opacity: _hasFace && stage == 0 ? 0 : 1,
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                child: _SlotTile(
                  slot: slots[i],
                  stage: stage,
                  index: shuffle + i * 3,
                  still: _reduceMotion,
                ),
              ),
            ),

          if (_hasFace)
            AnimatedPositioned.fromRect(
              rect: _faceRect,
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 750),
              curve: Curves.easeInOutCubic,
              child: _FaceHead(
                photo: widget.facePhoto!,
                scanning: stage == 0 && !_reduceMotion,
                done: stage > 0,
                loop: _loop,
              ),
            ),

          // Луч скана по фигуре (этап 1); по голове-намёку — на этапе 0,
          // когда фото нет (с фото луч идёт прямо по лицу).
          if (!_reduceMotion && (stage == 1 || (stage == 0 && !_hasFace)))
            AnimatedBuilder(
              animation: _loop,
              builder: (context, _) {
                final sweep =
                    0.5 - 0.5 * math.cos(_loop.value * 2 * math.pi);
                final from = stage == 0
                    ? MirrorFigureLayout.mirrorTop + 10
                    : MirrorFigureLayout.bodyTop;
                final to = stage == 0
                    ? MirrorFigureLayout.bodyTop + 6
                    : MirrorFigureLayout.bodyBottom;
                final start = stage == 0 ? from : _bodyTop;
                final half = stage == 0 ? 34.0 : 72.0;
                return Positioned(
                  left: _centerX - half,
                  width: half * 2,
                  top: start + (to - start) * sweep - 14,
                  height: 28,
                  child: const _ScanBeam(),
                );
              },
            ),

          Positioned(
            left: _centerX + 42,
            top: 16,
            child: const Floaty(variant: 3, child: MirrorAiBadge()),
          ),
        ],
      ),
    );
  }
}

class _Slot {
  const _Slot(this.rect, this.label, this.pool, this.pinned);

  final Rect rect;
  final String label;
  final List<KioskCatalogItem> pool;
  final KioskCatalogItem? pinned;
}

/// Плитка слота в зеркале: выбранная вещь (с чеком), перелистываемые вещи
/// зала либо типографская заглушка с подписью категории.
class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.stage,
    required this.index,
    required this.still,
  });

  final _Slot slot;
  final int stage;
  final int index;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final pinned = slot.pinned;
    final radius = BorderRadius.circular(6);

    if (pinned != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: _Photo(url: pinned.imageUrl!),
          ),
          const Positioned(
            top: 4,
            right: 4,
            child: MirrorCheck(selected: true, size: 16),
          ),
        ],
      );
    }

    if (stage < 2 || slot.pool.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: t.primary.withValues(alpha: stage >= 1 ? 0.10 : 0.05),
          borderRadius: radius,
          border: Border.all(color: t.primary.withValues(alpha: 0.22)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    t.kickerCase(slot.label),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.kicker(0.62).copyWith(height: 1.3),
                  ),
                ),
              ),
              // Каталога нет — на подборе по заглушке хотя бы бежит блик.
              if (stage >= 2 && !still)
                const Gleam(
                  durationMs: 2200,
                  travelFraction: 0.6,
                  widthFraction: 0.5,
                  opacity: 0.6,
                ),
            ],
          ),
        ),
      );
    }

    final item = slot.pool[index % slot.pool.length];
    return ClipRRect(
      borderRadius: radius,
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        // Новая вещь выезжает снизу — как следующая вешалка на рейле.
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(item.id),
          child: _Photo(url: item.imageUrl!),
        ),
      ),
    );
  }
}

/// Карточка-полароид «с рейла» у зеркала; фото мягко сменяется.
class _RailCard extends StatelessWidget {
  const _RailCard({required this.item, required this.still});

  final KioskCatalogItem? item;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final current = item;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: current == null
              ? const SizedBox.expand()
              : AnimatedSwitcher(
                  duration:
                      still ? Duration.zero : const Duration(milliseconds: 500),
                  layoutBuilder: (child, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, if (child != null) child],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(current.id),
                    child: _Photo(url: current.imageUrl!),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final debugBuilder = MirrorFittingStage.debugImageBuilder;
    if (debugBuilder != null) return SizedBox.expand(child: debugBuilder(url));
    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 420,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => ColoredBox(color: t.surface),
        errorWidget: (_, __, ___) => ColoredBox(color: t.surface),
      ),
    );
  }
}

/// Лицо покупателя. Рисуется на условном холсте 60×60 и масштабируется под
/// свой бокс: на скане оно крупное, с бегущей дугой и лучом по лицу; после —
/// маленькое на месте головы, с чеком «готово».
class _FaceHead extends StatelessWidget {
  const _FaceHead({
    required this.photo,
    required this.scanning,
    required this.done,
    required this.loop,
  });

  final File photo;
  final bool scanning;
  final bool done;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.primary.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      photo,
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                      errorBuilder: (_, __, ___) => const SizedBox.expand(),
                    ),
                    if (scanning)
                      AnimatedBuilder(
                        animation: loop,
                        builder: (context, child) {
                          final sweep =
                              0.5 - 0.5 * math.cos(loop.value * 2 * math.pi);
                          return Align(
                            alignment: Alignment(0, -1 + 2 * sweep),
                            child: child,
                          );
                        },
                        child: const SizedBox(
                          height: 12,
                          width: double.infinity,
                          child: _ScanBeam(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (scanning)
              RotationTransition(
                turns: loop,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: _ArcPainter(color: t.accent),
                ),
              ),
            Positioned(
              right: 3,
              bottom: 3,
              child: AnimatedScale(
                scale: done ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.primary,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: t.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(1.5),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

/// Луч скана: тонкая линия акцентного цвета с мягким ореолом.
class _ScanBeam extends StatelessWidget {
  const _ScanBeam();

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.accent.withValues(alpha: 0),
                  t.accent.withValues(alpha: 0.28),
                  t.accent.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Container(height: 1.5, color: t.accent),
        ],
      ),
    );
  }
}
