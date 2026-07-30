import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_config.dart';
import 'kiosk_models.dart';

/// Ошибка киоск-API. [isNetwork] отличает «нет связи» (можно уйти в демо или
/// показать оффлайн) от «бэкенд отказал» (код в [code]).
class KioskApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final bool isNetwork;

  const KioskApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.isNetwork = false,
  });

  @override
  String toString() => 'KioskApiException($statusCode, $code): $message';
}

/// Клиент киоска `/kiosk/*`.
///
/// Отдельный Dio, а не общий [ApiClient]: у стенда нет пользователя и JWT,
/// устройство авторизуется ключом `X-Kiosk-Key`. Интерцептор общего клиента
/// подставил бы токен продавца в анонимные запросы покупателя, а его
/// 401-обработка могла бы разлогинить продавца из-за киоск-ошибки.
class KioskApi {
  KioskApi(this._prefs)
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final key = deviceKey;
          if (key != null && key.isNotEmpty) {
            options.headers['X-Kiosk-Key'] = key;
          }
          handler.next(options);
        },
      ),
    );
  }

  /// То же имя, что localStorage веб-киоска — ключ выдаётся при настройке
  /// планшета и живёт до переустановки.
  static const _keyStorage = 'kiosk_device_key';

  final Dio _dio;
  final SharedPreferences _prefs;

  String? get deviceKey => _prefs.getString(_keyStorage);

  Future<void> setDeviceKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _prefs.remove(_keyStorage);
    } else {
      await _prefs.setString(_keyStorage, key.trim());
    }
  }

  /// Открытый для чужих запросов Dio (демо-каталог ходит в публичный
  /// `/products/all` тем же клиентом — без JWT).
  Dio get dio => _dio;

  Future<KioskSession> startSession(String lang, String path) async {
    final res = await _request(
      () => _dio.post<dynamic>(
        '/kiosk/session',
        queryParameters: {'lang': lang, 'path': path},
      ),
    );
    return KioskSession.fromJson(_unwrap(res.data));
  }

  Future<({List<KioskCatalogItem> items, int total})> fetchCatalog({
    String? category,
    int page = 0,
    int size = 60,
  }) async {
    final res = await _request(
      () => _dio.get<dynamic>(
        '/kiosk/catalog',
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'size': size,
        },
      ),
    );
    final body = _unwrap(res.data);
    final items = (body['items'] as List?)
            ?.whereType<Map>()
            .map(KioskCatalogItem.fromJson)
            .toList() ??
        <KioskCatalogItem>[];
    return (items: items, total: (body['total'] as num?)?.toInt() ?? items.length);
  }

  /// Весь каталог зала, а не первая страница: обрезанный список на витрине
  /// читается как пустой магазин. Каждая страница отдаётся через [onPage]
  /// накопленным списком; [cancelled] останавливает цикл (смена категории).
  Future<void> fetchWholeCatalog(
    void Function(List<KioskCatalogItem> items) onPage, {
    String? category,
    required bool Function() cancelled,
  }) async {
    const pageSize = 60; // потолок бэкенда на размер страницы
    final collected = <KioskCatalogItem>[];
    var page = 0;
    var total = -1;

    while (total < 0 || collected.length < total) {
      final chunk =
          await fetchCatalog(category: category, page: page, size: pageSize);
      if (cancelled()) return;
      if (chunk.items.isEmpty) break;
      total = chunk.total > 0 ? chunk.total : chunk.items.length;
      collected.addAll(chunk.items);
      onPage(List.unmodifiable(collected));
      page += 1;
    }
  }

  /// Кадр уходит прямо в хранилище по временной ссылке (presigned PUT), минуя
  /// бэкенд — тот же путь, что у TryOnService.uploadOwnPhoto. Возвращает blobKey.
  Future<String> uploadPhoto(String sessionId, File photo) async {
    final presign = await _request(
      () => _dio.post<dynamic>(
        '/kiosk/sessions/$sessionId/photo-url',
        queryParameters: {'contentType': 'image/jpeg'},
      ),
    );
    final body = _unwrap(presign.data);
    final blobKey = body['blobKey']?.toString();
    final uploadUrl = body['uploadUrl']?.toString();
    if (blobKey == null || uploadUrl == null) {
      throw const KioskApiException(
        message: 'Backend did not return an upload URL',
        statusCode: 500,
      );
    }

    final bytes = await photo.readAsBytes();
    // PUT напрямую в Azure Blob (вне API base) — отдельный Dio без интерцепторов.
    try {
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'x-ms-blob-type': 'BlockBlob',
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
    return blobKey;
  }

  Future<KioskPhotoValidation> confirmPhoto(
    String sessionId,
    String blobKey,
  ) async {
    final res = await _request(
      () => _dio.post<dynamic>(
        '/kiosk/photo/confirm',
        data: {'sessionId': sessionId, 'blobKey': blobKey},
      ),
    );
    return KioskPhotoValidation.fromJson(_unwrap(res.data));
  }

  Future<KioskLook> createLook({
    required String sessionId,
    required String gender,
    required String bodyShape,
    List<String>? styles,
    List<String>? productIds,
  }) async {
    final res = await _request(
      () => _dio.post<dynamic>(
        '/kiosk/looks',
        data: {
          'sessionId': sessionId,
          'gender': gender,
          'bodyShape': bodyShape,
          if (styles != null && styles.isNotEmpty) 'styles': styles,
          if (productIds != null && productIds.isNotEmpty)
            'productIds': productIds,
        },
      ),
    );
    return KioskLook.fromJson(_unwrap(res.data));
  }

  Future<KioskLook> getLook(String lookId) async {
    final res = await _request(() => _dio.get<dynamic>('/kiosk/looks/$lookId'));
    return KioskLook.fromJson(_unwrap(res.data));
  }

  Future<KioskFinish> finishSession(String sessionId) async {
    final res = await _request(
      () => _dio.post<dynamic>('/kiosk/sessions/$sessionId/finish'),
    );
    return KioskFinish.fromJson(_unwrap(res.data));
  }

  /// Бэкенд удаляет фото лица немедленно. Вызывается fire-and-forget.
  Future<void> resetSession(String sessionId) async {
    await _request(() => _dio.post<dynamic>('/kiosk/sessions/$sessionId/reset'));
  }

  /// Следим за генерацией поллингом раз в 2.5с (SSE намеренно не используем:
  /// поток требует ключ устройства, а веб и сам молча падает на поллинг).
  /// Сетевые ошибки не прерывают цикл — экран сам решает про таймаут.
  KioskLookWatch watchLook(
    String lookId, {
    void Function(KioskLook look)? onProgress,
    required void Function(KioskLook look) onDone,
  }) {
    final watch = KioskLookWatch._();

    Future<void> tick() async {
      if (watch._closed) return;
      Duration next = const Duration(milliseconds: 2500);
      try {
        final look = await getLook(lookId);
        if (watch._closed) return;
        if (look.isTerminal) {
          watch.close();
          onDone(look);
          return;
        }
        onProgress?.call(look);
      } catch (_) {
        next = const Duration(seconds: 3);
      }
      if (watch._closed) return;
      watch._timer = Timer(next, tick);
    }

    watch._timer = Timer(const Duration(milliseconds: 2500), tick);
    return watch;
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  KioskApiException _mapError(DioException e) {
    final isNetwork = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
    String? code;
    final data = e.response?.data;
    if (data is Map) {
      code = data['code']?.toString() ??
          (data['error'] is Map ? (data['error'] as Map)['code']?.toString() : null);
    }
    return KioskApiException(
      message: e.message ?? 'Kiosk request failed',
      statusCode: e.response?.statusCode,
      code: code,
      isNetwork: isNetwork,
    );
  }

  /// Бэкенд заворачивает ответы в `{data: …}`, иногда дважды.
  Map _unwrap(dynamic data) {
    var current = data;
    for (var i = 0; i < 2; i++) {
      if (current is Map && current['data'] is Map) {
        current = current['data'];
      }
    }
    return current is Map ? current : const {};
  }
}

/// Ручка остановки поллинга генерации.
class KioskLookWatch {
  KioskLookWatch._();

  Timer? _timer;
  bool _closed = false;

  void close() {
    _closed = true;
    _timer?.cancel();
    _timer = null;
  }
}
