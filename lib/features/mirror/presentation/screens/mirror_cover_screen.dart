import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_arch.dart';
import '../widgets/mirror_chrome.dart';

/// Экран 0 — постер (обложка). Два варианта сцены по бренду:
/// видео в арочном зеркале на светлой сцене ([MirrorVideoCover], LIBAS) или
/// студия с моделью ([MirrorCoverHero], Lacoste). Текст и кнопки общие.
///
/// Студия собрана по макету бренда: тёмно-зелёная
/// фотостудия с овальным стеклом и светом из окна, в центре — модель в образе
/// бренда, по бокам — карточки вещей, от которых к ней тянутся тонкие линии.
/// Сверху — крупный вопрос «А вам так пойдёт?», снизу — лаймовая кнопка.
///
/// Вся композиция считается от бокса модели (а не от экрана), поэтому на
/// телефоне и на планшете карточки и линии попадают в те же вещи. Анимации:
/// каскадный вход (как у онбординга), линии «дорисовываются», карточки
/// парят, свет из окна дышит, по стеклу и кнопке пробегает блик, стрелка на
/// кнопке подталкивает вправо. «Меньше движения» — статичная сцена.
class MirrorCoverScreen extends StatefulWidget {
  const MirrorCoverScreen({
    super.key,
    required this.controller,
    required this.onOpenSetup,
    this.active = true,
    this.fullscreen = false,
    this.onEnterFullscreen,
    this.playIntro = true,
  });

  final MirrorSessionController controller;
  final VoidCallback onOpenSetup;

  /// false, когда вкладка «Зеркало» скрыта — анимации останавливаются.
  final bool active;

  /// Полноэкранный киоск-режим: нижняя навигация продавца скрыта.
  /// Выход — только через скрытый шит настройки (5 касаний по знаку),
  /// чтобы покупатель не попал во вкладки продавца.
  final bool fullscreen;
  final VoidCallback? onEnterFullscreen;

  /// false — постер появляется сразу собранным, без каскадного входа. Так
  /// он открывается с экрана выбора оформления: превью уже «сыграло» вход и
  /// на глазах выросло до полного экрана.
  final bool playIntro;

  @override
  State<MirrorCoverScreen> createState() => _MirrorCoverScreenState();
}

