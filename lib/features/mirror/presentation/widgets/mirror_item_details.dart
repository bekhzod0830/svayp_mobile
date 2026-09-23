import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_models.dart';
import '../../data/kiosk_taxonomy.dart';
import '../mirror_theme.dart';

/// Слой подробностей о вещи. Оборачивает экран; любой потомок открывает
/// карточку вещи через [MirrorItemDetails.open], передав ключ своего фото:
/// фото «вырастает» из миниатюры в большую карточку, под ним проявляются
/// название, размер и цена. Закрытие — обратным движением в ту же миниатюру
/// (касание фона, крестик или кнопка «Закрыть»).
///
/// Своего Navigator'а у киоска нет, поэтому это слой в Stack, а не маршрут:
/// сброс сессии не может оставить карточку висеть поверх постера.
class MirrorItemDetails extends StatefulWidget {
  const MirrorItemDetails({
    super.key,
    required this.lang,
    required this.child,
  });

  /// Язык покупателя — для цены и подписей категорий.
  final String lang;
  final Widget child;

  /// Открыть карточку [item], вырастая из виджета с ключом [source].
  static void open(
    BuildContext context,
    KioskLookItem item,
    GlobalKey source,
  ) {
    context.findAncestorStateOfType<_MirrorItemDetailsState>()?._open(
          item,
          source,
        );
  }

  @override
  State<MirrorItemDetails> createState() => _MirrorItemDetailsState();
}

class _MirrorItemDetailsState extends State<MirrorItemDetails>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final GlobalKey _rootKey = GlobalKey();

  KioskLookItem? _item;
  GlobalKey? _source;

  /// Прямоугольник миниатюры в координатах слоя — откуда растём и куда
  /// возвращаемся. Пересчитывается при закрытии: миниатюра могла сдвинуться
  /// (лента прокрутилась).
  Rect? _from;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      reverseDuration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final root = _rootKey.currentContext?.findRenderObject();
    if (box is! RenderBox || root is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: root) & box.size;
  }

  void _open(KioskLookItem item, GlobalKey source) {
    if (_anim.isAnimating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _item = item;
      _source = source;
      _from = _rectOf(source);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 1;
    } else {
      _anim.forward(from: 0);
    }
  }

  Future<void> _close() async {
    if (_item == null || _anim.status == AnimationStatus.reverse) return;
    final source = _source;
    final rect = source == null ? null : _rectOf(source);
    if (rect != null) setState(() => _from = rect);
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 0;
    } else {
      await _anim.reverse();
    }
    if (mounted) setState(() => _item = null);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Stack(
      key: _rootKey,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (item != null)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (_, __) => _close(),
              child: LayoutBuilder(
                builder: (context, box) => _DetailsOverlay(
                  item: item,
                  lang: widget.lang,
                  animation: _anim,
                  size: box.biggest,
                  from: _from,
                  onClose: _close,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailsOverlay extends StatelessWidget {
  const _DetailsOverlay({
    required this.item,
    required this.lang,
    required this.animation,
    required this.size,
    required this.from,
    required this.onClose,
  });

  final KioskLookItem item;
  final String lang;
  final Animation<double> animation;
  final Size size;
  final Rect? from;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final pad = MediaQuery.paddingOf(context);

    // Итоговая карточка: по центру, фото сверху 4:5, текст под ним.
    final cardW = math.min(size.width - 40 * s, 440 * s);
    final imageH = math.min(cardW * 1.2, size.height * 0.5);
    final textH = 210 * s;
    final cardH = math.min(imageH + textH, size.height - pad.vertical - 40 * s);
    final card = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + pad.top / 2),
      width: cardW,
      height: cardH,
    );
    final imageTo = Rect.fromLTWH(card.left, card.top, card.width, imageH);
    final start = from ?? Rect.fromCenter(center: card.center, width: 10, height: 10);
    final radius = math.min(t.rCard, 22 * s);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;
        final k = Curves.easeInOutCubic.transform(v);
        // Фото летит из миниатюры в верх карточки; фон карточки — следом,
        // из той же миниатюры, и дорастает до полной высоты.
        final imageRect = Rect.lerp(start, imageTo, k)!;
        final bgRect = Rect.lerp(start, card, k)!;
        final textIn = const Interval(0.55, 1, curve: Curves.easeOutCubic)
            .transform(v);

        return Stack(
          children: [
            // Фон: затемнение по мере раскрытия; касание — закрыть.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(
                  color: t.ink.withValues(alpha: 0.5 * k),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: bgRect,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25 * k),
                      blurRadius: 40 * s,
                      offset: Offset(0, 16 * s),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fromRect(
              rect: imageRect,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius),
                  bottom: Radius.circular(radius * (1 - k)),
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => ColoredBox(color: t.surface),
                          errorWidget: (_, __, ___) =>
                              ColoredBox(color: t.surface),
                        )
                      : ColoredBox(color: t.surface),
                ),
              ),
            ),
            // Текст и кнопки — только когда карточка почти раскрылась.
            if (textIn > 0)
              Positioned(
                left: card.left,
                width: card.width,
                top: card.top + imageH,
                height: card.height - imageH,
                child: Opacity(
                  opacity: textIn,
                  child: Transform.translate(
                    offset: Offset(0, 16 * s * (1 - textIn)),
                    child: _DetailsText(
                      item: item,
                      lang: lang,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            if (textIn > 0)
              Positioned(
                top: card.top + 12 * s,
                right: size.width - card.right + 12 * s,
                child: Opacity(
                  opacity: textIn,
                  child: _CloseButton(size: 40 * s, onTap: onClose),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailsText extends StatelessWidget {
  const _DetailsText({
    required this.item,
    required this.lang,
    required this.onClose,
  });

  final KioskLookItem item;
  final String lang;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final category = item.category == null
        ? null
        : kioskCategories.where((c) => c.code == item.category).firstOrNull;

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 16 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.kickerCase(
              category == null
                  ? l10n.mirrorItemInLook
                  : t.brand.categoryLabel(category, lang),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.kicker(s * 0.9),
          ),
          SizedBox(height: 8 * s),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.headline(21 * s).copyWith(height: 1.15),
          ),
          SizedBox(height: 10 * s),
          Row(
            children: [
              if (item.size != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 5 * s,
                  ),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(
                      math.min(t.rChip, 999),
                    ),
                    border: Border.all(color: t.hairline),
                  ),
                  child: Text(
                    '${l10n.mirrorSizeLabel} ${kioskSizeLabel(item.size!)}',
                    style: t.label(12.5 * s, weight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 10 * s),
              ],
              Container(
                width: 7 * s,
                height: 7 * s,
                decoration:
                    BoxDecoration(color: t.success, shape: BoxShape.circle),
              ),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(
                  l10n.mirrorInStock,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label(
                    12.5 * s,
                    weight: FontWeight.w600,
                    color: t.success,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.price != null ? kioskMoney(item.price!, lang) : '—',
                  maxLines: 1,
                  style: t.price(24 * s, color: t.primaryDeep),
                ),
              ),
              SizedBox(width: 12 * s),
              _TextPill(label: l10n.mirrorItemClose, onTap: onClose),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextPill extends StatelessWidget {
  const _TextPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return Material(
      color: t.surface,
      shape: t.controlShape(side: BorderSide(color: t.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 11 * s),
          child: Text(label, style: t.label(14 * s, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: t.iconButtonShape(side: BorderSide(color: t.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(Icons.close_rounded, size: size * 0.5, color: t.ink),
        ),
      ),
    );
  }
}
