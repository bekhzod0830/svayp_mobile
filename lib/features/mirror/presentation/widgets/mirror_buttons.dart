import 'package:flutter/material.dart';

import '../mirror_theme.dart';

/// Основная CTA киоска: сплошная заливка цветом бренда, углы из токенов,
/// подпись капсом с разрядкой (если бренд так ставит кнопки) и лёгкое
/// «нажатие» масштабом вместо свечения. Опциональная вторая строка — сумма
/// на «Отложить на примерку».
class MirrorPrimaryButton extends StatefulWidget {
  const MirrorPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.subLabel,
    this.height,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final String? subLabel;
  final VoidCallback? onTap;
  final double? height;
  final bool enabled;
  final bool isLoading;

  @override
  State<MirrorPrimaryButton> createState() => _MirrorPrimaryButtonState();
}

class _MirrorPrimaryButtonState extends State<MirrorPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final h = widget.height ?? 60 * s;
    final active =
        widget.enabled && !widget.isLoading && widget.onTap != null;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 180),
        child: SizedBox(
          width: double.infinity,
          height: h,
          child: Material(
            color: t.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.rButton),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: active ? widget.onTap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v && active),
              splashColor: t.onPrimary.withValues(alpha: 0.12),
              highlightColor: t.onPrimary.withValues(alpha: 0.06),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22 * s,
                        height: 22 * s,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(t.onPrimary),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.ctaCase(widget.label),
                            textAlign: TextAlign.center,
                            style: t.cta(15 * s),
                          ),
                          if (widget.subLabel != null) ...[
                            SizedBox(height: 4 * s),
                            Text(
                              widget.subLabel!,
                              style: t.label(
                                12.5 * s,
                                weight: FontWeight.w600,
                                color: t.onPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Контурная кнопка: тонкая чернильная рамка на светлом фоне; [light] —
/// рамка и текст цветом [MirrorTheme.onPrimary] поверх цветного блока.
class MirrorGhostButton extends StatelessWidget {
  const MirrorGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height,
    this.light = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double? height;
  final bool light;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final h = height ?? 60 * s;
    final color = light ? t.onPrimary : t.ink;
    final active = enabled && onTap != null;

    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: double.infinity,
        height: h,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.rButton),
            side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.rButton),
            ),
            onTap: active ? onTap : null,
            child: Center(
              child: Text(
                t.ctaCase(label),
                textAlign: TextAlign.center,
                style: t.cta(14 * s, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Тихая вторичная кнопка: текст цветом бренда с подчёркиванием, без рамки.
/// Для действий, которые не должны спорить с главной CTA.
class MirrorTextButton extends StatelessWidget {
  const MirrorTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = MirrorTheme.scale(context);
    final c = color ?? t.primary;

    return SizedBox(
      width: double.infinity,
      height: height ?? 56 * s,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.rButton),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: t.label(15 * s, weight: FontWeight.w600, color: c).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: c.withValues(alpha: 0.45),
                decorationThickness: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
