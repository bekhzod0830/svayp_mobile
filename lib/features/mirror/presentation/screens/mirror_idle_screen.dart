import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран 0 — постер (заставка). Полноэкранное зациклённое видео без звука
/// под чернильным скримом; пока видео не поднялось (или не смогло) — фоном
/// работают плывущие свечения. Живёт бесконечно: один видеоплеер на повторе
/// и два repeat-контроллера Floaty, утекать нечему.
class MirrorIdleScreen extends StatefulWidget {
  const MirrorIdleScreen({
    super.key,
    required this.controller,
    required this.onOpenSetup,
    this.active = true,
    this.fullscreen = false,
    this.onEnterFullscreen,
  });

  final MirrorSessionController controller;
  final VoidCallback onOpenSetup;

  /// false, когда вкладка «Зеркало» скрыта — видео ставится на паузу.
  final bool active;

  /// Полноэкранный киоск-режим: нижняя навигация продавца скрыта.
  /// Выход — только через скрытый шит настройки (5 касаний по логотипу),
  /// чтобы покупатель не попал во вкладки продавца.
  final bool fullscreen;
  final VoidCallback? onEnterFullscreen;

  @override
  State<MirrorIdleScreen> createState() => _MirrorIdleScreenState();
}

class _MirrorIdleScreenState extends State<MirrorIdleScreen>
    with WidgetsBindingObserver {
  static const _videoAsset = 'lib/video/kiosk_poster/poster_video.mp4';

  VideoPlayerController? _video;
  bool _videoReady = false;

  int _wordmarkTaps = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final video = VideoPlayerController.asset(_videoAsset);
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
      setState(() => _videoReady = true);
    } catch (_) {
      // Видео не поднялось — остаёмся на градиентном фоне, постер живёт.
    }
  }

  @override
  void didUpdateWidget(covariant MirrorIdleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active && _videoReady) {
      widget.active ? _video?.play() : _video?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_videoReady) return;
    if (state == AppLifecycleState.resumed && widget.active) {
      _video?.play();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _video?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapResetTimer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  /// 5 быстрых касаний по словесному знаку — скрытый шит настройки
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
    final s = MirrorTheme.scale(context);
    final size = MediaQuery.sizeOf(context);

    return ColoredBox(
      color: MirrorTheme.ink,
      child: Stack(
        children: [
          // Фон: видео (cover) либо плывущие свечения, пока его нет.
          if (_videoReady && _video != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _video!.value.size.width,
                  height: _video!.value.size.height,
                  child: VideoPlayer(_video!),
                ),
              ),
            )
          else ...[
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.3,
              child: Floaty(
                variant: 1,
                child: _GlowCircle(
                  diameter: size.width * 0.9,
                  color: MirrorTheme.pink.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.12,
              left: -size.width * 0.35,
              child: Floaty(
                variant: 2,
                child: _GlowCircle(
                  diameter: size.width * 0.85,
                  color: IntroPalette.amber.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              right: size.width * 0.14,
              child: Twinkle(size: 16 * s, color: Colors.white),
            ),
          ],

          // Скрим: лёгкое общее затемнение + плотный низ под текст и CTA.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onWordmarkTap,
                        child: Padding(
                          padding: EdgeInsets.all(8 * s),
                          child: MirrorWordmark(
                            size: 26 * s,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          MirrorLangToggle(
                            langCode: widget.controller.shopperLang,
                            onChanged: widget.controller.setShopperLang,
                            light: true,
                          ),
                          if (!widget.fullscreen &&
                              widget.onEnterFullscreen != null) ...[
                            SizedBox(width: 10 * s),
                            _FrostedIconButton(
                              icon: Icons.fullscreen_rounded,
                              size: 44 * s,
                              onTap: widget.onEnterFullscreen!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Нижняя треть: монументальный заголовок + CTA.
                  Text(
                    l10n.mirrorIdleTitle,
                    style: MirrorTheme.headline(46 * s, color: Colors.white),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        IntroPalette.pinkGradient.createShader(bounds),
                    child: Text(
                      l10n.mirrorIdleTitleAccent,
                      style:
                          MirrorTheme.headline(46 * s, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 36 * s),
                  MirrorPrimaryButton(
                    label: l10n.mirrorCtaCreate,
                    height: 64 * s,
                    onTap: () =>
                        widget.controller.begin(MirrorPath.create),
                  ),
                  SizedBox(height: 14 * s),
                  MirrorGhostButton(
                    label: l10n.mirrorCtaCatalog,
                    height: 64 * s,
                    light: true,
                    onTap: () =>
                        widget.controller.begin(MirrorPath.catalog),
                  ),
                  SizedBox(height: 36 * s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: size * 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
