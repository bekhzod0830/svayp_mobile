import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Style Categories Screen
/// Allows users to choose one or multiple style categories
class StyleCategoriesScreen extends StatefulWidget {
  const StyleCategoriesScreen({super.key});

  @override
  State<StyleCategoriesScreen> createState() => _StyleCategoriesScreenState();
}

class _StyleCategoriesScreenState extends State<StyleCategoriesScreen> {
  Set<String> _selectedCategories = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Load saved style categories from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.styleCategories.isNotEmpty) {
        setState(() {
          _selectedCategories = Set<String>.from(manager.styleCategories);
        });
      }
    }
  }

  List<CategoryOption> _getCategories(AppLocalizations l10n) {
    return [
      CategoryOption(id: 'casual', title: l10n.casual),
      CategoryOption(id: 'formal', title: l10n.formal),
      CategoryOption(id: 'business', title: l10n.business),
      CategoryOption(id: 'sporty', title: l10n.sporty),
      CategoryOption(id: 'elegant', title: l10n.elegant),
      CategoryOption(id: 'bohemian', title: l10n.bohemian),
      CategoryOption(id: 'vintage', title: l10n.vintage),
      CategoryOption(id: 'modern', title: l10n.modern),
      CategoryOption(id: 'minimalist', title: l10n.minimalist),
      CategoryOption(id: 'classic', title: l10n.classic),
      CategoryOption(id: 'trendy', title: l10n.trendy),
      CategoryOption(id: 'modest', title: l10n.modest),
      CategoryOption(id: 'streetwear', title: l10n.streetwear),
      CategoryOption(id: 'romantic', title: l10n.romantic),
    ];
  }

  Future<void> _continue() async {
    if (_selectedCategories.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.selectAtLeastOne);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save style categories to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setStyleCategories(_selectedCategories.toList());

      if (!mounted) return;

      // Navigate to budget-preference screen
      Navigator.of(context).pushNamed('/budget-preference');
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
    final categories = _getCategories(l10n);

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
                    const OnboardingProgressBar(currentStep: 8, totalSteps: 10),
                    const SizedBox(height: 32),
                    // Header
                    Text(l10n.styleCategories, style: AppTypography.heading1),
                    const SizedBox(height: 8),
                    Text(
                      l10n.styleCategoriesDescription,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Categories List
                    ...List.generate(categories.length, (index) {
                      final category = categories[index];
                      final isSelected = _selectedCategories.contains(
                        category.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CategoryCard(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategories.remove(category.id);
                              } else {
                                _selectedCategories.add(category.id);
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
                color: AppColors.white,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Next Button (pill-shaped, dynamic width)
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedCategories.isEmpty || _isLoading
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

class CategoryOption {
  final String id;
  final String title;

  CategoryOption({required this.id, required this.title});
}

class _CategoryCard extends StatelessWidget {
  final CategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
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
                category.title,
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
