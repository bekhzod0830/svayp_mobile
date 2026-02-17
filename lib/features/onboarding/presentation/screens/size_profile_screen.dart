import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Size Profile Screen - Second step of profile setup
/// User selects height and body type
class SizeProfileScreen extends StatefulWidget {
  const SizeProfileScreen({super.key});

  @override
  State<SizeProfileScreen> createState() => _SizeProfileScreenState();
}

class _SizeProfileScreenState extends State<SizeProfileScreen> {
  double _height = 170; // in cm
  double _weight = 65; // in kg
  bool _isLoading = false;
  String? _bodyType;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Get body type from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bodyType = args['bodyType'] as String?;
      }

      // Load saved data from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.heightCm != null) {
        _height = manager.heightCm!.toDouble();
      }
      if (manager.weightKg != null) {
        _weight = manager.weightKg!;
      }
      if (manager.bodyType != null) {
        _bodyType = manager.bodyType;
      }

      // Trigger UI update if data was loaded
      if (manager.heightCm != null || manager.weightKg != null) {
        setState(() {});
      }
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate that body type was passed from previous screen
    if (_bodyType == null) {
      SnackBarHelper.showError(context, 'Body type is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save body measurements to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setBodyMeasurements(
        heightCm: _height.toInt(),
        weightKg: _weight,
        bodyType: _bodyType!,
      );

      if (!mounted) return;

      // Navigate to sizes screen
      Navigator.of(context).pushNamed('/sizes');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveInfoError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getHorizontalPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    const OnboardingProgressBar(currentStep: 5, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.sizeProfile,
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      l10n.helpUsRecommendPerfectSizes,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Height Selector
                    Text(
                      l10n.height,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_height.round()} cm',
                            style: AppTypography.display2,
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.black,
                              inactiveTrackColor: AppColors.gray300,
                              thumbColor: AppColors.black,
                              overlayColor: AppColors.black.withOpacity(0.1),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              value: _height,
                              min: 140,
                              max: 220,
                              divisions: 80,
                              onChanged: (value) {
                                setState(() {
                                  _height = value;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '140 cm',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.tertiaryText,
                                ),
                              ),
                              Text(
                                '220 cm',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.tertiaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Weight Selector
                    Text(
                      l10n.weight,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_weight.round()} kg',
                            style: AppTypography.display2,
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.black,
                              inactiveTrackColor: AppColors.gray300,
                              thumbColor: AppColors.black,
                              overlayColor: AppColors.black.withOpacity(0.1),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              value: _weight,
                              min: 40,
                              max: 150,
                              divisions: 110,
                              onChanged: (value) {
                                setState(() {
                                  _weight = value;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '40 kg',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.tertiaryText,
                                ),
                              ),
                              Text(
                                '150 kg',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.tertiaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                                l10n.continueButton,
                                style: AppTypography.button.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16,
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
