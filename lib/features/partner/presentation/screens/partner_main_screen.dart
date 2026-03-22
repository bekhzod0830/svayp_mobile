import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/partner/presentation/screens/partner_cashback_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';

/// Partner Main Screen
/// Bottom navigation for partners (sellers, admins, managers, etc.)
/// Shows: Cashback | Orders | Profile
/// Hides the consumer tabs: Discover, Liked, Shop, Cart.
class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final token = getIt<ApiClient>().getToken();
    if (token == null) return;
    getIt<ChatWebSocketService>().connect(token);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    getIt<ChatWebSocketService>().disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      getIt<ChatWebSocketService>().disconnect();
    } else if (state == AppLifecycleState.resumed) {
      _connectWebSocket();
    }
  }

  static const int _tabCount = 4;

  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  /// Safe index that never exceeds the tab count (guards against hot-reload
  /// stale state when the number of tabs changed).
  int get _safeIndex => _currentIndex.clamp(0, _tabCount - 1);

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  Widget _buildTab(int index, Widget child) {
    final isActive = _safeIndex == index;
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: IgnorePointer(ignoring: !isActive, child: child),
    );
  }

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
        body: Stack(
          children: [
            // 0 – Cashback
            _buildTab(
              0,
              Navigator(
                key: _navKeys[0],
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => const PartnerCashbackScreen(),
                ),
              ),
            ),

            // 1 – Orders
            _buildTab(
              1,
              Navigator(
                key: _navKeys[1],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
            ),

            // 2 – Chat
            _buildTab(
              2,
              Navigator(
                key: _navKeys[2],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
              ),
            ),

            // 3 – Profile
            _buildTab(
              3,
              Navigator(
                key: _navKeys[3],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
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
                icon: const Icon(Icons.receipt_long_outlined),
                activeIcon: const Icon(Icons.receipt_long),
                label: l10n.orders,
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
        ), // Theme
      ),
    );
  }
}
