import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/analytics/onboarding_analytics_mixin.dart';

/// Section Intent Screen — shown right after the onboarding completion
/// ("You're All Set!") screen. Asks the new user where they want to start and
/// routes them straight to the matching main-app tab.
///
/// Tab indices mirror MainScreen's nav order:
///   0 = Feed · 1 = Closet · 2 = Market · 3 = Shop · 5 = Discover (LIBΛS swipes)
class SectionIntentScreen extends StatefulWidget {
  const SectionIntentScreen({super.key});

  @override
  State<SectionIntentScreen> createState() => _SectionIntentScreenState();
}

class _SectionIntentScreenState extends State<SectionIntentScreen>
    with SingleTickerProviderStateMixin, OnboardingAnalyticsMixin {
  @override
  String get viewedEvent => AnalyticsEvents.onboardingIntentViewed;
  @override
  String get completedEvent => AnalyticsEvents.onboardingIntentSelected;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    trackStepViewed();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Navigate to the chosen main-app tab, clearing the onboarding stack.
  void _selectSection(int tabIndex, String tabName) {
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.onboardingIntentSelected,
      parameters: {AnalyticsEvents.paramTabName: tabName},
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'initialIndex': tabIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <_SectionOption>[
      _SectionOption(
        icon: Icons.swipe_outlined,
        title: l10n.intentDiscoverTitle,
        subtitle: l10n.intentDiscoverSubtitle,
        tabIndex: 5,
        tabName: 'discover',
      ),
      _SectionOption(
        icon: Icons.shopping_bag_outlined,
        title: l10n.shop,
        subtitle: l10n.intentShopSubtitle,
        tabIndex: 3,
        tabName: 'shop',
      ),
      _SectionOption(
        icon: Icons.storefront_outlined,
        title: l10n.market,
        subtitle: l10n.intentMarketSubtitle,
        tabIndex: 2,
        tabName: 'market',
      ),
      _SectionOption(
        icon: Icons.checkroom_outlined,
        title: l10n.closet,
        subtitle: l10n.intentClosetSubtitle,
        tabIndex: 1,
        tabName: 'closet',
      ),
      _SectionOption(
        icon: Icons.dynamic_feed_outlined,
        title: l10n.feed,
        subtitle: l10n.intentFeedSubtitle,
        tabIndex: 0,
        tabName: 'feed',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.intentTitle,
                      style: AppTypography.display2.copyWith(
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.intentSubtitle,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final o = options[i];
                    return _SectionCard(
                      option: o,
                      onTap: () => _selectSection(o.tabIndex, o.tabName),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final int tabIndex;
  final String tabName;

  const _SectionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tabIndex,
    required this.tabName,
  });
}

class _SectionCard extends StatelessWidget {
  final _SectionOption option;
  final VoidCallback onTap;

  const _SectionCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lightBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(option.icon, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gray400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
