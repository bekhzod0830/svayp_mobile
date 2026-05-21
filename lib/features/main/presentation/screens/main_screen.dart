import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/physics.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/constants/web_urls.dart';
import 'package:swipe/features/shop/presentation/utils/visual_search_launcher.dart';
import 'package:swipe/shared/widgets/web_view_screen.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';

import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/features/discover/presentation/screens/discover_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_screen.dart';
import 'package:swipe/features/chat/presentation/screens/chat_list_screen.dart';

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

class MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late int _currentIndex;
  // Pill position controller — drives the spring simulation in tab-index space
  // (0.0 = first tab … 4.0 = last tab). Wide bounds allow spring overshoot.
  late final AnimationController _pillCtrl;

  // Global keys for screen access
  final GlobalKey<NavigatorState> _closetKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shopKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _chatKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _discoverKey = GlobalKey<NavigatorState>();
  late final List<_TabNavObserver> _tabObservers;

  // Keys for screens to enable refresh
  // Immediate-increment listener so the badge updates even before
  // ChatListScreen has finished loading its chats and set up _syncBadge.
  StreamSubscription<({String chatId, ChatMessageResponse message})>?
  _badgeListSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pillCtrl = AnimationController(
      vsync: this,
      lowerBound: -0.6,
      upperBound: 4.6,
      value: _currentIndex.toDouble(),
    );
    _tabObservers = List.generate(
      4,
      (_) => _TabNavObserver(() {
        if (mounted) setState(() {});
      }),
    );
    WidgetsBinding.instance.addObserver(this);
    _connectWebSocket();
    // Register badge listener SYNCHRONOUSLY before any await so it is always
    // the first listener on the broadcast stream. This guarantees it fires
    // before ChatListScreen._listMessageSub, so _syncBadge() always runs after
    // and corrects the value to the accurate sum — preventing double-counting.
    final wsService = getIt<ChatWebSocketService>();
    _badgeListSub = wsService.listMessageStream.listen((event) {
      if (_currentIndex != 2) {
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

    // Seed the notification bell badge from the API unread count.
    try {
      final api = getIt<ApiClient>();
      final resp = await api.get<dynamic>('/notifications/unread-count');
      final outer = resp.data as Map<String, dynamic>;
      final count =
          (outer['data']?['unread_count'] ?? outer['unread_count'] ?? 0) as int;
      if (count > 0) BadgeNotifier.instance.markUnreadNotifications();
    } catch (_) {}
  }

  @override
  void dispose() {
    _badgeListSub?.cancel();
    _pillCtrl.dispose();
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
    // Gate certain tabs for guest users (chat = 2)
    if (index == 2) {
      final storage = await LocalStorageHelper.getInstance();
      if (storage.isGuestMode()) {
        if (mounted) GuestLoginPrompt.show(context);
        return;
      }
    }

    // If tapping the already-active tab, pop its navigator to root (toggle behaviour).
    if (index == _currentIndex) {
      final keys = [_closetKey, _shopKey, _chatKey, _discoverKey];
      _popTabToRoot(keys[index]);
      return;
    }

    // Pop all sub-routes in the tab we are leaving so it resets to root.
    final keys = [_closetKey, _shopKey, _chatKey, _discoverKey];
    _popTabToRoot(keys[_currentIndex]);

    const tabNames = ['closet', 'shop', 'chat', 'discover'];
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.tabSelected,
      parameters: {AnalyticsEvents.paramTabName: tabNames[index < tabNames.length ? index : 0]},
    );

    final fromPos = _pillCtrl.value;
    setState(() {
      _currentIndex = index;
    });
    _pillCtrl.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 200.0, damping: 22.0),
        fromPos,
        _tabToNavSlot(index),
        0.0,
      ),
    );

  }

  /// Method to navigate to a specific tab from child screens
  void navigateToTab(int index) {
    // Pop all routes in the current tab before switching
    final keys = [_closetKey, _shopKey, _chatKey, _discoverKey];
    _popTabToRoot(keys[_currentIndex]);

    final fromPos = _pillCtrl.value;
    setState(() {
      _currentIndex = index;
    });
    _pillCtrl.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 200.0, damping: 22.0),
        fromPos,
        _tabToNavSlot(index),
        0.0,
      ),
    );

  }

  /// Maps tab index (0-3) to visual nav-bar slot (0,1,3,4 — slot 2 is VS).
  double _tabToNavSlot(int tabIndex) =>
      tabIndex < 2 ? tabIndex.toDouble() : (tabIndex + 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconScale = ResponsiveUtils.getIconSizeScale(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get the current navigator key based on selected tab
    GlobalKey<NavigatorState> getCurrentNavigatorKey() {
      switch (_currentIndex) {
        case 0:
          return _closetKey;
        case 1:
          return _shopKey;
        case 2:
          return _chatKey;
        case 3:
          return _discoverKey;
        default:
          return _closetKey;
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
          // If can't pop and not on first tab, go to first tab
          final fromPos = _pillCtrl.value;
          setState(() {
            _currentIndex = 0;
          });
          _pillCtrl.animateWith(
            SpringSimulation(
              const SpringDescription(
                mass: 1.0,
                stiffness: 200.0,
                damping: 22.0,
              ),
              fromPos,
              0.0,
              0.0,
            ),
          );
        } else {
          // On first tab with nothing to pop, allow app to exit
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                // Tab 0: Closet (WebView)
                Navigator(
                  key: _closetKey,
                  observers: [_tabObservers[0]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) {
                      final mq = MediaQuery.of(context);
                      final bottomInset =
                          mq.viewPadding.bottom.clamp(16.0, 60.0);
                      return WebViewScreen(
                        url: WebUrls.closet,
                        bottomPadding: 60.0 + bottomInset,
                      );
                    },
                  ),
                ),
                // Tab 1: Shop (native)
                Navigator(
                  key: _shopKey,
                  observers: [_tabObservers[1]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const ShopScreen(),
                  ),
                ),
                // Tab 2: Chat (native)
                Navigator(
                  key: _chatKey,
                  observers: [_tabObservers[2]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                ),
                // Tab 3: Discover (native)
                Navigator(
                  key: _discoverKey,
                  observers: [_tabObservers[3]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const DiscoverScreen(),
                  ),
                ),
              ],
            ),
            // ── Floating bottom navbar ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ListenableBuilder(
                listenable:
                    getIt<ChatWebSocketService>().unreadCountNotifier,
                builder: (context, _) {
                  final unread = getIt<ChatWebSocketService>()
                      .unreadCountNotifier
                      .value;
                  final mq = MediaQuery.of(context);
                  final bottomInset =
                      mq.viewPadding.bottom.clamp(16.0, 60.0);

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: bottomInset,
                    ),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xF0101014)
                            : const Color(0xF5FFFFFF),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x18FFFFFF)
                              : const Color(0x12000000),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (ctx, bc) {
                          final itemW = bc.maxWidth / 5;
                          return Stack(
                            children: [
                              // ── Sliding indicator pill ──────
                              AnimatedBuilder(
                                animation: _pillCtrl,
                                builder: (ctx, child) {
                                  return Positioned(
                                    left:
                                        _pillCtrl.value * itemW + 4.0,
                                    width: itemW - 8.0,
                                    top: 7,
                                    bottom: 7,
                                    child: child!,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0x28FFFFFF)
                                        : const Color(0x0F000000),
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                              // ── Nav item row ─────────────────
                              Row(
                                children: [
                                  _buildNavItem(
                                    context: context,
                                    index: 0,
                                    inactiveIcon:
                                        Icons.checkroom_outlined,
                                    activeIcon: Icons.checkroom,
                                    label: l10n.closet,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 1,
                                    inactiveIcon: Icons.search,
                                    activeIcon: Icons.search,
                                    label: l10n.shop,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  // Visual Search — center button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AnalyticsService.instance.logEvent(
                                            AnalyticsEvents
                                                .visualSearchOpened);
                                        launchVisualSearch(context);
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            const _VisualSearchNavButton(),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.visualSearch,
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style: TextStyle(
                                                fontSize:
                                                    9.5 * fontScale,
                                                fontWeight:
                                                    FontWeight.w400,
                                                color: (isDark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withValues(
                                                        alpha: 0.45),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 2,
                                    inactiveIcon: Icons.send_outlined,
                                    activeIcon: Icons.send,
                                    label: l10n.chat,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                    badge: unread > 0 ? unread : null,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 3,
                                    inactiveIcon:
                                        Icons.explore_outlined,
                                    activeIcon: Icons.explore,
                                    label: 'LIB\u039bS',
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,                                    labelWidget: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 9.5 * fontScale,
                                          fontWeight: _currentIndex == 3
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        children: const [
                                          TextSpan(text: 'LIB'),
                                          TextSpan(
                                            text: 'Λ',
                                            style: TextStyle(
                                              color: Color(0xFFF370A7),
                                            ),
                                          ),
                                          TextSpan(text: 'S'),
                                        ],
                                      ),
                                    ),                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single nav item (no glass/blur effect).
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData inactiveIcon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    required double iconScale,
    required double fontScale,
    int? badge,
    Widget? labelWidget,
  }) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? Colors.white : Colors.black;

    Widget scaledIcon = AnimatedScale(
      scale: isActive ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Icon(
        isActive ? activeIcon : inactiveIcon,
        size: 24 * iconScale,
        color: activeColor,
      ),
    );

    Widget iconWidget;
    if (badge != null && badge > 0) {
      iconWidget = Badge(
        backgroundColor: const Color(0xFFFF3B30),
        textColor: Colors.white,
        label: Text(badge > 99 ? '99+' : '$badge'),
        child: scaledIcon,
      );
    } else {
      iconWidget = scaledIcon;
    }

    iconWidget = AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: iconWidget,
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(height: 3),
                if (labelWidget != null)
                  AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: labelWidget,
                  )
                else
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      fontSize: 9.5 * fontScale,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: activeColor.withValues(alpha: isActive ? 1.0 : 0.45),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper method to access MainScreen state from anywhere
MainScreenState? findMainScreenState(BuildContext context) {
  return context.findAncestorStateOfType<MainScreenState>();
}

/// Pulsing gradient circle for the Visual Search center bottom-nav button.
class _VisualSearchNavButton extends StatefulWidget {
  const _VisualSearchNavButton();

  @override
  State<_VisualSearchNavButton> createState() => _VisualSearchNavButtonState();
}

class _VisualSearchNavButtonState extends State<_VisualSearchNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pulse =
            (math.sin(_ctrl.value * math.pi * 2 - math.pi / 2) + 1) / 2;
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(240, 147, 251, 0.30 + pulse * 0.30),
                blurRadius: 8.0 + pulse * 14.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 18,
          ),
        );
      },
    );
  }
}

class _TabNavObserver extends NavigatorObserver {
  final VoidCallback onChanged;
  _TabNavObserver(this.onChanged);

  // Schedule the notification AFTER the current frame so we never call
  // setState() synchronously while a Navigator is mid-build — that causes
  // the "GlobalKey used multiple times in one widget's child list" crash.
  void _schedule() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _schedule();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _schedule();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _schedule();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _schedule();
}