class _MirrorCoverScreenState extends State<MirrorCoverScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Каскадный вход страницы (таймлайн 1.2с, как у слайдов онбординга).
  late final AnimationController _intro;

  /// Парение карточек, «дыхание» модели, стрелка на кнопке.
  late final AnimationController _ambient;

  /// Свет из окна.
  late final AnimationController _light;

  bool _lifecyclePaused = false;
  bool _reduceMotion = false;
  bool _synced = false;

  int _wordmarkTaps = 0;
  Timer? _tapResetTimer;

  /// Показан QR сайта (касание подписи «На базе Libas AI · libas.uz»).
  bool _siteQr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    );
    _light = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    if (!widget.playIntro) _intro.value = 1;
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
    _tapResetTimer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    _light.dispose();
    super.dispose();
  }

  /// Приводит анимации в соответствие с видимостью и настройкой «меньше
  /// движения». Идемпотентен.
  void _sync() {
    if (_reduceMotion) {
      _intro.value = 1;
      _ambient
        ..stop()
        ..value = 0;
      // 0 — яркая фаза света (см. Tween у слоя окна).
      _light
        ..stop()
        ..value = 0;
      return;
    }
    if (widget.active && !_lifecyclePaused) {
      if (_intro.value == 0 && !_intro.isAnimating) _intro.forward();
      if (!_ambient.isAnimating) _ambient.repeat(reverse: true);
      if (!_light.isAnimating) _light.repeat(reverse: true);
    } else {
      _ambient.stop();
      _light.stop();
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
      _tapResetTimer = Timer(
        const Duration(seconds: 2),
        () => _wordmarkTaps = 0,
      );
    }
  }

  /// Сцена видео-постера: светлый фон, дышащее свечение, арочное зеркало с
  /// роликом внутри, бегущая по стеклу полоса света, искры и плашка «AI».
  List<Widget> _videoStage(MirrorVideoCover v, _Geometry g, _SceneLook look) {
    final u = g.u;
    final arch = g.mirror(0.6);
    // Искры вокруг рамы: позиция в долях арки, размер в единицах макета.
    const sparkles = [
      (Offset(-0.13, 0.20), 30.0, 0.0),
      (Offset(1.10, 0.08), 20.0, 0.35),
      (Offset(1.13, 0.52), 34.0, 0.6),
      (Offset(-0.09, 0.66), 18.0, 0.8),
      (Offset(0.12, -0.035), 14.0, 0.2),
    ];
    return [
      RepaintBoundary(
        child: CustomPaint(
          painter: _VideoBackdropPainter(v: v, arch: arch, u: u),
        ),
      ),
      FadeTransition(
        opacity: Tween<double>(
          begin: 1,
          end: 0.45,
        ).animate(CurvedAnimation(parent: _light, curve: Curves.easeInOut)),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ArchGlowPainter(color: v.glow, arch: arch, u: u),
          ),
        ),
      ),
      Positioned.fromRect(
        rect: arch,
        child: Entrance(
          parent: _intro,
          kind: IntroEntranceKind.riseCard,
          delay: 0.16,
          duration: 0.75,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: const MirrorArchClipper(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: v.bgBottom),
                    _VideoHero(
                      asset: v.asset,
                      active: widget.active && !_lifecyclePaused,
                      aspect: v.aspect,
                      zoom: v.zoom,
                      poster: v.posterAsset,
                    ),
                    // Полоса света медленно проходит по стеклу сверху вниз.
                    AnimatedBuilder(
                      animation: _light,
                      builder: (context, child) => FractionalTranslation(
                        translation: Offset(
                          0,
                          -0.4 + 1.4 * Curves.easeInOut.transform(_light.value),
                        ),
                        child: child,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: 0.28,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gleam(
                      durationMs: 6400,
                      travelFraction: 0.4,
                      widthFraction: 0.3,
                      opacity: 0.22,
                      initialDelayMs: 1400,
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _ArchRimPainter(rim: v.rim, u: u),
                ),
              ),
            ],
          ),
        ),
      ),
      for (var i = 0; i < sparkles.length; i++)
        Positioned(
          left: arch.left +
              arch.width * sparkles[i].$1.dx -
              g.sz(sparkles[i].$2, 8) / 2,
          top: arch.top +
              arch.height * sparkles[i].$1.dy -
              g.sz(sparkles[i].$2, 8) / 2,
          child: Entrance(
            parent: _intro,
            kind: IntroEntranceKind.pop,
            delay: 0.5 + 0.06 * i,
            child: _Sparkle(
              size: g.sz(sparkles[i].$2, 8),
              color: v.glow,
              ambient: _ambient,
              phase: sparkles[i].$3,
            ),
          ),
        ),
      // Плашка «AI» сидит на раме справа сверху и слегка парит.
      Positioned(
        left: arch.left + arch.width * 0.80,
        top: arch.top + arch.height * 0.17,
        child: Entrance(
          parent: _intro,
          kind: IntroEntranceKind.badgePop,
          delay: 0.62,
          child: AnimatedBuilder(
            animation: _ambient,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, g.bob(_ambient.value, 0)),
              child: child,
            ),
            child: _AiChip(color: v.glow, text: v.text, u: u),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final brand = t.brand;
    final hero = brand.coverHero;
    final video = brand.videoCover;
    final lang = Localizations.localeOf(context).languageCode;
    final pad = MediaQuery.paddingOf(context);

    // Цвета сцены: видео-постер, студия бренда или палитра киоска.
    final look =
        video != null ? _SceneLook.video(video) : _SceneLook.of(t, hero);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: look.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: look.wallDeep,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final g = _Geometry.compute(
              size: constraints.biggest,
              padding: pad,
              modelAspect: hero?.modelAspect ?? 0.39,
            );
            final u = g.u;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (video != null)
                  ..._videoStage(video, g, look)
                else ...[
                  // Студия: стены, пол, подиум, овал стекла — статичный слой.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _StudioPainter(look: look, g: g),
                    ),
                  ),
                  // Свет из окна «дышит»: меняется только прозрачность уже
                  // растрированного слоя, размытие не пересчитывается.
                  // Цикл начинается с яркой фазы: первый кадр — как на макете.
                  FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0.58).animate(
                      CurvedAnimation(parent: _light, curve: Curves.easeInOut),
                    ),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _WindowLightPainter(look: look, g: g),
                      ),
                    ),
                  ),
                  // Блик по овальному стеклу.
                  Positioned.fromRect(
                    rect: g.ring,
                    child: const ClipOval(
                      child: Gleam(
                        durationMs: 7200,
                        travelFraction: 0.4,
                        widthFraction: 0.36,
                        opacity: 0.10,
                        initialDelayMs: 1800,
                      ),
                    ),
                  ),
                  if (hero != null) ...[
                    // Линии от карточек к вещам на модели.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ConnectorsPainter(
                            pieces: hero.pieces,
                            g: g,
                            color: look.text,
                            progress: CurvedAnimation(
                              parent: _intro,
                              curve: const Interval(
                                0.55,
                                0.95,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            ambient: _ambient,
                          ),
                        ),
                      ),
                    ),
                    // Модель.
                    Positioned.fromRect(
                      rect: g.model,
                      child: Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.riseCard,
                        delay: 0.16,
                        duration: 0.75,
                        child: AnimatedBuilder(
                          animation: _ambient,
                          builder: (context, child) => Transform.scale(
                            alignment: Alignment.bottomCenter,
                            scale: 1 +
                                0.006 *
                                    Curves.easeInOut.transform(_ambient.value),
                            child: child,
                          ),
                          child: Image.asset(
                            hero.modelAsset,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    // Карточки вещей.
                    for (var i = 0; i < hero.pieces.length; i++)
                      Positioned.fromRect(
                        rect: g.cardRect(hero.pieces[i]),
                        child: Entrance(
                          parent: _intro,
                          kind: hero.pieces[i].fromLeft
                              ? IntroEntranceKind.flyL
                              : IntroEntranceKind.flyR,
                          delay: 0.40 + 0.10 * i,
                          child: AnimatedBuilder(
                            animation: _ambient,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, g.bob(_ambient.value, i)),
                              child: child,
                            ),
                            child: _PieceCard(
                              piece: hero.pieces[i],
                              label: hero.pieces[i].labelFor(
                                lang,
                                brand.defaultLang,
                              ),
                              look: look,
                              u: u,
                            ),
                          ),
                        ),
                      ),
                    // «Вдохновение из коллекции».
                    Positioned(
                      left: g.captionLeft,
                      top: g.captionTop,
                      right: g.margin * 0.6,
                      child: Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.62,
                        child: _Caption(
                          text: l10n.mirrorCoverInspiration,
                          look: look,
                          size: g.sz(19, 10),
                        ),
                      ),
                    ),
                  ],
                ],

                // Шапка.
                Positioned(
                  top: pad.top + 30 * u,
                  left: g.margin,
                  right: g.margin,
                  child: Entrance(
                    parent: _intro,
                    kind: IntroEntranceKind.rise,
                    child: _Header(
                      g: g,
                      look: look,
                      controller: widget.controller,
                      onWordmarkTap: _onWordmarkTap,
                      fullscreen: widget.fullscreen,
                      onEnterFullscreen: widget.onEnterFullscreen,
                    ),
                  ),
                ),

                // Заголовок и подзаголовок.
                Positioned(
                  top: g.headlineTop,
                  left: g.margin,
                  right: g.margin,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.06,
                        child: _Headline(
                          text: l10n.mirrorCoverHeadline,
                          style: t
                              .label(
                                g.headlineSize,
                                weight: look.dark
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: look.text,
                              )
                              .copyWith(
                                height: _Geometry.headlineLeading,
                                letterSpacing: -0.02 * g.headlineSize,
                              ),
                          accent: look.headlineAccent,
                        ),
                      ),
                      SizedBox(height: _Geometry.gapHeadlineSubline * u),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.14,
                        child: Text(
                          l10n.mirrorCoverSubline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t
                              .subtitle(g.sublineSize, color: look.text)
                              .copyWith(height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

                // Низ: главная кнопка «Создать мой образ», вторая — выбор
                // из каталога, подпись Libas AI с сайтом.
                Positioned(
                  left: g.margin,
                  right: g.margin,
                  bottom: pad.bottom + _Geometry.bottomInset * u,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // riseCard, а не pop: кнопка во всю ширину, и перелёт
                      // масштаба 1.1 выносил бы её за поля экрана.
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.riseCard,
                        delay: 0.5,
                        child: _CoverCta(
                          label: l10n.mirrorCoverCta,
                          height: g.ctaHeight,
                          look: look,
                          ambient: _ambient,
                          // Главный путь: образ собирается по фото и
                          // ответам покупателя.
                          onTap: () =>
                              widget.controller.begin(MirrorPath.create),
                        ),
                      ),
                      SizedBox(height: _Geometry.gapCtaLink * u),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.6,
                        child: _SecondaryButton(
                          label: l10n.mirrorCoverCatalog,
                          icon: Icons.checkroom_rounded,
                          height: g.secondaryHeight,
                          look: look,
                          // Второй путь: покупатель сам выбирает вещи зала.
                          onTap: () =>
                              widget.controller.begin(MirrorPath.catalog),
                        ),
                      ),
                      SizedBox(height: _Geometry.gapLinkPowered * u),
                      Entrance(
                        parent: _intro,
                        kind: IntroEntranceKind.rise,
                        delay: 0.7,
                        child: _PoweredBy(
                          label: l10n.mirrorPoweredBy,
                          size: g.poweredSize,
                          look: look,
                          onTap: () => setState(() => _siteQr = true),
                        ),
                      ),
                    ],
                  ),
                ),

                // QR сайта поверх постера: киоск не уходит в браузер —
                // покупатель открывает сайт у себя в телефоне.
                if (_siteQr)
                  Positioned.fill(
                    child: _SiteQrOverlay(
                      onClose: () => setState(() => _siteQr = false),
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

/// Цвета сцены: из [MirrorCoverHero] бренда либо собранные из палитры киоска.
class _SceneLook {
  const _SceneLook({
    required this.wall,
    required this.wallLight,
    required this.wallDeep,
    required this.floor,
    required this.podium,
    required this.podiumTop,
    required this.ring,
    required this.glass,
    required this.card,
    required this.onCard,
    required this.text,
    required this.textMuted,
    required this.cta,
    required this.onCta,
    required this.pillBg,
    required this.pillBorder,
    required this.onText,
    this.dark = true,
    this.headlineAccent,
    this.ctaGradient,
  });

  /// Светлая сцена видео-постера.
  factory _SceneLook.video(MirrorVideoCover v) => _SceneLook(
        wall: v.bgTop,
        wallLight: v.bgTop,
        wallDeep: v.bgBottom,
        floor: v.bgBottom,
        podium: v.bgBottom,
        podiumTop: v.bgTop,
        ring: v.rim,
        glass: v.bgTop,
        card: Colors.white,
        onCard: v.text,
        text: v.text,
        textMuted: v.textMuted,
        cta: v.cta,
        onCta: v.onCta,
        pillBg: Colors.white.withValues(alpha: 0.82),
        pillBorder: v.text.withValues(alpha: 0.10),
        onText: Colors.white,
        dark: false,
        headlineAccent: v.headlineAccent,
        ctaGradient: v.ctaGradient,
      );

  factory _SceneLook.of(MirrorTheme t, MirrorCoverHero? hero) {
    if (hero != null) {
      return _SceneLook(
        wall: hero.wall,
        wallLight: hero.wallLight,
        wallDeep: hero.wallDeep,
        floor: hero.floor,
        podium: hero.podium,
        podiumTop: hero.podiumTop,
        ring: hero.ring,
        glass: hero.glass,
        card: hero.card,
        onCard: hero.onCard,
        text: hero.text,
        textMuted: hero.textMuted,
        cta: hero.cta,
        onCta: hero.onCta,
        pillBg: hero.wallDeep.withValues(alpha: 0.6),
        pillBorder: hero.text.withValues(alpha: 0.22),
        onText: hero.onCta,
      );
    }
    return _SceneLook(
      wall: t.primary,
      wallLight: t.primaryBright,
      wallDeep: t.primaryDeep,
      floor: t.primaryBright,
      podium: t.primaryBright,
      podiumTop: t.primaryBright,
      ring: t.onPrimary,
      glass: t.primaryBright,
      card: t.surface,
      onCard: t.ink,
      text: t.onPrimary,
      textMuted: t.onPrimary.withValues(alpha: 0.6),
      cta: t.onPrimary,
      onCta: t.primaryDeep,
      pillBg: t.primaryDeep.withValues(alpha: 0.6),
      pillBorder: t.onPrimary.withValues(alpha: 0.22),
      onText: t.primaryDeep,
    );
  }

  final Color wall;
  final Color wallLight;
  final Color wallDeep;
  final Color floor;
  final Color podium;
  final Color podiumTop;
  final Color ring;
  final Color glass;
  final Color card;
  final Color onCard;
  final Color text;
  final Color textMuted;
  final Color cta;
  final Color onCta;

  /// Фон и рамка переключателя языка и круглой кнопки в шапке.
  final Color pillBg;
  final Color pillBorder;

  /// Текст поверх заливки цветом [text] (выбранный язык).
  final Color onText;

  /// Тёмная сцена: светлые статус-бар и текст.
  final bool dark;

  /// Цвет второй строки заголовка.
  final Color? headlineAccent;

  /// Градиент главной кнопки.
  final List<Color>? ctaGradient;
}

/// Геометрия постера. Макет — 941×1672; единица [u] ограничена и шириной, и
/// высотой, чтобы композиция помещалась и на телефоне, и на планшете. Бокс
/// модели занимает всё место между текстом сверху и блоком кнопки снизу, а
/// карточки, линии, подпись и овал стекла считаются от него.
class _Geometry {
  _Geometry._({
    required this.size,
    required this.u,
    required this.margin,
    required this.headlineTop,
    required this.headlineSize,
    required this.sublineSize,
    required this.ctaHeight,
    required this.secondaryHeight,
    required this.poweredSize,
    required this.model,
  });

  factory _Geometry.compute({
    required Size size,
    required EdgeInsets padding,
    required double modelAspect,
  }) {
    final usable = size.height - padding.top - padding.bottom;
    final u = math.min(size.width / 941, usable / 1672);
    double sz(double design, double min) => math.max(design * u, min);

    final margin = math.max(62 * u, 20.0);
    final headlineTop = padding.top + 110 * u;
    final headlineSize = 88 * u;
    final sublineSize = sz(31, 12.5);
    final ctaHeight = sz(96, 54);
    final secondaryHeight = sz(80, 48);
    final poweredSize = sz(19, 10);

    // Верх: шапка + заголовок в две строки + подзаголовок.
    final topBlockBottom = headlineTop +
        headlineSize * headlineLeading * 2 +
        gapHeadlineSubline * u +
        sublineSize * 1.3;
    // Низ: строка «фото → образ», кнопка, ссылка, подпись. Высоты — те же,
    // что дают виджеты (label: 1.1, subtitle: 1.5, ссылка — см.
    // вторая кнопка — [secondaryHeight]).
    final bottomBlock = ctaHeight +
        gapCtaLink * u +
        secondaryHeight +
        gapLinkPowered * u +
        _PoweredBy.boxHeight(poweredSize) +
        bottomInset * u;

    final modelTop = topBlockBottom + 4 * u;
    final modelBottom =
        size.height - padding.bottom - bottomBlock - gapModelCta * u;
    final modelHeight = math.max(modelBottom - modelTop, 80.0);
    final modelWidth = modelHeight * modelAspect;
    final model = Rect.fromLTWH(
      size.width * 0.53 - modelWidth / 2,
      modelTop,
      modelWidth,
      modelHeight,
    );

    return _Geometry._(
      size: size,
      u: u,
      margin: margin,
      headlineTop: headlineTop,
      headlineSize: headlineSize,
      sublineSize: sublineSize,
      ctaHeight: ctaHeight,
      secondaryHeight: secondaryHeight,
      poweredSize: poweredSize,
      model: model,
    );
  }

  // Отступы макета в единицах [u] — общие для расчёта бокса модели и для
  // самой вёрстки, чтобы они не разъехались.
  static const double headlineLeading = 0.9;
  static const double gapHeadlineSubline = 12;
  static const double gapModelCta = 30;
  static const double gapCtaLink = 14;
  static const double gapLinkPowered = 14;
  static const double bottomInset = 30;

  final Size size;
  final double u;
  final double margin;
  final double headlineTop;
  final double headlineSize;
  final double sublineSize;
  final double ctaHeight;

  /// Высота второй кнопки «Создать мой образ».
  final double secondaryHeight;
  final double poweredSize;

  /// Бокс картинки модели.
  final Rect model;

  double sz(double design, double min) => math.max(design * u, min);

  /// Точка в долях бокса модели → координаты экрана.
  Offset at(Offset fraction) => Offset(
        model.left + model.width * fraction.dx,
        model.top + model.height * fraction.dy,
      );

  /// Карточка вещи: размер — от высоты модели, по горизонтали не выходит за
  /// поля экрана (на телефоне макетные позиции лежат за краем).
  Rect cardRect(MirrorCoverPiece piece) {
    final w = model.height * 0.184;
    final h = model.height * 0.2564;
    final c = at(piece.card);
    final minX = margin * 0.7 + w / 2;
    final maxX = size.width - margin * 0.7 - w / 2;
    return Rect.fromCenter(
      center: Offset(c.dx.clamp(minX, math.max(minX, maxX)), c.dy),
      width: w,
      height: h,
    );
  }

  /// Парение карточки [index]: соседние качаются в противофазе.
  double bob(double ambient, int index) =>
      -6 * u * Curves.easeInOut.transform(ambient) * (index.isEven ? 1 : -1);

  /// Овал стекла за моделью.
  Rect get ring => Rect.fromCenter(
        center: at(const Offset(0.722, 0.217)),
        width: model.height * 0.311 * 2,
        height: model.height * 0.452 * 2,
      );

  /// Арочное зеркало видео-постера: занимает высоту бокса модели, по
  /// ширине — не больше [aspect] от высоты и с полями от краёв экрана.
  Rect mirror(double aspect) {
    final h = model.height * 0.98;
    final w = math.min(h * aspect, size.width - margin * 2.6);
    return Rect.fromLTWH(size.width / 2 - w / 2, model.top + 4 * u, w, h);
  }

  /// Линия пола (стык стены и пола).
  double get floorY => model.top + model.height * 0.856;

  double get captionLeft => model.left + model.width * 0.872;
  double get captionTop => model.top + model.height * 0.134;
}

/// Студия: стена с мягким светом справа, пол, подиум слева, тень под моделью
/// и овальное стекло. Рисуется один раз (RepaintBoundary).
class _StudioPainter extends CustomPainter {
  const _StudioPainter({required this.look, required this.g});

  final _SceneLook look;
  final _Geometry g;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final u = g.u;

    // Стена.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            look.wall,
            Color.lerp(look.wall, look.wallDeep, 0.35)!,
            look.wallDeep,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    // Рассеянный свет от окна справа сверху.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.95, -0.55),
          radius: 1.1,
          colors: [
            look.wallLight.withValues(alpha: 0.75),
            look.wallLight.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    // Пол.
    final floorRect = Rect.fromLTRB(0, g.floorY, size.width, size.height);
    canvas
      ..drawRect(
        floorRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              look.floor,
              Color.lerp(look.floor, look.wallDeep, 0.6)!,
              look.wallDeep,
            ],
            stops: const [0, 0.45, 1],
          ).createShader(floorRect),
      )
      ..drawRect(
        Rect.fromLTWH(0, g.floorY - 1, size.width, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.05),
      );

    _paintPodium(canvas, size);
    _paintRing(canvas);

    // Контактная тень под ногами модели.
    final m = g.model;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(m.center.dx, m.bottom - m.height * 0.012),
        width: m.width * 0.95,
        height: m.height * 0.035,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * u),
    );
  }

  /// Подиум слева: высокий блок у края и широкая тумба перед ним.
  void _paintPodium(Canvas canvas, Size size) {
    final m = g.model;
    final u = g.u;
    final top = m.top + m.height * 0.646;
    final bottom = g.floorY + m.height * 0.022;
    final right = math.max(m.left + m.width * 0.03, size.width * 0.2);
    final lip = 16 * u;

    // Высокий блок.
    final blockTop = m.top + m.height * 0.455;
    final block = Rect.fromLTRB(0, blockTop, 65 * u, top - lip);
    canvas
      ..drawRect(
        block,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(look.podium, look.wallDeep, 0.45)!,
              Color.lerp(look.podium, look.wallDeep, 0.72)!,
            ],
          ).createShader(block),
      )
      ..drawRect(
        Rect.fromLTRB(0, blockTop - 8 * u, 65 * u, blockTop),
        Paint()..color = look.podiumTop.withValues(alpha: 0.45),
      );

    // Тень тумбы на полу.
    canvas.drawRect(
      Rect.fromLTRB(0, bottom - 6 * u, right + 40 * u, bottom + 14 * u),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * u),
    );
    // Фасад тумбы.
    final front = Rect.fromLTRB(0, top, right, bottom);
    canvas
      ..drawRect(
        front,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(look.podium, look.wallDeep, 0.12)!,
              Color.lerp(look.podium, look.wallDeep, 0.78)!,
            ],
          ).createShader(front),
      )
      // Правый край тумбы уходит в тень от модели.
      ..drawRect(
        front,
        Paint()
          ..shader = LinearGradient(
            colors: [
              look.wallDeep.withValues(alpha: 0),
              look.wallDeep.withValues(alpha: 0.55),
            ],
            stops: const [0.55, 1],
          ).createShader(front),
      );
    // Верхняя грань — светлее, сходит на нет вправо.
    final topFace = Rect.fromLTRB(0, top - lip, right, top);
    canvas.drawRect(
      topFace,
      Paint()
        ..shader = LinearGradient(
          colors: [
            look.podiumTop,
            Color.lerp(look.podiumTop, look.podium, 0.6)!,
          ],
        ).createShader(topFace),
    );
  }

  /// Овальное стекло: лёгкая заливка, тонкий светлый обод, внутренний блик.
  void _paintRing(Canvas canvas) {
    final ring = g.ring;
    final u = g.u;

    canvas
      ..drawOval(
        ring,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              look.glass.withValues(alpha: 0.55),
              look.glass.withValues(alpha: 0.10),
            ],
          ).createShader(ring),
      )
      // Мягкое свечение обода.
      ..drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * u
          ..color = look.ring.withValues(alpha: 0.14)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * u),
      )
      // Обод стекла: свет из окна ложится на левую верхнюю дугу — там обод
      // почти белый, по остальному овалу он тонет в стене. Развёртка идёт по
      // часовой от «3 часов»: 0.5 — слева, 0.75 — сверху.
      ..drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4.5 * u, 1.6)
          ..shader = SweepGradient(
            colors: [
              // Правый край ловит свет окна — тёплая золотистая кромка.
              Color.lerp(look.ring, Colors.white, 0.35)!,
              look.ring.withValues(alpha: 0.45),
              look.ring.withValues(alpha: 0.22),
              look.ring.withValues(alpha: 0.50),
              Color.lerp(look.ring, Colors.white, 0.70)!,
              Color.lerp(look.ring, Colors.white, 0.55)!,
              look.ring.withValues(alpha: 0.55),
              Color.lerp(look.ring, Colors.white, 0.25)!,
              Color.lerp(look.ring, Colors.white, 0.35)!,
            ],
            stops: const [0, 0.10, 0.25, 0.46, 0.60, 0.72, 0.84, 0.94, 1],
          ).createShader(ring),
      )
      // Тонкая яркая кромка поверх — «толщина» стекла на освещённой дуге.
      ..drawArc(
        ring.deflate(1.2 * u),
        math.pi * 1.04,
        math.pi * 0.50,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.6 * u, 0.9)
          ..color = Colors.white.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8 * u),
      )
      // Внутренний блик по левому верхнему краю.
      ..drawArc(
        ring.deflate(11 * u),
        math.pi * 1.02,
        math.pi * 0.42,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4 * u, 0.8)
          ..color = Colors.white.withValues(alpha: 0.13),
      );
  }

  @override
  bool shouldRepaint(_StudioPainter oldDelegate) =>
      oldDelegate.g.size != g.size ||
      oldDelegate.g.model != g.model ||
      oldDelegate.look != look;
}

