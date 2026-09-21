import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';
import '../widgets/mirror_cover_stage.dart';

/// Экран 0 — постер (обложка). Зелёная «стена бутика» с линиями корта и
/// арочным зеркалом: вещи зала влетают с боков и собираются в зеркале в образ
/// (см. [MirrorCoverStage]) — человек видит результат ещё до старта. Под
/// сценой — серифный заголовок, который меняется вместе с образом, и одна
/// главная кнопка с бликом. Язык анимаций — тот же, что у онбординга:
/// каскадные входы, парение, искры, блик. При выключенных анимациях сцена
/// показывает собранный образ и меняет его без переходов раз в 12 секунд.
class MirrorCoverScreen extends StatefulWidget {
  const MirrorCoverScreen({
    super.key,
    required this.controller,
    required this.onOpenSetup,
    this.active = true,
    this.fullscreen = false,
    this.onEnterFullscreen,
  });

  final MirrorSessionController controller;
  final VoidCallback onOpenSetup;

  /// false, когда вкладка «Зеркало» скрыта — сцена останавливается.
  final bool active;

  /// Полноэкранный киоск-режим: нижняя навигация продавца скрыта.
  /// Выход — только через скрытый шит настройки (5 касаний по знаку),
  /// чтобы покупатель не попал во вкладки продавца.
  final bool fullscreen;
  final VoidCallback? onEnterFullscreen;

  @override
  State<MirrorCoverScreen> createState() => _MirrorCoverScreenState();
}

