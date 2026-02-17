import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Sizes Screen
/// User selects their typical clothing sizes
class SizesScreen extends StatefulWidget {
  const SizesScreen({super.key});

  @override
  State<SizesScreen> createState() => _SizesScreenState();
}

class _SizesScreenState extends State<SizesScreen> {
  String? _selectedTopSize;
  String? _selectedBottomSize;
  String? _selectedDressSize;
  String? _selectedJeanWaist;
  String? _selectedBraBand;
  String? _selectedBraCup;
  String? _selectedShoeSize;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      // Load saved sizes from OnboardingDataManager
      final manager = context.read<OnboardingDataManager>();
      if (manager.topSize != null) {
        _selectedTopSize = manager.topSize;
      }
      if (manager.bottomSize != null) {
        _selectedBottomSize = manager.bottomSize;
      }
      if (manager.dressSize != null) {
        _selectedDressSize = manager.dressSize;
      }
      if (manager.jeanWaistSize != null) {
        _selectedJeanWaist = manager.jeanWaistSize;
      }
      if (manager.braBandSize != null) {
        _selectedBraBand = manager.braBandSize;
      }
      if (manager.braCupSize != null) {
        _selectedBraCup = manager.braCupSize;
      }
      if (manager.shoeSize != null) {
        _selectedShoeSize = manager.shoeSize;
      }

      // Trigger UI update if data was loaded
      if (_selectedTopSize != null || _selectedBottomSize != null) {
        setState(() {});
      }
    }
  }

  final List<String> _topSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];
  final List<String> _bottomSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];
  final List<String> _dressSizes = [
    'XXS',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];
  final List<String> _jeanWaists = [
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '36',
    '38',
    '40',
  ];
  final List<String> _braBands = [
    '30',
    '32',
    '34',
    '36',
    '38',
    '40',
    '42',
    '44',
    '46',
  ];
  final List<String> _braCups = [
    'A',
    'B',
    'C',
    'D',
    'DD',
    'DDD',
    'E',
    'F',
    'G',
    'H',
  ];
  final List<String> _shoeSizes = [
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
  ];

  Future<void> _continue() async {
    // Validate at least some sizes are selected
    if (_selectedTopSize == null &&
        _selectedBottomSize == null &&
        _selectedDressSize == null) {
      SnackBarHelper.showError(context, 'Please select at least one size');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save clothing sizes to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setClothingSizes(
        topSize: _selectedTopSize,
        bottomSize: _selectedBottomSize,
        dressSize: _selectedDressSize,
        jeanWaistSize: _selectedJeanWaist,
        braBandSize: _selectedBraBand,
        braCupSize: _selectedBraCup,
        shoeSize: _selectedShoeSize,
        braType: null, // Not collected in this screen
        braSupportLevel: null, // Not collected in this screen
      );

      if (!mounted) return;

      // Navigate to style quiz screen with user data
      final gender = manager.gender ?? 'female';
      final hijabPref = manager.hijabPreference ?? 'uncovered';

      Navigator.of(context).pushNamed(
        '/style-quiz',
        arguments: {'gender': gender, 'hijabPreference': hijabPref},
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      SnackBarHelper.showError(context, l10n.saveInfoError);
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
                    const OnboardingProgressBar(currentStep: 6, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.whatSizesTypicallyWear,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.helpsShowPerfectlyFittedItems,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tops
                    Text(
                      l10n.tops,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SizeSelector(
                      sizes: _topSizes,
                      selectedSize: _selectedTopSize,
                      onSelected: (size) {
                        setState(() {
                          _selectedTopSize = size;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bottoms
                    Text(
                      l10n.bottoms,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SizeSelector(
                      sizes: _bottomSizes,
                      selectedSize: _selectedBottomSize,
                      onSelected: (size) {
                        setState(() {
                          _selectedBottomSize = size;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dresses
                    Text(
                      l10n.dresses,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SizeSelector(
                      sizes: _dressSizes,
                      selectedSize: _selectedDressSize,
                      onSelected: (size) {
                        setState(() {
                          _selectedDressSize = size;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Jean Waist
                    Text(
                      l10n.jeanWaist,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SizeSelector(
                      sizes: _jeanWaists,
                      selectedSize: _selectedJeanWaist,
                      onSelected: (size) {
                        setState(() {
                          _selectedJeanWaist = size;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bra
                    Text(
                      l10n.bra,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Band
                    Text(
                      l10n.band,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SizeSelector(
                      sizes: _braBands,
                      selectedSize: _selectedBraBand,
                      onSelected: (size) {
                        setState(() {
                          _selectedBraBand = size;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Cup
                    Text(
                      l10n.cup,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SizeSelector(
                      sizes: _braCups,
                      selectedSize: _selectedBraCup,
                      onSelected: (size) {
                        setState(() {
                          _selectedBraCup = size;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Shoes
                    Text(
                      l10n.shoes,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SizeSelector(
                      sizes: _shoeSizes,
                      selectedSize: _selectedShoeSize,
                      onSelected: (size) {
                        setState(() {
                          _selectedShoeSize = size;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

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
                        onPressed:
                            (_selectedTopSize == null ||
                                _selectedBottomSize == null ||
                                _selectedShoeSize == null ||
                                _isLoading)
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

/// Size Selector Widget
class _SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final Function(String) onSelected;

  const _SizeSelector({
    required this.sizes,
    required this.selectedSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final verticalPadding = isTablet ? 16.0 : 12.0;
    final fontSize = isTablet ? 16.0 : 14.0;

    return Wrap(
      spacing: isTablet ? 12 : 8,
      runSpacing: isTablet ? 12 : 8,
      children: sizes.map((size) {
        final isSelected = selectedSize == size;
        return GestureDetector(
          onTap: () => onSelected(size),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : AppColors.white,
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.gray300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              size,
              style: AppTypography.body2.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
