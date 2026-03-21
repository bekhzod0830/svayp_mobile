import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for product images
/// Configures caching behavior for all network images in the app
/// Reduced from 500 to 200 max objects to lower memory pressure on older devices
class ImageCacheManager {
  static const String key = 'swipe_image_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 24),
      maxNrOfCacheObjects:
          200, // Reduced from 500 to save memory on low-end devices
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
