import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Shows an in-app message popup with the notification's [title], [body] and an
/// optional [imageUrl]. Used when a SYSTEM / broadcast notification is opened —
/// instead of routing to a page we surface the full message right where the
/// user is.
///
/// If [actionLabel] and [onAction] are provided, a secondary button is shown
/// (e.g. "View Details") that runs [onAction] after closing the dialog.
Future<void> showInAppMessageDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? imageUrl,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => InAppMessageDialog(
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

class InAppMessageDialog extends StatelessWidget {
  const InAppMessageDialog({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardBackground : AppColors.white;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.black;
    final secondaryText =
        isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasAction = actionLabel != null && onAction != null;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            ConstrainedBox(
              // Show the whole image (no cropping): scale to fit the available
              // space while preserving aspect ratio, capped to a sane height.
              constraints: const BoxConstraints(maxHeight: 320),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: secondaryText.withValues(alpha: 0.08),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: AppTypography.heading3.copyWith(color: primaryText),
                  ),
                if (title.isNotEmpty && body.isNotEmpty)
                  const SizedBox(height: 8),
                if (body.isNotEmpty)
                  Text(
                    body,
                    style: AppTypography.body2.copyWith(
                      color: secondaryText,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.close,
                        style: TextStyle(color: secondaryText),
                      ),
                    ),
                    if (hasAction) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onAction!();
                        },
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
