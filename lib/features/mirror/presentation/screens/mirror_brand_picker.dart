import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_chrome.dart';
import 'mirror_cover_screen.dart';

/// Экран выбора оформления — первое, что видит продавец на вкладке
/// «Зеркало». Нужен для показов: одно и то же зеркало в стиле разных брендов.
///
/// Каждая карточка — живой постер бренда (тот же [MirrorCoverScreen],
/// уменьшенный до карточки), поэтому клиент видит оформление в движении, а не
/// картинку. «Запустить зеркало» раскрывает выбранную карточку на весь экран,
/// и постер продолжает жить уже как настоящий. Текст экрана — на языке
/// приложения продавца, а не покупателя.
class MirrorBrandPicker extends StatefulWidget {
  const MirrorBrandPicker({
    super.key,
    required this.brands,
    required this.current,
    required this.controller,
    required this.onPicked,
    this.active = true,
    this.fullscreen = false,
  });

  final List<MirrorBrand> brands;

  /// Оформление, которое сейчас стоит в киоске (выбрано заранее).
  final MirrorBrand current;
  final MirrorSessionController controller;
  final ValueChanged<MirrorBrand> onPicked;
  final bool active;

  /// Так же, как у постера: в полноэкранном режиме нет кнопки «на весь
  /// экран» — превью должно совпасть с настоящим постером.
  final bool fullscreen;

  @override
  State<MirrorBrandPicker> createState() => _MirrorBrandPickerState();
}

