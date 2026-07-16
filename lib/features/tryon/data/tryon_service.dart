import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// Статус примерки (совпадает с backend TryOnStatus).
enum TryOnStatus { pending, processing, completed, failed, unknown }

TryOnStatus _statusFrom(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'PENDING':
      return TryOnStatus.pending;
    case 'PROCESSING':
      return TryOnStatus.processing;
    case 'COMPLETED':
      return TryOnStatus.completed;
    case 'FAILED':
      return TryOnStatus.failed;
    default:
      return TryOnStatus.unknown;
  }
}

/// Результат примерки.
class TryOnResult {
  final String id;
  final TryOnStatus status;
  final String? resultImageUrl;
  final String? failureReason;

  const TryOnResult({
    required this.id,
    required this.status,
    this.resultImageUrl,
    this.failureReason,
  });

  bool get isTerminal =>
      status == TryOnStatus.completed || status == TryOnStatus.failed;

  factory TryOnResult.fromJson(Map data) {
    return TryOnResult(
      id: (data['id'] ?? '').toString(),
      status: _statusFrom(data['status']?.toString()),
      resultImageUrl: data['resultImageUrl']?.toString(),
      failureReason: data['failureReason']?.toString(),
    );
  }
}

/// Клиент примерки товара (Discover-колода). Гармент резолвится на бэке из
/// каноничной вещи товара (Product.catalogWardrobeItemId), режим — манекен или
/// «на своём фото» (personImageKey). Списание монет — серверно; при нехватке
/// прилетает ApiException.isInsufficientCoins.
class TryOnService {
  ApiClient get _client => getIt<ApiClient>();
  final _uuid = const Uuid();

  /// Запустить примерку товара. [personImageKey] — ключ своего фото (режим «на
  /// себе»); null → манекен. Бросает ApiException (в т.ч. 402 нехватки монет).
  Future<TryOnResult> createForProduct(
    String productId, {
    String? personImageKey,
  }) async {
    final res = await _client.post<dynamic>(
      ApiConfig.tryOn,
      data: {
        'productIds': [productId],
        if (personImageKey != null) 'personImageKey': personImageKey,
        'idempotencyKey': _uuid.v4(),
      },
    );
    return TryOnResult.fromJson(_unwrap(res.data));
  }

  /// Поллинг статуса одной джобы.
  Future<TryOnResult> poll(String jobId) async {
    final path = ApiConfig.tryOnDetail.replaceAll('{id}', jobId);
    final res = await _client.get<dynamic>(path);
    return TryOnResult.fromJson(_unwrap(res.data));
  }

  /// Поллит статус, пока не COMPLETED/FAILED (или пока не истечёт [maxAttempts]).
  /// SSE не используем — простой поллинг раз в ~2.5с (как веб-фолбэк).
  Future<TryOnResult> waitUntilDone(
    String jobId, {
    void Function(TryOnResult)? onProgress,
    int maxAttempts = 80,
    Duration interval = const Duration(milliseconds: 2500),
  }) async {
    TryOnResult last = TryOnResult(id: jobId, status: TryOnStatus.pending);
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      last = await poll(jobId);
      onProgress?.call(last);
      if (last.isTerminal) return last;
    }
    return last;
  }

  /// Загрузить своё фото (режим «на себе»): presigned PUT → возвращает blobKey
  /// для передачи как personImageKey.
  Future<String> uploadOwnPhoto(File file) async {
    final contentType = _contentTypeFor(file.path);
    final presign = await _client.post<dynamic>(
      ApiConfig.tryOnModelImageUrl,
      queryParameters: {'contentType': contentType},
    );
    final body = _unwrap(presign.data);
    final putUrl = body['putUrl']?.toString();
    final blobKey = body['blobKey']?.toString();
    if (putUrl == null || blobKey == null) {
      throw ApiException(message: 'Bad presign response', statusCode: 500);
    }
    // PUT напрямую в Azure Blob (вне API base). Отдельный Dio без интерцепторов.
    final bytes = await file.readAsBytes();
    await Dio().put(
      putUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'x-ms-blob-type': 'BlockBlob',
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
    return blobKey;
  }

  Map _unwrap(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) return inner;
      return data;
    }
    return const {};
  }

  String _contentTypeFor(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
