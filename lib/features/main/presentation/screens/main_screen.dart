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
import 'package:swipe/features/shop/presentation/screens/shop_screen.dart';
import 'package:swipe/features/chat/presentation/open_chat_list.dart';

/// Main Screen - Container with bottom navigation
/// Houses all main app features: Discover, Liked, Shop, Orders, Profile
class MainScreen extends StatefulWidget {
  final int initialIndex;

  // Static global key to access MainScreen from anywhere
  static final GlobalKey<MainScreenState> globalKey =
      GlobalKey<MainScreenState>();

  /// Tab names in IndexedStack order — the canonical mapping for push payloads
  /// and deep links (`tab: "closet"`, or the index as a string). The index is
  /// exactly the value [MainScreenState.navigateToTab] takes, so this list must
  /// stay in IndexedStack order; append new tabs, never reorder.
  ///
  /// 'shop' and 'chat' no longer own a bar slot but keep their indices:
  /// navigateToTab sends 'shop' to the Shop page inside Discover and 'chat' to
  /// the chat list pushed on the root navigator.
  static const List<String> tabNames = [
    'feed', // 0 — Lenta
    'closet', // 1 — Garderob (home tab)
    'market', // 2 — Bozor
    'shop', // 3 — Do'kon, opens inside Discover
    'chat', // 4 — Suhbat, opens as a pushed screen
    'discover', // 5 — LIBΛS
    'nur', // 6 — AI Stylist
  ];

  MainScreen({this.initialIndex = 1}) : super(key: globalKey);

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
  final GlobalKey<NavigatorState> _nurKey = GlobalKey<NavigatorState>();
  late final List<_TabNavObserver> _tabObservers;

  // WebView controllers for the web-backed tabs (0=Feed, 1=Closet, 2=Market,
  // 6=Nur), captured on creation so the root PopScope can walk the web page's
  // own history on Android back before falling back to tab-switch / app-exit.
  final Map<int, WebViewController> _webControllers = {};

  /// The Nur WebView is built on first visit, not up front like the other
  /// tabs: a fourth live WebView would cost cold-start time for everyone,
  /// including users who never open the stylist.
  bool _nurBuilt = false;

  // Keys for screens to enable refresh
  // Immediate-increment listener so the badge updates even before
  // ChatListScreen has finished loading its chats and set up _syncBadge.
  StreamSubscription<({String chatId, ChatMessageResponse message})>?
  _badgeListSub;

  /// Вкладки-вебвью: страница внутри присылает собственный screen_view,
  /// поэтому здесь экран проставляется молча. Остальные нативные, и кроме нас
  /// их просмотр зафиксировать некому.
  static const Set<int> _webViewTabs = {0, 1, 2, 6};

