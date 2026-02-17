import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/features/onboarding/data/onboarding_data_manager.dart';

/// Avoided Colors Screen - Let users select colors they want to avoid
class AvoidedColorsScreen extends StatefulWidget {
  const AvoidedColorsScreen({super.key});

  @override
  State<AvoidedColorsScreen> createState() => _AvoidedColorsScreenState();
}

class _AvoidedColorsScreenState extends State<AvoidedColorsScreen> {
  final Set<String> _avoidedColors = {};
  bool _isLoading = false;

  // Get color options with backend-compatible values and localized names
  List<Map<String, dynamic>> _getColors(AppLocalizations l10n) {
    return [
      {'id': 'red', 'name': l10n.colorReds, 'color': const Color(0xFFE53935)},
      {'id': 'pink', 'name': l10n.colorPinks, 'color': const Color(0xFFEC407A)},
      {
        'id': 'orange',
        'name': l10n.colorOranges,
        'color': const Color(0xFFFF7043),
      },
      {
        'id': 'yellow',
        'name': l10n.colorYellows,
        'color': const Color(0xFFFFEB3B),
      },
      {
        'id': 'green',
        'name': l10n.colorGreens,
        'color': const Color(0xFF66BB6A),
      },
      {'id': 'blue', 'name': l10n.colorBlues, 'color': const Color(0xFF42A5F5)},
      {
        'id': 'purple',
        'name': l10n.colorPurples,
        'color': const Color(0xFF9C27B0),
      },
      {
        'id': 'brown',
        'name': l10n.colorBrowns,
        'color': const Color(0xFF8D6E63),
      },
      {
        'id': 'beige',
        'name': l10n.colorBeiges,
        'color': const Color(0xFFD7CCC8),
      },
      {'id': 'gray', 'name': l10n.colorGrays, 'color': const Color(0xFF9E9E9E)},
      {
        'id': 'white',
        'name': l10n.colorWhites,
        'color': const Color(0xFFFAFAFA),
      },
      {
        'id': 'black',
        'name': l10n.colorBlacks,
        'color': const Color(0xFF212121),
      },
    ];
  }

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save avoided colors to onboarding manager
      final manager = context.read<OnboardingDataManager>();
      manager.setAvoidedColors(_avoidedColors.toList());

      if (!mounted) return;

      // Skip avoided-prints screen and navigate directly to budget-by-items
      Navigator.of(context).pushNamed('/budget-by-items');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleColor(String color) {
    setState(() {
      if (_avoidedColors.contains(color)) {
        _avoidedColors.remove(color);
      } else {
        _avoidedColors.add(color);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _getColors(l10n);

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
                    const OnboardingProgressBar(currentStep: 9, totalSteps: 10),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.whichColorsAvoid,
                      style: AppTypography.display2.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      l10n.selectColorsAvoid,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Colors Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        final colorItem = colors[index];
                        final colorId = colorItem['id'] as String;
                        final isSelected = _avoidedColors.contains(colorId);

                        return GestureDetector(
                          onTap: () => _toggleColor(colorId),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.black
                                    : AppColors.lightBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorItem['color'],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorId == 'white'
                                          ? AppColors.lightBorder
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color:
                                              colorId == 'white' ||
                                                  colorId == 'yellow' ||
                                                  colorId == 'beige'
                                              ? AppColors.black
                                              : AppColors.white,
                                          size: 28,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  colorItem['name'],
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
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
                                'Continue',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