/// Свет из окна: наклонённая сетка мягких пятен на стене справа и полосы на
/// полу. Статичный слой — «дыхание» делает прозрачность снаружи.
class _WindowLightPainter extends CustomPainter {
  const _WindowLightPainter({required this.look, required this.g});

  final _SceneLook look;
  final _Geometry g;

  @override
  void paint(Canvas canvas, Size size) {
    final u = g.u;
    // Солнечный зелёный: стена, подсвеченная тёплым светом.
    final light = Color.lerp(look.wallLight, look.cta, 0.5)!;
    final ring = g.ring;

    // Окно привязано к овалу стекла: на макете свет лежит на его правой
    // половине — чёткая колонка из четырёх стёкол и вторая, слабее, правее.
    const rows = 4;
    final paneH = ring.height * 0.115;
    final gap = ring.height * 0.020;
    final top = ring.top + ring.height * 0.07;
    final columns = <({double left, double width, double strength})>[
      (left: 0.715, width: 0.103, strength: 1.0),
      (left: 0.842, width: 0.092, strength: 0.5),
    ];

    canvas
      ..save()
      ..translate(ring.left, top)
      ..skew(-0.035, 0);
    for (final column in columns) {
      for (var row = 0; row < rows; row++) {
        // Ярче сверху, к полу свет рассеивается и мягчеет.
        final k = 1 - row / rows;
        canvas.drawRect(
          Rect.fromLTWH(
            ring.width * column.left,
            row * (paneH + gap),
            ring.width * column.width,
            paneH,
          ),
          Paint()
            ..color = light.withValues(
              alpha: (0.20 + 0.36 * k) * column.strength,
            )
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (3 + 2.5 * row) * u,
            ),
        );
      }
    }
    canvas.restore();

