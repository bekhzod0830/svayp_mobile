import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Дисковый кэш фото каталога для киоска.
///
/// Общий кэш приложения держит 200 файлов на сутки — в зале 1000+ вещей, и фото
/// в каталоге вытеснялись и грузились заново при каждом открытии. Здесь свой
/// кэш на 30 дней, а пока станция стоит на постере, фото докачиваются заранее.
class KioskImageCache {
  KioskImageCache._();

  static const key = 'kiosk_catalog_images';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 4000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Скачать на диск фото, которых в кэше ещё нет, — по одному, чтобы не
  /// забирать сеть у живых запросов. Ошибки молча пропускаются: следующий
  /// прогрев (раз в 15 минут) докачает.
  static Future<int> prefetch(
    Iterable<String> urls, {
    bool Function()? cancelled,
    CacheManager? cache,
  }) async {
    final manager = cache ?? instance;
    var downloaded = 0;
    for (final url in urls.toSet()) {
      if (cancelled?.call() ?? false) break;
      try {
        if (await manager.getFileFromCache(url) != null) continue;
        await manager.downloadFile(url);
        downloaded++;
      } catch (_) {
        // Битая ссылка или сеть — не повод останавливать прогрев остальных.
      }
    }
    return downloaded;
  }
}
