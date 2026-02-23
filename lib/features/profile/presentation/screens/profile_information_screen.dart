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

            // Personal Information Section
            _buildSection(
              context: context,
              title: l10n.personal,
              items: [
                _buildInfoRow(
                  context: context,
                  label: l10n.gender,
                  value: _formatGender(context, profile.gender),
                  icon: Icons.person_outline,
                ),
                if (profile.dateOfBirth != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.dateOfBirth,
                    value: profile.dateOfBirth!,
                    icon: Icons.calendar_today_outlined,
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
                if (profile.weightKg != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.weight,
                    value: '${profile.weightKg} kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                if (profile.bodyType != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.bodyType,
                    value: _translateEnum(context, profile.bodyType!),
                    icon: Icons.accessibility_new_outlined,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Clothing Sizes Section
            if (_hasAnySizeInfo())
              _buildSection(
                context: context,
                title: l10n.clothingSizes,
                items: [
                  if (profile.topSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.topSize,
                      value: profile.topSize!,
                      icon: Icons.checkroom_outlined,
                    ),
                  if (profile.bottomSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.bottomSize,
                      value: _extractSizeNumber(profile.bottomSize!),
                      icon: Icons.accessibility_outlined,
                    ),
                  if (profile.dressSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.dressSize,
                      value: profile.dressSize!,
                      icon: Icons.checkroom,
                    ),
                  if (profile.jeanWaistSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.jeanWaistSize,
                      value: _extractSizeNumber(profile.jeanWaistSize!),
                      icon: Icons.straighten_outlined,
                    ),
                  if (profile.shoeSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.shoeSize,
                      value: _extractSizeNumber(profile.shoeSize!),
                      icon: Icons.directions_walk_outlined,
                    ),
                ],
              ),

            if (_hasAnySizeInfo()) const SizedBox(height: 16),

            // Bra Sizes Section
            if (_hasAnyBraInfo())
              _buildSection(
                context: context,
                title: l10n.braSizes,
                items: [
                  if (profile.braBandSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.braBandSize,
                      value: _extractSizeNumber(profile.braBandSize!),
                      icon: Icons.straighten_outlined,
                    ),
                  if (profile.braCupSize != null)
                    _buildInfoRow(
                      context: context,
                      label: l10n.braCupSize,
                      value: profile.braCupSize!,
                      icon: Icons.text_fields_outlined,
                    ),
                ],
              ),

            if (_hasAnyBraInfo()) const SizedBox(height: 16),

            // Style Preferences Section
            _buildSection(
              context: context,
              title: l10n.stylePreferences,
              items: [
                _buildInfoRow(
                  context: context,
                  label: l10n.hijabPreference,
                  value: _translateEnum(context, profile.hijabPreference),
                  icon: Icons.checkroom_outlined,
                ),
                if (profile.fitPreference != null &&
                    profile.fitPreference!.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: l10n.fitPreference,
                    value: profile.fitPreference!
                        .map((f) => _translateEnum(context, f))
                        .join(', '),
                    icon: Icons.straighten_outlined,
                  ),
                if (profile.styleCategories != null &&
                    profile.styleCategories!.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: l10n.styleCategories,
                    value: profile.styleCategories!
                        .map((s) => _translateEnum(context, s))
                        .join(', '),
                    icon: Icons.style_outlined,
                  ),
                if (profile.stylePreference != null &&
                    profile.stylePreference!.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: l10n.stylePreferenceLabel,
                    value: profile.stylePreference!
                        .map((s) => _translateEnum(context, s))
                        .join(', '),
                    icon: Icons.favorite_border_outlined,
                  ),
                if (profile.budgetType != null)
                  _buildInfoRow(
                    context: context,
                    label: l10n.budgetType,
                    value: _translateEnum(context, profile.budgetType!),
                    icon: Icons.account_balance_wallet_outlined,
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

  /// Format gender value
  String _formatGender(BuildContext context, String gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender.toUpperCase()) {
      case 'FEMALE':
        return l10n.enumFemale;
      case 'MALE':
        return l10n.enumMale;
      default:
        return gender;
    }
  }

  /// Format enum with translation lookup
  String _translateEnum(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;

    // Map enum values to translation keys
    switch (value.toUpperCase()) {
      // Body Types
      case 'HOURGLASS':
        return l10n.enumHourglass;
      case 'TRIANGLE':
        return l10n.enumTriangle;
      case 'RECTANGLE':
        return l10n.enumRectangle;
      case 'OVAL':
        return l10n.enumOval;
      case 'HEART':
        return l10n.enumHeart;
      case 'PREFER_NOT_TO_SAY':
        return l10n.enumPreferNotToSay;

      // Hijab Preference
      case 'COVERED':
        return l10n.enumCovered;
      case 'UNCOVERED':
        return l10n.enumUncovered;
      case 'NOT_APPLICABLE':
        return l10n.enumNotApplicable;

      // Fit Types
      case 'LOOSE':
        return l10n.enumLoose;
      case 'REGULAR':
        return l10n.enumRegular;
      case 'OVERSIZED':
        return l10n.enumOversized;
      case 'SLIM':
        return l10n.enumSlim;
      case 'SUPER_SLIM':
        return l10n.enumSuperSlim;
      case 'FITTED':
        return l10n.enumFitted;

      // Style Preference
      case 'MODERATE':
        return l10n.enumModerate;
      case 'REVEALING':
        return l10n.enumRevealing;

      // Budget Types
      case 'BUDGET':
        return l10n.enumBudget;
      case 'PREMIUM':
        return l10n.enumPremium;
      case 'LUXURY':
        return l10n.enumLuxury;
      case 'FLEXIBLE':
        return l10n.enumFlexible;

      // Style Categories
      case 'CASUAL':
        return l10n.enumCasual;
      case 'FORMAL':
        return l10n.enumFormal;
      case 'BUSINESS':
        return l10n.enumBusiness;
      case 'SPORTY':
        return l10n.enumSporty;
      case 'ELEGANT':
        return l10n.enumElegant;
      case 'BOHEMIAN':
        return l10n.enumBohemian;
      case 'VINTAGE':
        return l10n.enumVintage;
      case 'MODERN':
        return l10n.enumModern;
      case 'MINIMALIST':
        return l10n.enumMinimalist;
      case 'CLASSIC':
        return l10n.enumClassic;
      case 'TRENDY':
        return l10n.enumTrendy;
      case 'MODEST':
        return l10n.enumModest;
      case 'STREETWEAR':
        return l10n.enumStreetwear;
      case 'ROMANTIC':
        return l10n.enumRomantic;
      case 'EDGY':
        return l10n.enumEdgy;
      case 'PREPPY':
        return l10n.enumPreppy;
      case 'ATHLEISURE':
        return l10n.enumAthleisure;
      case 'CHIC':
        return l10n.enumChic;
      case 'GLAMOROUS':
        return l10n.enumGlamorous;
      case 'SEXY':
        return l10n.enumSexy;
      case 'RETRO':
        return l10n.enumRetro;
      case 'GRUNGE':
        return l10n.enumGrunge;
      case 'GOTHIC':
        return l10n.enumGothic;
      case 'HIPPIE':
        return l10n.enumHippie;
      case 'ARTSY':
        return l10n.enumArtsy;
      case 'FEMININE':
        return l10n.enumFeminine;
      case 'MASCULINE':
        return l10n.enumMasculine;
      case 'ANDROGYNOUS':
        return l10n.enumAndrogynous;
      case 'LUXURIOUS':
        return l10n.enumLuxurious;

      default:
        // Fallback to formatted enum
        return value
            .split('_')
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }

  /// Extract just the number from size strings (e.g., "SIZE_24" -> "24", "EU_34" -> "34")
  String _extractSizeNumber(String size) {
    final match = RegExp(r'\d+').firstMatch(size);
    return match?.group(0) ?? size;
  }

  /// Check if profile has any size information
  bool _hasAnySizeInfo() {
    return profile.topSize != null ||
        profile.bottomSize != null ||
        profile.dressSize != null ||
        profile.jeanWaistSize != null ||
        profile.shoeSize != null;
  }

  /// Check if profile has any bra information
  bool _hasAnyBraInfo() {
    return profile.braBandSize != null || profile.braCupSize != null;
  }
}
