import 'dart:async';
import 'package:flutter/physics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:swipe/core/constants/web_urls.dart';
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
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/features/discover/presentation/screens/discover_screen.dart';
import 'package:swipe/features/discover/presentation/widgets/swipe_tutorial_overlay.dart';
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
  final GlobalKey<NavigatorState> _feedKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _marketKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shopKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _chatKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _discoverKey = GlobalKey<NavigatorState>();
  late final List<_TabNavObserver> _tabObservers;

  // WebView controllers for the web-backed tabs (0=Feed, 1=Closet, 2=Market),
  // captured on creation so the root PopScope can walk the web page's own history
  // on Android back before falling back to tab-switch / app-exit.
  final Map<int, WebViewController> _webControllers = {};

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
      upperBound: 5.6,
      value: _currentIndex.toDouble(),
    );
    _tabObservers = List.generate(
      6,
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
      if (_currentIndex != _chatTabIndex) {
        wsService.unreadCountNotifier.value += 1;
      }
    });
    _initBadge();
    // Now that the app has reached its landing screen, surface any cold-start
    // notification (tapped while terminated) that was deferred during startup.
    // Done after the first frame so the navigator has settled on /main and the
    // popup/deep-link lands here instead of on the to-be-replaced splash route.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationService.instance.flushPendingInitialNotification(),
    );
    // Cover the case where the app launches straight onto the Discover tab.
    if (_currentIndex == _discoverTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeShowDiscoverTutorial(),
      );
    }
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
    // Gate certain tabs for guest users (closet = 1, chat = 4). Feed (0) is public.
    if (index == _closetTabIndex || index == _chatTabIndex) {
      final storage = await LocalStorageHelper.getInstance();
      if (storage.isGuestMode()) {
        if (mounted) GuestLoginPrompt.show(context);
        return;
      }
    }

    // If tapping the already-active tab, pop its navigator to root (toggle behaviour).
    if (index == _currentIndex) {
      _popTabToRoot(_tabKeys[index]);
      return;
    }

    // Pop all sub-routes in the tab we are leaving so it resets to root.
    _popTabToRoot(_tabKeys[_currentIndex]);

    const tabNames = ['feed', 'closet', 'market', 'shop', 'chat', 'discover'];
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

    if (index == _discoverTabIndex) _maybeShowDiscoverTutorial();
  }

  /// Method to navigate to a specific tab from child screens
  void navigateToTab(int index) {
    // Pop all routes in the current tab before switching
    _popTabToRoot(_tabKeys[_currentIndex]);

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

    if (index == _discoverTabIndex) _maybeShowDiscoverTutorial();
  }

  /// Ordered navigator keys, one per tab (matches the nav-bar order:
  /// Feed, Closet, Market, Shop, Chat, LIBΛS).
  List<GlobalKey<NavigatorState>> get _tabKeys =>
      [_feedKey, _closetKey, _marketKey, _shopKey, _chatKey, _discoverKey];

  /// Each tab now maps 1:1 to its visual nav-bar slot.
  double _tabToNavSlot(int tabIndex) => tabIndex.toDouble();

  /// Tab index of the Closet (Гардероб) — second tab, after Feed.
  static const int _closetTabIndex = 1;

  /// Tab index of the Chat feed.
  static const int _chatTabIndex = 4;

  /// Tab index of the Discover (LIBΛS) feed.
  static const int _discoverTabIndex = 5;

  /// Shows the swipe tutorial as a full screen the first time the user opens
  /// the Discover tab. The tutorial persists a "seen" flag so it only appears
  /// once. Shown here — rather than from DiscoverScreen.initState — so it
  /// appears when the user actually navigates to Discover, not while the tab is
  /// still built off-screen inside the IndexedStack (which previously made it
  /// pop up over the closet tab on first launch).
  Future<void> _maybeShowDiscoverTutorial() async {
    final show = await shouldShowSwipeTutorial();
    if (!mounted || !show) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SwipeTutorialScreen(),
      ),
    );
  }

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
          return _feedKey;
        case 1:
          return _closetKey;
        case 2:
          return _marketKey;
        case 3:
          return _shopKey;
        case 4:
          return _chatKey;
        case 5:
          return _discoverKey;
        default:
          return _closetKey;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final currentIndex = _currentIndex;

        // 1. Pop within the current tab's nested navigator first (pushed routes).
        final navigatorState = getCurrentNavigatorKey().currentState;
        if (navigatorState != null && navigatorState.canPop()) {
          navigatorState.pop();
          return;
        }

        // 2. WebView tabs (Feed/Closet/Market): walk back through the web page's
        //    OWN history. The tab's nested Navigator never receives the Android
        //    system-back event, so WebViewScreen's own PopScope can't do this —
        //    the host drives it here via the captured controller. This is what
        //    makes "back inside Market" return to the previous web page instead
        //    of jumping to another tab or showing a black screen.
        //
        //    The page itself reports whether Back has anywhere to go: the web
        //    app sets __svaypTabRoot on tab-root pages and counts open overlays
        //    in __svaypOverlays (see use-root-back-guard / use-overlay-back-close).
        //    This is authoritative — the native canGoBack() misreports SPA
        //    pushState history on some Android WebViews, which exited the app
        //    from pushed pages like /feed/me or /market/<id>.
        final webController = _webControllers[currentIndex];
        if (webController != null) {
          try {
            final res = await webController.runJavaScriptReturningResult(
              '(function(){var o=window.__svaypOverlays||0;'
              'var r=window.__svaypTabRoot===true;'
              'return (o>0)||(!r&&history.length>1);})()',
            );
            final webWantsBack = res == true || res.toString() == 'true';
            if (webWantsBack) {
              await webController.runJavaScript('history.back()');
              return;
            }
          } catch (_) {
            // Page not ready / JS failed — fall back to the native history API.
            if (await webController.canGoBack()) {
              await webController.goBack();
              return;
            }
          }
        }

        // 3. Nothing left to go back to in this tab.
        if (currentIndex != 0) {
          // Not on the home (Feed) tab → go home, mirroring Android convention.
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
          // On the home tab with nothing to pop → background the app cleanly.
          // (Navigator.pop() here would tear down MainScreen and reveal a bare
          // black Scaffold underneath — the reported "black screen".)
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        // Keep the floating bottom navbar pinned to the bottom when a soft
        // keyboard opens inside a WebView tab (Closet/Market). Without this the
        // Scaffold resizes to the keyboard inset and pushes the navbar up over
        // the page content. The WebView handles scrolling its focused input
        // into view above the keyboard itself.
        resizeToAvoidBottomInset: false,
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                // Tab 0: Feed / Лента (WebView)
                Navigator(
                  key: _feedKey,
                  observers: [_tabObservers[0]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) {
                      final mq = MediaQuery.of(context);
                      final bottomInset =
                          mq.viewPadding.bottom.clamp(16.0, 60.0);
                      return WebViewScreen(
                        url: WebUrls.feed,
                        bottomPadding: 60.0 + bottomInset,
                        onControllerCreated: (c) => _webControllers[0] = c,
                      );
                    },
                  ),
                ),
                // Tab 1: Closet (WebView)
                Navigator(
                  key: _closetKey,
                  observers: [_tabObservers[1]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) {
                      final mq = MediaQuery.of(context);
                      final bottomInset =
                          mq.viewPadding.bottom.clamp(16.0, 60.0);
                      return WebViewScreen(
                        url: WebUrls.closet,
                        bottomPadding: 60.0 + bottomInset,
                        onControllerCreated: (c) => _webControllers[1] = c,
                      );
                    },
                  ),
                ),
                // Tab 2: Market (WebView)
                Navigator(
                  key: _marketKey,
                  observers: [_tabObservers[2]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) {
                      final mq = MediaQuery.of(context);
                      final bottomInset =
                          mq.viewPadding.bottom.clamp(16.0, 60.0);
                      return WebViewScreen(
                        url: WebUrls.market,
                        bottomPadding: 60.0 + bottomInset,
                        onControllerCreated: (c) => _webControllers[2] = c,
                      );
                    },
                  ),
                ),
                // Tab 3: Shop (native)
                Navigator(
                  key: _shopKey,
                  observers: [_tabObservers[3]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const ShopScreen(),
                  ),
                ),
                // Tab 4: Chat (native)
                Navigator(
                  key: _chatKey,
                  observers: [_tabObservers[4]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                ),
                // Tab 5: Discover (native)
                Navigator(
                  key: _discoverKey,
                  observers: [_tabObservers[5]],
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
                          final itemW = bc.maxWidth / 6;
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
                                        Icons.home_outlined,
                                    activeIcon: Icons.home,
                                    label: l10n.feed,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 1,
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
                                    index: 2,
                                    inactiveIcon:
                                        Icons.storefront_outlined,
                                    activeIcon: Icons.storefront,
                                    label: l10n.market,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 3,
                                    inactiveIcon: Icons.search,
                                    activeIcon: Icons.search,
                                    label: l10n.shop,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: 4,
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
                                    index: 5,
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
                                          fontWeight: _currentIndex == _discoverTabIndex
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
