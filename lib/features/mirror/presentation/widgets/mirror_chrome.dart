import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../mirror_theme.dart';

/// Словесный знак LIBΛS — ровно тот же, что на экране входа приложения:
/// системный шрифт w700, плотный трекинг, розовая «Λ» (#F370A7).
class MirrorWordmark extends StatelessWidget {
  const MirrorWordmark({super.key, this.size = 18, this.color = MirrorTheme.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Пропорции логотипа заданы в auth (48px / letterSpacing -1).
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -size / 48,
      color: color,
      height: 1.0,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: const [
          TextSpan(text: 'LIB'),
          TextSpan(text: 'Λ', style: TextStyle(color: Color(0xFFF370A7))),
          TextSpan(text: 'S'),
        ],
      ),
    );
  }
}

/// Переключатель языка покупателя РУ / OʻZ (киоск говорит только на двух).
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
    final s = MirrorTheme.scale(context);
    final fg = light ? Colors.white : MirrorTheme.ink;

    Widget segment(String code, String label) {
      final selected = langCode == code;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: selected
                ? (light ? Colors.white : MirrorTheme.ink)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: MirrorTheme.label(
              12.5 * s,
              color: selected ? (light ? MirrorTheme.ink : Colors.white) : fg,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [segment('ru', 'РУ'), segment('uz', 'OʻZ')],
      ),
    );
  }
}

/// Верхняя планка внутренних экранов: матовая кнопка «назад», словесный знак,
/// опциональный переключатель языка.
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
    final s = MirrorTheme.scale(context);
    final size = 44 * s;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 12 * s),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: onBack == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Material(
                        color: MirrorTheme.surface.withValues(alpha: 0.9),
                        child: InkWell(
                          onTap: onBack,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 22 * s,
                            color: MirrorTheme.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Center(child: MirrorWordmark(size: 16 * s)),
          ),
          SizedBox(
            width: langCode == null ? size : null,
            child: langCode == null || onLangChanged == null
                ? SizedBox(width: size)
                : MirrorLangToggle(
                    langCode: langCode!,
                    onChanged: onLangChanged!,
                  ),
          ),
        ],
      ),
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
    final s = MirrorTheme.scale(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 3 ? 0 : 8 * s),
              height: 5 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: done || active
                    ? null
                    : MirrorTheme.hairline,
                gradient: done
                    ? const LinearGradient(
                        colors: [MirrorTheme.pink, MirrorTheme.pink])
                    : active
                        ? LinearGradient(
                            colors: [
                              MirrorTheme.pink,
                              MirrorTheme.pink.withValues(alpha: 0.25),
                            ],
                          )
                        : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
