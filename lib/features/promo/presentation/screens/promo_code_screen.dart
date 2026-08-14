import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/promo/data/models/promo_models.dart';
import 'package:swipe/features/promo/data/services/promo_service.dart';
import 'package:swipe/features/promo/presentation/widgets/promo_success_sheet.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/custom_button.dart';
import 'package:swipe/shared/widgets/custom_input.dart';
import 'package:swipe/shared/widgets/web_view_bridge.dart';

/// Профиль → «Промокод» (пункт 6.1 ТЗ).
///
/// Если код уже привязан, поле ввода не показывается вовсе: второй код применить нельзя,
/// и предлагать ввод было бы обманом. Вместо него — какой код активирован.
///
/// Ошибки разбираются по machine-readable коду из тела ответа ([ApiException.code]),
/// а не по тексту: тексты локализованы на трёх языках, сравнивать их нельзя.
class PromoCodeScreen extends StatefulWidget {
  /// Показывать ли кнопку «Пропустить» — включается на шаге онбординга.
  final bool showSkip;

  /// Куда уйти после успеха или пропуска. null = обычный pop.
  final VoidCallback? onDone;

  const PromoCodeScreen({super.key, this.showSkip = false, this.onDone});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final _controller = TextEditingController();
  final _service = getIt<PromoService>();

  MyPromo? _existing;
  bool _loading = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final promo = await _service.myPromo();
      if (mounted) setState(() => _existing = promo);
    } catch (_) {
      // Не смогли прочитать — не мешаем ввести код: сервер всё равно отобьёт второй.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Локализованный текст по коду ошибки сервера. Их ровно четыре (см. PromoException).
  String _messageFor(ApiException e, AppLocalizations l10n) {
    switch (e.code) {
      case 'PROMO_NOT_FOUND':
        return l10n.promoErrNotFound;
      case 'PROMO_EXPIRED':
        return l10n.promoErrExpired;
      case 'PROMO_LIMIT_REACHED':
        return l10n.promoErrLimit;
      case 'PROMO_ALREADY_HAS':
        return l10n.promoErrAlready;
      case 'RATE_LIMITED':
        return l10n.promoErrTooManyAttempts;
      default:
        return l10n.promoErrGeneric;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _controller.text.trim();
    if (code.length < 4 || _submitting) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final result = await _service.apply(code);
      AnalyticsService.instance.logEvent('promo_applied', parameters: {
        'code': result.code,
        'type': result.type.name,
        'value': '${result.value}',
      });
      // Бонусные монеты меняют баланс, который показывает вебвью Гардероба. Он в
      // IndexedStack и сам не перемонтируется — просим его перечитать баланс,
      // иначе человек не увидит начисления и решит, что промокод не сработал.
      if (result.type == PromoType.bonusCoins) {
        WebViewBridge.requestCoinsRefresh();
      }
      if (!mounted) return;
      await showPromoSuccessSheet(context, result);
      if (!mounted) return;
      _finish();
    } on ApiException catch (e) {
      AnalyticsService.instance.logEvent('promo_apply_failed', parameters: {
        'code': code,
        'error_code': e.code ?? 'UNKNOWN',
      });
      if (mounted) setState(() => _errorText = _messageFor(e, l10n));
    } catch (_) {
      if (mounted) setState(() => _errorText = l10n.promoErrGeneric);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _finish() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.promoCode),
        actions: [
          if (widget.showSkip)
            TextButton(
              onPressed: _submitting ? null : _finish,
              child: Text(l10n.promoSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.showSkip ? l10n.promoOnboardingTitle : l10n.promoCode,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _existing != null ? l10n.promoAlreadyAttached : l10n.promoHint,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 24),
                    if (_existing != null)
                      _AttachedCode(promo: _existing!)
                    else ...[
                      CustomTextField(
                        controller: _controller,
                        hintText: 'MALIKA',
                        errorText: _errorText,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        maxLength: 20,
                        // Авто-UPPERCASE и обрезка пробелов прямо во вводе: сервер всё равно
                        // нормализует, но человек должен видеть код таким, каким его дали.
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          _UpperCaseFormatter(),
                        ],
                        onChanged: (_) {
                          if (_errorText != null) setState(() => _errorText = null);
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: l10n.promoApply,
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Привязанный код: показываем какой и жива ли ещё скидка.
class _AttachedCode extends StatelessWidget {
  final MyPromo promo;

  const _AttachedCode({required this.promo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final live = promo.discountActive && promo.discountPercent != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: live ? const Color(0x1FF370A7) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: live ? const Color(0xFFF370A7) : theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.code,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(promo.ownerName, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          if (live) ...[
            const SizedBox(height: 10),
            Text(
              l10n.promoDiscountActive(promo.discountPercent!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFE0559A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (promo.type == PromoType.discountPercent) ...[
            const SizedBox(height: 10),
            Text(l10n.promoDiscountUsed, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ],
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
