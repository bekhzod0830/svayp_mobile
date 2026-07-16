import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_garments.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// One marketplace/shop listing: a photo plus title, size and price. Content
/// strings are localized per-item in the ARB files.
class IntroListing {
  const IntroListing({
    required this.asset,
    required this.title,
    required this.size,
    required this.price,
  });

  final String asset;
  final String title;
  final String size;
  final String price;
}

/// A listing card shared by the Shop (swipe) and Market (feed) intro scenes:
/// photo on top, then title, size and a highlighted price.
class IntroListingCard extends StatelessWidget {
  const IntroListingCard({
    super.key,
    required this.listing,
    this.showLike = false,
    this.compact = false,
  });

  final IntroListing listing;

  /// Adds the ♥ chip (used by the top swipe card).
  final bool showLike;

  /// Tighter typography/padding for the smaller feed cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 12.0 : 14.0;
    final metaSize = compact ? 9.5 : 10.5;
    final priceSize = compact ? 13.0 : 15.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33141118), // rgba(20,17,24,.2)
            offset: Offset(0, 14),
            blurRadius: 30,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GarmentImage(asset: listing.asset),
                if (showLike)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F141118),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        '♥',
                        style: TextStyle(
                          color: IntroPalette.pink,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 14,
              compact ? 9 : 12,
              compact ? 10 : 14,
              compact ? 10 : 13,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IntroPalette.label(size: titleSize),
                ),
                const SizedBox(height: 3),
                Text(
                  listing.size,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IntroPalette.label(
                    size: metaSize,
                    weight: FontWeight.w500,
                    color: IntroPalette.gray,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  listing.price,
                  style: IntroPalette.label(
                    size: priceSize,
                    color: IntroPalette.pink,
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
