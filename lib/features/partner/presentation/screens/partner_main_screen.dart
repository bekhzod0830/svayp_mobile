import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/mirror/presentation/mirror_tab.dart';
import 'package:swipe/features/partner/presentation/screens/partner_cashback_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

/// Partner Main Screen
/// Bottom navigation for partners (sellers, admins, managers, etc.)
/// Shows: Mirror | Cashback | Orders | Chat | Profile
/// Mirror (the in-store Magic Mirror kiosk) is the default landing tab.
/// Hides the consumer tabs: Discover, Liked, Shop, Cart.
class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  StreamSubscription<({String chatId, ChatMessageResponse message})>?
  _badgeListSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectWebSocket();
    // Register badge listener synchronously before any await so it is always
    // the first listener — prevents double-counting (same logic as main_screen).
    final wsService = getIt<ChatWebSocketService>();
    _badgeListSub = wsService.listMessageStream.listen((event) {
      if (_currentIndex != 3) {
        wsService.unreadCountNotifier.value += 1;
      }
    });
    _initBadge();
  }

  void _connectWebSocket() {
    final token = getIt<ApiClient>().getToken();
    if (token == null) return;
    getIt<ChatWebSocketService>().connect(token);
  }

  Future<void> _initBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final wsService = getIt<ChatWebSocketService>();
    final chatService = ChatService(getIt<ApiClient>());

    try {
      final count = await chatService.getUnreadCount();
      wsService.unreadCountNotifier.value = count;
    } catch (_) {}

    try {
      final chats = await chatService.getChats();
      wsService.openList(chats.map((c) => c.id).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _badgeListSub?.cancel();
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
      _initBadge();
    }
  }

  static const int _tabCount = 5;

  /// Киоск «Зеркало» в полноэкранном режиме — нижняя навигация скрыта,
  /// чтобы покупатель у планшета не попал во вкладки продавца.
  bool _mirrorFullscreen = false;

  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  final GlobalKey<ChatListScreenState> _chatListScreenKey =
      GlobalKey<ChatListScreenState>();

  /// Safe index that never exceeds the tab count (guards against hot-reload
  /// stale state when the number of tabs changed).
  int get _safeIndex => _currentIndex.clamp(0, _tabCount - 1);

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    // Refresh chat list so newly created conversations appear immediately
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatListScreenKey.currentState?.refresh();
      });
    }
  }

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
            // 0 – Mirror (Magic Mirror kiosk). No inner Navigator: the kiosk
            // drives its own screen switcher so a session reset can never
            // leave stale routes behind.
            _buildTab(
              0,
              MirrorTab(
                isActive: _safeIndex == 0,
                onFullscreenChanged: (fullscreen) =>
                    setState(() => _mirrorFullscreen = fullscreen),
              ),
            ),

            // 1 – Cashback
            _buildTab(
              1,
              Navigator(
                key: _navKeys[1],
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => const PartnerCashbackScreen(),
                ),
              ),
            ),

            // 2 – Orders
            _buildTab(
              2,
              Navigator(
                key: _navKeys[2],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
            ),

            // 3 – Chat
            _buildTab(
              3,
              Navigator(
                key: _navKeys[3],
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => ChatListScreen(key: _chatListScreenKey),
                ),
              ),
            ),

            // 4 – Profile
            _buildTab(
              4,
              Navigator(
                key: _navKeys[4],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _mirrorFullscreen
            ? null
            : ListenableBuilder(
          listenable: getIt<ChatWebSocketService>().unreadCountNotifier,
          builder: (context, _) {
            final unread =
                getIt<ChatWebSocketService>().unreadCountNotifier.value;
            final chatIcon = unread > 0
                ? Badge(
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.send_outlined),
                  )
                : const Icon(Icons.send_outlined);
            final chatActiveIcon = unread > 0
                ? Badge(
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.send),
                  )
                : const Icon(Icons.send);
            return Theme(
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
                    icon: const Icon(Icons.auto_awesome_outlined),
                    activeIcon: const Icon(Icons.auto_awesome),
                    label: l10n.mirrorTab,
                  ),
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
                    icon: chatIcon,
                    activeIcon: chatActiveIcon,
                    label: l10n.chat,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: l10n.profile,
                  ),
                ],
              ),
            );
          },
        ), // ListenableBuilder
      ),
    );
  }
}
