import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_image_cache.dart';
import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_arch.dart';
import '../widgets/mirror_item_details.dart';

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

  // Плавный прогресс. Время генерации считается по времени кадров тикера
  // (монотонное, как у любой анимации), а не по целым секундам контроллера:
  // его Timer.periodic «плывёт», и досчёт между тиками упирался в границу
  // секунды — линия рамы замирала и дёргалась. Значение пересчитывается
  // каждый кадр ([_progressTicker]) и раздаётся через [_progress] только тем
  // слоям, что от него зависят, — экран целиком на каждый кадр не
  // перестраивается.

  /// Время кадра, с которого идёт текущая генерация, и сколько секунд
  /// контроллер уже насчитал к открытию экрана (обычно 0).
  Duration _genStart = Duration.zero;
  double _baseSec = 0;
  int _lastElapsed = 0;
  bool _sawFailure = false;
  double _shown = 0;

  /// Финиш: образ готов — прогресс одним плавным движением добегает от
  /// [_finishFrom] до 100%. Пока картинка результата не скачана
  /// ([_imageReady]), движение держится на 97%: раньше 100% горели всё время
  /// загрузки, будто экран завис. Результат открывается, когда дошли до 100%.
  Duration? _finishStart;
  double _finishFrom = 0;
  bool _imageReady = false;
  bool _revealed = false;

  /// Одна лента появлений на весь экран: вещь, ответ, вещь, ответ… —
  /// «Верх», «Пол», «Низ», «Тип фигуры»… Ключи `item:i` и `ans:i` в порядке
  /// показа; открываются по прогрессу (см. [_threshold]) и больше не
  /// прячутся. Вещи — в ленте под зеркалом, ответы — карточками на раме.
  List<String> _timeline = const [];
  final Set<String> _shownKeys = {};

  /// Ключи миниатюр вещей: из них «вырастает» карточка подробностей.
  final Map<String, GlobalKey> _thumbKeys = {};
  GlobalKey _thumbKey(KioskLookItem item) =>
      _thumbKeys.putIfAbsent(item.productId, GlobalKey.new);

  /// На каком прогрессе открывается шаг [j] из [n]: от 8% до 86%, поровну —
  /// последний ближе к концу, чтобы до самой готовности что-то происходило.
  static double _threshold(int j, int n) =>
      n <= 1 ? 0.08 : 0.08 + 0.78 * j / (n - 1);

  static List<String> _timelineFor(int items, int answers) => [
    for (var k = 0; k < math.max(items, answers); k++) ...[
      if (k < items) 'item:$k',
      if (k < answers) 'ans:$k',
    ],
  ];

  void _revealByProgress() {
    final p = _progress.value;
    final n = _timeline.length;
    var added = false;
    for (var j = 0; j < n; j++) {
      if (p >= _threshold(j, n) && _shownKeys.add(_timeline[j])) added = true;
    }
    if (added && mounted) setState(() {});
  }

  /// Сколько вещей подряд, с первой, уже открыто.
  int get _itemsShown {
    var count = 0;
    while (_shownKeys.contains('item:$count')) {
      count++;
    }
    return count;
  }

  /// Прогресс 0..1 — каждый кадр (рама, процент).
  final ValueNotifier<double> _progress = ValueNotifier(0);

  /// Он же ступеньками по 2,5% — для проявления фото. Размытие и цвет снимка
  /// дорого пересчитывать каждый кадр (на планшете это и роняло кадры), а
  /// шаг в 2,5% на глаз не виден.
  final ValueNotifier<double> _develop = ValueNotifier(0);

  /// Кадры для прогресса — свои, не от [_scan]. Декор при системном «отключить
  /// анимации» (на киосках включают часто) стоит, а прогресс — это информация:
  /// без своих кадров он двигался бы рывком раз в секунду.
  late final Ticker _progressTicker = createTicker(_onProgressFrame);

  @override
  void initState() {
    super.initState();
    _lastElapsed = widget.controller.elapsedSec;
    _baseSec = _lastElapsed.toDouble();
    _progress.addListener(_revealByProgress);
    _progressTicker.start();
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

  /// Кривая ожидания: к обычному для станции времени генерации
  /// ([MirrorSessionController.expectedGenSec]) — плавно к 90%, дальше
  /// медленный хвост к 95%. Время станция выучивает по прошлым образам,
  /// поэтому готовность приходит около 90%, а не прыжком с середины.
  double _targetFor(double t) {
    final expected = widget.controller.expectedGenSec;
    // Чуть мягче easeOut: начало не убегает, конец не залипает.
    final x = (t / expected).clamp(0.0, 1.0);
    final base = (1 - math.pow(1 - x, 1.6)) * 0.9;
    final crawl = t > expected ? math.min(0.05, (t - expected) * 0.004) : 0.0;
    return (base + crawl).clamp(0.0, 0.95);
  }

  void _onProgressFrame(Duration now) {
    final c = widget.controller;

    // Новая генерация (повтор после ошибки): счётчик контроллера пошёл заново.
    if (c.genFailed) _sawFailure = true;
    final restarted =
        c.elapsedSec < _lastElapsed || (_sawFailure && !c.genFailed);
    _lastElapsed = c.elapsedSec;
    if (restarted) {
      _sawFailure = false;
      _shown = 0;
      _genStart = now;
      _baseSec = 0;
      _finishStart = null;
      _shownKeys.clear();
    }
    if (c.genFailed) return;

    if (c.resultReady) {
      if (_finishStart == null) {
        _finishStart = now;
        _finishFrom = _shown;
      }
      final start = _finishStart!;
      // Остаток — за 0,8–2,5 с, чем больше осталось, тем дольше: без рывка.
      final rest = 1 - _finishFrom;
      final duration = (rest * 3).clamp(0.8, 2.5);
      final x = ((now - start).inMicroseconds / 1e6 / duration).clamp(0.0, 1.0);
      final run = _finishFrom + rest * Curves.easeInOutCubic.transform(x);
      _shown = math.max(_shown, math.min(run, _imageReady ? 1.0 : 0.97));
      if (_shown >= 1 && !_revealed) {
        _revealed = true;
        // Открываем результат после кадра со 100% — не посреди тика.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) c.revealResult();
        });
      }
    } else {
      // Прогресс только растёт.
      final t = _baseSec + (now - _genStart).inMicroseconds / 1e6;
      _shown = math.max(_shown, _targetFor(t));
    }
    _progress.value = _shown;
    _develop.value = (_shown * 40).round() / 40;
  }

  @override
  void dispose() {
    _progressTicker.dispose();
    _progress.dispose();
    _develop.dispose();
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
      answers.add(
        _Answer(
          kicker: l10n.mirrorGenderLabel,
          value: gender == 'MALE' ? l10n.mirrorMale : l10n.mirrorFemale,
        ),
      );
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
      answers.add(_Answer(kicker: l10n.mirrorShapeLabel, value: label));
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
      answers.add(
        _Answer(kicker: l10n.mirrorGenStyleLabel, value: labels.join(' · ')),
      );
    } else if (c.path == MirrorPath.catalog && c.pickedProductIds.isNotEmpty) {
      answers.add(
        _Answer(
          kicker: l10n.mirrorPicked,
          value: l10n.mirrorGenPickedCount(c.pickedProductIds.length),
        ),
      );
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

    final stages = [
      l10n.mirrorGen1,
      l10n.mirrorGen2,
      l10n.mirrorGen3,
      l10n.mirrorGen4,
    ];
    // Этап ~25 секунд (образ через FASHN ≈105 c); последний держится до конца.
    final activeStage = math.min(c.generationStage, stages.length - 1);
    final answers = _answers(l10n);
    _timeline = _timelineFor(c.generatingItems.length, answers.length);

    // Открытую вещь можно рассмотреть, не дожидаясь образа: касание — карточка
    // подробностей (без цены — на этом экране только образ).
    return MirrorItemDetails(
      lang: c.shopperLang,
      sizesFor: c.sizesFor,
      showPrice: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 0),
        child: Column(
          children: [
            Expanded(
              child: _DevelopingMirror(
                progress: _progress,
                develop: _develop,
                stage: activeStage,
                photo: c.capturedPhoto,
                answers: answers,
                answerShown: [
                  for (var i = 0; i < answers.length; i++)
                    _shownKeys.contains('ans:$i'),
                ],
                scan: _scan,
                ambient: _ambient,
              ),
            ),
            SizedBox(height: 12 * s),
            // Вещи образа: бэкенд подбирает их до картинки, а показываем по
            // одной по ходу прогресса — образ «собирается» на глазах, пока
            // зеркало его проявляет. Место под ленту держим всегда — зеркало
            // не прыгает, когда вещи приходят.
            SizedBox(
              height: 112 * s,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: c.generatingItems.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('no-items'))
                    : _LookItemsStrip(
                        key: const ValueKey('items'),
                        items: c.generatingItems,
                        lang: c.shopperLang,
                        revealed: _itemsShown,
                        ambient: _ambient,
                        thumbKey: _thumbKey,
                      ),
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              l10n.mirrorGenTitle,
              textAlign: TextAlign.center,
              style: t.headline(30 * s),
            ),
            SizedBox(height: 10 * s),
            _StatusLine(text: stages[activeStage], stage: activeStage),
            SizedBox(
              height: 30 * s,
              child: c.generationRunsLong
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
    final code = (reason ?? '').replaceFirst('KIOSK_', '');
    final limited = code == 'REGENERATE_LIMIT' || code == 'RATE_LIMIT';
    final unavailable = MirrorSessionController.isLookUnavailable(reason);
    // Человеку у стенда — понятный текст, а не код ошибки (код уходит в аналитику).
    final String? reasonText = unavailable
        ? l10n.mirrorLookUnavailable
        : limited
        ? l10n.mirrorGenLimit
        : code == 'TIMEOUT'
        ? l10n.mirrorGenTimeout
        : null;
    final canRetry = !unavailable && !limited;

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
              if (canRetry) ...[
                SizedBox(height: 24 * s),
                MirrorPrimaryButton(
                  label: l10n.mirrorGenRetry,
                  height: 60 * s,
                  onTap: c.retryGeneration,
                ),
              ],
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
    // Открывает результат тикер прогресса, когда рама дойдёт до 100%.
    _imageReady = true;
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
  const _Answer({required this.kicker, required this.value});

  final String kicker;
  final String value;
}

/// Сцена экрана генерации: арочное зеркало с фото покупателя, рама-прогресс,
/// сканирование, ответы на раме, процент на нижней кромке. Каждый слой слушает
/// только своё: рама и процент — [progress] каждый кадр, фото — ступенчатый
/// [develop]; слои разделены RepaintBoundary, чтобы бегущая линия рамы не
/// заставляла перерисовывать размытое фото.
class _DevelopingMirror extends StatelessWidget {
  const _DevelopingMirror({
    required this.progress,
    required this.develop,
    required this.stage,
    required this.photo,
    required this.answers,
    required this.answerShown,
    required this.scan,
    required this.ambient,
  });

  final ValueListenable<double> progress;
  final ValueListenable<double> develop;
  final int stage;
  final File? photo;
  final List<_Answer> answers;

  /// Какие ответы уже открыты (общая лента появлений экрана).
  final List<bool> answerShown;
  final Animation<double> scan;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        // Стекло общего размера (как на камере и результате); ответы
        // заходят на раму с боков.
        final arch = mirrorGlassRect(
          context,
          size,
          center: Offset(size.width / 2, size.height * 0.49),
        );
        final chipMaxW = math.min(250 * s, size.width * 0.48);
        // Ответы по очереди слева и справа, на своих высотах.
        const slots = [0.24, 0.40, 0.60, 0.74];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Мягкое свечение цветом бренда за зеркалом.
            // Ореол перерисовывается только на ступеньках проявки; пульс —
            // прозрачностью готового слоя, а не размытием заново каждый кадр.
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: develop,
                builder: (context, value, _) => MirrorBreathingHalo(
                  arch: arch,
                  color: t.glow,
                  base: 0.14 + 0.10 * value,
                  swing: 0.05,
                  pulse: ambient,
                  shape: t.mirror,
                  s: s,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: arch,
              child: ValueListenableBuilder<double>(
                valueListenable: develop,
                builder: (context, value, _) => _MirrorGlass(
                  photo: photo,
                  develop: value,
                  stage: stage,
                  scan: scan,
                ),
              ),
            ),
            // Рама: тонкий контур и поверх — линия прогресса с точкой.
            Positioned.fromRect(
              rect: arch.inflate(mirrorFrameInset(t.mirror, s)),
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([ambient, progress]),
                    builder: (context, _) => CustomPaint(
                      painter: MirrorArchFramePainter(
                        shape: t.mirror,
                        progress: progress.value,
                        track: t.hairline,
                        color: t.primary,
                        glow: Curves.easeInOut.transform(ambient.value),
                        s: s,
                      ),
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
                  visible: answerShown[i],
                  fromLeft: i.isEven,
                  maxWidth: chipMaxW,
                ),
              ),
            // Процент — плашкой по центру нижней линии рамы (как сумма на
            // результате).
            Positioned(
              left: 0,
              right: 0,
              top: arch.bottom + mirrorFrameInset(t.mirror, s),
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (context, value, _) =>
                        _PercentBadge(percent: (value * 100).floor()),
                  ),
                ),
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
    required this.develop,
    required this.stage,
    required this.scan,
  });

  final File? photo;

  /// Насколько фото проявилось, 0..1 (ступеньками, см. `_develop`).
  final double develop;
  final int stage;
  final Animation<double> scan;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final file = photo;
    // Проявление: насыщенность 10% → 100%, размытие 5 → 0.
    final develop = this.develop.clamp(0.0, 1.0);
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
      clipper: MirrorArchClipper(t.mirror),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: t.surface),
          // Своим слоем: полоса сканирования бежит каждый кадр, а фото с
          // фильтрами перерисовывается только на шаге проявления.
          RepaintBoundary(child: image),
          // Лёгкая «вуаль» цвета бренда, которая уходит по мере проявления.
          IgnorePointer(
            child: ColoredBox(
              color: t.primary.withValues(alpha: 0.10 * (1 - develop)),
            ),
          ),
          // Полоса сканирования.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: scan,
              builder: (context, _) => CustomPaint(
                painter: _ScanPainter(
                  value: scan.value,
                  color: t.primary,
                  s: s,
                ),
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
  const _ScanPainter({
    required this.value,
    required this.color,
    required this.s,
  });

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
        crossAxisAlignment: fromLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            t.kickerCase(answer.kicker),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.kicker(s * 0.8),
          ),
          SizedBox(height: 5 * s),
          // Одной строкой: длинное («Перевёрнутый треугольник», три стиля)
          // ужимается, а не переносится посреди слова.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              answer.value,
              maxLines: 1,
              softWrap: false,
              style: t
                  .label(14 * s, weight: FontWeight.w700)
                  .copyWith(height: 1.2),
            ),
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
  const _PercentBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return MirrorArchBadge(
      child: Text('$percent%', style: t.price(16 * s, color: t.onPrimary)),
    );
  }
}

