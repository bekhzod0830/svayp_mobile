import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/custom_button.dart';

/// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? illustration;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else if (icon != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 60, color: AppColors.gray500),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.body2.copyWith(color: AppColors.gray600),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(text: actionText!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle,
    this.actionText = 'Try Again',
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 60,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.body2.copyWith(color: AppColors.gray600),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: actionText!,
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network Error Widget
class NetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'No Internet Connection',
      subtitle: 'Please check your internet connection and try again',
      actionText: 'Retry',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }
}

/// No Data Widget (for empty lists)
class NoDataWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const NoDataWidget({
    super.key,
    this.title = 'No data found',
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon ?? Icons.inbox_outlined,
    );
  }
}

/// Search Empty State
class SearchEmptyState extends StatelessWidget {
  final String searchQuery;

  const SearchEmptyState({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No results found',
      subtitle: 'We couldn\'t find anything matching "$searchQuery"',
      icon: Icons.search_off,
    );
  }
}

/// Coming Soon Widget
class ComingSoon extends StatelessWidget {
  final String? message;

  const ComingSoon({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'Coming Soon',
      subtitle: message ?? 'This feature is under development',
      icon: Icons.upcoming_outlined,
    );
  }
}

/// Maintenance Mode Widget
class MaintenanceMode extends StatelessWidget {
  const MaintenanceMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        title: 'Under Maintenance',
        subtitle:
            'We\'re currently performing maintenance. Please check back soon!',
        icon: Icons.construction_outlined,
      ),
    );
  }
}

/// Snackbar Helper
class SnackBarHelper {
  SnackBarHelper._();

  /// Show success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body2.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
      ),
    );
  }

  /// Show error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body2.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body2.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.gray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
      ),
    );
  }
}
