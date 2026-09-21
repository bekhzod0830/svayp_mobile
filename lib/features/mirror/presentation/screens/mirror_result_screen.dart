import 'dart:async';
import 'dart:io';
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
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';

/// Экран результата — «момент у зеркала», без верхней планки киоска. Фон —
/// размытая копия образа во весь экран; резкий образ виден ЦЕЛИКОМ в рамке
/// над панелью (обувь и низ не прячутся), проявляется из размытия, по нему
/// пробегает блик. Поверх — матовая кнопка «назад» и знак бренда, парящая
/// карточка QR справа; снизу — матовая панель: заголовок, сумма со счётчиком,
/// лента вещей и два действия. Входы каскадные, как у онбординга.
class MirrorResultScreen extends StatefulWidget {
  const MirrorResultScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorResultScreen> createState() => _MirrorResultScreenState();
}

class _MirrorResultScreenState extends State<MirrorResultScreen>
    with SingleTickerProviderStateMixin {
  /// Каскадный вход (таймлайн 1.2с, как у слайдов онбординга).
  late final AnimationController _entrance;
  bool _started = false;

  bool _qrPulse = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (!_started) {
      _started = true;
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _entrance.dispose();
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
    final image = _lookImage(look);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: t.primaryDeep,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Фон — тот же образ, размытый и притемнённый: экран залит
            // целиком, а резкое фото остаётся видно полностью.
            _Backdrop(image: image),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + 130 * s,
              child: const _Scrim(strength: 0.4),
            ),

            Column(
              children: [
                // Образ целиком (contain) — ноги и обувь не уходят под панель.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * s,
                      pad.top + 12 * s,
                      16 * s,
                      12 * s,
                    ),
                    child: Center(child: _RevealImage(image: image)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16 * s,
                    0,
                    16 * s,
                    pad.bottom + 16 * s,
                  ),
                  child: Entrance(
                    parent: _entrance,
                    kind: IntroEntranceKind.riseCard,
                    delay: 0.22,
                    duration: 0.7,
                    child: _Panel(
                      look: look,
                      lang: lang,
                      entrance: _entrance,
                      regenerateLabel: c.canRegenerate
                          ? l10n.mirrorRegenerateLeft(c.regenerationsLeft)
                          : l10n.mirrorContinueInApp,
                      canRegenerate: c.canRegenerate,
                      onRegenerate: c.regenerate,
                      // Сессия не должна закончиться без QR или кода: пока
                      // finish не прошёл, «Отложить» подождёт (ensureShare
                      // ретраится сам).
                      canCollect: c.sellerCode != null,
                      onCollect: c.openBuy,
                    ),
                  ),
                ),
              ],
            ),

            // Кнопка «назад» на углу фото.
            Positioned(
              top: pad.top + 24 * s,
              left: 28 * s,
              right: 28 * s,
              child: Entrance(
                parent: _entrance,
                kind: IntroEntranceKind.rise,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    size: 44 * s,
                    onTap: c.goBack,
                  ),
                ),
              ),
            ),

            // Искры у карточки QR.
            Positioned(
              top: pad.top + 14 * s,
              right: 146 * s,
              child: Twinkle(color: Colors.white, size: 14 * s),
            ),
            Positioned(
              top: pad.top + 204 * s,
              right: 18 * s,
              child: Twinkle(
                color: t.accent,
                size: 12 * s,
                delaySeconds: 0.9,
              ),
            ),

            // Парящая карточка QR.
            Positioned(
              top: pad.top + 24 * s,
              right: 28 * s,
              child: Entrance(
                parent: _entrance,
                kind: IntroEntranceKind.flyR,
                delay: 0.45,
                child: Floaty(
                  variant: 2,
                  child: _QrCard(
                    shareUrl: c.shareUrl,
                    pulse: _qrPulse,
                    onTap: _onDownloadTap,
                  ),
                ),
              ),
            ),
          ],
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

/// Размытая, притемнённая копия образа во весь экран.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.image});

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final provider = image;
    if (provider == null) return ColoredBox(color: t.primaryDeep);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Масштаб прячет светлую кайму, которую размытие даёт по краям.
          Transform.scale(
            scale: 1.15,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Image(
                image: provider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    ColoredBox(color: t.primaryDeep),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.30)),
        ],
      ),
    );
  }
}

/// Резкий образ в рамке со скруглением: виден целиком, проявляется из
/// размытия (sigma 24→0, scale 1.05→1), по нему пробегает блик — зеркало, а
/// не просто картинка. Свободные ограничения Center дают рамке размер самой
/// картинки, поэтому скругление ложится по её краям, а не по пустым полям.
class _RevealImage extends StatelessWidget {
  const _RevealImage({required this.image});

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final provider = image;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(t.rCard + 4);

