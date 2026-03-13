import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';

/// Shows a bottom sheet prompting a guest user to sign in.
///
/// Usage:
/// ```dart
/// GuestLoginPrompt.show(context);
/// ```
class GuestLoginPrompt {
  GuestLoginPrompt._();

  static void show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray600 : AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray700 : AppColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  l10n.guestPromptTitle,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  l10n.guestPromptMessage,
                  style: AppTypography.body2.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Clear guest mode so phone auth screen shows properly
                      final storage = await LocalStorageHelper.getInstance();
                      await storage.clearGuestMode();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pushNamedAndRemoveUntil(
                          '/phone-auth',
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.white
                          : AppColors.black,
                      foregroundColor: isDark
                          ? AppColors.black
                          : AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.guestPromptSignIn,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.black : AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Continue browsing
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.guestPromptContinueBrowsing,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
