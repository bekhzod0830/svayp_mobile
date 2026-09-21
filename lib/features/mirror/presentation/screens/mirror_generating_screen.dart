import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/body_scan_visual.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран генерации. Человек стоит посреди зала 20–30 секунд, поэтому экран —
/// спокойный спектакль на фоне бренда: сканирующийся силуэт, плывущие
/// карточки выбранных вещей и чек-лист этапов, которые отмечаются по мере
/// работы. Полоса прогресса детерминированная; «почти готово» после 25с;
/// ошибка после 40с с Retry и QR. Отмена доступна всегда.
class MirrorGeneratingScreen extends StatefulWidget {
  const MirrorGeneratingScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorGeneratingScreen> createState() => _MirrorGeneratingScreenState();
}

class _MirrorGeneratingScreenState extends State<MirrorGeneratingScreen> {
  bool _precaching = false;

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
    final stages = [l10n.mirrorGen1, l10n.mirrorGen2, l10n.mirrorGen3, l10n.mirrorGen4];
    // Этап ~6 секунд; последний держится до конца генерации.
    final activeStage = math.min(elapsed ~/ 6, stages.length - 1);

    // До 25с — easeOut к 90%; дальше медленный доползающий хвост к 95%.
    final base = Curves.easeOut
            .transform((elapsed / MirrorSessionController.reassureAfterSec).clamp(0.0, 1.0)) *
        0.9;
    final crawl = elapsed > MirrorSessionController.reassureAfterSec
        ? math.min(0.05, (elapsed - MirrorSessionController.reassureAfterSec) * 0.005)
        : 0.0;
    final progress = (base + crawl).clamp(0.03, 0.95);

    // До трёх выбранных вещей плывут вокруг силуэта (ветка «каталог») —
    // человек видит, что примеряются именно его вещи.
    final pickedImages = c.catalog
        .where((item) =>
            c.pickedProductIds.contains(item.id) && item.imageUrl != null)
        .map((item) => item.imageUrl!)
        .take(3)
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: BodyScanVisual(
                    accent: t.primary,
                    badge: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * s,
                        vertical: 6 * s,
                      ),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(t.rChip),
                      ),
                      child: Text(
                        'AI',
                        style: t.label(12 * s, color: t.onPrimary)
                            .copyWith(letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
                if (pickedImages.isNotEmpty)
                  Positioned(
                    top: 24 * s,
                    left: 0,
                    child: _FloatingGarment(
                        url: pickedImages[0], s: s, variant: 1),
                  ),
                if (pickedImages.length > 1)
                  Positioned(
                    top: 90 * s,
                    right: 0,
                    child: _FloatingGarment(
                        url: pickedImages[1], s: s, variant: 2),
                  ),
                if (pickedImages.length > 2)
                  Positioned(
                    bottom: 30 * s,
                    left: 8 * s,
                    child: _FloatingGarment(
                        url: pickedImages[2], s: s, variant: 3),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14 * s),
          Text(
            l10n.mirrorGenTitle,
            textAlign: TextAlign.center,
            style: t.headline(30 * s),
          ),
          SizedBox(height: 16 * s),
          // Чек-лист этапов: сделанные отмечаются квадратным чеком, активный
          // пульсирует. Осмысленный прогресс вместо крутилки.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460 * s),
            child: Column(
              children: [
                for (var i = 0; i < stages.length; i++)
                  _StageRow(
                    label: stages[i],
                    state: i < activeStage
                        ? _StageState.done
                        : i == activeStage
                            ? _StageState.active
                            : _StageState.pending,
                    s: s,
                  ),
              ],
            ),
          ),
          if (elapsed > MirrorSessionController.reassureAfterSec) ...[
            SizedBox(height: 8 * s),
            Text(
              l10n.mirrorGenAlmost,
              textAlign: TextAlign.center,
              style: t.subtitle(16 * s, color: t.accent),
            ),
          ],
          SizedBox(height: 16 * s),
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Container(
                    height: 6 * s,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: t.hairline,
                      borderRadius: BorderRadius.circular(t.rChip),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      height: 6 * s,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(t.rChip),
                        color: t.primary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * s),
              SizedBox(
                width: 48 * s,
                child: Text(
                  '${(progress * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: t.price(15 * s, color: t.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * s),
          MirrorGhostButton(
            label: l10n.mirrorCancel,
            height: 56 * s,
            onTap: c.cancelGeneration,
          ),
          SizedBox(height: 24 * s),
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
              Icon(
                Icons.auto_awesome_outlined,
                size: 44 * s,
                color: t.muted,
              ),
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
        await precacheImage(CachedNetworkImageProvider(url), context)
            .timeout(const Duration(seconds: 6));
      } else if (look?.localResultPath != null) {
        await precacheImage(FileImage(File(look!.localResultPath!)), context)
            .timeout(const Duration(seconds: 6));
      }
    } catch (_) {
      // Прекэш — оптимизация; без него результат просто догрузится на экране.
    }
    if (mounted) c.revealResult();
  }
}

