import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/profile/data/models/profile_models.dart';

/// Profile Information Screen - Displays detailed profile information
class ProfileInformationScreen extends StatelessWidget {
  final UserProfileResponse profile;

  const ProfileInformationScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.profileInformation,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Gender & Hijab Preference Section
            _buildSection(
              context: context,
              title: l10n.personal,
              items: [
                _buildInfoRow(
                  context: context,
                  label: l10n.gender,
                  value: profile.gender.toUpperCase(),
                  icon: Icons.person_outline,
                ),
                if (profile.hijabPreference.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: l10n.hijabPreference,
                    value: profile.hijabPreference.toUpperCase(),
                    icon: Icons.checkroom_outlined,
                  ),
                if (profile.age != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.age,
                    value: '${profile.age} ${l10n.years}',
                    icon: Icons.cake_outlined,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Body Information Section
            _buildSection(
              context: context,
              title: l10n.bodyInformation,
              items: [
                if (profile.heightCm != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.height,
                    value: '${profile.heightCm} cm',
                    icon: Icons.height_outlined,
                  ),
                if (profile.bodyType != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.bodyType,
                    value: profile.bodyType!.toUpperCase(),
                    icon: Icons.accessibility_new_outlined,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Shopping Preferences Section
            _buildSection(
              context: context,
              title: l10n.shoppingPreferences,
              items: [
                if (profile.budgetMin != null || profile.budgetMax != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.budget,
                    value: _formatBudget(
                      context,
                      profile.budgetMin,
                      profile.budgetMax,
                    ),
                    icon: Icons.monetization_on_outlined,
                  ),
                _buildInfoRow(
                  context: context,
                  label: l10n.styleQuiz,
                  value: profile.styleQuizCompleted
                      ? l10n.completed
                      : l10n.notCompleted,
                  icon: Icons.check_circle_outline,
                  valueColor: profile.styleQuizCompleted
                      ? Colors.green
                      : AppColors.gray600,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray800 : AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ??
                        (isDark ? AppColors.darkPrimaryText : AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudget(BuildContext context, int? min, int? max) {
    final l10n = AppLocalizations.of(context)!;
    if (min != null && max != null) {
      return '${min.toString()} - ${max.toString()} UZS';
    } else if (min != null) {
      return '${l10n.from} ${min.toString()} UZS';
    } else if (max != null) {
      return '${l10n.upTo} ${max.toString()} UZS';
    }
    return l10n.notSet;
  }
}
