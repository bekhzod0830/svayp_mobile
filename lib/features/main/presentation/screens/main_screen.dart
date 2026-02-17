import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/presentation/screens/discover_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_screen.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';

/// Main Screen - Container with bottom navigation
/// Houses all main app features: Discover, Liked, Shop, Orders, Profile
class MainScreen extends StatefulWidget {
  final int initialIndex;

  // Static global key to access MainScreen from anywhere
  static final GlobalKey<MainScreenState> globalKey =
      GlobalKey<MainScreenState>();

  MainScreen({this.initialIndex = 0}) : super(key: globalKey);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  // Global keys for screen access
  final GlobalKey<NavigatorState> _discoverKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _likedKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shopKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _ordersKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();

  // Keys for screens to enable refresh
  final GlobalKey<LikedScreenState> _likedScreenKey =
      GlobalKey<LikedScreenState>();
  final GlobalKey<OrdersScreenState> _ordersScreenKey =
      GlobalKey<OrdersScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh screens when navigating to them
    if (index == 1) {
      // Liked tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _likedScreenKey.currentState?.refresh();
      });
    } else if (index == 3) {
      // Orders tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ordersScreenKey.currentState?.refresh();
      });
    }
  }

  /// Method to navigate to a specific tab from child screens
  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh screens when navigating to them
    if (index == 1) {
      // Liked tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _likedScreenKey.currentState?.refresh();
      });
    } else if (index == 3) {
      // Orders tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ordersScreenKey.currentState?.refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get responsive sizing
    final iconScale = ResponsiveUtils.getIconSizeScale(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

    // Get the current navigator key based on selected tab
    GlobalKey<NavigatorState> getCurrentNavigatorKey() {
      switch (_currentIndex) {
        case 0:
          return _discoverKey;
        case 1:
          return _likedKey;
        case 2:
          return _shopKey;
        case 3:
          return _ordersKey;
        case 4:
          return _profileKey;
        default:
          return _discoverKey;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Try to pop within the current tab's navigator first
        final navigatorKey = getCurrentNavigatorKey();
        final navigatorState = navigatorKey.currentState;

        if (navigatorState != null && navigatorState.canPop()) {
          navigatorState.pop();
        } else if (_currentIndex != 0) {
          // If can't pop and not on first tab, go to first tab (Discover)
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // On first tab with nothing to pop, allow app to exit
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            Navigator(
              key: _discoverKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const DiscoverScreen(),
              ),
            ),
            Navigator(
              key: _likedKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => LikedScreen(key: _likedScreenKey),
              ),
            ),
            Navigator(
              key: _shopKey,
              onGenerateRoute: (settings) =>
                  MaterialPageRoute(builder: (context) => const ShopScreen()),
            ),
            Navigator(
              key: _ordersKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => OrdersScreen(key: _ordersScreenKey),
              ),
            ),
            Navigator(
              key: _profileKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
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
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: l10n.discover,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              activeIcon: const Icon(Icons.favorite),
              label: l10n.liked,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              activeIcon: const Icon(Icons.search),
              label: l10n.shop,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: l10n.orders,
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

/// Helper method to access MainScreen state from anywhere
MainScreenState? findMainScreenState(BuildContext context) {
  return context.findAncestorStateOfType<MainScreenState>();
}
