import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Body Type Screen
/// User selects their body type with visual examples
class BodyTypeScreen extends StatefulWidget {
  const BodyTypeScreen({super.key});

  @override
  State<BodyTypeScreen> createState() => _BodyTypeScreenState();
}

class _BodyTypeScreenState extends State<BodyTypeScreen> {
  String? _selectedBodyType;
  bool _isLoading = false;
  String _gender = 'female';
  String _hijabPreference = 'uncovered';
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
        _hijabPreference = args['hijabPreference'] as String? ?? 'uncovered';
      }

      // Load saved body type from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.bodyType != null) {
        setState(() {
          _selectedBodyType = manager.bodyType;
        });
      }
    }
  }

  List<BodyTypeOption> _getBodyTypes(AppLocalizations l10n) {
    return [
      BodyTypeOption(
        id: 'hourglass',
        title: l10n.hourglass,
        description: l10n.hourglassDescription,
        imagePath: 'lib/img/body_type/Hourglass.png',
      ),
      BodyTypeOption(
        id: 'triangle',
        title: l10n.triangle,
        description: l10n.triangleDescription,
        imagePath: 'lib/img/body_type/Triangle.png',
      ),
      BodyTypeOption(
        id: 'rectangle',
        title: l10n.rectangle,
        description: l10n.rectangleDescription,
        imagePath: 'lib/img/body_type/Rectangle.png',
      ),
      BodyTypeOption(
        id: 'oval',
        title: l10n.oval,
        description: l10n.ovalDescription,
        imagePath: 'lib/img/body_type/Oval.png',
      ),
      BodyTypeOption(
        id: 'heart',
        title: l10n.heart,
        description: l10n.heartDescription,
        imagePath: 'lib/img/body_type/Heart.png',
      ),
    ];
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedBodyType == null) {
      SnackBarHelper.showError(context, l10n.selectBodyTypeError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Body type will be saved along with measurements in size_profile_screen
      // We pass it via route arguments

      if (!mounted) return;

      // Navigate to size profile screen where height, weight, and body type are saved together
      Navigator.of(context).pushNamed(
        '/size-profile',
        arguments: {
          'gender': _gender,
          'hijabPreference': _hijabPreference,
          'bodyType': _selectedBodyType,
        },
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveBodyTypeError);
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
    final bodyTypes = _getBodyTypes(l10n);

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
                    const OnboardingProgressBar(currentStep: 5, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.bodyType,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.selectBodyTypeHelpRecommend,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Body Type Options
                    ...List.generate(bodyTypes.length, (index) {
                      final bodyType = bodyTypes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BodyTypeCard(
                          bodyType: bodyType,
                          isSelected: _selectedBodyType == bodyType.id,
                          onTap: () {
                            if (!_isLoading) {
                              setState(() {
                                _selectedBodyType = bodyType.id;
                              });
                            }
                          },
                        ),
                      );
                    }),

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
                        onPressed: _selectedBodyType == null || _isLoading
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

/// Body Type Option Model
class BodyTypeOption {
  final String id;
  final String title;
  final String description;
  final String imagePath;

  BodyTypeOption({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

/// Body Type Card Widget
class _BodyTypeCard extends StatelessWidget {
  final BodyTypeOption bodyType;
  final bool isSelected;
  final VoidCallback onTap;

  const _BodyTypeCard({
    required this.bodyType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray300,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
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
            // Body Type Image
            Container(
              width: 70,
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  bodyType.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: AppColors.gray400,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bodyType.title,
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bodyType.description,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Radio Button (single selection)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.black : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.gray400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
