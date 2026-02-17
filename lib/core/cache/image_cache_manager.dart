import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:swipe/core/constants/app_constants.dart';

/// Custom cache manager for product images
/// Configures caching behavior for all network images in the app
class ImageCacheManager {
  static const String key = 'swipe_image_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: Duration(days: AppConstants.imageCacheDays),
      maxNrOfCacheObjects: 500, // Maximum number of cached images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