    // Общий мягкий луч от окна — наискось через правую половину овала.
    final beam = Rect.fromLTWH(
      ring.left + ring.width * 0.62,
      ring.top,
      ring.width * 0.46,
      ring.height * 0.72,
    );
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [light.withValues(alpha: 0.20), light.withValues(alpha: 0)],
        ).createShader(beam)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * u),
    );

    // Полосы света на полу: широкая справа и короткая слева, у подиума.
    final mh = g.model.height;
    final w = size.width;
    final fy = g.floorY;
    final right = Path()
      ..moveTo(w * 0.52, fy + mh * 0.012)
      ..lineTo(w * 1.04, fy + mh * 0.012)
      ..lineTo(w * 1.04, fy + mh * 0.055)
      ..lineTo(w * 0.40, fy + mh * 0.055)
      ..close();
    final left = Path()
      ..moveTo(-w * 0.04, fy + mh * 0.046)
      ..lineTo(w * 0.44, fy + mh * 0.046)
      ..lineTo(w * 0.35, fy + mh * 0.080)
      ..lineTo(-w * 0.04, fy + mh * 0.080)
      ..close();
    canvas
      ..drawPath(
        right,
        Paint()
          ..color = light.withValues(alpha: 0.32)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 13 * u),
      )
      ..drawPath(
        left,
        Paint()
          ..color = light.withValues(alpha: 0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 13 * u),
      );
  }

  @override
  bool shouldRepaint(_WindowLightPainter oldDelegate) =>
      oldDelegate.g.size != g.size ||
      oldDelegate.g.model != g.model ||
      oldDelegate.look != look;
}

