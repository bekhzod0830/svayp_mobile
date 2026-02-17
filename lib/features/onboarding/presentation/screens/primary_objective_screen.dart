import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Primary Objective Screen
/// User selects their main styling objectives (single or multiple selection)
class PrimaryObjectiveScreen extends StatefulWidget {
  const PrimaryObjectiveScreen({super.key});

  @override
  State<PrimaryObjectiveScreen> createState() => _PrimaryObjectiveScreenState();
}

class _PrimaryObjectiveScreenState extends State<PrimaryObjectiveScreen> {
  final Set<String> _selectedObjectives = {};
  bool _isLoading = false;
  String? _hijabPreference;
  String _gender = 'female';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get user data from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _hijabPreference = args['hijabPreference'] as String?;
      _gender = args['gender'] as String? ?? 'female';
    }
  }

  List<ObjectiveOption> _getObjectives(AppLocalizations l10n) {
    return [
      ObjectiveOption(
        id: 'stylist',
        title: l10n.havingOwnStylist,
        icon: Icons.person_outline,
      ),
      ObjectiveOption(
        id: 'personalized_shop',
        title: l10n.browsePersonalizedShop,
        icon: Icons.storefront_outlined,
      ),
      ObjectiveOption(
        id: 'surprise',
        title: l10n.funSurprise,
        icon: Icons.card_giftcard_outlined,
      ),
      ObjectiveOption(
        id: 'unique',
        title: l10n.uniquePieces,
        icon: Icons.diamond_outlined,
      ),
      ObjectiveOption(
        id: 'update_look',
        title: l10n.updateLook,
        icon: Icons.auto_awesome_outlined,
      ),
      ObjectiveOption(
        id: 'save_time',
        title: l10n.saveTimeShopping,
        icon: Icons.access_time_outlined,
      ),
      ObjectiveOption(
        id: 'new_trends',
        title: l10n.tryNewTrends,
        icon: Icons.trending_up_outlined,
      ),
      ObjectiveOption(
        id: 'best_fit',
        title: l10n.findBestFit,
        icon: Icons.checkroom_outlined,
      ),
    ];
  }

  void _toggleObjective(String id) {
    if (_isLoading) return;

    setState(() {
      if (_selectedObjectives.contains(id)) {
        _selectedObjectives.remove(id);
      } else {
        _selectedObjectives.add(id);
      }
    });
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedObjectives.isEmpty) {
      SnackBarHelper.showError(context, l10n.selectObjectiveError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save primary objectives to onboarding manager (join multiple selections with comma)
      final manager = context.read<OnboardingDataManager>();
      manager.setPrimaryObjective(_selectedObjectives.join(','));

      if (!mounted) return;

      // Navigate to fit preference screen for all users
      // The fit preference screen will handle conditional navigation based on hijab preference
      Navigator.of(context).pushNamed(
        '/fit-preference',
        arguments: {'gender': _gender, 'hijabPreference': _hijabPreference},
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveObjectiveError);
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
    final objectives = _getObjectives(l10n);

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
                      l10n.primaryObjective,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.selectWhatMatters,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Objectives Grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: objectives.map((objective) {
                        final isSelected = _selectedObjectives.contains(
                          objective.id,
                        );
                        return _ObjectiveCard(
                          objective: objective,
                          isSelected: isSelected,
                          onTap: () => _toggleObjective(objective.id),
                          isEnabled: !_isLoading,
                        );
                      }).toList(),
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
                        onPressed: _selectedObjectives.isEmpty || _isLoading
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

/// Objective Option Model
class ObjectiveOption {
  final String id;
  final String title;
  final IconData icon;

  ObjectiveOption({required this.id, required this.title, required this.icon});
}

/// Objective Card Widget
class _ObjectiveCard extends StatelessWidget {
  final ObjectiveOption objective;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ObjectiveCard({
    required this.objective,
    required this.isSelected,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final cardPadding = isTablet ? 24.0 : 16.0;
    final iconSize = isTablet ? 48.0 : 32.0;
    final spacing = isTablet ? 16.0 : 12.0;

    final width = (screenWidth - 60) / 2;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: width,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              objective.icon,
              size: iconSize,
              color: isSelected ? AppColors.white : AppColors.black,
            ),
            SizedBox(height: spacing),
            Text(
              objective.title,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