/// Вещи будущего образа на экране генерации. Состав известен с первых
/// секунд, но открываем его по одной вещи вперемешку с ответами на раме
/// (общая лента экрана): пустые ячейки «дышат», и каждая вещь появляется со
/// вспышкой. Цены здесь нет — только образ.
class _LookItemsStrip extends StatelessWidget {
  const _LookItemsStrip({
    super.key,
    required this.items,
    required this.lang,
    required this.revealed,
    required this.ambient,
    required this.thumbKey,
  });

  final List<KioskLookItem> items;
  final String lang;

  /// Сколько вещей, с первой, уже открыто.
  final int revealed;
  final Animation<double> ambient;
  final GlobalKey Function(KioskLookItem) thumbKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final n = items.length;
    final counter = revealed >= n
        ? l10n.mirrorItemsCount(n)
        : l10n.mirrorGenItemsShown(revealed, n);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            t.kickerCase('${l10n.mirrorItemInLook} · $counter'),
            key: ValueKey(counter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.kicker(s * 0.85),
          ),
        ),
        SizedBox(height: 8 * s),
        Expanded(
          child: Center(
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20 * s),
              itemCount: n,
              separatorBuilder: (_, __) => SizedBox(width: 10 * s),
              itemBuilder: (context, i) => SizedBox(
                width: 76 * s,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: i < revealed
                      ? _RevealedItemTile(
                          key: ValueKey(items[i].productId),
                          item: items[i],
                          lang: lang,
                          thumbKey: thumbKey(items[i]),
                        )
                      : _PendingSlot(
                          key: ValueKey('slot-$i'),
                          ambient: ambient,
                          // Ячейки «дышат» вразнобой, а не хором.
                          phase: i * 0.25,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Пустая ячейка будущей вещи: силуэт вешалки, мягко «дышит».
class _PendingSlot extends StatelessWidget {
  const _PendingSlot({super.key, required this.ambient, required this.phase});

  final Animation<double> ambient;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        // Синус от непрерывного значения — без скачка на стыке циклов.
        final v = 0.5 + 0.5 * math.sin((ambient.value + phase) * 2 * math.pi);
        return Opacity(opacity: 0.45 + 0.4 * v, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(math.min(t.rCard, 14 * s)),
          border: Border.all(color: t.hairline),
        ),
        child: Center(
          child: Icon(Icons.checkroom_rounded, size: 28 * s, color: t.muted),
        ),
      ),
    );
  }
}