/// Тонкие линии от карточек к вещам на модели: «дорисовываются» на входе,
/// начало следует за парящей карточкой, на конце пульсирует точка.
class _ConnectorsPainter extends CustomPainter {
  _ConnectorsPainter({
    required this.pieces,
    required this.g,
    required this.color,
    required this.progress,
    required this.ambient,
  }) : super(repaint: Listenable.merge([progress, ambient]));

  final List<MirrorCoverPiece> pieces;
  final _Geometry g;
  final Color color;
  final Animation<double> progress;
  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0) return;
    final u = g.u;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6 * u, 1.0)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85);

    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      final card = g.cardRect(piece).shift(Offset(0, g.bob(ambient.value, i)));
      final start = Offset(
        piece.fromLeft ? card.right : card.left,
        card.top + card.height * piece.anchor,
      );
      final end = g.at(piece.target);
      // Линия выходит из карточки горизонтально и дугой заворачивает к вещи.
      final control = Offset(start.dx + (end.dx - start.dx) * 0.72, start.dy);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      final PathMetric metric = path.computeMetrics().first;
      canvas.drawPath(metric.extractPath(0, metric.length * p), line);

      if (p >= 1) {
        final pulse = Curves.easeInOut.transform(ambient.value);
        canvas
          ..drawCircle(
            end,
            (5 + 5 * pulse) * u,
            Paint()..color = color.withValues(alpha: 0.18 * (1 - pulse * 0.6)),
          )
          ..drawCircle(end, math.max(3.2 * u, 2.0), Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorsPainter oldDelegate) =>
      oldDelegate.g.model != g.model ||
      oldDelegate.pieces != pieces ||
      oldDelegate.color != color;
}

