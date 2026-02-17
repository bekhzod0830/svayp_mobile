import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:lottie/lottie.dart';

/// Order Confirmation Screen - Success message after order placement
class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double totalAmount;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
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

              const SizedBox(height: 24),

              // Success Message
              Text(
                l10n.orderPlacedSuccessfully,
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                l10n.orderConfirmedMessage,
                style: AppTypography.body1.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
                textAlign: TextAlign.center,
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
                    _buildDetailRow(l10n.orderId, orderId, context),
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
                      l10n.estimatedDelivery,
                      _getEstimatedDeliveryDate(),
                      context,
                    ),
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
                        // Find MainScreenState and navigate to Orders tab (index 3)
                        final mainScreenState = context
                            .findAncestorStateOfType<MainScreenState>();
                        if (mainScreenState != null) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                          mainScreenState.navigateToTab(
                            3,
                          ); // Navigate to Orders tab
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
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
          ),
        ),
        Text(
          value,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _getEstimatedDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 5));
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${deliveryDate.day} ${months[deliveryDate.month - 1]}, ${deliveryDate.year}';
  }
}
