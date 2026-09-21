import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';
import '../widgets/mirror_cover_look_card.dart';

/// Экран 0 — постер (обложка). Показывает результат до старта: «образ
/// момента» из реальных вещей зала, серифный заголовок, три шага и одну
/// главную кнопку. Заголовок и образ меняются одним «ударом сердца» раз в
/// шесть секунд; при выключенных анимациях — без переходов и вдвое реже,
/// чтобы постер не застывал на смену. Если бренд дал видео-герой, вместо
/// образов крутится оно.
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

  /// false, когда вкладка «Зеркало» скрыта — ротация останавливается.
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
    with WidgetsBindingObserver {
  static const _beat = Duration(seconds: 6);
  static const _stillBeat = Duration(seconds: 12);

  /// Общий счётчик ротации: фраза и образ меняются вместе.
  int _tick = 0;
  Timer? _timer;
  bool _lifecyclePaused = false;
  bool _reduceMotion = false;

  int _wordmarkTaps = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion || _timer == null) {
      _reduceMotion = reduce;
      _armTimer();
    }
  }

  @override
  void didUpdateWidget(covariant MirrorCoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _armTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (paused == _lifecyclePaused) return;
    _lifecyclePaused = paused;
    _armTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (!widget.active || _lifecyclePaused) return;
    _timer = Timer.periodic(_reduceMotion ? _stillBeat : _beat, (_) {
      if (!mounted) return;
      setState(() => _tick++);
      _precacheNextLook();
    });
  }

  /// Следующий образ подгружается заранее, чтобы смена была мгновенной.
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
    final switchDuration =
        _reduceMotion ? Duration.zero : const Duration(milliseconds: 700);

    return ColoredBox(
      color: t.bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Масштаб постера ограничен высотой: на планшете всё вдвое
            // крупнее, а экран лишь в полтора раза выше телефона — иначе
            // герою не остаётся места.
            final cs = math.min(
              MirrorTheme.scale(context),
              constraints.maxHeight / 620,
            );

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * cs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 12 * cs),
                  _Header(
                    cs: cs,
                    controller: widget.controller,
                    onWordmarkTap: _onWordmarkTap,
                    fullscreen: widget.fullscreen,
                    onEnterFullscreen: widget.onEnterFullscreen,
                  ),
                  SizedBox(height: 18 * cs),

                  // Заголовок: сериф бренда, фразы сменяются мягким подъёмом.
                  AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      phrase,
                      key: ValueKey('phrase-${_tick % math.max(1, phrases.length)}'),
                      maxLines: 3,
                      style: t.display(30 * cs),
                    ),
                  ),
                  SizedBox(height: 8 * cs),
                  Text(
                    l10n.mirrorCoverSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.subtitle(14 * cs),
                  ),
                  SizedBox(height: 16 * cs),

                  // Герой: видео бренда, живой образ из каталога или
                  // типографский блок, когда каталога ещё нет.
                  Expanded(
                    child: brand.heroVideoAsset != null
                        ? _VideoHero(
                            asset: brand.heroVideoAsset!,
                            active: widget.active && !_lifecyclePaused,
                            radius: t.rCard,
                          )
                        : AnimatedSwitcher(
                            duration: switchDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 1.02, end: 1)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                            child: look == null
                                ? _TypographicHero(
                                    // Следующая фраза ротации — чтобы герой
                                    // не повторял заголовок над собой.
                                    key: const ValueKey('typo-hero'),
                                    cs: cs,
                                    phrase: phrases.isEmpty
                                        ? l10n.mirrorCoverSubtitle
                                        : phrases[(_tick + 1) % phrases.length],
                                  )
                                : RepaintBoundary(
                                    key: ValueKey(
                                      'look-${_tick % looks.length}',
                                    ),
                                    child: MirrorCoverLookCard(
                                      look: look,
                                      lang: lang,
                                      kicker: l10n.mirrorCoverLookKicker,
                                    ),
                                  ),
                          ),
                  ),
                  SizedBox(height: 16 * cs),

                  _HowItWorksStrip(cs: cs),
                  SizedBox(height: 16 * cs),

                  MirrorPrimaryButton(
                    label: l10n.mirrorCtaCreate,
                    height: 58 * cs,
                    onTap: () => widget.controller.begin(MirrorPath.create),
                  ),
                  SizedBox(height: 4 * cs),
                  MirrorTextButton(
                    label: l10n.mirrorCtaCatalog,
                    height: 46 * cs,
                    onTap: () => widget.controller.begin(MirrorPath.catalog),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 13 * cs, color: t.muted),
                      SizedBox(width: 6 * cs),
                      Flexible(
                        child: Text(
                          l10n.mirrorPrivacyShort,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.subtitle(12 * cs),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * cs),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Верхняя строка постера: знак бренда (5 касаний — настройка), язык,
/// кнопка полноэкранного режима.
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
            child: MirrorBrandMark(height: 20 * cs),
          ),
        ),
        Row(
          children: [
            MirrorLangToggle(
              langCode: controller.shopperLang,
              onChanged: controller.setShopperLang,
            ),
            if (!fullscreen && onEnterFullscreen != null) ...[
              SizedBox(width: 10 * cs),
              SizedBox(
                width: 40 * cs,
                height: 40 * cs,
                child: Material(
                  color: t.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.rButton),
                    side: BorderSide(color: t.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onEnterFullscreen,
                    child: Icon(
                      Icons.fullscreen_rounded,
                      size: 22 * cs,
                      color: t.ink,
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

/// Три шага в одну строку: серифная цифра + короткая подпись, волосяные
/// разделители. Заменяет отдельный экран «Как это работает».
class _HowItWorksStrip extends StatelessWidget {
  const _HowItWorksStrip({required this.cs});

  final double cs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final steps = [l10n.mirrorHow1, l10n.mirrorHow2, l10n.mirrorHow3];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.kickerCase(l10n.mirrorIntroTitle),
          style: t.kicker(cs * 0.85, color: t.muted),
        ),
        SizedBox(height: 8 * cs),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 26 * cs,
                  margin: EdgeInsets.symmetric(horizontal: 10 * cs),
                  color: t.hairline,
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${i + 1}',
                      style: t.display(18 * cs, color: t.primary),
                    ),
                    SizedBox(width: 6 * cs),
                    Expanded(
                      child: Text(
                        steps[i],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.label(
                          12 * cs,
                          weight: FontWeight.w600,
                        ).copyWith(height: 1.15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Типографский герой — когда каталога ещё нет (нет ключа, нет сети,
/// пустой зал): блок цвета бренда, знак и первая фраза серифом.
class _TypographicHero extends StatelessWidget {
  const _TypographicHero({super.key, required this.cs, required this.phrase});

  final double cs;
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.primary,
        borderRadius: BorderRadius.circular(t.rCard),
      ),
      child: Padding(
        padding: EdgeInsets.all(22 * cs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MirrorBrandMark(height: 18 * cs, color: t.onPrimary),
            const Spacer(),
            Container(
              width: 36 * cs,
              height: 1.5,
              color: t.onPrimary.withValues(alpha: 0.6),
            ),
            SizedBox(height: 14 * cs),
            // Flexible: на тесном герое фраза ужимается, а не переполняет блок.
            Flexible(
              child: Text(
                phrase,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: t.display(26 * cs, color: t.onPrimary),
              ),
            ),
          ],
        ),
      ),
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
    final t = MirrorTheme.of(context);
    final video = _video;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: ColoredBox(
        color: t.primary,
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
      ),
    );
  }
}
