import 'dart:io' show HttpException;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/features/mirror/data/kiosk_image_cache.dart';

class _Info extends Fake implements FileInfo {}

/// Кэш под контролем теста: «на диске» — множество url, скачивание — запись в список.
class _FakeCache extends Fake implements CacheManager {
  _FakeCache({this.cached = const {}, this.broken = const {}});

  final Set<String> cached;
  final Set<String> broken;
  final downloads = <String>[];

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async =>
      cached.contains(key) ? _Info() : null;

  @override
  Future<FileInfo> downloadFile(String url, {String? key, Map<String, String>? authHeaders, bool force = false}) async {
    downloads.add(url);
    if (broken.contains(url)) throw const HttpException('404');
    return _Info();
  }
}

void main() {
  test('качает только то, чего нет на диске, и по одному разу', () async {
    final cache = _FakeCache(cached: {'a'});
    final n = await KioskImageCache.prefetch(['a', 'b', 'b', 'c'], cache: cache);
    expect(cache.downloads, ['b', 'c']);
    expect(n, 2);
  });

  test('битая ссылка не останавливает прогрев остальных', () async {
    final cache = _FakeCache(broken: {'b'});
    final n = await KioskImageCache.prefetch(['a', 'b', 'c'], cache: cache);
    expect(cache.downloads, ['a', 'b', 'c']);
    expect(n, 2);
  });

  test('ушли с постера — прогрев останавливается', () async {
    final cache = _FakeCache();
    var left = 1;
    await KioskImageCache.prefetch(['a', 'b', 'c'], cache: cache, cancelled: () => left-- <= 0);
    expect(cache.downloads, ['a']);
  });

  test('свой кэш киоска держит весь каталог зала месяц, а не 200 файлов на сутки', () {
    expect(KioskImageCache.key, isNot('swipe_image_cache'));
  });
}