/// Кремовая карточка вещи: фото и подпись.
class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.label,
    required this.look,
    required this.u,
  });

  final MirrorCoverPiece piece;
  final String label;
  final _SceneLook look;
  final double u;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.card,
        borderRadius: BorderRadius.circular(18 * u),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30 * u,
            spreadRadius: -8 * u,
            offset: Offset(0, 16 * u),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * u),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4 * u, 10 * u, 4 * u, 0),
                child: Image.asset(
                  piece.asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4 * u, bottom: 14 * u),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label(
                  math.max(24 * u, 11),
                  weight: FontWeight.w500,
                  color: look.onCard,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Вдохновение из коллекции» — маленькая серифная подпись с линейкой.
class _Caption extends StatelessWidget {
  const _Caption({required this.text, required this.look, required this.size});

  final String text;
  final _SceneLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          maxLines: 2,
          style: t
              .headline(size, color: look.text.withValues(alpha: 0.85))
              .copyWith(height: 1.25, letterSpacing: 0.2),
        ),
        SizedBox(height: size * 0.55),
        Container(
          width: size * 2.2,
          height: 1,
          color: look.text.withValues(alpha: 0.55),
        ),
      ],
    );
  }
}

/// Шапка: знак бренда (5 касаний — настройка), язык, полноэкранный режим.
class _Header extends StatelessWidget {
  const _Header({
    required this.g,
    required this.look,
    required this.controller,
    required this.onWordmarkTap,
    required this.fullscreen,
    required this.onEnterFullscreen,
  });

  final _Geometry g;
  final _SceneLook look;
  final MirrorSessionController controller;
  final VoidCallback onWordmarkTap;
  final bool fullscreen;
  final VoidCallback? onEnterFullscreen;

