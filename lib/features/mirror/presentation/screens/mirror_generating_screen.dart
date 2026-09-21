import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_fitting_stage.dart';
import '../widgets/mirror_stage_parts.dart';

/// Экран генерации. Человек стоит посреди зала 20–30 секунд, поэтому экран —
/// маленький спектакль у того же зеркала, что на постере: в нём уже сам
/// покупатель (его фото), слоты фигуры сканируются, а затем в них листаются
/// реальные вещи зала (см. [MirrorFittingStage]). Под сценой — одна живая
/// строка статуса вместо списка и прогресс из четырёх сегментов по этапам.
/// Прогресс детерминированный; «почти готово» после 25с; ошибка после 40с с
/// Retry и QR. Отмена доступна всегда, но не спорит со сценой.
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

    final brand = t.brand;
    final lang = c.shopperLang;
    String slotLabel(String code) => brand.categoryLabel(
          kioskCategories.firstWhere((x) => x.code == code),
          lang,
        );

    final pool = c.catalogPreview;
    // Вещи, выбранные в каталоге, — это правда о будущем образе: они стоят в
    // зеркале сразу и не листаются.
    final pinned =
        pool.where((i) => c.pickedProductIds.contains(i.id)).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 14 * s, 20 * s, 0),
      child: Column(
        children: [
          Expanded(
            child: MirrorStageWall(
              borderRadius: BorderRadius.circular(14 * s),
              child: Padding(
                padding: EdgeInsets.all(10 * s),
                child: LayoutBuilder(
                  // Стена шире, чем выше (планшет) — широкая сцена.
                  builder: (context, box) => FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      child: MirrorFittingStage(
                        stage: activeStage,
                        pool: pool,
                        pinned: pinned,
                        facePhoto: c.capturedPhoto,
                        slotLabels: [
                          slotLabel('TOPWEAR'),
                          slotLabel('BOTTOMWEAR'),
                          slotLabel('FOOTWEAR'),
                        ],
                        wide: box.maxWidth > box.maxHeight * 1.05,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 18 * s),
          Text(
            l10n.mirrorGenTitle,
            textAlign: TextAlign.center,
            style: t.headline(30 * s),
          ),
          SizedBox(height: 10 * s),
          _StatusLine(text: stages[activeStage], stage: activeStage),
          if (elapsed > MirrorSessionController.reassureAfterSec) ...[
            SizedBox(height: 6 * s),
            Text(
              l10n.mirrorGenAlmost,
              textAlign: TextAlign.center,
              style: t.subtitle(16 * s, color: t.accent),
            ),
          ],
          SizedBox(height: 16 * s),
          _SegmentedProgress(progress: progress),
          SizedBox(height: 4 * s),
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

/// Прогресс из четырёх сегментов — по одному на этап — и процент справа.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) SizedBox(width: 6 * s),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(t.rChip),
                    child: SizedBox(
                      height: 5 * s,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: t.hairline),
                          AnimatedFractionallySizedBox(
                            duration: still
                                ? Duration.zero
                                : const Duration(milliseconds: 900),
                            curve: Curves.easeOut,
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                (progress * 4 - i).clamp(0.0, 1.0),
                            child: ColoredBox(color: t.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
    );
  }
}
