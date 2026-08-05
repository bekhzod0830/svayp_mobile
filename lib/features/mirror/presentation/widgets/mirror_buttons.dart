import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

import '../mirror_theme.dart';

/// Розовая градиентная CTA-пилюля киоска — та же пластика, что у
/// IntroPrimaryButton, но с масштабируемым шрифтом (на планшете кнопка 88px,
/// интро-шрифт 17px в ней потерялся бы) и опциональной второй строкой (сумма
/// на «Собрать на примерку»).
class MirrorPrimaryButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final s = MirrorTheme.scale(context);
    final h = height ?? 60 * s;
    final active = enabled && !isLoading && onTap != null;

    return Opacity(
      opacity: active ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: IntroPalette.pinkGradient,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: IntroPalette.pink.withValues(alpha: 0.45),
                      blurRadius: 30,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: active ? onTap : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (active)
                      const Positioned.fill(
                        child: Gleam(widthFraction: 0.36, opacity: 0.5),
                      ),
                    if (isLoading)
                      SizedBox(
                        width: 22 * s,
                        height: 22 * s,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: MirrorTheme.label(
                              17 * s,
                              color: Colors.white,
                            ),
                          ),
                          if (subLabel != null) ...[
                            SizedBox(height: 3 * s),
                            Text(
                              subLabel!,
                              style: MirrorTheme.label(
                                12.5 * s,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
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

/// Контурная пилюля: [light] — белый контур на чернильном фоне (постер),
/// иначе чернильный контур на белом.
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
    final s = MirrorTheme.scale(context);
    final h = height ?? 60 * s;
    final color = light ? Colors.white : MirrorTheme.ink;
    final active = enabled && onTap != null;

    return Opacity(
      opacity: active ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: h,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: color.withValues(alpha: 0.55), width: 1.5),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onTap: active ? onTap : null,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: MirrorTheme.label(16 * s, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