  @override
  Widget build(BuildContext context) {
    final pillHeight = g.sz(46, 32);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onWordmarkTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6 * g.u),
            child: MirrorBrandMark(height: g.sz(36, 18), color: look.text),
          ),
        ),
        Row(
          children: [
            _LangPill(
              height: pillHeight,
              look: look,
              langCode: controller.shopperLang,
              onChanged: controller.setShopperLang,
            ),
            if (!fullscreen && onEnterFullscreen != null) ...[
              SizedBox(width: 10 * g.u),
              SizedBox(
                width: pillHeight,
                height: pillHeight,
                child: Material(
                  color: look.pillBg,
                  shape: CircleBorder(side: BorderSide(color: look.pillBorder)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onEnterFullscreen,
                    child: Icon(
                      Icons.fullscreen_rounded,
                      size: pillHeight * 0.52,
                      color: look.text,
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

/// Переключатель языка по макету: тёмная пилюля, выбранный язык — кремовой
/// пилюлей внутри, между языками тонкий разделитель.
class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.height,
    required this.look,
    required this.langCode,
    required this.onChanged,
  });

  final double height;
  final _SceneLook look;
  final String langCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final languages = t.brand.languages;
    if (languages.length < 2) return const SizedBox.shrink();
    final fontSize = height * 0.40;

    return Container(
      height: height,
      padding: EdgeInsets.all(height * 0.09),
      decoration: BoxDecoration(
        color: look.pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: look.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < languages.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: height * 0.36,
                margin: EdgeInsets.symmetric(horizontal: height * 0.10),
                color: look.text.withValues(alpha: 0.3),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(languages[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: height * 0.42),
                decoration: BoxDecoration(
                  color:
                      languages[i] == langCode ? look.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  MirrorBrand.langLabel(languages[i]),
                  style: t.label(
                    fontSize,
                    weight: languages[i] == langCode
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: languages[i] == langCode ? look.onText : look.text,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Главная кнопка постера: лаймовая пилюля с мягким свечением, бликом и
/// стрелкой, которая подталкивает вправо.
class _CoverCta extends StatefulWidget {
  const _CoverCta({
    required this.label,
    required this.height,
    required this.look,
    required this.ambient,
    required this.onTap,
  });

  final String label;
  final double height;
  final _SceneLook look;
  final Animation<double> ambient;
  final VoidCallback onTap;

  @override
  State<_CoverCta> createState() => _CoverCtaState();
}

class _CoverCtaState extends State<_CoverCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final look = widget.look;
    final h = widget.height;
    final fontSize = h * 0.42;
    final style = t.label(fontSize, weight: FontWeight.w700, color: look.onCta);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedBuilder(
        animation: widget.ambient,
        builder: (context, child) {
          final pulse = Curves.easeInOut.transform(widget.ambient.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: look.cta.withValues(alpha: 0.18 + 0.16 * pulse),
                  blurRadius: h * (0.35 + 0.2 * pulse),
                  spreadRadius: -h * 0.08,
                  offset: Offset(0, h * 0.12),
                ),
              ],
            ),
            child: child,
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: h,
          child: Material(
            color: look.ctaGradient == null ? look.cta : Colors.transparent,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: look.onCta.withValues(alpha: 0.10),
              highlightColor: look.onCta.withValues(alpha: 0.05),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (look.ctaGradient case final colors?)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                        ),
                      ),
                    ),
                  const Positioned.fill(
                    child: Gleam(
                      durationMs: 4200,
                      travelFraction: 0.45,
                      widthFraction: 0.28,
                      opacity: 0.55,
                      initialDelayMs: 1600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      SizedBox(width: fontSize * 0.45),
                      AnimatedBuilder(
                        animation: widget.ambient,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                            fontSize *
                                0.22 *
                                Curves.easeInOut.transform(
                                  widget.ambient.value,
                                ),
                            0,
                          ),
                          child: child,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: fontSize * 1.15,
                          color: look.onCta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Вторая кнопка — контурная пилюля под главной, с иконкой. Не спорит с
/// главной, но это полноценная кнопка, а не ссылка.
class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.height,
    required this.look,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double height;
  final _SceneLook look;
  final VoidCallback onTap;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final look = widget.look;
    final h = widget.height;
    final fontSize = h * 0.36;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        height: h,
        child: Material(
          color: look.pillBg,
          shape: StadiumBorder(
            side: BorderSide(
              color: look.text.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: look.text.withValues(alpha: 0.08),
            highlightColor: look.text.withValues(alpha: 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: fontSize * 1.1,
                  color: look.headlineAccent ?? look.text,
                ),
                SizedBox(width: fontSize * 0.45),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label(
                      fontSize,
                      weight: FontWeight.w700,
                      color: look.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Сайт Libas AI: подпись внизу постера ведёт на него через QR.
const String _libasSite = 'libas.uz';
const String _libasSiteUrl = 'https://libas.uz';

/// Подпись «На базе Libas AI · libas.uz» — нажимается и показывает QR сайта.
class _PoweredBy extends StatelessWidget {
  const _PoweredBy({
    required this.label,
    required this.size,
    required this.look,
    required this.onTap,
  });

  final String label;
  final double size;
  final _SceneLook look;
  final VoidCallback onTap;

  /// Высота с полями касания — нужна расчёту бокса модели.
  static double boxHeight(double size) => size * 1.4 + size * 1.2;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final muted = t.label(size, weight: FontWeight.w500, color: look.textMuted);
    return Semantics(
      button: true,
      label: '$label · $_libasSite',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size,
            vertical: size * 0.6,
          ),
          child: Text.rich(
            TextSpan(
              style: muted.copyWith(height: 1.4),
              children: [
                TextSpan(text: '$label · '),
                TextSpan(
                  text: _libasSite,
                  style: TextStyle(
                    color: look.text,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: look.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// QR сайта Libas AI поверх постера. Закрывается касанием или сам через
/// 15 секунд — постер не должен застрять с открытой карточкой.
class _SiteQrOverlay extends StatefulWidget {
  const _SiteQrOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_SiteQrOverlay> createState() => _SiteQrOverlayState();
}

class _SiteQrOverlayState extends State<_SiteQrOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 15), widget.onClose);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final qr = 180 * s;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => ColoredBox(
          color: Colors.black.withValues(alpha: 0.45 * v),
          child: Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
          ),
        ),
        child: Center(
          child: Container(
            width: qr + 56 * s,
            padding: EdgeInsets.fromLTRB(28 * s, 28 * s, 28 * s, 22 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40 * s,
                  offset: Offset(0, 16 * s),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR всегда чернилами на белом — сканеру нужен контраст.
                QrImageView(
                  data: _libasSiteUrl,
                  size: qr,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF111111),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 16 * s),
                Text(
                  _libasSite,
                  style: t.label(22 * s,
                      weight: FontWeight.w800, color: const Color(0xFF111111)),
                ),
                SizedBox(height: 6 * s),
                Text(
                  l10n.mirrorSiteQrHint,
                  textAlign: TextAlign.center,
                  style: t
                      .label(14 * s,
                          weight: FontWeight.w500,
                          color: const Color(0xFF5C5C5C))
                      .copyWith(height: 1.35),
                ),
                SizedBox(height: 14 * s),
                Icon(
                  Icons.close_rounded,
                  size: 24 * s,
                  color: const Color(0xFF8A8A8A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Видео бренда: зациклённый ролик без звука, заполняет свой бокс (обрезка
/// по краям, увеличение [zoom] от нижнего края). Пока плеер не готов — первый
/// кадр картинкой [poster]. На паузе, пока постер не виден. Один плеер на всё
/// время жизни экрана.
class _VideoHero extends StatefulWidget {
  const _VideoHero({
    required this.asset,
    required this.active,
    required this.aspect,
    this.zoom = 1.0,
    this.poster,
  });

  final String asset;
  final bool active;
  final double aspect;
  final double zoom;
  final String? poster;

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
      // Видео не поднялось — остаётся первый кадр, постер живёт.
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
    final poster = widget.poster;
    final Widget frame;
    if (_ready && video != null) {
      frame = SizedBox(
        width: video.value.size.width,
        height: video.value.size.height,
        child: VideoPlayer(video),
      );
    } else if (poster != null) {
      frame = SizedBox(
        width: 1000 * widget.aspect,
        height: 1000,
        child: Image.asset(poster, fit: BoxFit.fill),
      );
    } else {
      return const SizedBox.expand();
    }
    return ClipRect(
      child: Transform.scale(
        scale: widget.zoom,
        alignment: Alignment.bottomCenter,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: frame,
        ),
      ),
    );
  }
}

/// Заголовок постера: первая строка цветом текста, остальные — [accent].
class _Headline extends StatelessWidget {
  const _Headline({required this.text, required this.style, this.accent});

  final String text;
  final TextStyle style;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent;
    final split = text.indexOf('\n');
    if (color == null || split < 0) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, split + 1)),
          TextSpan(
            text: text.substring(split + 1),
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

/// Фон видео-постера: вертикальный градиент и два больших размытых пятна
/// цвета бренда за зеркалом. Статичный слой.
class _VideoBackdropPainter extends CustomPainter {
  const _VideoBackdropPainter({
    required this.v,
    required this.arch,
    required this.u,
  });

  final MirrorVideoCover v;
  final Rect arch;
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [v.bgTop, v.bgBottom],
        ).createShader(rect),
    );
    final blob = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 70 * u);
    canvas
      ..drawCircle(
        Offset(arch.left - arch.width * 0.05, arch.top + arch.height * 0.25),
        arch.width * 0.42,
        blob..color = v.glow.withValues(alpha: 0.16),
      )
      ..drawCircle(
        Offset(arch.right + arch.width * 0.02, arch.top + arch.height * 0.7),
        arch.width * 0.5,
        blob..color = v.glow.withValues(alpha: 0.13),
      )
      // Тень под зеркалом на «полу».
      ..drawOval(
        Rect.fromCenter(
          center: Offset(arch.center.dx, arch.bottom + 6 * u),
          width: arch.width * 1.05,
          height: 34 * u,
        ),
        Paint()
          ..color = v.text.withValues(alpha: 0.10)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * u),
      );
  }

  @override
  bool shouldRepaint(_VideoBackdropPainter old) =>
      old.arch != arch || old.v != v || old.u != u;
}

/// Подсветка зеркала: широкое свечение за рамкой. Статичный слой — «дышит»
/// через прозрачность снаружи.
class _ArchGlowPainter extends CustomPainter {
  const _ArchGlowPainter({
    required this.color,
    required this.arch,
    required this.u,
  });

  final Color color;
  final Rect arch;
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final path = mirrorArchPath(arch.size).shift(arch.topLeft);
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30 * u
          ..color = color.withValues(alpha: 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * u),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * u
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * u),
      );
  }

  @override
  bool shouldRepaint(_ArchGlowPainter old) =>
      old.arch != arch || old.color != color || old.u != u;
}

/// Рама зеркала: белый борт и тонкая светящаяся линия внутри — как
/// LED-подсветка у зеркала в ролике.
class _ArchRimPainter extends CustomPainter {
  const _ArchRimPainter({required this.rim, required this.u});

  final Color rim;
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = math.max(9 * u, 4.0);
    final outer = mirrorArchPath(size);
    canvas
      ..drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame
          ..color = Colors.white,
      )
      ..drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2 * u, 0.8)
          ..color = rim.withValues(alpha: 0.25),
      );
    final inset = frame * 0.5 + math.max(5 * u, 2.5);
    final inner = mirrorArchPath(
      Size(size.width - inset * 2, size.height - inset * 2),
    ).shift(Offset(inset, inset));
    canvas
      ..drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(6 * u, 3.0)
          ..color = Colors.white.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * u),
      )
      ..drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2 * u, 1.2)
          ..color = Colors.white.withValues(alpha: 0.95),
      );
  }

  @override
  bool shouldRepaint(_ArchRimPainter old) => old.rim != rim || old.u != u;
}

/// Четырёхлучевая искра, мерцает на общем «дыхании» экрана со своей фазой.
class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.size,
    required this.color,
    required this.ambient,
    required this.phase,
  });

  final double size;
  final Color color;
  final Animation<double> ambient;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final v = (math.sin((ambient.value + phase) * math.pi * 2) + 1) / 2;
        return Opacity(
          opacity: 0.35 + 0.65 * v,
          child: Transform.scale(scale: 0.65 + 0.35 * v, child: child),
        );
      },
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final k = r * 0.22;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k * 0.35, c.dy - k * 0.35, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k * 0.35, c.dy + k * 0.35, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k * 0.35, c.dy + k * 0.35, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k * 0.35, c.dy - k * 0.35, c.dx, c.dy - r)
      ..close();
    canvas
      ..drawCircle(
        c,
        r * 0.55,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      )
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// Плашка «AI» на раме зеркала.
class _AiChip extends StatelessWidget {
  const _AiChip({required this.color, required this.text, required this.u});

  final Color color;
  final Color text;
  final double u;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final size = math.max(22 * u, 12.0);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.7,
        vertical: size * 0.38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: size * 1.2,
            offset: Offset(0, size * 0.3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size.square(size * 0.95),
            painter: _SparklePainter(color),
          ),
          SizedBox(width: size * 0.35),
          Text(
            'AI',
            style: t.label(size, weight: FontWeight.w800, color: text),
          ),
        ],
      ),
    );
  }
}