enum _StageState { pending, active, done }

/// Строка чек-листа: чек / пульс / ожидание.
class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state, required this.s});

  final String label;
  final _StageState state;
  final double s;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final Color textColor;
    final FontWeight weight;
    switch (state) {
      case _StageState.done:
        textColor = t.ink;
        weight = FontWeight.w600;
      case _StageState.active:
        textColor = t.ink;
        weight = FontWeight.w700;
      case _StageState.pending:
        textColor = t.muted.withValues(alpha: 0.6);
        weight = FontWeight.w500;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * s),
      child: Row(
        children: [
          SizedBox(
            width: 22 * s,
            height: 22 * s,
            child: switch (state) {
              _StageState.done => MirrorCheck(selected: true, size: 22 * s),
              _StageState.active => _PulsingSquare(s: s),
              _StageState.pending => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.rChip),
                    border: Border.all(color: t.hairline, width: 1.5),
                  ),
                ),
            },
          ),
          SizedBox(width: 14 * s),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: t
                  .label(15 * s, weight: weight, color: textColor)
                  .copyWith(height: 1.2),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пульсирующий квадрат активного этапа.
class _PulsingSquare extends StatefulWidget {
  const _PulsingSquare({required this.s});

  final double s;

  @override
  State<_PulsingSquare> createState() => _PulsingSquareState();
}

class _PulsingSquareState extends State<_PulsingSquare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    if (MediaQuery.of(context).disableAnimations) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.rChip),
          border: Border.all(color: t.primary, width: 2),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final p = 0.5 + 0.5 * math.sin(_anim.value * 2 * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.rChip),
            border: Border.all(
              color: t.primary.withValues(alpha: 0.45 + 0.55 * p),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.3 * p),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Плывущая карточка выбранной вещи вокруг силуэта.
class _FloatingGarment extends StatefulWidget {
  const _FloatingGarment({
    required this.url,
    required this.s,
    required this.variant,
  });

  final String url;
  final double s;
  final int variant;

  @override
  State<_FloatingGarment> createState() => _FloatingGarmentState();
}

class _FloatingGarmentState extends State<_FloatingGarment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4200 + widget.variant * 600),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = widget.s;
    final card = Container(
      width: 74 * s,
      height: 96 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(t.rImage),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: t.ink.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.cover,
        placeholder: (_, __) => ColoredBox(color: t.surface),
        errorWidget: (_, __, ___) => ColoredBox(color: t.surface),
      ),
    );

    if (MediaQuery.of(context).disableAnimations) return card;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final a = _anim.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(3 * s * math.sin(a + widget.variant), 8 * s * math.sin(a)),
          child: Transform.rotate(
            angle: 0.04 * math.sin(a + widget.variant * 2),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
