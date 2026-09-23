import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_arch.dart';

/// Экран генерации: «зеркало проявляет ваш образ». В арочном зеркале бренда
/// — фото самого покупателя. Сначала оно бледное и размытое и по мере сборки
/// проявляется в цвет; рама зеркала дорисовывается по прогрессу, по стеклу
/// идёт полоса сканирования, а к раме по этапам прикрепляются ответы
/// покупателя — пол, фигура, стили или число выбранных вещей. Ни одной
/// картинки товара: до результата мы не знаем, какие вещи войдут в образ,
/// и не показываем случайные.
///
/// Прогресс детерминированный; «почти готово» после 25с; ошибка после 40с с
/// Retry и QR. Отмена доступна всегда, но не спорит со сценой.
class MirrorGeneratingScreen extends StatefulWidget {
  const MirrorGeneratingScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorGeneratingScreen> createState() => _MirrorGeneratingScreenState();
}

class _MirrorGeneratingScreenState extends State<MirrorGeneratingScreen>
    with TickerProviderStateMixin {
  bool _precaching = false;

  /// Полоса сканирования по стеклу.
  late final AnimationController _scan;

  /// Общее «дыхание»: свечение, искры, точка на конце линии прогресса.
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scan
        ..stop()
        ..value = 0;
      _ambient
        ..stop()
        ..value = 0.5;
    } else {
      if (!_scan.isAnimating) _scan.repeat();
      if (!_ambient.isAnimating) _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Ответы покупателя, которые прикрепляются к зеркалу, по этапам.
  List<_Answer> _answers(AppLocalizations l10n) {
    final c = widget.controller;
    final brand = c.brand;
    final lang = c.shopperLang;
    final answers = <_Answer>[];

    final gender = c.gender;
    if (gender != null) {
      answers.add(_Answer(
        stage: 1,
        kicker: l10n.mirrorGenderLabel,
        value: gender == 'MALE' ? l10n.mirrorMale : l10n.mirrorFemale,
      ));
    }
    final shape = c.bodyShape;
    if (shape != null) {
      final label = shape == kioskShapeUnknown
          ? l10n.mirrorDontKnow
          : (kioskShapes[gender] ?? const <KioskLabeled>[])
                  .where((x) => x.code == shape)
                  .map((x) => x.label(lang))
                  .firstOrNull ??
              l10n.mirrorDontKnow;
      answers
          .add(_Answer(stage: 1, kicker: l10n.mirrorShapeLabel, value: label));
    }
    if (c.path == MirrorPath.create && c.styles.isNotEmpty) {
      final labels = [
        for (final code in c.styles)
          brand.styleLabel(
            kioskStyles.firstWhere(
              (x) => x.code == code,
              orElse: () => KioskLabeled(code, code, code),
            ),
            lang,
          ),
      ];
      answers.add(_Answer(
        stage: 2,
        kicker: l10n.mirrorGenStyleLabel,
        value: labels.join(' · '),
      ));
    } else if (c.path == MirrorPath.catalog && c.pickedProductIds.isNotEmpty) {
      answers.add(_Answer(
        stage: 2,
        kicker: l10n.mirrorPicked,
        value: l10n.mirrorGenPickedCount(c.pickedProductIds.length),
      ));
    }
    return answers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = widget.controller;

    if (c.resultReady && !_precaching) {
      _precaching = true;
      _precacheAndReveal();
    }

    if (c.genFailed) return _buildFailure(context, l10n, t, s);

    final elapsed = c.elapsedSec;
    final stages = [
      l10n.mirrorGen1,
      l10n.mirrorGen2,
      l10n.mirrorGen3,
      l10n.mirrorGen4
    ];
    // Этап ~6 секунд; последний держится до конца генерации.
    final activeStage = math.min(elapsed ~/ 6, stages.length - 1);

    // До 25с — easeOut к 90%; дальше медленный доползающий хвост к 95%.
    final base = Curves.easeOut.transform(
            (elapsed / MirrorSessionController.reassureAfterSec)
                .clamp(0.0, 1.0)) *
        0.9;
    final crawl = elapsed > MirrorSessionController.reassureAfterSec
        ? math.min(
            0.05, (elapsed - MirrorSessionController.reassureAfterSec) * 0.005)
        : 0.0;
    final progress = c.resultReady ? 1.0 : (base + crawl).clamp(0.03, 0.95);

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 0),
      child: Column(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, p, _) => _DevelopingMirror(
                progress: p,
                stage: activeStage,
                photo: c.capturedPhoto,
                answers: _answers(l10n),
                scan: _scan,
                ambient: _ambient,
              ),
            ),
          ),
          SizedBox(height: 16 * s),
          Text(
            l10n.mirrorGenTitle,
            textAlign: TextAlign.center,
            style: t.headline(30 * s),
          ),
          SizedBox(height: 10 * s),
          _StatusLine(text: stages[activeStage], stage: activeStage),
          SizedBox(
            height: 30 * s,
            child: elapsed > MirrorSessionController.reassureAfterSec
                ? Center(
                    child: Text(
                      l10n.mirrorGenAlmost,
                      textAlign: TextAlign.center,
                      style: t.subtitle(16 * s, color: t.accent),
                    ),
                  )
                : null,
          ),
          MirrorTextButton(
            label: l10n.mirrorCancel,
            height: 48 * s,
            color: t.muted,
            onTap: c.cancelGeneration,
          ),
          SizedBox(height: 10 * s),
        ],
      ),
    );
  }

  Widget _buildFailure(
    BuildContext context,
    AppLocalizations l10n,
    MirrorTheme t,
    double s,
  ) {
    final c = widget.controller;
    final reason = c.genReason;
    final reasonText = MirrorSessionController.isLookUnavailable(reason)
        ? l10n.mirrorLookUnavailable
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32 * s),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 44 * s, color: t.muted),
              SizedBox(height: 18 * s),
              Text(
                l10n.mirrorGenFailed,
                textAlign: TextAlign.center,
                style: t.headline(30 * s),
              ),
              if (reasonText != null) ...[
                SizedBox(height: 10 * s),
                Text(
                  reasonText,
                  textAlign: TextAlign.center,
                  style: t.subtitle(15 * s),
                ),
              ],
              SizedBox(height: 24 * s),
              MirrorPrimaryButton(
                label: l10n.mirrorGenRetry,
                height: 60 * s,
                onTap: c.retryGeneration,
              ),
              SizedBox(height: 20 * s),
              if (c.shareUrl != null) ...[
                Text(
                  l10n.mirrorGenContinueInApp,
                  textAlign: TextAlign.center,
                  style: t.subtitle(14 * s),
                ),
                SizedBox(height: 12 * s),
                Container(
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(t.rCard),
                    border: Border.all(color: t.hairline),
                  ),
                  child: QrImageView(
                    data: c.shareUrl!,
                    size: 120 * s,
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(height: 16 * s),
              ],
              if (reason != null && reasonText == null)
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: t.mono(11 * s, color: t.muted.withValues(alpha: 0.7)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _precacheAndReveal() async {
    final c = widget.controller;
    final look = c.look;
    final url = look?.resultImageUrl;
    try {
      if (url != null && url.startsWith('http')) {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        ).timeout(const Duration(seconds: 6));
      } else if (look?.localResultPath != null) {
        await precacheImage(
          FileImage(File(look!.localResultPath!)),
          context,
        ).timeout(const Duration(seconds: 6));
      }
    } catch (_) {
      // Прекэш — оптимизация; без него результат просто догрузится на экране.
    }
    if (mounted) c.revealResult();
  }
}