    final Widget picture = provider == null
        ? AspectRatio(
            aspectRatio: 2 / 3,
            child: ColoredBox(
              color: t.primary,
              child: Center(
                child: MirrorBrandMark(height: 18 * s, color: t.onPrimary),
              ),
            ),
          )
        : Image(
            image: provider,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => AspectRatio(
              aspectRatio: 2 / 3,
              child: ColoredBox(
                color: t.primary,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: t.onPrimary.withValues(alpha: 0.6),
                  size: 40 * s,
                ),
              ),
            ),
          );

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 50,
            spreadRadius: -14,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            picture,
            const Positioned.fill(
              child: Gleam(
                durationMs: 6400,
                travelFraction: 0.35,
                widthFraction: 0.34,
                opacity: 0.2,
                initialDelayMs: 1500,
              ),
            ),
          ],
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        final sigma = 24.0 * (1 - v);
        return Opacity(
          opacity: (v * 1.6).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1.05 - 0.05 * v,
            child: sigma < 0.5
                ? child!
                : ImageFiltered(
                    imageFilter:
                        ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: child,
                  ),
          ),
        );
      },
      child: framed,
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: strength),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Матовая квадратная кнопка поверх фото.
class _GlassButton extends StatelessWidget {
  const _GlassButton({
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.rButton + 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: size * 0.42),
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка QR: «Заберите образ в телефон». Пока finish не ответил — шиммер.
/// Сам QR всегда чернилами на белом — сканеру нужен контраст, не бренд.
class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.shareUrl,
    required this.pulse,
    required this.onTap,
  });

  final String? shareUrl;
  final bool pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final url = shareUrl;
    final qrSize = 92 * s;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: qrSize + 20 * s,
        padding: EdgeInsets.all(10 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(t.rCard),
          border: Border.all(
            color: pulse ? t.primary : Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
            if (pulse)
              BoxShadow(
                color: t.primaryBright.withValues(alpha: 0.55),
                blurRadius: 24,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url != null)
              QrImageView(
                data: url,
                size: qrSize,
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
            else
              Shimmer.fromColors(
                baseColor: t.hairline,
                highlightColor: Colors.white,
                child: Container(
                  width: qrSize,
                  height: qrSize,
                  color: t.hairline,
                ),
              ),
            SizedBox(height: 8 * s),
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
            SizedBox(height: 6 * s),
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
      ),
    );
  }
}

/// Матовая панель снизу: заголовок и сумма со счётчиком, лента вещей, действия.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.look,
    required this.lang,
    required this.entrance,
    required this.regenerateLabel,
    required this.canRegenerate,
    required this.onRegenerate,
    required this.canCollect,
    required this.onCollect,
  });

  final KioskLook look;
  final String lang;
  final Animation<double> entrance;
  final String regenerateLabel;
  final bool canRegenerate;
  final VoidCallback onRegenerate;
  final bool canCollect;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final radius = BorderRadius.circular(t.rCard + 6);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bg.withValues(alpha: 0.88),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 14 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Подпись бренда — как на ярлыке вещи.
                          MirrorBrandMark(
                            height: 10.5 * s,
                            color: t.primaryBright,
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            l10n.mirrorResultTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.display(25 * s),
                          ),
                          SizedBox(height: 3 * s),
                          Text(
                            l10n.mirrorItemsCount(look.items.length),
                            style: t.subtitle(13 * s),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    _CountUpPrice(total: look.totalPrice, lang: lang),
                  ],
                ),
                if (look.items.isNotEmpty) ...[
                  SizedBox(height: 12 * s),
                  _LookItemsStrip(
                    items: look.items,
                    lang: lang,
                    entrance: entrance,
                  ),
                ],
                SizedBox(height: 12 * s),
                Entrance(
                  parent: entrance,
                  kind: IntroEntranceKind.rise,
                  delay: 0.7,
                  duration: 0.5,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 100,
                        child: MirrorGhostButton(
                          label: regenerateLabel,
                          height: 56 * s,
                          enabled: canRegenerate,
                          onTap: onRegenerate,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Expanded(
                        flex: 145,
                        child: MirrorPrimaryButton(
                          label: l10n.mirrorCollect,
                          height: 56 * s,
                          enabled: canCollect,
                          gleam: true,
                          onTap: onCollect,
                        ),
                      ),
                    ],
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

/// Сумма образа, «набегающая» от нуля — маленькая радость в конце пути.
class _CountUpPrice extends StatelessWidget {
  const _CountUpPrice({required this.total, required this.lang});

  final int total;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
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
        style: t.price(19 * s, color: t.primaryDeep),
      ),
    );
  }
}

