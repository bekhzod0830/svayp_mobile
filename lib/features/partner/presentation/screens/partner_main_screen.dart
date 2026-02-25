import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/partner/presentation/screens/partner_cashback_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Partner Main Screen
/// Bottom navigation for partners (sellers, admins, managers, etc.)
/// Shows: Cashback | Orders | Profile
/// Hides the consumer tabs: Discover, Liked, Shop, Cart.
class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen> {
  int _currentIndex = 0;

  static const int _tabCount = 3;

  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  /// Safe index that never exceeds the tab count (guards against hot-reload
  /// stale state when the number of tabs changed).
  int get _safeIndex => _currentIndex.clamp(0, _tabCount - 1);

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconScale = ResponsiveUtils.getIconSizeScale(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKeys[_safeIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_safeIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _safeIndex,
          children: [
            // 0 – Cashback
            Navigator(
              key: _navKeys[0],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const PartnerCashbackScreen(),
              ),
            ),

            // 1 – Orders
            Navigator(
              key: _navKeys[1],
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),

            // 2 – Profile
            Navigator(
              key: _navKeys[2],
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _safeIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark
              ? AppColors.darkCardBackground
              : AppColors.white,
          selectedItemColor: isDark
              ? AppColors.darkPrimaryText
              : AppColors.black,
          unselectedItemColor: isDark
              ? AppColors.darkSecondaryText
              : AppColors.gray600,
          selectedFontSize: 12 * fontScale,
          unselectedFontSize: 11 * fontScale,
          iconSize: 24 * iconScale,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.qr_code_scanner_outlined),
              activeIcon: const Icon(Icons.qr_code_scanner),
              label: l10n.partnerCashbackTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: l10n.chat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
