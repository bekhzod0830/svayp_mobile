import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Hijab Preference Screen - For female users to select their preference
/// Covered (wearing Hijab) or Uncovered (Traditional)
class HijabPreferenceScreen extends StatefulWidget {
  const HijabPreferenceScreen({super.key});

  @override
  State<HijabPreferenceScreen> createState() => _HijabPreferenceScreenState();
}

class _HijabPreferenceScreenState extends State<HijabPreferenceScreen> {
  String _selectedPreference = '';
  bool _isLoading = false;
  String _gender = 'female';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Get user data from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gender = args['gender'] as String? ?? 'female';
      }

      // Load saved preference from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.hijabPreference != null) {
        setState(() {
          _selectedPreference = manager.hijabPreference!;
        });
      }
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedPreference.isEmpty) {
      SnackBarHelper.showError(context, l10n.selectPreferenceError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save hijab preference to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setHijabPreference(_selectedPreference);

      if (!mounted) return;

      // Navigate to fit preference screen (skipping primary-objective)
      Navigator.of(context).pushNamed(
        '/fit-preference',
        arguments: {'gender': _gender, 'hijabPreference': _selectedPreference},
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.savePreferenceError);
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
            // Full Content Area - SingleChildScrollView to prevent overflow
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Section with Title and Subtitle
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          const OnboardingProgressBar(
                            currentStep: 2,
                            totalSteps: 10,
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            l10n.yourStylePreference,
                            style: AppTypography.heading2,
                          ),
                          const SizedBox(height: 6),
                          // Subtitle
                          Text(
                            l10n.relevantFashionChoices,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main Content - Centered Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Covered Card (Left) - Angled outward
                          Expanded(
                            child: Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..rotateY(
                                  -0.15,
                                ), // rotate to the left (outward)
                              child: _PreferenceImageCard(
                                title: l10n.covered,
                                imagePath:
                                    'lib/img/style_preference/covered.png',
                                isSelected: _selectedPreference == 'covered',
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedPreference = 'covered';
                                        });
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Uncovered Card (Right) - Angled outward
                          Expanded(
                            child: Transform(
                              alignment: Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..rotateY(
                                  0.15,
                                ), // rotate to the right (outward)
                              child: _PreferenceImageCard(
                                title: l10n.uncovered,
                                imagePath:
                                    'lib/img/style_preference/uncovered.png',
                                isSelected: _selectedPreference == 'uncovered',
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedPreference = 'uncovered';
                                        });
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Navigation - Outside SafeArea
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
                        onPressed: _selectedPreference.isEmpty || _isLoading
                            ? null
                            : _continue,
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

/// Preference Image Card Widget with Large Rounded Corners (iOS-style)
class _PreferenceImageCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PreferenceImageCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // More flexible height calculation - smaller on smaller screens
    final cardHeight = screenHeight < 700
        ? screenHeight *
              0.45 // 45% for smaller screens
        : screenHeight * 0.50; // 50% for larger screens (max)

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        constraints: const BoxConstraints(
          maxHeight: 450, // Maximum height cap
          minHeight: 300, // Minimum height
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32), // Large iOS-style radius
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(isSelected ? 0.15 : 0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full Image Background
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.gray200,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                    ),
                  );
                },
              ),

              // Bottom Gradient Overlay for better text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Selection Indicator and Label at Bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Radio Button (single selection)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.white
                            : Colors.transparent,
                        border: Border.all(color: AppColors.white, width: 2.5),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.black,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    // Label Text - Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
