import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Brand Preferences Screen
/// Allows users to choose one or multiple preferred brands
class BrandPreferencesScreen extends StatefulWidget {
  const BrandPreferencesScreen({super.key});

  @override
  State<BrandPreferencesScreen> createState() => _BrandPreferencesScreenState();
}

class _BrandPreferencesScreenState extends State<BrandPreferencesScreen> {
  Set<String> _selectedBrands = {};
  bool _isLoading = false;

  List<BrandOption> _getBrands() {
    return [
      BrandOption(
        id: 'Louis Vuitton',
        name: 'Louis Vuitton',
        logoPath: 'lib/img/brands/louis_vuitton.png',
      ),
      BrandOption(
        id: 'Bershka',
        name: 'Bershka',
        logoPath: 'lib/img/brands/bershka.png',
      ),
      BrandOption(
        id: 'Massimo Dutti',
        name: 'Massimo Dutti',
        logoPath: 'lib/img/brands/massimo_dutti.png',
      ),
      BrandOption(
        id: 'Pull & Bear',
        name: 'Pull & Bear',
        logoPath: 'lib/img/brands/pull_bear.png',
      ),
      BrandOption(id: 'H&M', name: 'H&M', logoPath: 'lib/img/brands/hm.png'),
      BrandOption(
        id: 'Adidas',
        name: 'Adidas',
        logoPath: 'lib/img/brands/adidas.png',
      ),
      BrandOption(
        id: 'Nike',
        name: 'Nike',
        logoPath: 'lib/img/brands/nike.png',
      ),
      BrandOption(
        id: 'Hermes',
        name: 'Hermès',
        logoPath: 'lib/img/brands/hermes.png',
      ),
      BrandOption(
        id: 'Zara',
        name: 'Zara',
        logoPath: 'lib/img/brands/zara.png',
      ),
      BrandOption(
        id: 'Balenciaga',
        name: 'Balenciaga',
        logoPath: 'lib/img/brands/balenciaga.png',
      ),
      BrandOption(
        id: 'Yves Saint Laurent',
        name: 'Yves Saint Laurent',
        logoPath: 'lib/img/brands/ysl.png',
      ),
      BrandOption(
        id: 'Lacoste',
        name: 'Lacoste',
        logoPath: 'lib/img/brands/lacoste.png',
      ),
      BrandOption(id: 'GAP', name: 'GAP', logoPath: 'lib/img/brands/gap.png'),
      BrandOption(
        id: 'Burberry',
        name: 'Burberry',
        logoPath: 'lib/img/brands/burberry.png',
      ),
      BrandOption(
        id: 'The North Face',
        name: 'The North Face',
        logoPath: 'lib/img/brands/north_face.png',
      ),
      BrandOption(
        id: 'Prada',
        name: 'Prada',
        logoPath: 'lib/img/brands/prada.png',
      ),
      BrandOption(
        id: 'Tommy Hilfiger',
        name: 'Tommy Hilfiger',
        logoPath: 'lib/img/brands/tommy_hilfiger.png',
      ),
      BrandOption(
        id: 'Levis',
        name: "Levi's",
        logoPath: 'lib/img/brands/levis.png',
      ),
    ];
  }

  Future<void> _continue() async {
    // Allow skipping brand selection
    setState(() {
      _isLoading = true;
    });

    try {
      // Save brand preferences to onboarding manager (empty list if none selected)
      final manager = context.read<OnboardingDataManager>();
      manager.setBrandPreference(_selectedBrands.toList());

      if (!mounted) return;

      // Navigate to avoided colors screen
      Navigator.of(context).pushReplacementNamed('/avoided-colors');
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
    final brands = _getBrands();

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
                    Text(l10n.brandPreferences, style: AppTypography.heading1),
                    const SizedBox(height: 8),
                    Text(
                      l10n.brandPreferencesDescription,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.optionalSelection,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.tertiaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brands Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        final brand = brands[index];
                        final isSelected = _selectedBrands.contains(brand.id);

                        return _BrandCard(
                          brand: brand,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedBrands.remove(brand.id);
                              } else {
                                _selectedBrands.add(brand.id);
                              }
                            });
                          },
                        );
                      },
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

class BrandOption {
  final String id;
  final String name;
  final String logoPath;

  BrandOption({required this.id, required this.name, required this.logoPath});
}

class _BrandCard extends StatelessWidget {
  final BrandOption brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.standardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Brand Logo
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  brand.logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to text if image not found
                    return Text(
                      brand.name,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
            ),
            // Selection Indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
