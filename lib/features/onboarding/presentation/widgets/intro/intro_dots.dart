import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Page dots for the intro carousel. The active dot stretches to 26px and
/// takes the pink gradient (smooth_page_indicator can't paint gradient dots,
/// hence hand-rolled — same approach as _StepDots in swipe_tutorial_overlay).
class IntroDots extends StatelessWidget {
  const IntroDots({
    super.key,
    required this.count,
    required this.index,
    this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap == null ? null : () => onTap!(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: const Cubic(0.5, 0, 0.2, 1),
                width: i == index ? 26 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i == index ? null : IntroPalette.dotInactive,
                  gradient: i == index ? IntroPalette.pinkGradient : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
