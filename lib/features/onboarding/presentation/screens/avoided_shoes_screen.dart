import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Avoided Shoes Screen - Let users select shoe types they want to avoid
class AvoidedShoesScreen extends StatefulWidget {
  const AvoidedShoesScreen({super.key});

  @override
  State<AvoidedShoesScreen> createState() => _AvoidedShoesScreenState();
}

class _AvoidedShoesScreenState extends State<AvoidedShoesScreen> {
  final Set<String> _avoidedShoes = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _shoes = [
    {'name': 'Wedges', 'icon': Icons.stairs},
    {'name': 'Flats', 'icon': Icons.horizontal_rule},
    {'name': 'Sandals', 'icon': Icons.sunny},
    {'name': 'Heels', 'icon': Icons.arrow_upward},
    {'name': 'Booties', 'icon': Icons.ac_unit},
    {'name': 'Sneakers', 'icon': Icons.directions_run},
  ];

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save avoided shoes to backend/local storage
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to budget-by-items screen (skipping avoided-colors)
      Navigator.of(context).pushNamed('/budget-by-items');
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

  void _toggleShoe(String shoe) {
    setState(() {
      if (_avoidedShoes.contains(shoe)) {
        _avoidedShoes.remove(shoe);
      } else {
        _avoidedShoes.add(shoe);
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
                      currentStep: 12,
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
                      'Select shoe types you want to avoid',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Shoes Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: _shoes.length,
                      itemBuilder: (context, index) {
                        final shoe = _shoes[index];
                        final isSelected = _avoidedShoes.contains(shoe['name']);

                        return GestureDetector(
                          onTap: () => _toggleShoe(shoe['name']),
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
                                  shoe['icon'],
                                  size: 48,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  shoe['name'],
                                  style: AppTypography.body1.copyWith(
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