class _MirrorBrandPickerState extends State<MirrorBrandPicker>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF0E0C11);

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _zoom;
  late MirrorBrand _selected;

  /// Раскрываемая карточка: откуда растёт превью.
  Rect? _zoomFrom;
  final Map<String, GlobalKey> _cardKeys = {};
  final GlobalKey _rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _zoom.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onPicked(_selected);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _ambient
        ..stop()
        ..value = 0.5;
    } else {
      if (_intro.value == 0 && !_intro.isAnimating) _intro.forward();
      if (!_ambient.isAnimating) _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _zoom.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(MirrorBrand b) =>
      _cardKeys.putIfAbsent(b.id, GlobalKey.new);

  void _select(MirrorBrand b) {
    if (_zoom.isAnimating || _zoomFrom != null) return;
    HapticFeedback.selectionClick();
    if (b.id == _selected.id) {
      _launch();
    } else {
      setState(() => _selected = b);
    }
  }

  void _launch() {
    if (_zoomFrom != null) return;
    final card = _keyFor(_selected).currentContext?.findRenderObject();
    final root = _rootKey.currentContext?.findRenderObject();
    if (card is! RenderBox || root is! RenderBox) {
      widget.onPicked(_selected);
      return;
    }
    final topLeft = card.localToGlobal(Offset.zero, ancestor: root);
    setState(() => _zoomFrom = topLeft & card.size);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onPicked(_selected);
    } else {
      _zoom.forward();
    }
  }

  /// Живой постер бренда в размере полного экрана, вписанный в карточку.
  Widget _preview(MirrorBrand b, Size full, {bool playIntro = true}) {
    return IgnorePointer(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox.fromSize(
          size: full,
          child: MirrorBrandScope(
            brand: b,
            child: Localizations.override(
              context: context,
              locale: Locale(b.defaultLang),
              child: MirrorCoverScreen(
                controller: widget.controller,
                onOpenSetup: _noop,
                active: widget.active,
                fullscreen: widget.fullscreen,
                onEnterFullscreen: widget.fullscreen ? null : _noop,
                playIntro: playIntro,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = MirrorTheme.scale(context);
    final pad = MediaQuery.paddingOf(context);
    final accent = MirrorTheme(_selected).primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        key: _rootKey,
        color: _bg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final full = constraints.biggest;
            final margin = 24.0 * s;

            final content = Column(
              children: [
                SizedBox(height: pad.top + 26 * s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  child: Entrance(
                    parent: _intro,
                    kind: IntroEntranceKind.rise,
                    child: _Header(l10n: l10n, s: s),
                  ),
                ),
                SizedBox(height: 22 * s),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, area) => _cardsRow(
                      area: area.biggest,
                      full: full,
                      margin: margin,
                      s: s,
                      l10n: l10n,
                    ),
                  ),
                ),
                SizedBox(height: 18 * s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  child: Entrance(
                    parent: _intro,
                    kind: IntroEntranceKind.rise,
                    delay: 0.5,
                    child: _StartButton(
                      label: l10n.mirrorPickerStart,
                      brand: _selected,
                      height: 56 * s,
                      onTap: _launch,
                    ),
                  ),
                ),
                SizedBox(height: pad.bottom + 22 * s),
              ],
            );

            final from = _zoomFrom;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Свечение цветом выбранного бренда: перетекает при выборе и
                // медленно дышит.
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: accent),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, color, _) => AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) => CustomPaint(
                      painter: _GlowPainter(
                        color: color ?? accent,
                        breath: Curves.easeInOut.transform(_ambient.value),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _zoom,
                  builder: (context, child) => Opacity(
                    opacity: 1 - Curves.easeOut.transform(_zoom.value),
                    child: child,
                  ),
                  child: content,
                ),
                if (from != null)
                  AnimatedBuilder(
                    animation: _zoom,
                    builder: (context, child) {
                      final k = Curves.easeInOutCubic.transform(_zoom.value);
                      final rect = Rect.lerp(from, Offset.zero & full, k)!;
                      return Positioned.fromRect(
                        rect: rect,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22 * s * (1 - k)),
                          child: child,
                        ),
                      );
                    },
                    // Постер уже «собран»: карточка сыграла вход раньше.
                    child: _preview(_selected, full, playIntro: false),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardsRow({
    required Size area,
    required Size full,
    required double margin,
    required double s,
    required AppLocalizations l10n,
  }) {
    final brands = widget.brands;
    final n = brands.length;
    final gap = 18.0 * s;
    // Под карточкой: отступ, знак, строка описания в две строки.
    final labelH = 82.0 * s;
    final aspect = full.width / full.height;
    final byWidth = (area.width - margin * 2 - gap * (n - 1)) / n;
    final byHeight = (area.height - labelH) * aspect;
    final cardW = math.max(math.min(byWidth, byHeight), 120.0);
    final cardH = cardW / aspect;
    final lang = Localizations.localeOf(context).languageCode;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Entrance(
            parent: _intro,
            kind: n == 1
                ? IntroEntranceKind.riseCard
                : i == 0
                    ? IntroEntranceKind.flyL
                    : i == n - 1
                        ? IntroEntranceKind.flyR
                        : IntroEntranceKind.riseCard,
            delay: 0.15 + 0.1 * i,
            duration: 0.7,
            child: _BrandCard(
              brand: brands[i],
              selected: brands[i].id == _selected.id,
              current: brands[i].id == widget.current.id,
              hidden: _zoomFrom != null && brands[i].id == _selected.id,
              width: cardW,
              height: cardH,
              s: s,
              ambient: _ambient,
              phase: i.isEven,
              tagline: brands[i].taglineFor(lang),
              currentLabel: l10n.mirrorPickerCurrent,
              previewKey: _keyFor(brands[i]),
              preview: _preview(brands[i], full),
              onTap: () => _select(brands[i]),
            ),
          ),
        ],
      ],
    );

    // Карточки не влезли по ширине — листаются вбок.
    final totalW = cardW * n + gap * (n - 1) + margin * 2;
    if (totalW > area.width) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: row,
      );
    }
    return Center(child: row);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n, required this.s});

  final AppLocalizations l10n;
  final double s;

  @override
  Widget build(BuildContext context) {
    const family = 'GolosText';
    return Column(
      children: [
        Text(
          l10n.mirrorPickerKicker.toUpperCase(),
          style: TextStyle(
            fontFamily: family,
            fontSize: 12 * s,
            fontWeight: FontWeight.w700,
            letterSpacing: 12 * s * 0.24,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 12 * s),
        Text(
          l10n.mirrorPickerTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: family,
            fontFamilyFallback: const ['PlayfairDisplay'],
            fontSize: 26 * s,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 26 * s,
            height: 1.1,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10 * s),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 460 * s),
          child: Text(
            l10n.mirrorPickerSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: family,
              fontFamilyFallback: const ['PlayfairDisplay'],
              fontSize: 13 * s,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка бренда: живое превью постера, знак и строка описания.
class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.selected,
    required this.current,
    required this.hidden,
    required this.width,
    required this.height,
    required this.s,
    required this.ambient,
    required this.phase,
    required this.tagline,
    required this.currentLabel,
    required this.previewKey,
    required this.preview,
    required this.onTap,
  });

  final MirrorBrand brand;
  final bool selected;
  final bool current;

  /// Карточка уже раскрывается на весь экран — её место пустеет.
  final bool hidden;
  final double width;
  final double height;
  final double s;
  final Animation<double> ambient;
  final bool phase;
  final String tagline;
  final String currentLabel;
  final GlobalKey previewKey;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = MirrorTheme(brand).primary;
    final radius = BorderRadius.circular(22 * s);

    return Semantics(
      button: true,
      selected: selected,
      label: brand.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0.55,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                // Выбранная карточка чуть парит.
                AnimatedBuilder(
                  animation: ambient,
                  builder: (context, child) {
                    final v = Curves.easeInOut.transform(ambient.value);
                    final dy = selected ? -5 * s * (phase ? v : 1 - v) : 0.0;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: AnimatedScale(
                    scale: selected ? 1 : 0.94,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.12),
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? accent.withValues(alpha: 0.38)
                                : Colors.black.withValues(alpha: 0.35),
                            blurRadius: 36 * s,
                            spreadRadius: -10 * s,
                            offset: Offset(0, 10 * s),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: hidden ? 0 : 1,
                        child: ClipRRect(
                          key: previewKey,
                          borderRadius: radius,
                          child: RepaintBoundary(child: preview),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: MirrorBrandScope(
                        brand: brand,
                        child: MirrorBrandMark(
                          height: 17 * s,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (current) ...[
                      SizedBox(width: 8 * s),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * s,
                          vertical: 3 * s,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          currentLabel,
                          style: TextStyle(
                            fontFamily: 'GolosText',
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6 * s),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'GolosText',
                    fontFamilyFallback: const ['PlayfairDisplay'],
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.55),
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

/// Кнопка запуска в цветах выбранного бренда (градиент, если он у бренда
/// есть); цвет перетекает при смене выбора.
class _StartButton extends StatefulWidget {
  const _StartButton({
    required this.label,
    required this.brand,
    required this.height,
    required this.onTap,
  });

  final String label;
  final MirrorBrand brand;
  final double height;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme(widget.brand);
    final colors = t.brand.palette.primaryGradient ?? [t.primary, t.primary];
    final h = widget.height;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: double.infinity,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.3),
                blurRadius: h * 0.45,
                spreadRadius: -h * 0.2,
                offset: Offset(0, h * 0.12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                    child: Gleam(
                      durationMs: 4200,
                      travelFraction: 0.45,
                      widthFraction: 0.28,
                      opacity: 0.3,
                      initialDelayMs: 1500,
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
                          style: TextStyle(
                            fontFamily: 'GolosText',
                            fontFamilyFallback: const ['PlayfairDisplay'],
                            fontSize: h * 0.3,
                            fontWeight: FontWeight.w700,
                            color: t.onPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: h * 0.15),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: h * 0.36,
                        color: t.onPrimary,
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

/// Мягкое свечение цветом бренда из-за карточек.
class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.color, required this.breath});

  final Color color;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.1),
          radius: 0.75 + 0.08 * breath,
          colors: [
            color.withValues(alpha: 0.30 + 0.08 * breath),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.breath != breath;
}
