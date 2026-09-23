import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_arch.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';
import '../widgets/mirror_item_details.dart';

/// Экран результата — продолжение экрана генерации: то же арочное зеркало
/// бренда, но в нём уже готовый образ, рама замкнута, на нижней кромке —
/// сумма образа. Вещи образа приколоты к раме карточками (фото, название,
/// цена), справа сверху — QR «Заберите образ в телефон». Под зеркалом —
/// заголовок и два действия. Входы каскадные, как у онбординга.
class MirrorResultScreen extends StatefulWidget {
  const MirrorResultScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorResultScreen> createState() => _MirrorResultScreenState();
}

class _MirrorResultScreenState extends State<MirrorResultScreen>
    with TickerProviderStateMixin {
  /// Каскадный вход (таймлайн 1.2с, как у слайдов онбординга).
  late final AnimationController _entrance;

  /// Дыхание свечения рамы.
  late final AnimationController _ambient;
  bool _started = false;

  bool _qrPulse = false;
  Timer? _pulseTimer;

  /// Ключи миниатюр ленты: из них вырастает карточка подробностей.
  final Map<String, GlobalKey> _thumbKeys = {};

  GlobalKey _keyFor(KioskLookItem item) =>
      _thumbKeys.putIfAbsent(item.productId, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      _entrance.value = 1;
      _ambient
        ..stop()
        ..value = 0.5;
    } else {
      if (!_started) {
        _started = true;
        _entrance.forward();
      }
      if (!_ambient.isAnimating) _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// «Скачать фото» — скачивать на киоске некуда: подсвечиваем QR и
  /// объясняем, что фото уедет в телефон.
  void _onDownloadTap() {
    setState(() => _qrPulse = true);
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _qrPulse = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = widget.controller;
    final look = c.look;
    if (look == null) return const SizedBox.shrink();

    final lang = c.shopperLang;
    final pad = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MirrorItemDetails(
        lang: lang,
        child: ColoredBox(
          color: t.bg,
          child: Column(
            children: [
              SizedBox(height: pad.top + 10 * s),
              // Шапка: «назад» и знак бренда по центру.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                child: Entrance(
                  parent: _entrance,
                  kind: IntroEntranceKind.rise,
                  child: Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        size: 44 * s,
                        onTap: c.goBack,
                      ),
                      Expanded(
                        child: Center(child: MirrorBrandMark(height: 15 * s)),
                      ),
                      SizedBox(width: 44 * s),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 6 * s),
              Expanded(
                child: _ResultMirror(
                  look: look,
                  lang: lang,
                  entrance: _entrance,
                  ambient: _ambient,
                  qrUrl: c.shareUrl,
                  qrPulse: _qrPulse,
                  onQrTap: _onDownloadTap,
                ),
              ),
              SizedBox(height: 26 * s),
              // Вещи образа — одной лентой под суммой; касание открывает
              // подробности вещи.
              Entrance(
                parent: _entrance,
                kind: IntroEntranceKind.rise,
                delay: 0.5,
                child: Text(
                  t.kickerCase(
                    '${l10n.mirrorResultTag} · '
                    '${l10n.mirrorItemsCount(look.items.length)}',
                  ),
                  style: t.kicker(s, color: t.muted),
                ),
              ),
              SizedBox(height: 10 * s),
              _ItemsRow(
                items: look.items,
                lang: lang,
                entrance: _entrance,
                keyFor: _keyFor,
              ),
              SizedBox(height: 14 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                child: Entrance(
                  parent: _entrance,
                  kind: IntroEntranceKind.rise,
                  delay: 0.7,
                  duration: 0.5,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 100,
                        child: MirrorGhostButton(
                          label: c.canRegenerate
                              ? l10n.mirrorRegenerateLeft(c.regenerationsLeft)
                              : l10n.mirrorContinueInApp,
                          height: 56 * s,
                          enabled: c.canRegenerate,
                          onTap: c.regenerate,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Expanded(
                        flex: 145,
                        child: MirrorPrimaryButton(
                          label: l10n.mirrorCollect,
                          height: 56 * s,
                          // Сессия не должна закончиться без QR или кода: пока
                          // finish не прошёл, «Отложить» подождёт (ensureShare
                          // ретраится сам).
                          enabled: c.sellerCode != null,
                          gleam: true,
                          onTap: c.openBuy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: pad.bottom + 16 * s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Зеркало с готовым образом: свечение, стекло с образом (проявляется из
/// лёгкого размытия), замкнутая рама, вещи и QR на раме, сумма на кромке.
class _ResultMirror extends StatelessWidget {
  const _ResultMirror({
    required this.look,
    required this.lang,
    required this.entrance,
    required this.ambient,
    required this.qrUrl,
    required this.qrPulse,
    required this.onQrTap,
  });

  final KioskLook look;
  final String lang;
  final Animation<double> entrance;
  final Animation<double> ambient;
  final String? qrUrl;
  final bool qrPulse;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final image = _lookImage(look);

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        // Узкий экран (телефон): зеркало шире, QR мельче. Вещи везде —
        // компактные ярлыки «фото + цена» на кромке рамы: образ не
        // закрывается, названия есть на экране состава.
        final compact = size.width < 600;
        // Арка в пропорции результата (2:3) — образ виден целиком.
        final maxH = size.height - 22 * s;
        final archW =
            math.min(maxH * 2 / 3, size.width * (compact ? 0.7 : 0.58));
        final archH = math.min(maxH, archW * 1.5);
        final arch = Rect.fromLTWH(
          size.width / 2 - archW / 2,
          (maxH - archH) / 2,
          archW,
          archH,
        );
        final inset = arch.width * 0.06;
        final qrSize = (compact ? 70 : 84) * s;
        final qrPad = (compact ? 7 : 10) * s;
        // Карточка QR не должна уходить за край экрана.
        final qrLeft = math.min(
          arch.right - inset,
          size.width - (qrSize + qrPad * 2) - 6 * s,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: ambient,
                builder: (context, _) => CustomPaint(
                  painter: MirrorArchHaloPainter(
                    arch: arch,
                    color: t.primary,
                    strength:
                        0.22 + 0.06 * Curves.easeInOut.transform(ambient.value),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: arch,
              child: _RevealGlass(image: image, entrance: entrance),
            ),
            Positioned.fromRect(
              rect: arch.inflate(8 * s),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: ambient,
                  builder: (context, _) => CustomPaint(
                    painter: MirrorArchFramePainter(
                      progress: 1,
                      track: t.hairline,
                      color: t.primary,
                      glow: Curves.easeInOut.transform(ambient.value),
                      s: s,
                    ),
                  ),
                ),
              ),
            ),
            // Искры у рамы — образ готов.
            for (final (dx, dy, sz, delay) in const [
              (-0.10, 0.08, 16.0, 0.0),
              (1.06, 0.44, 13.0, 0.8),
              (-0.07, 0.72, 11.0, 1.4),
            ])
              Positioned(
                left: arch.left + arch.width * dx,
                top: arch.top + arch.height * dy,
                child: Twinkle(
                  color: t.primary,
                  size: sz * s,
                  delaySeconds: delay,
                ),
              ),
            // QR — справа сверху на раме.
            Positioned(
              left: qrLeft,
              top: arch.top + arch.height * 0.04,
              child: Entrance(
                parent: entrance,
                kind: IntroEntranceKind.flyR,
                delay: 0.42,
                child: GestureDetector(
                  onTap: onQrTap,
                  child: MirrorPinnedCard(
                    fromLeft: false,
                    highlight: qrPulse,
                    padding: EdgeInsets.all(qrPad),
                    child: _QrContent(
                      shareUrl: qrUrl,
                      pulse: qrPulse,
                      size: qrSize,
                    ),
                  ),
                ),
              ),
            ),
            // Сумма образа — на нижней кромке рамы.
            Positioned(
              left: 0,
              right: 0,
              top: arch.bottom - 4 * s,
              child: Center(
                child: Entrance(
                  parent: entrance,
                  kind: IntroEntranceKind.pop,
                  delay: 0.35,
                  child: MirrorArchBadge(
                    child: _CountUpPrice(
                      total: look.totalPrice,
                      lang: lang,
                      size: 17 * s,
                      color: t.onPrimary,
                    ),
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

/// Стекло зеркала с образом: проявляется из лёгкого размытия, по нему один
/// раз пробегает блик.
class _RevealGlass extends StatelessWidget {
  const _RevealGlass({required this.image, required this.entrance});

  final ImageProvider? image;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final img = image;
    final reveal = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    );
    return ClipPath(
      clipper: const MirrorArchClipper(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: t.surface),
          if (img != null)
            AnimatedBuilder(
              animation: reveal,
              builder: (context, child) {
                final sigma = 8 * (1 - reveal.value);
                final scaled = Transform.scale(
                  scale: 1.04 - 0.04 * reveal.value,
                  child: child,
                );
                return sigma < 0.05
                    ? scaled
                    : ImageFiltered(
                        imageFilter:
                            ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        child: scaled,
                      );
              },
              child: Image(
                image: img,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
              ),
            ),
          const Gleam(
            durationMs: 5200,
            travelFraction: 0.4,
            widthFraction: 0.3,
            opacity: 0.35,
            initialDelayMs: 700,
          ),
        ],
      ),
    );
  }
}

/// Круглая кнопка на светлом фоне.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: t.surface,
        shape: t.iconButtonShape(side: BorderSide(color: t.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: size * 0.4, color: t.ink),
        ),
      ),
    );
  }
}

/// Лента вещей образа под суммой: миниатюра, категория и цена. Если вещи
/// не влезают в ширину — лента листается; если влезают — стоит по центру.
class _ItemsRow extends StatelessWidget {
  const _ItemsRow({
    required this.items,
    required this.lang,
    required this.entrance,
    required this.keyFor,
  });

  final List<KioskLookItem> items;
  final String lang;
  final Animation<double> entrance;
  final GlobalKey Function(KioskLookItem) keyFor;

  @override
  Widget build(BuildContext context) {
    final s = MirrorTheme.scale(context);
    return SizedBox(
      height: 124 * s,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(width: 10 * s),
          itemBuilder: (context, i) => Entrance(
            parent: entrance,
            kind: IntroEntranceKind.riseCard,
            delay: (0.55 + 0.06 * i).clamp(0.0, 0.8),
            duration: 0.45,
            child: _ItemTile(
              item: items[i],
              lang: lang,
              thumbKey: keyFor(items[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.lang,
    required this.thumbKey,
  });

  final KioskLookItem item;
  final String lang;
  final GlobalKey thumbKey;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final item = widget.item;
    final category = item.category == null
        ? null
        : kioskCategories.where((c) => c.code == item.category).firstOrNull;

    return Semantics(
      button: true,
      label: item.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () => MirrorItemDetails.open(context, item, widget.thumbKey),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 84 * s,
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(math.min(t.rCard, 16 * s)),
              border: Border.all(color: t.hairline),
            ),
            child: Column(
              children: [
                ClipRRect(
                  key: widget.thumbKey,
                  borderRadius:
                      BorderRadius.circular(math.min(t.rImage, 10 * s)),
                  child: SizedBox(
                    width: 72 * s,
                    height: 72 * s,
                    child: ColoredBox(
                      color: Colors.white,
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 240,
                              placeholder: (_, __) =>
                                  ColoredBox(color: t.surface),
                              errorWidget: (_, __, ___) =>
                                  ColoredBox(color: t.surface),
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  category == null
                      ? item.title
                      : t.brand.categoryLabel(category, widget.lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label(10.5 * s,
                      weight: FontWeight.w600, color: t.muted),
                ),
                SizedBox(height: 2 * s),
                Text(
                  item.price != null ? kioskMoneyShort(item.price!) : '—',
                  maxLines: 1,
                  style: t.price(12.5 * s, color: t.primaryBright),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Источник картинки результата: файл в демо-режиме, иначе сеть через тот же
/// провайдер, которым экран генерации её уже прогрел.
ImageProvider? _lookImage(KioskLook look) {
  final localPath = look.localResultPath;
  if (localPath != null) return FileImage(File(localPath));
  final url = look.resultImageUrl;
  if (url != null && url.startsWith('http')) {
    return CachedNetworkImageProvider(url);
  }
  return null;
}

/// Содержимое карточки QR: «Заберите образ в телефон». Пока finish не
/// ответил — шиммер. Сам QR всегда чернилами на белом — сканеру нужен
/// контраст, не бренд.
class _QrContent extends StatelessWidget {
  const _QrContent({
    required this.shareUrl,
    required this.pulse,
    required this.size,
  });

  final String? shareUrl;
  final bool pulse;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final url = shareUrl;
    final qrSize = size;

    return SizedBox(
      width: qrSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6 * s),
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(5 * s),
                child: url != null
                    ? QrImageView(
                        data: url,
                        size: qrSize - 10 * s,
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
                      )
                    : Shimmer.fromColors(
                        baseColor: t.hairline,
                        highlightColor: Colors.white,
                        child: Container(
                          width: qrSize - 10 * s,
                          height: qrSize - 10 * s,
                          color: t.hairline,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 7 * s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              pulse ? l10n.mirrorDownloadHint : l10n.mirrorQrTitle,
              key: ValueKey(pulse),
              textAlign: TextAlign.center,
              maxLines: 4,
              style: t
                  .label(10.5 * s, weight: FontWeight.w600)
                  .copyWith(height: 1.25),
            ),
          ),
          SizedBox(height: 5 * s),
          Text(
            l10n.mirrorDownload,
            style: t
                .label(10.5 * s, weight: FontWeight.w600, color: t.primary)
                .copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: t.primary.withValues(alpha: 0.45),
                ),
          ),
        ],
      ),
    );
  }
}

/// Сумма образа, «набегающая» от нуля — маленькая радость в конце пути.
class _CountUpPrice extends StatelessWidget {
  const _CountUpPrice({
    required this.total,
    required this.lang,
    required this.size,
    required this.color,
  });

  final int total;
  final String lang;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: reduceMotion ? total.toDouble() : 0,
        end: total.toDouble(),
      ),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        kioskMoney(v.round(), lang),
        style: t.price(size, color: color),
      ),
    );
  }
}

/// Экран состава образа — финал сессии. Сверху «билет на примерку» в
/// цветах бренда: миниатюра образа в арке, код для продавца (буквы
/// проявляются по очереди) и итог под линией отрыва. Ниже — вещи образа;
/// касание вещи открывает её подробности.
class MirrorBuyScreen extends StatefulWidget {
  const MirrorBuyScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorBuyScreen> createState() => _MirrorBuyScreenState();
}

class _MirrorBuyScreenState extends State<MirrorBuyScreen> {
  final Map<String, GlobalKey> _thumbKeys = {};

  GlobalKey _keyFor(KioskLookItem item) =>
      _thumbKeys.putIfAbsent(item.productId, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = widget.controller;
    final look = c.look;
    if (look == null) return const SizedBox.shrink();
    final lang = c.shopperLang;
    final pad = MediaQuery.paddingOf(context);

    return MirrorItemDetails(
      lang: lang,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18 * s),
            MirrorFadeIn(
              rise: 24,
              child: _FittingTicket(
                code: c.sellerCode,
                total: look.totalPrice,
                lang: lang,
                image: _lookImage(look),
              ),
            ),
            SizedBox(height: 22 * s),
            MirrorFadeIn(
              delayMs: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      l10n.mirrorBuyTitle,
                      style: t.headline(26 * s),
                    ),
                  ),
                  Text(
                    l10n.mirrorItemsCount(look.items.length),
                    style: t.subtitle(14 * s),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4 * s),
            MirrorFadeIn(
              delayMs: 160,
              child: Row(
                children: [
                  Container(
                    width: 7 * s,
                    height: 7 * s,
                    decoration: BoxDecoration(
                      color: t.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 7 * s),
                  Expanded(
                    child: Text(
                      l10n.mirrorBuySubtitle,
                      style: t.subtitle(13.5 * s),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10 * s),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 * s),
                itemCount: look.items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10 * s),
                itemBuilder: (context, i) => MirrorFadeIn(
                  delayMs: 200 + 70 * i,
                  child: _LookItemRow(
                    item: look.items[i],
                    lang: lang,
                    thumbKey: _keyFor(look.items[i]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * s),
            // «Вернуться к образу» и «Завершить»: второе закрывает сессию
            // (фото удаляется) и возвращает киоск на постер — к следующему
            // покупателю.
            Row(
              children: [
                Expanded(
                  child: MirrorGhostButton(
                    label: l10n.mirrorBackToLook,
                    height: 58 * s,
                    onTap: c.goBack,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: MirrorPrimaryButton(
                    label: l10n.mirrorFinish,
                    height: 58 * s,
                    onTap: () => c.hardReset('finish'),
                  ),
                ),
              ],
            ),
            SizedBox(height: pad.bottom + 18 * s),
          ],
        ),
      ),
    );
  }
}

/// Билет на примерку: форма с вырезами по бокам на линии отрыва.
class _FittingTicket extends StatelessWidget {
  const _FittingTicket({
    required this.code,
    required this.total,
    required this.lang,
    required this.image,
  });

  final String? code;
  final int total;
  final String lang;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final colors =
        t.brand.palette.primaryGradient ?? [t.primary, t.primaryDeep];
    final topH = 148 * s;
    final bottomH = 58 * s;
    final notch = 12 * s;
    final on = t.onPrimary;
    final img = image;

    return ClipPath(
      clipper: _TicketClipper(
        cut: topH,
        notch: notch,
        radius: math.min(t.rCard + 6, 24 * s),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            // Знак бренда водяным знаком в углу.
            Positioned(
              top: 14 * s,
              right: 16 * s,
              child: MirrorBrandMark(
                height: 12 * s,
                color: on.withValues(alpha: 0.55),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: topH,
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(18 * s, 16 * s, 18 * s, 16 * s),
                    child: Row(
                      children: [
                        // Образ в маленькой арке — тот же, что в зеркале.
                        Container(
                          width: 74 * s,
                          height: topH - 32 * s,
                          padding: EdgeInsets.all(3 * s),
                          decoration: ShapeDecoration(
                            color: on.withValues(alpha: 0.9),
                            shape: const _ArchBorder(),
                          ),
                          child: ClipPath(
                            clipper: const MirrorArchClipper(),
                            child: img == null
                                ? ColoredBox(color: t.surface)
                                : Image(
                                    image: img,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                          ),
                        ),
                        SizedBox(width: 16 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.kickerCase(l10n.mirrorCodeKicker),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.kicker(
                                  s * 0.85,
                                  color: on.withValues(alpha: 0.8),
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _CodeReveal(
                                  code: code,
                                  style: t
                                      .price(34 * s, color: on)
                                      .copyWith(letterSpacing: 4 * s),
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                l10n.mirrorCodeLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t
                                    .label(
                                      12 * s,
                                      weight: FontWeight.w500,
                                      color: on.withValues(alpha: 0.85),
                                    )
                                    .copyWith(height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Линия отрыва.
                SizedBox(
                  height: 1.5 * s,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _DashPainter(
                      color: on.withValues(alpha: 0.5),
                      inset: notch + 6 * s,
                      s: s,
                    ),
                  ),
                ),
                SizedBox(
                  height: bottomH,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22 * s),
                    child: Row(
                      children: [
                        Text(
                          l10n.mirrorTotal,
                          style: t.label(
                            15 * s,
                            weight: FontWeight.w600,
                            color: on.withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          kioskMoney(total, lang),
                          style: t.price(21 * s, color: on),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: Gleam(
                  durationMs: 5200,
                  travelFraction: 0.45,
                  widthFraction: 0.3,
                  opacity: 0.22,
                  initialDelayMs: 900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Буквы кода проявляются по очереди, с лёгким подъёмом. Пока кода нет —
/// спокойные точки.
class _CodeReveal extends StatelessWidget {
  const _CodeReveal({required this.code, required this.style});

  final String? code;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final value = code;
    if (value == null) return Text('· · ·', style: style);
    final still = MediaQuery.disableAnimationsOf(context);
    final chars = value.characters.toList();
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: Duration(milliseconds: 300 + 90 * chars.length),
      builder: (context, v, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chars.length; i++)
            Builder(
              builder: (context) {
                final start = i / (chars.length + 3);
                final k =
                    ((v - start) * (chars.length + 3) / 4).clamp(0.0, 1.0);
                final e = Curves.easeOutBack.transform(k);
                return Opacity(
                  opacity: k,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - e)),
                    child: Text(chars[i], style: style),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({
    required this.cut,
    required this.notch,
    required this.radius,
  });

  final double cut;
  final double notch;
  final double radius;

  @override
  Path getClip(Size size) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, cut), radius: notch))
      ..addOval(
          Rect.fromCircle(center: Offset(size.width, cut), radius: notch));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.cut != cut || old.notch != notch || old.radius != radius;
}

class _DashPainter extends CustomPainter {
  const _DashPainter(
      {required this.color, required this.inset, required this.s});

  final Color color;
  final double inset;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final dash = 6 * s;
    final gap = 5 * s;
    final y = size.height / 2;
    for (var x = inset; x < size.width - inset; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width - inset), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.inset != inset || old.s != s;
}

/// Рамка-арка для миниатюры образа.
class _ArchBorder extends OutlinedBorder {
  const _ArchBorder({super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      mirrorArchPath(rect.size).shift(rect.topLeft);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _ArchBorder(side: side.scale(t));

  @override
  _ArchBorder copyWith({BorderSide? side}) =>
      _ArchBorder(side: side ?? this.side);
}

/// Вещь образа на финальном экране: фото, название, размер и наличие, цена.
/// Касание открывает подробности.
class _LookItemRow extends StatelessWidget {
  const _LookItemRow({
    required this.item,
    required this.lang,
    required this.thumbKey,
  });

  final KioskLookItem item;
  final String lang;
  final GlobalKey thumbKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.min(t.rCard, 18 * s)),
        side: BorderSide(color: t.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => MirrorItemDetails.open(context, item, thumbKey),
        child: Padding(
          padding: EdgeInsets.all(10 * s),
          child: Row(
            children: [
              ClipRRect(
                key: thumbKey,
                borderRadius: BorderRadius.circular(math.min(t.rImage, 12 * s)),
                child: SizedBox(
                  width: 58 * s,
                  height: 70 * s,
                  child: ColoredBox(
                    color: Colors.white,
                    child: item.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            placeholder: (_, __) =>
                                ColoredBox(color: t.surface),
                            errorWidget: (_, __, ___) =>
                                ColoredBox(color: t.surface),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t
                          .label(14.5 * s, weight: FontWeight.w600)
                          .copyWith(height: 1.2),
                    ),
                    SizedBox(height: 6 * s),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${l10n.mirrorSizeLabel} '
                            '${item.size == null ? '—' : kioskSizeLabel(item.size!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.subtitle(12.5 * s).copyWith(height: 1.2),
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Text(
                          item.price != null
                              ? kioskMoney(item.price!, lang)
                              : '—',
                          style: t.price(13.5 * s, color: t.primaryDeep),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * s),
              Icon(
                Icons.chevron_right_rounded,
                size: 22 * s,
                color: t.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
