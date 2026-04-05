import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Rounded map preview card that shows a static Yandex map tile.
/// Tapping the card opens a native-style bottom sheet to choose a map app.
class MapPreviewCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? address;

  const MapPreviewCard({
    super.key,
    this.latitude,
    this.longitude,
    this.address,
  });

  bool get _hasCoords => latitude != null && longitude != null;

  String get _staticMapUrl {
    final lon = longitude!.toStringAsFixed(6);
    final lat = latitude!.toStringAsFixed(6);
    // Yandex static map: 600×300, zoom 15, red pin at centre
    return 'https://static-maps.yandex.ru/1.x/?ll=$lon,$lat&z=15&size=600,300&l=map&pt=$lon,$lat,pm2rdm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showMapSheet(context, isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Static map image or placeholder
              if (_hasCoords)
                Image.network(
                  _staticMapUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _placeholder(isDark),
                  errorBuilder: (_, __, ___) => _placeholder(isDark),
                )
              else
                _placeholder(isDark),

              // Subtle bottom-gradient so the card feels grounded
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x33000000)],
                  ),
                ),
              ),

              // "Open map" badge — top-right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xAA000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context)!.mapOpenMap,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pin icon centred (only for coordinate-based maps)
              if (_hasCoords)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.location_pin,
                        color: Color(0xFFFC3F1D),
                        size: 32,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE9EAF0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 38,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            if (address != null && address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  address!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMapSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      useRootNavigator: true,
      builder: (_) => _MapSelectionSheet(
        latitude: latitude,
        longitude: longitude,
        address: address,
        isDark: isDark,
      ),
    );
  }
}

// ─── Bottom sheet ──────────────────────────────────────────────────────────────

class _MapSelectionSheet extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isDark;

  const _MapSelectionSheet({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isDark,
  });

  bool get _hasCoords => latitude != null && longitude != null;

  Future<void> _openAppleMaps() async {
    final Uri uri;
    if (_hasCoords) {
      final lat = latitude!.toStringAsFixed(6);
      final lon = longitude!.toStringAsFixed(6);
      uri = Uri.parse('https://maps.apple.com/?ll=$lat,$lon&q=$lat,$lon');
    } else if (address != null && address!.isNotEmpty) {
      uri = Uri.parse(
        'https://maps.apple.com/?q=${Uri.encodeQueryComponent(address!)}',
      );
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openGoogleMaps() async {
    final Uri uri;
    if (_hasCoords) {
      final lat = latitude!.toStringAsFixed(6);
      final lon = longitude!.toStringAsFixed(6);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );
    } else if (address != null && address!.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address!)}',
      );
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openYandexMaps() async {
    if (_hasCoords) {
      final lat = latitude!.toStringAsFixed(6);
      final lon = longitude!.toStringAsFixed(6);
      final nativeUri = Uri.parse(
        'yandexmaps://maps.yandex.ru/?pt=$lon,$lat&z=15&l=map',
      );
      final webUri = Uri.parse(
        'https://yandex.com/maps/?pt=$lon,$lat&z=15&l=map',
      );
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } else if (address != null && address!.isNotEmpty) {
      final uri = Uri.parse(
        'https://yandex.com/maps/?text=${Uri.encodeQueryComponent(address!)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF141418) : Colors.white;
    final divider = isDark ? const Color(0xFF2A2A35) : const Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.mapOpenInMaps,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: divider),

          // Apple Maps — iOS only
          if (Platform.isIOS) ...[
            _SheetOption(
              iconWidget: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apple, color: Colors.white, size: 22),
              ),
              label: 'Apple Maps',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps();
              },
            ),
            Divider(height: 1, thickness: 1, indent: 62, color: divider),
          ],

          _SheetOption(
            iconWidget: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SvgPicture.asset(
                'assets/icons/ic_google_maps.svg',
                width: 38,
                height: 38,
              ),
            ),
            label: 'Google Maps',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              _openGoogleMaps();
            },
          ),
          Divider(height: 1, thickness: 1, indent: 62, color: divider),

          _SheetOption(
            iconWidget: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SvgPicture.asset(
                'assets/icons/ic_yandex_maps.svg',
                width: 38,
                height: 38,
              ),
            ),
            label: 'Yandex Maps',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              _openYandexMaps();
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─── Sheet row option ─────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetOption({
    required this.iconWidget,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 38, height: 38, child: iconWidget),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