class _MirrorCoverScreenState extends State<MirrorCoverScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _stillBeat = Duration(seconds: 12);

  /// Каскадный вход страницы (таймлайн 1.2с, как у слайдов онбординга).
  late final AnimationController _intro;

  /// Хореография одного образа: влёт → посадка в зеркало → бейдж → уход.
  late final AnimationController _cycle;

  /// Парение вещей на «рейле».
  late final AnimationController _ambient;

  /// Счётчик ротации: образ и фраза заголовка меняются вместе.
  int _tick = 0;
  Timer? _stillTimer;
  bool _lifecyclePaused = false;
  bool _reduceMotion = false;
  bool _synced = false;

  int _wordmarkTaps = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    )..addStatusListener(_onCycleStatus);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
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
  void didUpdateWidget(covariant MirrorCoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (paused == _lifecyclePaused) return;
    _lifecyclePaused = paused;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stillTimer?.cancel();
    _tapResetTimer?.cancel();
    _intro.dispose();
    _cycle.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _onCycleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _tick++);
    _precacheNextLook();
    _cycle.forward(from: 0);
  }

  /// Приводит анимации в соответствие с видимостью и настройкой «меньше
  /// движения». Идемпотентен.
  void _sync() {
    final run = widget.active && !_lifecyclePaused;
    _stillTimer?.cancel();
    _stillTimer = null;

    if (_reduceMotion) {
      _intro.value = 1;
      _cycle
        ..stop()
        ..value = 0.85; // образ уже собран в зеркале
      _ambient
        ..stop()
        ..value = 0;
      if (run) {
        _stillTimer = Timer.periodic(_stillBeat, (_) {
          if (mounted) setState(() => _tick++);
        });
      }
      return;
    }

    if (run) {
      if (_intro.value == 0 && !_intro.isAnimating) _intro.forward();
      if (!_cycle.isAnimating) _cycle.forward();
      if (!_ambient.isAnimating) _ambient.repeat(reverse: true);
    } else {
      _cycle.stop();
      _ambient.stop();
    }
  }

  /// Следующий образ подгружается заранее, чтобы вещи влетали уже с фото.
  void _precacheNextLook() {
    final looks = widget.controller.coverLooks;
    if (looks.length < 2) return;
    final next = looks[(_tick + 1) % looks.length];
    for (final item in next.items) {
      final url = item.imageUrl;
      if (url == null || url.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (_, __) {},
      );
    }
  }

  /// 5 быстрых касаний по знаку бренда — скрытый шит настройки
  /// (ключ устройства, демо-режим). Тот же жест, что вход партнёра.
  void _onWordmarkTap() {
    _wordmarkTaps++;
    _tapResetTimer?.cancel();
    if (_wordmarkTaps >= 5) {
      _wordmarkTaps = 0;
      widget.onOpenSetup();
    } else {
      _tapResetTimer =
          Timer(const Duration(seconds: 2), () => _wordmarkTaps = 0);
    }
  }

  /// Подписи типографских карточек, когда каталога ещё нет.
  List<String> _fallbackLabels(MirrorBrand brand, String lang) {
    String label(String code) => brand.categoryLabel(
          kioskCategories.firstWhere((c) => c.code == code),
          lang,
        );
    return [label('TOPWEAR'), label('BOTTOMWEAR'), label('FOOTWEAR')];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final brand = t.brand;
    final lang = Localizations.localeOf(context).languageCode;
    final phrases = brand.phrasesFor(lang);
    final looks = widget.controller.coverLooks;
    final phrase = phrases.isEmpty ? '' : phrases[_tick % phrases.length];
    final look = looks.isEmpty ? null : looks[_tick % looks.length];
    final pad = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Шапка лежит на зелёной сцене — иконки статус-бара светлые.
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: t.bg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Масштаб постера ограничен высотой: на планшете всё вдвое
            // крупнее, а экран лишь в полтора раза выше телефона.
            final usable = constraints.maxHeight - pad.top - pad.bottom;
            final cs = math.min(MirrorTheme.scale(context), usable / 620);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StageWall(
                    cs: cs,
                    topInset: pad.top,
                    header: Entrance(
                      parent: _intro,
                      kind: IntroEntranceKind.rise,
                      child: _Header(
                        cs: cs,
                        controller: widget.controller,
                        onWordmarkTap: _onWordmarkTap,
                        fullscreen: widget.fullscreen,
                        onEnterFullscreen: widget.onEnterFullscreen,
                      ),
                    ),
                    child: brand.heroVideoAsset != null
                        ? _VideoHero(
                            asset: brand.heroVideoAsset!,
                            active: widget.active && !_lifecyclePaused,
                            radius: t.rCard,
                          )
                        : LayoutBuilder(
                            // Стена шире, чем выше (планшет) — широкая сцена
                            // с крупными вещами; иначе компактная.
                            builder: (context, box) => FittedBox(
                              fit: BoxFit.contain,
                              child: RepaintBoundary(
                                child: MirrorCoverStage(
                                  cycle: _cycle,
                                  ambient: _ambient,
                                  look: look,
                                  fallbackLabels:
                                      _fallbackLabels(brand, lang),
                                  lang: lang,
                                  kicker: l10n.mirrorCoverLookKicker,
                                  wide: box.maxWidth > box.maxHeight * 1.05,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24 * cs,
                    20 * cs,
                    24 * cs,
                    12 * cs + pad.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.05,
                        child: Text(
                          t.kickerCase(l10n.mirrorCoverKicker),
                          style: t.kicker(cs),
                        ),
                      ),
                      SizedBox(height: 10 * cs),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.12,
                        child: AnimatedSwitcher(
                          duration: _reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 700),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              ...previous,
                              if (current != null) current,
                            ],
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.14),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            phrase,
                            key: ValueKey(
                              'phrase-${_tick % math.max(1, phrases.length)}',
                            ),
                            maxLines: 3,
                            style: t.display(31 * cs),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * cs),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.riseCard,
                        delay: 0.24,
                        child: MirrorPrimaryButton(
                          label: l10n.mirrorCtaCreate,
                          height: 60 * cs,
                          gleam: true,
                          onTap: () =>
                              widget.controller.begin(MirrorPath.create),
                        ),
                      ),
                      SizedBox(height: 2 * cs),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.34,
                        child: MirrorTextButton(
                          label: l10n.mirrorCtaCatalog,
                          height: 46 * cs,
                          onTap: () =>
                              widget.controller.begin(MirrorPath.catalog),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Зелёная стена бутика со скруглённым низом: линии корта фоном, шапка
/// поверх, сцена — в оставшемся месте под шапкой.
class _StageWall extends StatelessWidget {
  const _StageWall({
    required this.cs,
    required this.topInset,
    required this.header,
    required this.child,
  });

  final double cs;
  final double topInset;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22 * cs)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.primary, t.primaryDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CourtLinesPainter(
                  color: t.onPrimary.withValues(alpha: 0.075),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10 * cs,
                  topInset + 62 * cs,
                  10 * cs,
                  12 * cs,
                ),
                child: child,
              ),
            ),
            Positioned(
              top: topInset + 12 * cs,
              left: 24 * cs,
              right: 24 * cs,
              child: header,
            ),
          ],
        ),
      ),
    );
  }
}