  /// Проставляет экран текущей вкладки, чтобы события несли верный контекст.
  void _applyTabScreen(int index) {
    if (index < 0 || index >= MainScreen.tabNames.length) {
      return;
    }
    final screen = '/tab/${MainScreen.tabNames[index]}';
    if (_webViewTabs.contains(index)) {
      AnalyticsService.instance.setScreenSilent(screen);
    } else {
      AnalyticsService.instance.setScreen(screen);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _nurBuilt = _currentIndex == _nurTabIndex;
    // Стартовая вкладка тоже должна попасть в аналитику: раньше первый экран
    // после входа не фиксировался вовсе, и события уходили с предыдущим экраном.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyTabScreen(_currentIndex);
    });
    _pillCtrl = AnimationController(
      vsync: this,
      lowerBound: -0.6,
      upperBound: 4.6,
      value: _tabToNavSlot(_currentIndex),
    );
    _tabObservers = List.generate(
      MainScreen.tabNames.length,
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
    // Chat is no longer a tab, so there is no "chat tab is active" case to
    // skip: a pushed ChatListScreen, when present, reconciles the count.
    final wsService = getIt<ChatWebSocketService>();
    _badgeListSub = wsService.listMessageStream.listen((event) {
      wsService.unreadCountNotifier.value += 1;
    });
    _initBadge();
    // Now that the app has reached its landing screen, surface any cold-start
    // notification (tapped while terminated) that was deferred during startup.
    // Done after the first frame so the navigator has settled on /main and the
    // popup/deep-link lands here instead of on the to-be-replaced splash route.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationService.instance.flushPendingInitialNotification(),
    );
  }

  void _connectWebSocket() {
    final token = getIt<ApiClient>().getToken();
    if (token == null) return;
    getIt<ChatWebSocketService>().connect(token);
  }

  /// Last badge init — dampens resume flapping (rapid pause/resume cycles)
  /// without breaking the post-pause resync: STOMP does not replay messages
  /// missed while paused, so the REST reseed must still run on a real return.
  DateTime? _lastBadgeInitAt;

  Future<void> _initBadge() async {
    final last = _lastBadgeInitAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 15)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;
    _lastBadgeInitAt = DateTime.now();

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
    // Gate the account-bound tabs for guest users: the closet, the feed and
    // Nur all need an authenticated web session.
    if (index == _closetTabIndex ||
        index == _feedTabIndex ||
        index == _nurTabIndex) {
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

    final tabName = MainScreen.tabNames[index < MainScreen.tabNames.length ? index : 0];
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.tabSelected,
      parameters: {AnalyticsEvents.paramTabName: tabName},
    );
    _applyTabScreen(index);
    _switchTo(index);
  }

  /// Method to navigate to a specific tab from child screens.
  ///
  /// Shop (3) and Chat (4) left the bottom bar; their indices keep working for
  /// notification payloads and legacy callers by routing to the new homes.
  void navigateToTab(int index) {
    if (index == _shopTabIndex) {
      openShop();
      return;
    }
    if (index == _chatTabIndex) {
      openChatList(context);
      return;
    }
    if (!_visibleTabs.contains(index)) return;

    // Pop all routes in the current tab before switching
    _popTabToRoot(_tabKeys[_currentIndex]);
    _switchTo(index);
  }

  /// Shows tab [index] and springs the indicator pill under its slot.
  void _switchTo(int index) {
    final fromPos = _pillCtrl.value;
    setState(() {
      if (index == _nurTabIndex) _nurBuilt = true;
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

  /// Shop lives behind the search icon in the LIBΛS header now: switch to
  /// Discover, then push ShopScreen inside its nested navigator after the
  /// frame so the push lands in the visible IndexedStack child.
  void openShop() {
    navigateToTab(_discoverTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _discoverKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ShopScreen()),
      );
    });
  }

  /// Switch to the Closet tab and point its WebView at [path] — a web-app path
  /// such as `/closet?tab=outfits`.
  ///
  /// Used by native screens that finish on something the closet owns (the
  /// try-on sheet's "My outfits"). The load is a plain same-origin navigation,
  /// so the tokens the WebView stored on its first load still apply — no need
  /// to re-append auth params.
  Future<void> openClosetPath(String path) async {
    // The closet tab may be sitting on a pushed sub-route; land on its root
    // WebView, not on top of whatever was open.
    _popTabToRoot(_closetKey);
    navigateToTab(_closetTabIndex);

    // Absent only if the tab has never been built. The IndexedStack builds all
    // tabs up front, so this is a defensive branch: the WebView will come up on
    // the closet root by itself.
    final controller = _webControllers[_closetTabIndex];
    if (controller == null) return;
    await controller.loadRequest(Uri.parse(WebUrls.resolve(path)));
  }

  /// Ordered navigator keys, one per IndexedStack child (index = child index):
  /// 0=Feed, 1=Closet, 2=Market, 3=Shop (placeholder), 4=Chat (placeholder),
  /// 5=LIBΛS, 6=Nur.
  List<GlobalKey<NavigatorState>> get _tabKeys => [
        _feedKey,
        _closetKey,
        _marketKey,
        _shopKey,
        _chatKey,
        _discoverKey,
        _nurKey,
      ];

  /// Tab indices shown in the bottom nav bar, in visual left-to-right order:
  /// Garderob · Lenta · Suhbat (Nur) · Bozor · LIBΛS. The Nth entry occupies
  /// visual slot N. Shop (3) and Chat (4) are not in the bar — see
  /// [navigateToTab].
  static const List<int> _visibleTabs = [1, 0, 6, 2, 5];

  /// Home tab — the first visible tab. Android back from any other tab returns
  /// here; back from here backgrounds the app.
  static const int _homeTabIndex = 1;

  /// Maps a tab index to its visual nav-bar slot (0-based, left to right).
  /// Returns -1 for tabs without a slot, which never drive the pill.
  double _tabToNavSlot(int tabIndex) =>
      _visibleTabs.indexOf(tabIndex).toDouble();

  /// Tab index of the Feed (Лента).
  static const int _feedTabIndex = 0;

  /// Tab index of the Closet (Гардероб).
  static const int _closetTabIndex = 1;

  /// Tab index of the Market (Bozor).
  static const int _marketTabIndex = 2;

  /// Tab index of the Shop — no bar slot; opens inside Discover.
  static const int _shopTabIndex = 3;

  /// Tab index of the Chat — no bar slot; opens as a pushed screen.
  static const int _chatTabIndex = 4;

  /// Tab index of the Discover (LIBΛS) feed.
  static const int _discoverTabIndex = 5;

  /// Tab index of Nur, the AI stylist (center slot).
  static const int _nurTabIndex = 6;

  /// Shows the swipe tutorial as a full screen the first time the user opens
  /// the Discover tab. The tutorial persists a "seen" flag so it only appears
  /// once. Shown here — rather than from DiscoverScreen.initState — so it
  /// appears when the user actually navigates to Discover, not while the tab is
  /// still built off-screen inside the IndexedStack (which previously made it
  /// pop up over the closet tab on first launch).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconScale = ResponsiveUtils.getIconSizeScale(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get the current navigator key based on selected tab
    GlobalKey<NavigatorState> getCurrentNavigatorKey() {
      if (_currentIndex < 0 || _currentIndex >= _tabKeys.length) {
        return _closetKey;
      }
      return _tabKeys[_currentIndex];
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
        if (currentIndex != _homeTabIndex) {
          // Not on the home (Closet) tab → go home, mirroring Android convention.
          final fromPos = _pillCtrl.value;
          setState(() {
            _currentIndex = _homeTabIndex;
          });
          _pillCtrl.animateWith(
            SpringSimulation(
              const SpringDescription(
                mass: 1.0,
                stiffness: 200.0,
                damping: 22.0,
              ),
              fromPos,
              _tabToNavSlot(_homeTabIndex),
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
                // Tab 3: Shop — no longer a tab. The placeholder keeps
                // IndexedStack index == tab index; ShopScreen is pushed inside
                // the Discover navigator instead (see openShop).
                const SizedBox.shrink(),
                // Tab 4: Chat — no longer a tab. ChatListScreen is pushed on the
                // root navigator from the header icon (see openChatList).
                const SizedBox.shrink(),
                // Tab 5: Discover (native)
                Navigator(
                  key: _discoverKey,
                  observers: [_tabObservers[5]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => const DiscoverScreen(),
                  ),
                ),
                // Tab 6: Nur — AI stylist (WebView), built on first visit.
                if (_nurBuilt)
                  Navigator(
                    key: _nurKey,
                    observers: [_tabObservers[6]],
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) {
                        final mq = MediaQuery.of(context);
                        final bottomInset =
                            mq.viewPadding.bottom.clamp(16.0, 60.0);
                        return WebViewScreen(
                          url: WebUrls.stylist,
                          bottomPadding: 60.0 + bottomInset,
                          onControllerCreated: (c) => _webControllers[6] = c,
                        );
                      },
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            // ── Floating bottom navbar ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
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
                          final itemW = bc.maxWidth / _visibleTabs.length;
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
                              // Order mirrors [_visibleTabs]:
                              // Garderob · Lenta · Suhbat · Bozor · LIBΛS.
                              Row(
                                children: [
                                  _buildNavItem(
                                    context: context,
                                    index: _closetTabIndex,
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
                                    index: _feedTabIndex,
                                    inactiveIcon:
                                        Icons.grid_view_outlined,
                                    activeIcon: Icons.grid_view_rounded,
                                    label: l10n.feed,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  // Nur. Voice bars rather than a speech
                                  // bubble: the tab is a stylist you talk to,
                                  // and nothing here can be mistaken for the
                                  // header paper plane, which is seller chat.
                                  _buildNavItem(
                                    context: context,
                                    index: _nurTabIndex,
                                    inactiveIcon: Icons.graphic_eq,
                                    activeIcon: Icons.graphic_eq,
                                    label: l10n.aiStylist,
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                  ),
                                  _buildNavItem(
                                    context: context,
                                    index: _marketTabIndex,
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
                                    index: _discoverTabIndex,
                                    inactiveIcon:
                                        Icons.explore_outlined,
                                    activeIcon: Icons.explore,
                                    label: 'LIB\u039bS',
                                    isDark: isDark,
                                    iconScale: iconScale,
                                    fontScale: fontScale,
                                    labelWidget: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 9.5 * fontScale,
                                          fontWeight:
                                              _currentIndex == _discoverTabIndex
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
                                    ),
                                  ),
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
    Widget? labelWidget,
  }) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? Colors.white : Colors.black;

    final Widget iconWidget = AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: isActive ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Icon(
          isActive ? activeIcon : inactiveIcon,
          size: 24 * iconScale,
          color: activeColor,
        ),
      ),
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            // 6, not 10: "AI Stylist" / "AI-стилист" is the widest label in the
            // bar and needs the room. Anything still too wide for a slot shrinks
            // via the FittedBox below rather than ellipsizing into "AI Sty…".
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: labelWidget,
                    ),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                      ),
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
