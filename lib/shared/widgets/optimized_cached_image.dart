import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';

/// Optimized network image widget with memory-efficient caching.
///
/// Wraps [CachedNetworkImage] with automatic memory cache sizing
/// based on display dimensions, reducing memory usage significantly
/// on high-resolution images displayed at smaller sizes.
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.fadeOutDuration,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Calculate memory cache dimensions based on display size
    // Using 2x pixel ratio as a reasonable cap for memory caching
    final cachePixelRatio = devicePixelRatio.clamp(1.0, 2.0);
    final memWidth = width != null ? (width! * cachePixelRatio).toInt() : null;
    final memHeight = height != null
        ? (height! * cachePixelRatio).toInt()
        : null;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: ImageCacheManager.instance,
      memCacheWidth: memWidth,
      memCacheHeight: memHeight,
      maxWidthDiskCache: memWidth != null ? memWidth * 2 : 800,
      maxHeightDiskCache: memHeight != null ? memHeight * 2 : 800,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 200),
      placeholder:
          placeholder ??
          (context, url) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: width,
              height: height,
              color: isDark ? AppColors.darkCardBackground : AppColors.gray100,
            );
          },
      errorWidget:
          errorWidget ??
          (context, url, error) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: width,
              height: height,
              color: isDark ? AppColors.darkCardBackground : AppColors.gray100,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
                size: _iconSize,
              ),
            );
          },
    );
  }

  double get _iconSize {
    if (width != null && width! <= 60) return 20;
    if (width != null && width! <= 100) return 32;
    return 48;
  }
}