/// Открытая вещь: фото и категория. Появляется с отскоком и вспышкой
/// цвета бренда по рамке.
class _RevealedItemTile extends StatelessWidget {
  const _RevealedItemTile({
    super.key,
    required this.item,
    required this.lang,
    required this.thumbKey,
  });

  final KioskLookItem item;
  final String lang;

  /// Ключ фото — из него карточка подробностей «вырастает» и в него же
  /// возвращается.
  final GlobalKey thumbKey;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final url = item.imageUrl;
    final category = item.category == null
        ? null
        : kioskCategories.where((c) => c.code == item.category).firstOrNull;
    final still = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(math.min(t.rCard, 14 * s));

    final tile = Container(
      padding: EdgeInsets.all(5 * s),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.hairline),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              key: thumbKey,
              borderRadius: BorderRadius.circular(math.min(t.rImage, 9 * s)),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox.expand(
                  child: url == null
                      ? null
                      : CachedNetworkImage(
                          imageUrl: url,
                          cacheManager: KioskImageCache.instance,
                          fit: BoxFit.cover,
                          memCacheWidth: 240,
                          placeholder: (_, __) => ColoredBox(color: t.surface),
                          errorWidget: (_, __, ___) =>
                              ColoredBox(color: t.surface),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            category == null
                ? item.title
                : t.brand.categoryLabel(category, lang),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.label(10.5 * s, weight: FontWeight.w600, color: t.muted),
          ),
        ],
      ),
    );

    final tappable = Semantics(
      button: true,
      label: item.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => MirrorItemDetails.open(context, item, thumbKey),
        child: tile,
      ),
    );
    if (still) return tappable;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, v, child) {
        final pop = Curves.easeOutBack.transform(math.min(1.0, v / 0.7));
        final flash = (1 - v).clamp(0.0, 1.0);
        return Opacity(
          opacity: math.min(1.0, v * 2.5),
          child: Transform.scale(
            scale: 0.6 + 0.4 * pop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.55 * flash),
                    blurRadius: 18 * s,
                    spreadRadius: 2 * s * flash,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: tappable,
    );
  }
}
