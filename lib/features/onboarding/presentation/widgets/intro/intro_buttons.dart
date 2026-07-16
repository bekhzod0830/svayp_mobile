import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_slide.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Full-width pink-gradient CTA pill (deck primary action) with an animated
/// gleam sweep and a twinkle. Shared by the intro carousel, the welcome gift
/// dialog and the auth screens so the whole registration funnel matches.
class IntroPrimaryButton extends StatelessWidget {
  const IntroPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onTap != null;
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: IntroPalette.pinkGradient,
            boxShadow: [
              BoxShadow(
                color: IntroPalette.pink.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
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
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: IntroPalette.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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

/// Frosted-glass circular/pill control used by the intro top overlay
/// (back, skip, language). Fades out when [visible] is false.
class IntroFrostedButton extends StatelessWidget {
  const IntroFrostedButton({
    super.key,
    required this.visible,
    required this.onTap,
    required this.child,
  });

  final bool visible;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: Colors.white.withValues(alpha: 0.72),
              child: InkWell(onTap: onTap, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
