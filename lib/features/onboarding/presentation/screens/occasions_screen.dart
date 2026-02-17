import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Occasions Screen
/// Allows users to choose one or multiple occasions they dress for
class OccasionsScreen extends StatefulWidget {
  const OccasionsScreen({super.key});

  @override
  State<OccasionsScreen> createState() => _OccasionsScreenState();
}

class _OccasionsScreenState extends State<OccasionsScreen> {
  Set<String> _selectedOccasions = {};
  bool _isLoading = false;

  List<OccasionOption> _getOccasions(AppLocalizations l10n) {
    return [
      OccasionOption(id: 'casual', title: l10n.occasionCasual),
      OccasionOption(id: 'work', title: l10n.occasionWork),
      OccasionOption(id: 'study', title: l10n.occasionStudy),
      OccasionOption(id: 'formal', title: l10n.occasionFormal),
      OccasionOption(id: 'religious', title: l10n.occasionReligious),
      OccasionOption(id: 'party', title: l10n.occasionParty),
      OccasionOption(id: 'sports', title: l10n.occasionSports),
      OccasionOption(id: 'travel', title: l10n.occasionTravel),
      OccasionOption(id: 'outdoor', title: l10n.occasionOutdoor),
      OccasionOption(id: 'special', title: l10n.occasionSpecial),
    ];
  }

  Future<void> _continue() async {
    if (_selectedOccasions.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.selectAtLeastOne);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save occasions to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setOccasionPreference(_selectedOccasions.toList());

      if (!mounted) return;

      // Navigate to brand preferences screen
      Navigator.of(context).pushReplacementNamed('/brand-preferences');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.genericError);
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
    final occasions = _getOccasions(l10n);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                    // Header
                    Text(l10n.occasions, style: AppTypography.heading1),
                    const SizedBox(height: 8),
                    Text(
                      l10n.occasionsDescription,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Occasions List
                    ...List.generate(occasions.length, (index) {
                      final occasion = occasions[index];
                      final isSelected = _selectedOccasions.contains(
                        occasion.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OccasionCard(
                          occasion: occasion,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedOccasions.remove(occasion.id);
                              } else {
                                _selectedOccasions.add(occasion.id);
                              }
                            });
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
                color: AppColors.pageBackground,
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
                        onPressed: _selectedOccasions.isEmpty || _isLoading
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

class OccasionOption {
  final String id;
  final String title;

  OccasionOption({required this.id, required this.title});
}

class _OccasionCard extends StatelessWidget {
  final OccasionOption occasion;
  final bool isSelected;
  final VoidCallback onTap;

  const _OccasionCard({
    required this.occasion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.standardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                occasion.title,
                style: AppTypography.body1.copyWith(
                  color: isSelected ? AppColors.black : AppColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.black, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.standardBorder, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
