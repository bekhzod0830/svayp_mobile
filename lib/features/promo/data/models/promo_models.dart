/// Модели промокодов блогеров.
///
/// Ключевое различие, которое видно и в API: привязка кода к аккаунту вечная (нужна для
/// статистики блогера — покупка даже через полгода засчитается ему), а право на скидку
/// сгорает после первой покупки или по сроку. Поэтому [MyPromo] отдаёт и код, и отдельный
/// флаг [discountActive].
library;

enum PromoType { bonusCoins, discountPercent, unknown }

PromoType _parseType(String? raw) {
  switch (raw) {
    case 'BONUS_COINS':
      return PromoType.bonusCoins;
    case 'DISCOUNT_PERCENT':
      return PromoType.discountPercent;
    default:
      return PromoType.unknown;
  }
}

/// Результат успешной активации — питает bottom sheet «Промокод применён».
class PromoApplied {
  final String code;
  final PromoType type;
  final int value;
  final int balanceAfter;

  /// Код уже был активирован раньше — повторный ввод ничего не начислил.
  ///
  /// Раньше сервер отвечал на это ошибкой «промокод уже использован», и человек читал её
  /// как «код сгорел», хотя скидка была жива. Поле опционально: старый бэкенд его не шлёт.
  final bool alreadyActivated;

  /// Живо ли право на скидку прямо сейчас.
  final bool discountActive;

  const PromoApplied({
    required this.code,
    required this.type,
    required this.value,
    required this.balanceAfter,
    this.alreadyActivated = false,
    this.discountActive = false,
  });

  factory PromoApplied.fromJson(Map<String, dynamic> json) => PromoApplied(
        code: json['code'] as String? ?? '',
        type: _parseType(json['type'] as String?),
        value: (json['value'] as num?)?.toInt() ?? 0,
        balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
        alreadyActivated: json['alreadyActivated'] as bool? ?? false,
        discountActive: json['discountActive'] as bool? ?? false,
      );
}

/// Промокод пользователя. null на уровне сервиса = код не активирован.
class MyPromo {
  final String code;
  final String ownerName;
  final PromoType type;
  final int value;
  final DateTime? activatedAt;

  /// Право на скидку ещё живо. Отдельно от [code]: привязка вечная, скидка — нет.
  final bool discountActive;
  final int? discountPercent;
  final DateTime? discountExpiresAt;

  const MyPromo({
    required this.code,
    required this.ownerName,
    required this.type,
    required this.value,
    required this.activatedAt,
    required this.discountActive,
    required this.discountPercent,
    required this.discountExpiresAt,
  });

  factory MyPromo.fromJson(Map<String, dynamic> json) => MyPromo(
        code: json['code'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        type: _parseType(json['type'] as String?),
        value: (json['value'] as num?)?.toInt() ?? 0,
        activatedAt: DateTime.tryParse(json['activatedAt'] as String? ?? ''),
        discountActive: json['discountActive'] as bool? ?? false,
        discountPercent: (json['discountPercent'] as num?)?.toInt(),
        discountExpiresAt: DateTime.tryParse(json['discountExpiresAt'] as String? ?? ''),
      );
}
