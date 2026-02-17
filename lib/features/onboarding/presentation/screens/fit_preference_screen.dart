import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Fit Preference Screen
/// For covered hijab users to choose their preferred style fit
class FitPreferenceScreen extends StatefulWidget {
  const FitPreferenceScreen({super.key});

  @override
  State<FitPreferenceScreen> createState() => _FitPreferenceScreenState();
}

class _FitPreferenceScreenState extends State<FitPreferenceScreen> {
  Set<String> _selectedFits = {}; // Changed to Set for multiple selections
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
      }

      // Load saved preferences from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.hijabPreference != null) {
        _hijabPreference = manager.hijabPreference!;
      }
      if (manager.fitPreference.isNotEmpty) {
        setState(() {
          _selectedFits = Set<String>.from(manager.fitPreference);
        });
      }
    }
  }

  List<FitOption> _getFitOptions(AppLocalizations l10n) {
    // Determine folder based on hijab preference
    final String folderPath = _hijabPreference == 'covered'
        ? 'lib/img/fit_preference/covered/'
        : 'lib/img/fit_preference/uncovered/';

    final List<FitOption> options = [
      FitOption(
        id: 'loose',
        title: l10n.loose,
        description: l10n.comfortableRelaxedFit,
        imagePath: '${folderPath}loose.png',
      ),
      FitOption(
        id: 'regular',
        title: l10n.regular,
        description: l10n.standardComfortableFit,
        imagePath: '${folderPath}regular.png',
      ),
      FitOption(
        id: 'oversized',
        title: l10n.fitOversized,
        description: 'Extra roomy and relaxed fit',
        imagePath: '${folderPath}oversized.png',
      ),
      FitOption(
        id: 'slim',
        title: l10n.fitSlim,
        description: 'Fitted and tailored silhouette',
        imagePath: '${folderPath}slim.png',
      ),
    ];

    // Add super_slim only for uncovered users
    if (_hijabPreference == 'uncovered') {
      options.add(
        FitOption(
          id: 'super_slim',
          title: l10n.fitSuperSlim,
          description: 'Very fitted and body-hugging',
          imagePath: '${folderPath}super_slim.png',
        ),
      );
    }

    return options;
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedFits.isEmpty) {
      SnackBarHelper.showError(context, l10n.selectFitError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save fit preferences to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      // Save as list of selected fits
      manager.setFitPreference(_selectedFits.toList());

      if (!mounted) return;

      // If user is covered, skip modesty level and go directly to body type
      // For covered users, modesty level is automatically set to "covered"
      if (_hijabPreference == 'covered') {
        Navigator.of(context).pushNamed(
          '/body-type',
          arguments: {'gender': _gender, 'hijabPreference': _hijabPreference},
        );
      } else {
        // For uncovered users, show the modesty level screen
        Navigator.of(context).pushNamed(
          '/modesty-level',
          arguments: {'gender': _gender, 'hijabPreference': _hijabPreference},
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveFitError);
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
    final fitOptions = _getFitOptions(l10n);

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
                    const OnboardingProgressBar(currentStep: 3, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.fitPreference,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.howDoYouPreferClothesToFit,
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
                        l10n.selectMultipleOptions,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fit Options - Modern Card Grid
                    ...fitOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FitOptionCard(
                          option: option,
                          isSelected: _selectedFits.contains(option.id),
                          onTap: () {
                            if (!_isLoading) {
                              setState(() {
                                if (_selectedFits.contains(option.id)) {
                                  _selectedFits.remove(option.id);
                                } else {
                                  _selectedFits.add(option.id);
                                }
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),

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
                        onPressed: _selectedFits.isEmpty || _isLoading
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

/// Fit Option Model
class FitOption {
  final String id;
  final String title;
  final String description;
  final String imagePath;

  FitOption({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

/// Fit Option Card Widget - Horizontal Layout like Liked Items
class _FitOptionCard extends StatelessWidget {
  final FitOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FitOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image (Left)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 100,
                height: 110,
                color: AppColors.gray100,
                child: Image.asset(
                  option.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.gray200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: AppColors.gray400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Product Details (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and checkbox
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: AppTypography.heading4.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isSelected
                                ? AppColors.black
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.gray400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      option.description,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
