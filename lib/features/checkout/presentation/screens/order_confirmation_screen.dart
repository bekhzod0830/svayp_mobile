import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:lottie/lottie.dart';

/// Order Confirmation Screen - Success message after order placement
class OrderConfirmationScreen extends StatelessWidget {
  final String orderNumber;
  final double totalAmount;
  final int itemsCount;
  final String status;

  const OrderConfirmationScreen({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    this.itemsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: const SizedBox(), // Remove back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success Animation
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  'assets/lottie/success.json',
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.check_circle,
                      size: 120,
                      color: isDark ? Colors.greenAccent : Colors.green,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Success Message
              Text(
                l10n.orderPlacedSuccessfully,
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orderConfirmedMessage,
                  style: AppTypography.body1.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 32),

              // Order Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? Border.all(
                          color: AppColors.darkSecondaryText.withOpacity(0.1),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    _buildDetailRow(l10n.orderNumber, orderNumber, context),
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark
                          ? AppColors.darkSecondaryText.withOpacity(0.2)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      l10n.totalAmount,
                      '${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                      context,
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark
                          ? AppColors.darkSecondaryText.withOpacity(0.2)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      l10n.orderStatus,
                      _getLocalizedStatus(status, context),
                      context,
                    ),
                    if (itemsCount > 0) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: isDark
                            ? AppColors.darkSecondaryText.withOpacity(0.2)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        l10n.items,
                        l10n.itemsCount(itemsCount),
                        context,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Find MainScreenState and navigate to Discover (LIBΛS) tab (index 4)
                        // Prefer ancestor lookup; fall back to the global key
                        final mainScreenState =
                            context.findAncestorStateOfType<MainScreenState>()
                            ?? MainScreen.globalKey.currentState;
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        mainScreenState?.navigateToTab(4);
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.trackOrder,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate back to main screen
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.continueShopping,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _getLocalizedStatus(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'WAITING':
        return l10n.waiting;
      case 'CONFIRMED':
        return l10n.confirmed;
      case 'READY_TO_SHIP':
        return l10n.readyToShip;
      case 'READY_FOR_PICKUP':
        return l10n.readyForPickup;
      case 'SHIPPED':
        return l10n.shipped;
      case 'DELIVERED':
        return l10n.delivered;
      case 'COMPLETED':
        return l10n.completed;
      case 'CANCELLED':
        return l10n.cancelled;
      case 'RETURNED':
        return l10n.returned;
      case 'VOIDED':
        return l10n.voided;
      default:
        if (status.isEmpty) return status;
        return status.replaceAll('_', ' ');
    }
  }
}
