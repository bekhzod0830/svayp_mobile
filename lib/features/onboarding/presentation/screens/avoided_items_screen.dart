import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Avoided Items Screen - Let users select items they want their stylist to avoid
class AvoidedItemsScreen extends StatefulWidget {
  const AvoidedItemsScreen({super.key});

  @override
  State<AvoidedItemsScreen> createState() => _AvoidedItemsScreenState();
}

class _AvoidedItemsScreenState extends State<AvoidedItemsScreen> {
  final Set<String> _avoidedItems = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _items = [
    {'name': 'Dresses', 'icon': Icons.checkroom},
    {'name': 'Jackets', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Skirts', 'icon': Icons.style},
    {'name': 'Pants', 'icon': Icons.dry_cleaning},
    {'name': 'Shorts', 'icon': Icons.beach_access},
    {'name': 'Jeans', 'icon': Icons.man},
    {'name': 'Shoes', 'icon': Icons.shop},
    {'name': 'Bags', 'icon': Icons.shopping_bag},
    {'name': 'Blazers', 'icon': Icons.business_center},
    {'name': 'Earrings', 'icon': Icons.settings_bluetooth},
    {'name': 'Bracelets', 'icon': Icons.watch},
    {'name': 'Necklaces', 'icon': Icons.favorite_border},
  ];

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save avoided items to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setAvoidedItems(_avoidedItems.toList());

      if (!mounted) return;

      // Navigate to avoided shoes screen
      Navigator.of(context).pushNamed('/avoided-shoes');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleItem(String item) {
    setState(() {
      if (_avoidedItems.contains(item)) {
        _avoidedItems.remove(item);
      } else {
        _avoidedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    const OnboardingProgressBar(
                      currentStep: 11,
                      totalSteps: 13,
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Do you want your Stylist to avoid any of these?',
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Select all items you want to avoid',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Items Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isSelected = _avoidedItems.contains(item['name']);

                        return GestureDetector(
                          onTap: () => _toggleItem(item['name']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.black
                                    : AppColors.lightBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon'],
                                  size: 40,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item['name'],
                                  style: AppTypography.body2.copyWith(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.white,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (transparent background)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.black,
                        size: 28,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),

                    // Next Button (pill-shaped, dynamic width)
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.gray300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Continue',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
