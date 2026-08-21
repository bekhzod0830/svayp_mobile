import 'package:flutter/material.dart';
import 'package:swipe/features/promo/data/models/promo_models.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Bottom sheet «Промокод применён» (пункт 6.4 ТЗ).
///
/// Отдельный шит, а не снекбар: бонус может быть заметной суммой, и человек должен увидеть,
/// что именно получил — алмазы на баланс или скидку на первую покупку.
Future<void> showPromoSuccessSheet(BuildContext context, PromoApplied result) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  // Повторный ввод ничего не начисляет — писать «зачислено N алмазов» второй раз значит
  // врать. Показываем текущее состояние: скидка ещё жива или уже потрачена.
  final detail = result.alreadyActivated
      ? (result.discountActive
          ? l10n.promoAlreadyActive(result.value)
          : l10n.promoAlreadyUsedInfo)
      : result.type == PromoType.bonusCoins
          ? l10n.promoSuccessBonus(result.value)
          : l10n.promoSuccessDiscount(result.value);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE2DBE1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Icon(Icons.diamond_rounded, size: 52, color: Color(0xFFF370A7)),
            const SizedBox(height: 12),
            Text(
              result.alreadyActivated ? l10n.promoAlreadyTitle : l10n.promoSuccessTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFE0559A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.code,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF370A7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  l10n.promoSuccessOk,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
