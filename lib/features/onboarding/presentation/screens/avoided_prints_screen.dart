import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Avoided Prints Screen - Let users select patterns they want to avoid
class AvoidedPrintsScreen extends StatefulWidget {
  const AvoidedPrintsScreen({super.key});

  @override
  State<AvoidedPrintsScreen> createState() => _AvoidedPrintsScreenState();
}

class _AvoidedPrintsScreenState extends State<AvoidedPrintsScreen> {
  final Set<String> _avoidedPrints = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _prints = [
    {'name': 'Animals', 'icon': Icons.pets},
    {'name': 'Florals', 'icon': Icons.local_florist},
    {'name': 'Paisley', 'icon': Icons.grass},
    {'name': 'Plaids', 'icon': Icons.grid_4x4},
    {'name': 'Polka', 'icon': Icons.circle_outlined},
    {'name': 'Stripes', 'icon': Icons.line_weight},
  ];

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save avoided prints/patterns to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setAvoidedPatterns(_avoidedPrints.toList());

      if (!mounted) return;

      // Navigate to budget preferences by items screen
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

  void _togglePrint(String print) {
    setState(() {
      if (_avoidedPrints.contains(print)) {
        _avoidedPrints.remove(print);
      } else {
        _avoidedPrints.add(print);
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
                      currentStep: 13,
                      totalSteps: 13,
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Which patterns do you want to avoid?',
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Select patterns you want to avoid',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Prints Grid
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
                      itemCount: _prints.length,
                      itemBuilder: (context, index) {
                        final print = _prints[index];
                        final isSelected = _avoidedPrints.contains(
                          print['name'],
                        );

                        return GestureDetector(
                          onTap: () => _togglePrint(print['name']),
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
                                  print['icon'],
                                  size: 48,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  print['name'],
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