/// Лента вещей образа: что именно на человеке — ещё до экрана примерки.
/// Чипы влетают справа по очереди.
class _LookItemsStrip extends StatelessWidget {
  const _LookItemsStrip({
    required this.items,
    required this.lang,
    required this.entrance,
  });

  final List<KioskLookItem> items;
  final String lang;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return SizedBox(
      height: 54 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * s),
        itemBuilder: (context, i) {
          final item = items[i];
          return Entrance(
            parent: entrance,
            kind: IntroEntranceKind.flyR,
            delay: (0.5 + 0.08 * i).clamp(0.5, 0.74),
            duration: 0.46,
            child: Container(
              padding: EdgeInsets.all(6 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(t.rCard),
                border: Border.all(color: t.hairline),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(t.rImage),
                    child: SizedBox(
                      width: 33 * s,
                      height: 42 * s,
                      child: ColoredBox(
                        color: t.surface,
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    ColoredBox(color: t.surface),
                                errorWidget: (_, __, ___) =>
                                    ColoredBox(color: t.surface),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 150 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.label(12.5 * s, weight: FontWeight.w600),
                        ),
                        SizedBox(height: 3 * s),
                        Text(
                          item.price != null
                              ? kioskMoney(item.price!, lang)
                              : '—',
                          style: t.price(11.5 * s, color: t.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6 * s),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Экран состава образа: вещи с размерами и наличием, итог, код продавца.
class MirrorBuyScreen extends StatelessWidget {
  const MirrorBuyScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = controller;
    final look = c.look;
    if (look == null) return const SizedBox.shrink();
    final lang = c.shopperLang;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20 * s),
          MirrorFadeIn(
            child: Text(l10n.mirrorBuyTitle, style: t.headline(34 * s)),
          ),
          SizedBox(height: 6 * s),
          MirrorFadeIn(
            delayMs: 60,
            child: Text(l10n.mirrorBuySubtitle, style: t.subtitle(15 * s)),
          ),
          SizedBox(height: 16 * s),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: look.items.length,
              separatorBuilder: (_, __) => Divider(color: t.hairline, height: 1),
              itemBuilder: (context, i) => MirrorFadeIn(
                delayMs: 120 + 70 * i,
                child: _LookItemRow(item: look.items[i], lang: lang),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16 * s),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.ink, width: 1.5)),
            ),
            child: Row(
              children: [
                Text(l10n.mirrorTotal, style: t.label(18 * s)),
                const Spacer(),
                Text(
                  kioskMoney(look.totalPrice, lang),
                  style: t.price(22 * s, color: t.primaryDeep),
                ),
              ],
            ),
          ),
          MirrorFadeIn(
            delayMs: 260,
            rise: 24,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20 * s),
              decoration: BoxDecoration(
                color: t.primaryDeep,
                borderRadius: BorderRadius.circular(t.rCard),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mirrorCodeLabel,
                      style: t.subtitle(
                        13.5 * s,
                        color: t.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Text(
                    c.sellerCode ?? '· · ·',
                    style: t
                        .price(30 * s, color: t.onPrimary)
                        .copyWith(letterSpacing: 3 * s),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * s),
          MirrorGhostButton(
            label: l10n.mirrorBackToLook,
            height: 60 * s,
            onTap: c.goBack,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

class _LookItemRow extends StatelessWidget {
  const _LookItemRow({required this.item, required this.lang});

  final KioskLookItem item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12 * s),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(t.rImage),
            child: SizedBox(
              width: 56 * s,
              height: 72 * s,
              child: ColoredBox(
                color: Colors.white,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(color: t.surface),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label(15 * s, weight: FontWeight.w600),
                ),
                SizedBox(height: 5 * s),
                Row(
                  children: [
                    Text(
                      '${l10n.mirrorSizeLabel} ${item.size ?? '—'}',
                      style: t.subtitle(12.5 * s),
                    ),
                    Text(' · ', style: t.subtitle(12.5 * s)),
                    Text(
                      l10n.mirrorInStock,
                      style: t.subtitle(12.5 * s, color: t.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * s),
          Text(
            item.price != null ? kioskMoney(item.price!, lang) : '—',
            style: t.price(15 * s),
          ),
        ],
      ),
    );
  }
}
