import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';

/// Diamond cost to try a product on — mirrors the web closet `ACTION_COST.tryOn`.
const int kTryOnCost = 5;

/// Pink "Try it on" pill with the diamond cost, matching the web closet's
/// top-right action pill. Shown on the discovery deck and the shop grid cards.
///
/// Positioning (e.g. top-right of a card) is the caller's responsibility; this
/// widget only draws the pill and forwards taps to [onTap].
class TryOnPill extends StatelessWidget {
  const TryOnPill({super.key, required this.onTap, this.compact = false});

  final VoidCallback? onTap;

  /// Tighter sizing for dense grids (shop cards).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double height = compact ? 28 : 36;
    final double labelSize = compact ? 11 : 13;
    final double diamondSize = compact ? 10 : 12;
    final double costSize = compact ? 10 : 11;
    final double subPillH = compact ? 18 : 22;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.only(left: compact ? 9 : 12, right: compact ? 4 : 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF370A7), Color(0xFFE0409A), Color(0xFFF370A7)],
          ),
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x73F370A7), // rgba(243,112,167,0.45)
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tryItOn,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            // Diamond cost sub-pill
            Container(
              height: subPillH,
              padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6),
              decoration: BoxDecoration(
                color: const Color(0x3DFFFFFF), // rgba(255,255,255,0.24)
                borderRadius: BorderRadius.circular(subPillH / 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntroDiamond(size: diamondSize),
                  SizedBox(width: compact ? 2 : 3),
                  Text(
                    '$kTryOnCost',
                    style: TextStyle(
                      fontSize: costSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