/// Разметка теннисного корта тонкими линиями — наследие бренда вместо
/// орнамента: внешний контур, одиночные коридоры, сетка и линии подачи.
class _CourtLinesPainter extends CustomPainter {
  const _CourtLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.004)
      ..color = color;

    final court = Rect.fromLTRB(
      size.width * 0.07,
      size.height * 0.06,
      size.width * 0.93,
      size.height * 1.06, // дальняя половина уходит за скруглённый низ
    );
    canvas.drawRect(court, paint);

    // Одиночные коридоры.
    final alley = court.width * 0.125;
    canvas
      ..drawLine(
        Offset(court.left + alley, court.top),
        Offset(court.left + alley, court.bottom),
        paint,
      )
      ..drawLine(
        Offset(court.right - alley, court.top),
        Offset(court.right - alley, court.bottom),
        paint,
      );

    // Сетка и линия подачи с центральной линией.
    final net = court.top + court.height * 0.5;
    final service = court.top + court.height * 0.23;
    canvas
      ..drawLine(Offset(court.left, net), Offset(court.right, net), paint)
      ..drawLine(
        Offset(court.left + alley, service),
        Offset(court.right - alley, service),
        paint,
      )
      ..drawLine(
        Offset(court.center.dx, service),
        Offset(court.center.dx, net),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CourtLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Верхняя строка постера на зелёной стене: знак бренда (5 касаний —
/// настройка), язык, кнопка полноэкранного режима — всё в светлом варианте.
class _Header extends StatelessWidget {
  const _Header({
    required this.cs,
    required this.controller,
    required this.onWordmarkTap,
    required this.fullscreen,
    required this.onEnterFullscreen,
  });

  final double cs;
  final MirrorSessionController controller;
  final VoidCallback onWordmarkTap;
  final bool fullscreen;
  final VoidCallback? onEnterFullscreen;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onWordmarkTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8 * cs),
            child: MirrorBrandMark(height: 20 * cs, color: t.onPrimary),
          ),
        ),
        Row(
          children: [
            MirrorLangToggle(
              langCode: controller.shopperLang,
              onChanged: controller.setShopperLang,
              light: true,
            ),
            if (!fullscreen && onEnterFullscreen != null) ...[
              SizedBox(width: 10 * cs),
              SizedBox(
                width: 40 * cs,
                height: 40 * cs,
                child: Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.rButton),
                    side: BorderSide(
                      color: t.onPrimary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onEnterFullscreen,
                    child: Icon(
                      Icons.fullscreen_rounded,
                      size: 22 * cs,
                      color: t.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Видео-герой бренда: зациклённый ролик без звука, на паузе, пока постер
/// не виден. Один плеер на всё время жизни экрана.
class _VideoHero extends StatefulWidget {
  const _VideoHero({
    required this.asset,
    required this.active,
    required this.radius,
  });

  final String asset;
  final bool active;
  final double radius;

  @override
  State<_VideoHero> createState() => _VideoHeroState();
}

class _VideoHeroState extends State<_VideoHero> {
  VideoPlayerController? _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final video = VideoPlayerController.asset(widget.asset);
    _video = video;
    try {
      await video.initialize();
      await video.setLooping(true);
      await video.setVolume(0);
      if (!mounted) {
        await video.dispose();
        return;
      }
      if (widget.active) await video.play();
      setState(() => _ready = true);
    } catch (_) {
      // Видео не поднялось — остаёмся на цвете бренда, постер живёт.
    }
  }

  @override
  void didUpdateWidget(covariant _VideoHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active && _ready) {
      widget.active ? _video?.play() : _video?.pause();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: _ready && video != null
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
