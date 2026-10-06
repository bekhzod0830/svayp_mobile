import 'package:flutter/material.dart';

import '../mirror_theme.dart';
import 'mirror_chrome.dart';

/// Ширина / высота карточки выбора: картинка с подписью под ней.
const double kMirrorChoiceAspect = 0.86;

/// Сетка карточек выбора — одна на экраны пола, фигуры и стиля: столбцы
/// (2 на телефоне, 3 на планшете — так все шесть стилей видны без
/// прокрутки), зазоры и размер карточки одинаковы, поэтому прямоугольники
/// на всех трёх шагах совпадают. Карточек меньше ряда (пол) — ряд ставится
/// по [alignment].
class MirrorChoiceGrid extends StatelessWidget {
  const MirrorChoiceGrid({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final s = MirrorTheme.scale(context);
    final gap = 14 * s;
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 560 ? 3 : 2;
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        final h = w / kMirrorChoiceAspect;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 8 * s),
          child: Wrap(
            alignment: alignment,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children)
                SizedBox(width: w, height: h, child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Карточка выбора: картинка на белой плашке, квадратный чек в углу и
/// подпись снизу. Картинка — файл [asset], свой виджет [figure] (мужские
/// силуэты рисуются кодом) или, пока файла нет, пиктограмма [glyph].
/// Выбранная — рамка и чек цветом бренда, заливка [MirrorPalette.selectedBg].
class MirrorChoiceCard extends StatelessWidget {
  const MirrorChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.asset,
    this.figure,
    this.glyph,
    this.fadeInDelayMs = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? asset;
  final Widget? figure;
  final IconData? glyph;

  /// Задержка каскадного входа карточки.
  final int fadeInDelayMs;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);

    final Widget picture;
    if (figure != null) {
      picture = Center(child: figure);
    } else if (asset != null) {
      picture = Image.asset(
        asset!,
        fit: BoxFit.contain,
        // Иллюстрации ещё не для всех стилей: без файла — пиктограмма,
        // а не красный крест.
        errorBuilder: (_, __, ___) => _Glyph(glyph, selected: selected),
      );
    } else {
      picture = _Glyph(glyph, selected: selected);
    }

    return MirrorFadeIn(
      delayMs: fadeInDelayMs,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(10 * s),
            decoration: BoxDecoration(
              color: selected ? t.selectedBg : t.surface,
              borderRadius: BorderRadius.circular(t.rCard),
              border: Border.all(
                color: selected ? t.primary : t.hairline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Иллюстрации — полноцветные на белом: тонировать их
                      // нельзя, поэтому плашка всегда белая.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(t.rImage),
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(6 * s),
                          child: picture,
                        ),
                      ),
                      Positioned(
                        top: 6 * s,
                        right: 6 * s,
                        child: MirrorCheck(selected: selected, size: 22 * s),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8 * s),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: t.label(13.5 * s, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.icon, {required this.selected});

  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    return Center(
      child: Icon(
        icon ?? Icons.checkroom_rounded,
        size: 52 * s,
        color: selected ? t.primary : t.ink,
      ),
    );
  }
}
