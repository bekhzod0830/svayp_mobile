import 'package:flutter/material.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_theme.dart';

/// Real garment catalog photos used across the intro scenes, bundled from the
/// web app (public/images/onboarding/closet_items). They are product shots on
/// a near-white background, so they read best inside white tiles.
class IntroGarments {
  IntroGarments._();

  static const String _base = 'assets/onboarding/closet_items/';

  static const String top = '${_base}top.png';
  static const String skirt = '${_base}skirt.png';
  static const String dress = '${_base}dress.png';
  static const String bag = '${_base}bag.png';
  static const String romol = '${_base}romol.png'; // headscarf

  /// Ordered set used to fill garment grids / tiles.
  static const List<String> all = [top, skirt, dress, romol, bag];

  /// Тот же файл, что и [dress]: try_it_on/try_on.png был его побайтовой копией,
  /// дубликат удалён из ассетов.
  static const String tryOnFlat = dress;
  static const String tryOnMannequin =
      'assets/onboarding/try_it_on/on_mannequin.png';
  static const String tryOnPhoto = 'assets/onboarding/try_it_on/on_my_photo.png';
  static const String tryOnPhotoCovered =
      'assets/onboarding/try_it_on/on_my_photo_covered.png';

  /// Shop (B2B, brand catalog) listing photos.
  static const List<String> shop = [
    'assets/onboarding/shop/image1.png',
    'assets/onboarding/shop/image2.png',
    'assets/onboarding/shop/image3.png',
    'assets/onboarding/shop/image4.png',
  ];

  /// Market (C2C, second-hand) listing photos.
  static const List<String> market = [
    'assets/onboarding/market/image1.jpeg',
    'assets/onboarding/market/image2.jpeg',
    'assets/onboarding/market/image3.jpeg',
    'assets/onboarding/market/image4.jpeg',
    'assets/onboarding/market/image5.jpeg',
    'assets/onboarding/market/image6.jpeg',
    'assets/onboarding/market/image7.jpeg',
  ];
}

/// A transparent garment cutout on a soft rounded tile. The item is contained
/// (never cropped) and floats on the tile — the source PNGs already have their
/// backgrounds removed, so no opaque white box is drawn.
class GarmentTile extends StatelessWidget {
  const GarmentTile({
    super.key,
    required this.asset,
    required this.size,
    this.radius = 13,
    this.inset = 6,
    this.tileColor = IntroPalette.chipBg,
    this.shadow = false,
  });

  final String asset;
  final double size;
  final double radius;
  final double inset;
  final Color tileColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0x33781446), // rgba(120,20,70,.2)
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                  spreadRadius: -8,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// A bare product image with no background painted behind it. Photos (market /
/// shop / try-on results) fill with [BoxFit.cover]; transparent cutouts should
/// pass [BoxFit.contain].
class GarmentImage extends StatelessWidget {
  const GarmentImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, fit: fit, filterQuality: FilterQuality.medium);
  }
}