/// Одна живая строка статуса: пульсирующая точка и текст текущего этапа,
/// который сменяется мягким подъёмом.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, required this.stage});

  final String text;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulseDot(size: 8 * s),
        SizedBox(width: 10 * s),
        Flexible(
          child: AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              text,
              key: ValueKey(stage),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: t
                  .label(16 * s, weight: FontWeight.w600)
                  .copyWith(height: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.size});

  final double size;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim
        ..stop()
        ..value = 1;
    } else if (!_anim.isAnimating) {
      _anim.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final p = Curves.easeInOut.transform(_anim.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.primary.withValues(alpha: 0.45 + 0.55 * p),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.35 * p),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ответ покупателя на раме зеркала.
class _Answer {
  const _Answer(
      {required this.stage, required this.kicker, required this.value});

  /// С какого этапа генерации ответ виден.
  final int stage;
  final String kicker;
  final String value;
}

/// Сцена экрана генерации: арочное зеркало с фото покупателя, рама-прогресс,
/// сканирование, ответы на раме, процент на нижней кромке.
class _DevelopingMirror extends StatelessWidget {
  const _DevelopingMirror({
    required this.progress,
    required this.stage,
    required this.photo,
    required this.answers,
    required this.scan,
    required this.ambient,
  });

  final double progress;
  final int stage;
  final File? photo;
  final List<_Answer> answers;
  final Animation<double> scan;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        // Арка: по высоте сцены, пропорция зеркала ~0.62, с запасом по бокам
        // под ответы.
        final archH = size.height * 0.94;
        final archW = math.min(archH * 0.6, size.width * 0.56);
        final arch = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.49),
          width: archW,
          height: math.min(archH, archW / 0.5),
        );
        final chipMaxW = math.min(210 * s, size.width * 0.46);
        // Ответы по очереди слева и справа, на своих высотах.
        const slots = [0.24, 0.40, 0.60, 0.74];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Мягкое свечение цветом бренда за зеркалом.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: ambient,
                builder: (context, _) => CustomPaint(
                  painter: MirrorArchHaloPainter(
                    arch: arch,
                    color: t.primary,
                    strength: 0.14 +
                        0.10 * progress +
                        0.05 * Curves.easeInOut.transform(ambient.value),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: arch,
              child: _MirrorGlass(
                photo: photo,
                progress: progress,
                stage: stage,
                scan: scan,
              ),
            ),
            // Рама: тонкий контур и поверх — линия прогресса с точкой.
            Positioned.fromRect(
              rect: arch.inflate(8 * s),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: ambient,
                  builder: (context, _) => CustomPaint(
                    painter: MirrorArchFramePainter(
                      progress: progress,
                      track: t.hairline,
                      color: t.primary,
                      glow: Curves.easeInOut.transform(ambient.value),
                      s: s,
                    ),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < answers.length && i < slots.length; i++)
              // Карточка ответа заходит на раму на треть ширины арки —
              // «приколота» к зеркалу и не упирается в край экрана.
              Positioned(
                top: arch.top + arch.height * slots[i] - 45 * s,
                height: 90 * s,
                left: i.isEven ? 6 * s : arch.right - arch.width * 0.3,
                right: i.isEven
                    ? size.width - (arch.left + arch.width * 0.3)
                    : 6 * s,
                child: _AnswerChip(
                  answer: answers[i],
                  visible: stage >= answers[i].stage,
                  fromLeft: i.isEven,
                  maxWidth: chipMaxW,
                ),
              ),
            // Процент — плашкой на нижней кромке рамы.
            Positioned(
              left: 0,
              right: 0,
              top: arch.bottom - 4 * s,
              child: Center(
                child: _PercentBadge(progress: progress),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Стекло зеркала: фото покупателя проявляется из бледного и размытого в
/// цвет, по стеклу идёт полоса сканирования. На первом этапе вокруг лица
/// сходятся уголки фокуса.
class _MirrorGlass extends StatelessWidget {
  const _MirrorGlass({
    required this.photo,
    required this.progress,
    required this.stage,
    required this.scan,
  });

  final File? photo;
  final double progress;
  final int stage;
  final Animation<double> scan;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final file = photo;
    // Проявление: насыщенность 10% → 100%, размытие 5 → 0.
    final develop = progress.clamp(0.0, 1.0);
    final saturation = 0.1 + 0.9 * develop;
    final blur = 5 * (1 - develop);

    Widget image = file == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.surface, t.selectedBg],
              ),
            ),
          )
        : Image.file(
            file,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.35),
            cacheWidth: 900,
            gaplessPlayback: true,
          );
    image = ColorFiltered(
      colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
      child: image,
    );
    if (blur > 0.05) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: image,
      );
    }

    return ClipPath(
      clipper: const MirrorArchClipper(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: t.surface),
          image,
          // Лёгкая «вуаль» цвета бренда, которая уходит по мере проявления.
          IgnorePointer(
            child: ColoredBox(
              color: t.primary.withValues(alpha: 0.10 * (1 - develop)),
            ),
          ),
          // Полоса сканирования.
          AnimatedBuilder(
            animation: scan,
            builder: (context, _) => CustomPaint(
              painter: _ScanPainter(
                value: scan.value,
                color: t.primary,
                s: s,
              ),
            ),
          ),
          // Этап «лицо»: уголки фокуса вокруг лица.
          AnimatedOpacity(
            opacity: stage == 0 ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedScale(
              scale: stage == 0 ? 1 : 1.25,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                painter: _FocusPainter(color: Colors.white, s: s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<double> _saturationMatrix(double sat) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final inv = 1 - sat;
    return [
      r * inv + sat,
      g * inv,
      b * inv,
      0,
      0,
      r * inv,
      g * inv + sat,
      b * inv,
      0,
      0,
      r * inv,
      g * inv,
      b * inv + sat,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// Полоса сканирования: мягкий светлый шлейф и тонкая линия цвета бренда.
class _ScanPainter extends CustomPainter {
  const _ScanPainter(
      {required this.value, required this.color, required this.s});

  final double value;
  final Color color;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final y = -0.1 * size.height + value * size.height * 1.2;
    final trail = Rect.fromLTRB(0, y - size.height * 0.16, size.width, y);
    canvas
      ..drawRect(
        trail,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.28),
            ],
          ).createShader(trail),
      )
      ..drawRect(
        Rect.fromLTWH(0, y - 1.5 * s, size.width, 3 * s),
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s),
      )
      ..drawRect(
        Rect.fromLTWH(0, y - 0.6 * s, size.width, 1.2 * s),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
  }

  @override
  bool shouldRepaint(_ScanPainter old) =>
      old.value != value || old.color != color;
}

/// Уголки фокуса вокруг лица (верхняя часть зеркала).
class _FocusPainter extends CustomPainter {
  const _FocusPainter({required this.color, required this.s});

  final Color color;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.27),
      width: size.width * 0.48,
      height: size.width * 0.56,
    );
    final len = box.width * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9);
    for (final (corner, dx, dy) in [
      (box.topLeft, 1.0, 1.0),
      (box.topRight, -1.0, 1.0),
      (box.bottomLeft, 1.0, -1.0),
      (box.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * len, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy * len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FocusPainter old) => old.color != color || old.s != s;
}

/// Ответ покупателя: карточка, приколотая к раме зеркала точкой цвета
/// бренда. Влетает сбоку, когда наступает её этап.
class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.answer,
    required this.visible,
    required this.fromLeft,
    required this.maxWidth,
  });

  final _Answer answer;
  final bool visible;
  final bool fromLeft;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : const Duration(milliseconds: 520);
    final pinned = MirrorPinnedCard(
      fromLeft: fromLeft,
      maxWidth: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            fromLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            t.kickerCase(answer.kicker),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.kicker(s * 0.8),
          ),
          SizedBox(height: 5 * s),
          Text(
            answer.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: fromLeft ? TextAlign.right : TextAlign.left,
            style:
                t.label(14 * s, weight: FontWeight.w700).copyWith(height: 1.2),
          ),
        ],
      ),
    );

    return Align(
      alignment: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(fromLeft ? -0.25 : 0.25, 0),
          duration: duration,
          curve: Curves.easeOutBack,
          child: pinned,
        ),
      ),
    );
  }
}

/// Процент готовности плашкой на нижней кромке рамы.
class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return MirrorArchBadge(
      child: Text(
        '${(progress * 100).round()}%',
        style: t.price(16 * s, color: t.onPrimary),
      ),
    );
  }
}
