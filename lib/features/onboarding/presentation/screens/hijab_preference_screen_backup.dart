import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Hijab Preference Screen - For female users to select their preference
/// Covered (wearing Hijab) or Uncovered (Traditional)
class HijabPreferenceScreen extends StatefulWidget {
  const HijabPreferenceScreen({super.key});

  @override
  State<HijabPreferenceScreen> createState() => _HijabPreferenceScreenState();
}

class _HijabPreferenceScreenState extends State<HijabPreferenceScreen> {
  String _selectedPreference = '';
  bool _isLoading = false;
  String _gender = 'female';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get user data from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _gender = args['gender'] as String? ?? 'female';
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedPreference.isEmpty) {
      SnackBarHelper.showError(context, l10n.selectPreferenceError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save hijab preference to backend/local storage
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to primary objective screen with gender and hijab preference
      Navigator.of(context).pushNamed(
        '/primary-objective',
        arguments: {'gender': _gender, 'hijabPreference': _selectedPreference},
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        l10n.savePreferenceError,
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
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: 0.4,
                backgroundColor: AppColors.gray200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.black,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 32),

              // Title
              Text(l10n.yourStylePreference, style: AppTypography.heading1),
              const SizedBox(height: 12),
              Text(
                l10n.relevantFashionChoices,
                style: AppTypography.body1.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 40),

              // Preference Options
              _PreferenceCard(
                title: 'Covered',
                subtitle: 'Modest fashion with Hijab',
                icon: Icons.checkroom,
                isSelected: _selectedPreference == 'covered',
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedPreference = 'covered';
                        });
                      },
              ),
              const SizedBox(height: 16),
              _PreferenceCard(
                title: 'Uncovered',
                subtitle: 'Traditional fashion styles',
                icon: Icons.face_retouching_natural,
                isSelected: _selectedPreference == 'uncovered',
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedPreference = 'uncovered';
                        });
                      },
              ),

              const Spacer(),

              // Continue Button
              PrimaryButton(
                text: 'Continue',
                onPressed: _isLoading ? null : _continue,
                isFullWidth: true,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preference Card Widget
class _PreferenceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PreferenceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withOpacity(0.2)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading4.copyWith(
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body2.copyWith(
                      color: isSelected
                          ? AppColors.white.withOpacity(0.8)
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
