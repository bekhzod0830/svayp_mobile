import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../mirror_theme.dart';

/// Знак бренда: файл логотипа, если бренд его дал, иначе словесный знак
/// акцидентным шрифтом. [color] тонирует SVG/PNG (монохромная версия на
/// цветном блоке); без него растровый логотип показывается как есть.
class MirrorBrandMark extends StatelessWidget {
  const MirrorBrandMark({super.key, this.height = 18, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final brand = t.brand;
    final asset = brand.logoAsset;
    final tint = color;

    if (asset != null) {
      if (asset.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          asset,
          height: height,
          colorFilter:
              tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
          semanticsLabel: brand.wordmark,
        );
      }
      return Image.asset(
        asset,
        height: height,
        color: tint,
        semanticLabel: brand.wordmark,
      );
    }

    // Словесный знак по правилам бренда; без них — акцидентный шрифт с
    // широкой разрядкой.
    final ws = brand.wordmarkStyle;
    final ink = tint ?? t.ink;
    if (ws == null) {
      return Text(
        brand.wordmark,
        maxLines: 1,
        style: t
            .display(height, color: ink)
            .copyWith(letterSpacing: height * 0.2, height: 1.0),
      );
    }
    final style = TextStyle(
      fontFamily: ws.family,
      fontFamilyFallback:
          ws.family == null ? null : t.brand.type.fallbackFamilies,
      fontSize: height,
      fontWeight: ws.weight,
      letterSpacing: height * ws.tracking,
      height: 1.0,
      color: ink,
    );
    final chars = brand.wordmark.characters.toList();
    final accent = ws.accentIndex;
    final accentColor = ws.accentColor;
    if (accent == null || accentColor == null || accent >= chars.length) {
      return Text(brand.wordmark, maxLines: 1, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: chars.take(accent).join()),
          TextSpan(
            text: chars[accent],
            style: TextStyle(color: accentColor),
          ),
          TextSpan(text: chars.skip(accent + 1).join()),
        ],
      ),
      maxLines: 1,
      semanticsLabel: brand.name,
    );
  }
}

/// Сегментный переключатель языка покупателя по списку бренда.
/// [light] — поверх цветного блока (рамка и текст цветом onPrimary).
class MirrorLangToggle extends StatelessWidget {
  const MirrorLangToggle({
    super.key,
    required this.langCode,
    required this.onChanged,
    this.light = false,
  });

  final String langCode;
  final ValueChanged<String> onChanged;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final languages = t.brand.languages;
    if (languages.length < 2) return const SizedBox.shrink();

    final fg = light ? t.onPrimary : t.ink;
    final selectedBg = light ? t.onPrimary : t.ink;
    final selectedFg = light ? t.primary : t.bg;

    return Container(
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.2),
        borderRadius: BorderRadius.circular(t.rChip + 3 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in languages)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * s,
                  vertical: 8 * s,
                ),
                decoration: BoxDecoration(
                  color: langCode == code ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(t.rChip),
                ),
                child: Text(
                  MirrorBrand.langLabel(code),
                  style: t.label(
                    12.5 * s,
                    color: langCode == code ? selectedFg : fg,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Верхняя планка внутренних экранов: тонкий шеврон «назад», знак бренда по
/// центру, опциональный переключатель языка. Сплошной фон с волосяной
/// линией снизу — под планкой ничего не прокручивается, матовое стекло
/// здесь было бы декорацией без эффекта.
class MirrorTopBar extends StatelessWidget {
  const MirrorTopBar({
    super.key,
    this.onBack,
    this.langCode,
    this.onLangChanged,
  });

  final VoidCallback? onBack;
  final String? langCode;
  final ValueChanged<String>? onLangChanged;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final size = 44 * s;
    final lang = langCode;
    final onLang = onLangChanged;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
        child: Row(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: onBack == null
                  ? null
                  : Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(t.rButton),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onBack,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18 * s,
                          color: t.ink,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Center(child: MirrorBrandMark(height: 14 * s)),
            ),
            if (lang == null || onLang == null)
              SizedBox(width: size)
            else
              MirrorLangToggle(langCode: lang, onChanged: onLang),
          ],
        ),
      ),
    );
  }
}

/// Квадратный чек выбора: волосяная рамка → заливка цветом бренда с галочкой.
/// [onDark] — поверх залитой цветом бренда карточки (инверсия цветов).
class MirrorCheck extends StatelessWidget {
  const MirrorCheck({
    super.key,
    required this.selected,
    this.size = 24,
    this.onDark = false,
  });

  final bool selected;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final fill = onDark ? t.onPrimary : t.primary;
    final check = onDark ? t.primary : t.onPrimary;
    final idleBorder = onDark ? t.onPrimary.withValues(alpha: 0.6) : t.hairline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? fill : (onDark ? Colors.transparent : t.surface),
        borderRadius: BorderRadius.circular(t.rChip),
        border: Border.all(color: selected ? fill : idleBorder, width: 1.5),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: size * 0.66, color: check)
          : null,
    );
  }
}

/// Индикатор прогресса — всегда 4 сегмента, независимо от ветки: человек не
/// должен чувствовать, что один путь длиннее (ТЗ, раздел 3).
class MirrorSteps extends StatelessWidget {
  const MirrorSteps({super.key, required this.current});

  final int current; // 0..3

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 10 * s, 20 * s, 0),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: i == 3 ? 0 : 6 * s),
              height: 3 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.rChip),
                color: done
                    ? t.primary
                    : active
                        ? t.primary.withValues(alpha: 0.55)
                        : t.hairline,
              ),
            ),
          );
        }),
      ),
    );
  }
}
