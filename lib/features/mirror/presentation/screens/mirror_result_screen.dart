import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';

/// Экран результата: образ во всю доступную высоту (проявляется из
/// размытия), лента вещей образа, карточка QR, «Пересобрать» (лимит 3) и
/// «Отложить на примерку».
class MirrorResultScreen extends StatefulWidget {
  const MirrorResultScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorResultScreen> createState() => _MirrorResultScreenState();
}

class _MirrorResultScreenState extends State<MirrorResultScreen> {
  bool _qrPulse = false;
  Timer? _pulseTimer;

  @override
  void dispose() {
    _pulseTimer?.cancel();
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
    final total = kioskMoney(look.totalPrice, lang);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * s),
      child: Column(
        children: [
          Expanded(
            child: _RevealImage(
              look: look,
              s: s,
              meta: _ImageMeta(
                tag: t.kickerCase(l10n.mirrorResultTag),
                line: '${l10n.mirrorItemsCount(look.items.length)} · $total',
              ),
            ),
          ),
          if (look.items.isNotEmpty) ...[
            SizedBox(height: 12 * s),
            _LookItemsStrip(items: look.items, lang: lang, s: s),
          ],
          SizedBox(height: 12 * s),
          _QrCard(
            shareUrl: c.shareUrl,
            pulse: _qrPulse,
            onDownloadTap: _onDownloadTap,
          ),
          SizedBox(height: 14 * s),
          Row(
            children: [
              Expanded(
                flex: 100,
                child: MirrorGhostButton(
                  label: c.canRegenerate
                      ? l10n.mirrorRegenerateLeft(c.regenerationsLeft)
                      : l10n.mirrorContinueInApp,
                  height: 64 * s,
                  enabled: c.canRegenerate,
                  onTap: c.regenerate,
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                flex: 145,
                child: MirrorPrimaryButton(
                  label: l10n.mirrorCollect,
                  subLabel: total,
                  height: 64 * s,
                  // Сессия не должна закончиться без QR или кода: пока finish
                  // не прошёл, «Отложить» подождёт (ensureShare сам ретраится).
                  enabled: c.sellerCode != null,
                  onTap: c.openBuy,
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

class _ImageMeta {
  final String tag;
  final String line;
  const _ImageMeta({required this.tag, required this.line});
}

/// Картинка результата с проявлением из размытия (sigma 24→0, scale 1.05→1).
class _RevealImage extends StatelessWidget {
  const _RevealImage({required this.look, required this.s, required this.meta});

  final KioskLook look;
  final double s;
  final _ImageMeta meta;

  Widget _image(BoxFit fit, MirrorTheme t) {
    final url = look.resultImageUrl;
    final localPath = look.localResultPath;
    if (localPath != null) {
      return Image.file(File(localPath), fit: fit);
    }
    if (url != null && url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, __) => ColoredBox(color: t.surface),
        errorWidget: (_, __, ___) => ColoredBox(
          color: t.surface,
          child: Icon(Icons.image_not_supported_outlined, color: t.muted),
        ),
      );
    }
    return ColoredBox(color: t.surface);
  }

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);

    // Образ показываем ЦЕЛИКОМ (contain) — cover срезал бы голову у
    // вертикальной генерации. Пустых полей нет: фоном — размытая копия
    // той же картинки.
    final image = Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: _image(BoxFit.cover, t),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
        _image(BoxFit.contain, t),
      ],
    );

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        final sigma = 24.0 * (1 - v);
        return ClipRRect(
          borderRadius: BorderRadius.circular(t.rCard),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          // Мягкий низовой скрим под мету.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120 * s,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 * s,
            left: 16 * s,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: t.primary,
                borderRadius: BorderRadius.circular(t.rChip),
              ),
              child: Text(
                meta.tag,
                style: t.kicker(s * 0.9, color: t.onPrimary),
              ),
            ),
          ),
          Positioned(
            left: 18 * s,
            bottom: 16 * s,
            right: 18 * s,
            child: Text(
              meta.line,
              style: t.label(16 * s, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Лента вещей образа: что именно на человеке — ещё до экрана примерки.
class _LookItemsStrip extends StatelessWidget {
  const _LookItemsStrip({
    required this.items,
    required this.lang,
    required this.s,
  });

  final List<KioskLookItem> items;
  final String lang;
  final double s;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return SizedBox(
      height: 56 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * s),
        itemBuilder: (context, i) {
          final item = items[i];
          return Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.rCard),
              border: Border.all(color: t.hairline),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(t.rImage),
                  child: SizedBox(
                    width: 34 * s,
                    height: 44 * s,
                    child: ColoredBox(
                      color: Colors.white,
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
                        item.price != null ? kioskMoney(item.price!, lang) : '—',
                        style: t.price(11.5 * s, color: t.muted),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * s),
              ],
            ),
          );
        },
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
    required this.onDownloadTap,
  });

  final String? shareUrl;
  final bool pulse;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final url = shareUrl;

    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.rCard),
        border: Border.all(color: t.hairline),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(t.rImage),
              border: Border.all(
                color: pulse ? t.primary : t.hairline,
                width: pulse ? 2.5 : 1,
              ),
              boxShadow: pulse
                  ? [
                      BoxShadow(
                        color: t.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: url != null
                ? QrImageView(
                    data: url,
                    size: 92 * s,
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
                    highlightColor: t.surface,
                    child: Container(
                      width: 92 * s,
                      height: 92 * s,
                      color: t.hairline,
                    ),
                  ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mirrorQrTitle, style: t.label(16 * s)),
                SizedBox(height: 6 * s),
                Text(
                  pulse ? l10n.mirrorDownloadHint : l10n.mirrorQrSubtitle,
                  style: t.subtitle(12.5 * s),
                ),
                SizedBox(height: 10 * s),
                GestureDetector(
                  onTap: onDownloadTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 7 * s,
                    ),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(t.rChip),
                      border: Border.all(color: t.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_outlined,
                            size: 15 * s, color: t.ink),
                        SizedBox(width: 6 * s),
                        Text(
                          l10n.mirrorDownload,
                          style: t.label(12.5 * s, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Text(l10n.mirrorBuyTitle, style: t.headline(34 * s)),
          SizedBox(height: 6 * s),
          Text(l10n.mirrorBuySubtitle, style: t.subtitle(15 * s)),
          SizedBox(height: 16 * s),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: look.items.length,
              separatorBuilder: (_, __) => Divider(color: t.hairline, height: 1),
              itemBuilder: (context, i) =>
                  _LookItemRow(item: look.items[i], lang: lang),
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
                  style: t.headline(26 * s),
                ),
              ],
            ),
          ),
          Container(
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
                      .display(32 * s, color: t.onPrimary)
                      .copyWith(letterSpacing: 3 * s),
                ),
              ],
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
