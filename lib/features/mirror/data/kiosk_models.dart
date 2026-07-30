/// Модели контракта киоска `/kiosk/*` — зеркальная копия типов из
/// `swipe-web/lib/kiosk-api.ts`. Бэкенд отклоняет неизвестные поля тела
/// (INVALID_REQUEST_BODY), поэтому наружу уходит ровно этот контракт.
library;

/// Статус генерации образа (совпадает с backend KioskLookStatus).
enum KioskLookStatus { pending, processing, completed, failed, unknown }

KioskLookStatus kioskStatusFrom(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'PENDING':
      return KioskLookStatus.pending;
    case 'PROCESSING':
      return KioskLookStatus.processing;
    case 'COMPLETED':
      return KioskLookStatus.completed;
    case 'FAILED':
      return KioskLookStatus.failed;
    default:
      return KioskLookStatus.unknown;
  }
}

class KioskSession {
  final String sessionId;
  final String storeLabel;
  final int catalogSize;

  const KioskSession({
    required this.sessionId,
    required this.storeLabel,
    required this.catalogSize,
  });

  factory KioskSession.fromJson(Map data) => KioskSession(
        sessionId: (data['sessionId'] ?? '').toString(),
        storeLabel: (data['storeLabel'] ?? '').toString(),
        catalogSize: (data['catalogSize'] as num?)?.toInt() ?? 0,
      );
}

class KioskCatalogItem {
  final String id;
  final String title;
  final String? category;
  final int? price;
  final String? currency;
  final String? imageUrl;
  final List<String> sizes;

  const KioskCatalogItem({
    required this.id,
    required this.title,
    this.category,
    this.price,
    this.currency,
    this.imageUrl,
    this.sizes = const [],
  });

  factory KioskCatalogItem.fromJson(Map data) => KioskCatalogItem(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        category: data['category']?.toString(),
        price: (data['price'] as num?)?.toInt(),
        currency: data['currency']?.toString(),
        imageUrl: data['imageUrl']?.toString(),
        sizes: (data['sizes'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}

class KioskLookItem {
  final String productId;
  final String title;
  final String? category;
  final String? size;
  final int? price;
  final String? currency;
  final String? imageUrl;

  const KioskLookItem({
    required this.productId,
    required this.title,
    this.category,
    this.size,
    this.price,
    this.currency,
    this.imageUrl,
  });

  factory KioskLookItem.fromJson(Map data) => KioskLookItem(
        productId: (data['productId'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        category: data['category']?.toString(),
        size: data['size']?.toString(),
        price: (data['price'] as num?)?.toInt(),
        currency: data['currency']?.toString(),
        imageUrl: data['imageUrl']?.toString(),
      );
}

class KioskLook {
  final String lookId;
  final KioskLookStatus status;

  /// URL картинки результата. В демо-режиме — `file://<path>` снятого кадра
  /// (настоящей генерации в демо нет, см. [KioskLook.localResultPath]).
  final String? resultImageUrl;
  final List<KioskLookItem> items;
  final int totalPrice;
  final String? currency;
  final int regenerateCount;
  final bool canRegenerate;
  final String? failureReason;

  const KioskLook({
    required this.lookId,
    required this.status,
    this.resultImageUrl,
    this.items = const [],
    this.totalPrice = 0,
    this.currency,
    this.regenerateCount = 0,
    this.canRegenerate = true,
    this.failureReason,
  });

  bool get isTerminal =>
      status == KioskLookStatus.completed || status == KioskLookStatus.failed;

  /// Путь к локальному файлу результата (демо-режим), иначе null.
  String? get localResultPath {
    final url = resultImageUrl;
    if (url == null || !url.startsWith('file://')) return null;
    return url.substring('file://'.length);
  }

  factory KioskLook.fromJson(Map data) => KioskLook(
        lookId: (data['lookId'] ?? data['id'] ?? '').toString(),
        status: kioskStatusFrom(data['status']?.toString()),
        resultImageUrl: data['resultImageUrl']?.toString(),
        items: (data['items'] as List?)
                ?.whereType<Map>()
                .map(KioskLookItem.fromJson)
                .toList() ??
            const [],
        totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
        currency: data['currency']?.toString(),
        regenerateCount: (data['regenerateCount'] as num?)?.toInt() ?? 0,
        canRegenerate: data['canRegenerate'] as bool? ?? true,
        failureReason: data['failureReason']?.toString(),
      );
}

class KioskPhotoValidation {
  final bool faceFound;
  final int faceCount;
  final double faceRatio;
  final bool tooDark;

  /// FACE_NOT_FOUND | MULTIPLE_FACES | MOVE_CLOSER | TOO_DARK | null
  final String? hint;

  const KioskPhotoValidation({
    required this.faceFound,
    this.faceCount = 0,
    this.faceRatio = 0,
    this.tooDark = false,
    this.hint,
  });

  factory KioskPhotoValidation.fromJson(Map data) => KioskPhotoValidation(
        faceFound: data['faceFound'] as bool? ?? false,
        faceCount: (data['faceCount'] as num?)?.toInt() ?? 0,
        faceRatio: (data['faceRatio'] as num?)?.toDouble() ?? 0,
        tooDark: data['tooDark'] as bool? ?? false,
        hint: data['hint']?.toString(),
      );
}

class KioskFinish {
  final String code;
  final String shareUrl;
  final String? shareExpiresAt;

  const KioskFinish({
    required this.code,
    required this.shareUrl,
    this.shareExpiresAt,
  });

  factory KioskFinish.fromJson(Map data) => KioskFinish(
        code: (data['code'] ?? '').toString(),
        shareUrl: (data['shareUrl'] ?? '').toString(),
        shareExpiresAt: data['shareExpiresAt']?.toString(),
      );
}
