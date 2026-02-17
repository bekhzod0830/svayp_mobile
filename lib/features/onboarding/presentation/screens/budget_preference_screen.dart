import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Budget Preference Screen - Third step of profile setup
/// User selects their preferred price range
class BudgetPreferenceScreen extends StatefulWidget {
  const BudgetPreferenceScreen({super.key});

  @override
  State<BudgetPreferenceScreen> createState() => _BudgetPreferenceScreenState();
}

class _BudgetPreferenceScreenState extends State<BudgetPreferenceScreen> {
  String _selectedBudget = '';
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Load saved budget preference from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.budgetType != null) {
        setState(() {
          _selectedBudget = manager.budgetType!.toLowerCase();
        });
      }
    }
  }

  List<BudgetRange> _getBudgetRanges(AppLocalizations l10n) {
    return [
      BudgetRange(
        id: 'budget',
        label: l10n.budgetFriendly,
        description: l10n.under500k,
        minPrice: 0,
        maxPrice: 500000,
        icon: Icons.monetization_on_outlined,
      ),
      BudgetRange(
        id: 'moderate',
        label: l10n.moderate,
        description: l10n.range500kTo1500k,
        minPrice: 500000,
        maxPrice: 1500000,
        icon: Icons.attach_money,
      ),
      BudgetRange(
        id: 'premium',
        label: l10n.premium,
        description: l10n.range1500kTo3000k,
        minPrice: 1500000,
        maxPrice: 3000000,
        icon: Icons.diamond_outlined,
      ),
      BudgetRange(
        id: 'luxury',
        label: l10n.luxury,
        description: l10n.over3000k,
        minPrice: 3000000,
        maxPrice: null,
        icon: Icons.star_outline,
      ),
      BudgetRange(
        id: 'flexible',
        label: l10n.flexible,
        description: l10n.showMeEverything,
        minPrice: 0,
        maxPrice: null,
        icon: Icons.all_inclusive,
      ),
    ];
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedBudget.isEmpty) {
      SnackBarHelper.showError(context, l10n.selectBudgetError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save budget preference to onboarding manager
      final manager = context.read<OnboardingDataManager>();

      // Convert budget ID to API format (BUDGET, MODERATE, FLEXIBLE, etc.)
      String budgetType = _selectedBudget.toUpperCase();
      manager.setBudgetType(budgetType);

      if (!mounted) return;

      // Navigate to budget by items screen (final onboarding step)
      Navigator.of(context).pushNamed('/budget-by-items');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.saveBudgetError);
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
    final budgetRanges = _getBudgetRanges(l10n);

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
                    const OnboardingProgressBar(currentStep: 9, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.whatsYourBudgetRange,
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      l10n.showItemsWithinPriceRange,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Budget Range Options
                    ...List.generate(budgetRanges.length, (index) {
                      final budget = budgetRanges[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BudgetOption(
                          budgetRange: budget,
                          isSelected: _selectedBudget == budget.id,
                          onTap: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedBudget = budget.id;
                                  });
                                },
                        ),
                      );
                    }),

                    // Info Text
                    Center(
                      child: Text(
                        l10n.changeAnytimeInSettings,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.tertiaryText,
                        ),
                        textAlign: TextAlign.center,
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
                        onPressed: _selectedBudget.isEmpty || _isLoading
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

/// Budget Range Model
class BudgetRange {
  final String id;
  final String label;
  final String description;
  final int minPrice;
  final int? maxPrice;
  final IconData icon;

  BudgetRange({
    required this.id,
    required this.label,
    required this.description,
    required this.minPrice,
    this.maxPrice,
    required this.icon,
  });
}

/// Budget Option Widget
class _BudgetOption extends StatelessWidget {
  final BudgetRange budgetRange;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BudgetOption({
    required this.budgetRange,
    required this.isSelected,
    this.onTap,
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
            color: isSelected ? AppColors.black : AppColors.standardBorder,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(budgetRange.icon, size: 24, color: AppColors.gray700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budgetRange.label,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budgetRange.description,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
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
