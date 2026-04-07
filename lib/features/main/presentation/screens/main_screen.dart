import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/physics.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/presentation/screens/discover_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_screen.dart';
import 'package:swipe/features/shop/presentation/utils/visual_search_launcher.dart';
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

class MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late int _currentIndex;
  // Pill position controller — drives the spring simulation in tab-index space
  // (0.0 = first tab … 4.0 = last tab). Wide bounds allow spring overshoot.
  late final AnimationController _pillCtrl;

  // Global keys for screen access
  final GlobalKey<NavigatorState> _discoverKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shopKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _chatKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();
  late final List<_TabNavObserver> _tabObservers;

  // Keys for screens to enable refresh
  final GlobalKey<DiscoverScreenState> _discoverScreenKey =
      GlobalKey<DiscoverScreenState>();
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
    // Gate certain tabs for guest users
    if (index == 2 || index == 3) {
      final storage = await LocalStorageHelper.getInstance();
      if (storage.isGuestMode()) {
        if (mounted) GuestLoginPrompt.show(context);
        return;
      }
    }

    // If tapping the already-active tab, pop its navigator to root (toggle behaviour).
    if (index == _currentIndex) {
      final keys = [_discoverKey, _shopKey, _chatKey, _profileKey];
      _popTabToRoot(keys[index]);
      return;
    }

    // Pop all sub-routes in the tab we are leaving so it resets to root.
    final keys = [_discoverKey, _shopKey, _chatKey, _profileKey];
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

    // Refresh chat list when entering chat tab so new conversations appear
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatListScreenKey.currentState?.refresh();
      });
    }
  }

  /// Method to navigate to a specific tab from child screens
  void navigateToTab(int index) {
    // Pop all routes in the current tab before switching
    final keys = [_discoverKey, _shopKey, _chatKey, _profileKey];
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

    // Refresh chat list when navigating to it so new conversations appear
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatListScreenKey.currentState?.refresh();
      });
    }
  }

  /// Maps tab index (0-3) to visual nav-bar slot (0,1,3,4 — slot 2 is VS).
  double _tabToNavSlot(int tabIndex) =>
      tabIndex < 2 ? tabIndex.toDouble() : (tabIndex + 1).toDouble();

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
          return _shopKey;
        case 2:
          return _chatKey;
        case 3:
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
      child: Builder(
        builder: (context) {
          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Strip bottom padding from MediaQuery before it reaches
                // inner Scaffolds — WE own the bottom inset via the floating
                // navbar. Without this every inner Scaffold adds its own
                // bottom padding and paints scaffoldBackgroundColor there.
                // Only zero out `padding.bottom` (what Scaffold uses for body
                // insets). Keep `viewPadding.bottom` intact — the navbar reads
                // it directly to position itself above the OS gesture zone.
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: MediaQuery.of(context).padding.copyWith(bottom: 0),
                  ),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      Navigator(
                        key: _discoverKey,
                        observers: [_tabObservers[0]],
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) =>
                              DiscoverScreen(key: _discoverScreenKey),
                        ),
                      ),
                      Navigator(
                        key: _shopKey,
                        observers: [_tabObservers[1]],
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) => const ShopScreen(),
                        ),
                        onUnknownRoute: (settings) => MaterialPageRoute(
                          builder: (context) => const ShopScreen(),
                        ),
                      ),
                      Navigator(
                        key: _chatKey,
                        observers: [_tabObservers[2]],
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) =>
                              ChatListScreen(key: _chatListScreenKey),
                        ),
                      ),
                      Navigator(
                        key: _profileKey,
                        observers: [_tabObservers[3]],
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Glass navbar — floating overlay above all screens.
                // Hidden (opacity 0, non-interactive) when a sub-route is
                // active so buttons on sub-screens are never blocked.
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
                      // viewPadding.bottom = home indicator / gesture zone height.
                      // Never less than 16px so we always clear the OS zone.
                      final bottomInset = mq.viewPadding.bottom.clamp(
                        16.0,
                        60.0,
                      );
                      // Full-width gradient + blur background that extends
                      // from the pill all the way to the screen bottom edge.
                      return Padding(
                        padding: EdgeInsets.only(
                          left: 28,
                          right: 28,
                          bottom: bottomInset,
                          top: 8,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xD0050508)
                                  : const Color(0xBBFFFFFF),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x22FFFFFF)
                                    : const Color(0x55FFFFFF),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.65)
                                      : Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (ctx, bc) {
                                final itemW = bc.maxWidth / 5;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // ── Sliding glass indicator ──────
                                    AnimatedBuilder(
                                      animation: _pillCtrl,
                                      builder: (ctx, child) {
                                        return Positioned(
                                          left: _pillCtrl.value * itemW + 4.0,
                                          width: itemW - 8.0,
                                          top: 7,
                                          bottom: 7,
                                          child: child!,
                                        );
                                      },
                                      // No nested BackdropFilter here — the outer
                                      // nav bar already provides sigma=10 blur.
                                      // A nested blur forces the GPU to re-sample
                                      // the full backdrop every animation frame,
                                      // which drops frames when the discover screen
                                      // (3× sigma=20 BackdropFilters) is active.
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [
                                                    const Color(0x44FFFFFF),
                                                    const Color(0x1AFFFFFF),
                                                  ]
                                                : [
                                                    const Color(0x3D000000),
                                                    const Color(0x22000000),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x66FFFFFF),
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // ── Nav item row ─────────────────
                                    Row(
                                      children: [
                                        _buildGlassNavItem(
                                          context: context,
                                          index: 0,
                                          inactiveIcon: Icons.explore_outlined,
                                          activeIcon: Icons.explore,
                                          label: 'SV\u039bYP',
                                          isDark: isDark,
                                          iconScale: iconScale,
                                          fontScale: fontScale,
                                        ),
                                        _buildGlassNavItem(
                                          context: context,
                                          index: 1,
                                          inactiveIcon: Icons.search,
                                          activeIcon: Icons.search,
                                          label: l10n.shop,
                                          isDark: isDark,
                                          iconScale: iconScale,
                                          fontScale: fontScale,
                                        ),
                                        // Visual Search — center action button (not a tab)
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                launchVisualSearch(context),
                                            behavior: HitTestBehavior.opaque,
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const _VisualSearchNavButton(),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      l10n.visualSearch,
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 9.5 * fontScale,
                                                        fontWeight: FontWeight.w400,
                                                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        _buildGlassNavItem(
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
                                        _buildGlassNavItem(
                                          context: context,
                                          index: 3,
                                          inactiveIcon: Icons.person_outline,
                                          activeIcon: Icons.person,
                                          label: l10n.profile,
                                          isDark: isDark,
                                          iconScale: iconScale,
                                          fontScale: fontScale,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a single Liquid Glass nav item.
  Widget _buildGlassNavItem({
    required BuildContext context,
    required int index,
    required IconData inactiveIcon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    required double iconScale,
    required double fontScale,
    int? badge,
  }) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? Colors.white : Colors.black;

    // Scale up slightly when active for a tactile "press" feel
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

    // Fade the whole icon (+ optional badge) between active and inactive
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
