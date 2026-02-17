import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Budget Preferences By Items Screen - Let users set budget ranges for different categories
class BudgetByItemsScreen extends StatefulWidget {
  const BudgetByItemsScreen({super.key});

  @override
  State<BudgetByItemsScreen> createState() => _BudgetByItemsScreenState();
}

class _BudgetByItemsScreenState extends State<BudgetByItemsScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;

  // Budget options (keys for translation)
  final List<String> _budgetKeys = [
    'budgetUnder500k',
    'budget500kTo1m',
    'budget1mTo1_5m',
    'budget1_5mTo2m',
    'budget2mPlus',
  ];

  // Category keys for translation
  final List<String> _categoryKeys = [
    'categoryTops',
    'categoryBottoms',
    'categoryJacketsCoats',
    'categoryDresses',
    'categoryShoes',
    'categoryAccessories',
    'categoryJewelry',
  ];

  // Selected budget for each category (using keys)
  final Map<String, String?> _selectedBudgets = {
    'categoryTops': null,
    'categoryBottoms': null,
    'categoryJacketsCoats': null,
    'categoryDresses': null,
    'categoryShoes': null,
    'categoryAccessories': null,
    'categoryJewelry': null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;
      // Note: Per-category budgets are no longer supported by the API
      // The new API only supports a single budgetType field (BUDGET, MODERATE, FLEXIBLE)
      // This screen is kept for potential future use but doesn't save category budgets
    }
  }

  // Helper to get translated budget option
  String _getBudgetText(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'budgetUnder500k':
        return l10n.budgetUnder500k;
      case 'budget500kTo1m':
        return l10n.budget500kTo1m;
      case 'budget1mTo1_5m':
        return l10n.budget1mTo1_5m;
      case 'budget1_5mTo2m':
        return l10n.budget1_5mTo2m;
      case 'budget2mPlus':
        return l10n.budget2mPlus;
      default:
        return key;
    }
  }

  // Helper to get translated category
  String _getCategoryText(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'categoryTops':
        return l10n.categoryTops;
      case 'categoryBottoms':
        return l10n.categoryBottoms;
      case 'categoryJacketsCoats':
        return l10n.categoryJacketsCoats;
      case 'categoryDresses':
        return l10n.categoryDresses;
      case 'categoryShoes':
        return l10n.categoryShoes;
      case 'categoryAccessories':
        return l10n.categoryAccessories;
      case 'categoryJewelry':
        return l10n.categoryJewelry;
      default:
        return key;
    }
  }

  Future<void> _continue() async {
    print('🎯 [Budget By Items] Continue button pressed');

    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 [Budget By Items] Getting dependencies...');
      // Import required dependencies at the top of the file
      final manager = context.read<OnboardingDataManager>();
      final profileService = getIt<ProfileService>();
      final apiClient = getIt<ApiClient>();
      final l10n = AppLocalizations.of(context)!;

      // CRITICAL: Check if user is authenticated before creating profile
      print('🔐 [Budget By Items] Checking authentication...');
      if (!apiClient.isAuthenticated()) {
        print('❌ [Budget By Items] User not authenticated!');
        if (!mounted) return;
        SnackBarHelper.showError(context, l10n.authenticationRequired);
        // Navigate back to login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/phone-auth', (route) => false);
        return;
      }
      print('✅ [Budget By Items] User is authenticated');

      // Validate required fields
      print('📋 [Budget By Items] Validating required fields...');
      if (!manager.hasRequiredFields) {
        print('❌ [Budget By Items] Missing required fields!');
        SnackBarHelper.showError(context, l10n.pleaseCompleteAllFields);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('✅ [Budget By Items] All required fields present');

      // Convert collected data to API format
      print('🔄 [Budget By Items] Converting data to API format...');
      final profileRequest = manager.toProfileRequest();
      print('📦 [Budget By Items] Profile request created');
      print('   Gender: ${profileRequest.gender}');
      print('   DOB: ${profileRequest.dateOfBirth}');
      print('   Body Type: ${profileRequest.bodyType}');
      print('   Hijab: ${profileRequest.hijabPreference}');
      print('   Style Prefs: ${profileRequest.stylePreference}');

      // Submit profile to backend BEFORE navigating to completion screen
      print('📤 [Budget By Items] Sending profile creation request...');
      await profileService.createProfile(profileRequest);
      print('✅ [Budget By Items] Profile created successfully!');

      // TODO: Submit quiz results once real products are in database
      // Style quiz currently uses placeholder images (1, 2, 3...) not real product IDs
      // Uncomment when products are seeded:
      // if (manager.quizResults.isNotEmpty) {
      //   await profileService.submitStyleQuiz(manager.quizResults);
      // }

      if (!mounted) return;

      // Navigate to onboarding completion screen only after successful profile creation
      print('🎉 [Budget By Items] Navigating to completion screen...');
      Navigator.of(context).pushNamed('/onboarding-completion');
    } catch (e) {
      print('❌ [Budget By Items] Error: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(
        context,
        '${l10n.failedToCreateProfile}: ${e.toString()}',
      );
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    const OnboardingProgressBar(
                      currentStep: 10,
                      totalSteps: 10,
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.setBudgetPreferences,
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      l10n.choosePriceRange,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Budget Options for each category
                    ..._categoryKeys.map((categoryKey) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _BudgetSelector(
                          category: _getCategoryText(context, categoryKey),
                          options: _budgetKeys
                              .map((key) => _getBudgetText(context, key))
                              .toList(),
                          selectedOption: _selectedBudgets[categoryKey] != null
                              ? _getBudgetText(
                                  context,
                                  _selectedBudgets[categoryKey]!,
                                )
                              : null,
                          onChanged: (newOption) {
                            // Find the key that matches the selected translation
                            final budgetKey = _budgetKeys.firstWhere(
                              (key) =>
                                  _getBudgetText(context, key) == newOption,
                            );
                            setState(() {
                              _selectedBudgets[categoryKey] = budgetKey;
                            });
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
                                l10n.completeSetup,
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

class _BudgetSelector extends StatelessWidget {
  final String category;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onChanged;

  const _BudgetSelector({
    required this.category,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Name
        Text(
          category,
          style: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Budget Options - Horizontal Scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedOption == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.black : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.black
                            : AppColors.lightBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: AppTypography.body2.copyWith(
                        color: isSelected ? AppColors.white : AppColors.black,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
