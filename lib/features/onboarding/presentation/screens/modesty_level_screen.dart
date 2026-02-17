import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Modesty Level Screen
/// Allows users to choose their preferred modesty level
class ModestyLevelScreen extends StatefulWidget {
  const ModestyLevelScreen({super.key});

  @override
  State<ModestyLevelScreen> createState() => _ModestyLevelScreenState();
}

class _ModestyLevelScreenState extends State<ModestyLevelScreen> {
  Set<String> _selectedModestyLevels =
      {}; // Changed to Set for multiple selections
  bool _isLoading = false;
  String _gender = 'female';
  String _hijabPreference = 'covered';
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
        _hijabPreference = args['hijabPreference'] as String? ?? 'covered';

        // If user is covered, skip this screen and set default stylePreference
        if (_hijabPreference == 'covered') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Set stylePreference to 'covered' since hijab is covered
            final manager = context.read<OnboardingDataManager>();
            if (manager.stylePreference.isEmpty) {
              manager.setStylePreference(['covered']);
            }
            _navigateToNextScreen();
          });
        }
      }

      // Load saved preferences from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.stylePreference.isNotEmpty) {
        setState(() {
          _selectedModestyLevels = Set<String>.from(manager.stylePreference);
        });
      }
    }
  }

  List<ModestyOption> _getModestyOptions(AppLocalizations l10n) {
    return [
      ModestyOption(
        id: 'revealing',
        title: l10n.revealing,
        imagePath: 'lib/img/modesty_level/revealing.png',
      ),
      ModestyOption(
        id: 'covered',
        title: l10n.covered,
        imagePath: 'lib/img/modesty_level/covered.png',
      ),
    ];
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushNamed(
      '/body-type',
      arguments: {'gender': _gender, 'hijabPreference': _hijabPreference},
    );
  }

  Future<void> _continue() async {
    if (_selectedModestyLevels.isEmpty) {
      SnackBarHelper.showError(
        context,
        'Please select at least one modesty level',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save modesty level (style preference) to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setStylePreference(_selectedModestyLevels.toList());

      if (!mounted) return;

      // Navigate to next screen (body type screen)
      _navigateToNextScreen();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.saveModestyError);
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
    final modestyOptions = _getModestyOptions(l10n);

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
                            currentStep: 4,
                            totalSteps: 10,
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            l10n.modestyLevel,
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            l10n.modestyLevelDescription,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Multiple selection hint
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.selectOneOrBothPreferences,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main Content - Centered Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Revealing Card (Left) - Angled outward
                          Expanded(
                            child: Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..rotateY(
                                  -0.15,
                                ), // rotate to the left (outward)
                              child: _ModestyImageCard(
                                title: modestyOptions[0].title,
                                imagePath: modestyOptions[0].imagePath,
                                isSelected: _selectedModestyLevels.contains(
                                  modestyOptions[0].id,
                                ),
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_selectedModestyLevels.contains(
                                            modestyOptions[0].id,
                                          )) {
                                            _selectedModestyLevels.remove(
                                              modestyOptions[0].id,
                                            );
                                          } else {
                                            _selectedModestyLevels.add(
                                              modestyOptions[0].id,
                                            );
                                          }
                                        });
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Covered Card (Right) - Angled outward
                          Expanded(
                            child: Transform(
                              alignment: Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..rotateY(
                                  0.15,
                                ), // rotate to the right (outward)
                              child: _ModestyImageCard(
                                title: modestyOptions[1].title,
                                imagePath: modestyOptions[1].imagePath,
                                isSelected: _selectedModestyLevels.contains(
                                  modestyOptions[1].id,
                                ),
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_selectedModestyLevels.contains(
                                            modestyOptions[1].id,
                                          )) {
                                            _selectedModestyLevels.remove(
                                              modestyOptions[1].id,
                                            );
                                          } else {
                                            _selectedModestyLevels.add(
                                              modestyOptions[1].id,
                                            );
                                          }
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
                        onPressed: _selectedModestyLevels.isEmpty || _isLoading
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

/// Modesty Option Model
class ModestyOption {
  final String id;
  final String title;
  final String imagePath;

  ModestyOption({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}

/// Modesty Image Card Widget with Large Rounded Corners (iOS-style) - Same as hijab preference
class _ModestyImageCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModestyImageCard({
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
                    // Modern Checkbox (supporting multiple selections)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? AppColors.white
                            : Colors.black.withOpacity(0.3),
                        border: Border.all(color: AppColors.white, width: 2.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.white.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 20,
                                color: AppColors.black,
                                weight: 700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Label Text - Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
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
