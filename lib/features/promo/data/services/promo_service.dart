import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';
import 'package:swipe/features/promo/data/models/promo_models.dart';

/// Промокоды блогеров.
///
/// Нормализацию кода (регистр, пробелы, кириллические омоглифы) делает СЕРВЕР — клиент
/// только приводит к верхнему регистру для отображения. Иначе Flutter и вебвью разошлись бы
/// в трактовке одного и того же ввода.
class PromoService {
  final ApiClient _apiClient;

  PromoService(this._apiClient);

  /// Применить код. Бросает [ApiException] с кодом PROMO_NOT_FOUND / PROMO_EXPIRED /
  /// PROMO_LIMIT_REACHED / PROMO_ALREADY_HAS — экран мапит их на локализованные тексты.
  Future<PromoApplied> apply(String code) async {
    final response = await _apiClient.post(
      ApiConfig.promoApply,
      data: {
        'code': code,
        // Лимит «не больше N активаций с устройства» считается по этому идентификатору.
        // Поле необязательное: если id ещё не сгенерирован, сервер просто не применит проверку.
        'deviceId': AnalyticsService.instance.anonId,
      },
    );
    return PromoApplied.fromJson(_unwrap(response.data));
  }

  /// Промокод текущего пользователя или null, если не активирован.
  Future<MyPromo?> myPromo() async {
    final response = await _apiClient.get(ApiConfig.promoMe);
    final data = _unwrap(response.data);
    if (data.isEmpty) return null;
    return MyPromo.fromJson(data);
  }

  /// Бэкенд заворачивает ответы в `{ data: ... }`.
  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map<String, dynamic>) return body;
    return <String, dynamic>{};
  }
}
