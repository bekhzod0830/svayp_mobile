import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/presentation/screens/discover_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_screen.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';

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

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _currentIndex;

  // Global keys for screen access
  final GlobalKey<NavigatorState> _discoverKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _likedKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shopKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _chatKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();

  // Keys for screens to enable refresh
  final GlobalKey<DiscoverScreenState> _discoverScreenKey =
      GlobalKey<DiscoverScreenState>();
  final GlobalKey<LikedScreenState> _likedScreenKey =
      GlobalKey<LikedScreenState>();
  final GlobalKey<ChatListScreenState> _chatListScreenKey =
      GlobalKey<ChatListScreenState>();

  // Immediate-increment listener so the badge updates even before
  // ChatListScreen has finished loading its chats and set up _syncBadge.
  StreamSubscription<({String chatId, ChatMessageResponse message})>?
  _badgeListSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _connectWebSocket();
    // Register badge listener SYNCHRONOUSLY before any await so it is always
    // the first listener on the broadcast stream. This guarantees it fires
    // before ChatListScreen._listMessageSub, so _syncBadge() always runs after
    // and corrects the value to the accurate sum — preventing double-counting.
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

    // Set initial unread count from REST
    try {
      final count = await chatService.getUnreadCount();
      wsService.unreadCountNotifier.value = count;
    } catch (_) {}

    // Subscribe to all chat rooms via STOMP so list messages can arrive
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

  /// Pop all sub-routes in a tab navigator back to its root screen.
  void _popTabToRoot(GlobalKey<NavigatorState> tabKey) {
    final nav = tabKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  void _onTabTapped(int index) async {
    // Gate certain tabs for guest users
    if (index == 1 || index == 3 || index == 4) {
      final storage = await LocalStorageHelper.getInstance();
      if (storage.isGuestMode()) {
        if (mounted) GuestLoginPrompt.show(context);
        return;
      }
    }

    // If tapping the already-active tab, pop its navigator to root (toggle behaviour).
    if (index == _currentIndex) {
      final keys = [_discoverKey, _likedKey, _shopKey, _chatKey, _profileKey];
      _popTabToRoot(keys[index]);
      return;
    }

    // Pop all sub-routes in the tab we are leaving so it resets to root.
    final keys = [_discoverKey, _likedKey, _shopKey, _chatKey, _profileKey];
    _popTabToRoot(keys[_currentIndex]);

    setState(() {
      _currentIndex = index;
    });

    // Refresh Liked screen when navigating to it to show newly liked items
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _likedScreenKey.currentState?.refresh();
      });
    }
    // Refresh chat list when entering chat tab so new conversations appear
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatListScreenKey.currentState?.refresh();
      });
    }
  }

  /// Method to navigate to a specific tab from child screens
  void navigateToTab(int index) {
    // Pop all routes in the current tab before switching
    final keys = [_discoverKey, _likedKey, _shopKey, _chatKey, _profileKey];
    _popTabToRoot(keys[_currentIndex]);

    setState(() {
      _currentIndex = index;
    });

    // Refresh Liked screen when navigating to it so newly liked items appear
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _likedScreenKey.currentState?.refresh();
      });
    }
    // Refresh chat list when navigating to it so new conversations appear
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatListScreenKey.currentState?.refresh();
      });
    }
  }

  Widget _buildTab(int index, Widget child) {
    final isActive = _currentIndex == index;
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: IgnorePointer(ignoring: !isActive, child: child),
    );
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
          return _chatKey;
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
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Stack(
              children: [
                _buildTab(
                  0,
                  Navigator(
                    key: _discoverKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) =>
                          DiscoverScreen(key: _discoverScreenKey),
                    ),
                  ),
                ),
                _buildTab(
                  1,
                  Navigator(
                    key: _likedKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) => LikedScreen(key: _likedScreenKey),
                    ),
                  ),
                ),
                _buildTab(
                  2,
                  Navigator(
                    key: _shopKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) => const ShopScreen(),
                    ),
                    onUnknownRoute: (settings) => MaterialPageRoute(
                      builder: (context) => const ShopScreen(),
                    ),
                  ),
                ),
                _buildTab(
                  3,
                  Navigator(
                    key: _chatKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) =>
                          ChatListScreen(key: _chatListScreenKey),
                    ),
                  ),
                ),
                _buildTab(
                  4,
                  Navigator(
                    key: _profileKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: ListenableBuilder(
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
                    // Remove the glitchy ink-splash ripple on nav items
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
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
          );
        },
      ),
    );
  }
}

/// Helper method to access MainScreen state from anywhere
MainScreenState? findMainScreenState(BuildContext context) {
  return context.findAncestorStateOfType<MainScreenState>();
}
