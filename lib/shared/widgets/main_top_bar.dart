import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/chat/presentation/open_chat_list.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Shared top bar for every main screen — native and web use the SAME shape so
/// the app reads as one product while moving between tabs:
///
///   [back?]  Title (26/w700)                 [screen actions] [app actions]
///
/// Flat: no glass box, no border, no background of its own — it sits on the
/// screen's own colour, exactly like the web headers (Closet / Feed / Market).
/// [extraActions] carry the screen-specific entry points (e.g. Discover's
/// search) and come first; the app-wide icons follow in a fixed order — cart,
/// liked, profile, chat — so chat is always the last icon on every screen.
///
/// Set [isLikedScreen] to true when this bar is rendered on the Liked screen
/// itself so the heart icon shows filled (active) and pressing it is a no-op.
class MainTopBar extends StatefulWidget {
  final String title;
  final bool isLikedScreen;
  final List<Widget> extraActions;
  final Widget? titleChild;

  /// Whether a back button may be shown when this bar sits inside a pushed
  /// route. Root tab screens (Discover, Closet) set this to false: they are
  /// never meant to be popped, and the [Navigator.canPop] heuristic can misfire
  /// on them (e.g. after a locale-driven app rebuild), producing a phantom back
  /// button that crashes the app when tapped.
  final bool showBackButton;

  /// Whether to show the chat (paper-plane) icon. Chat is no longer a bottom
  /// tab, so every main header carries this entry point — except the chat
  /// list itself, which sets this to false.
  final bool showChatButton;

  const MainTopBar({
    super.key,
    required this.title,
    this.isLikedScreen = false,
    this.extraActions = const [],
    this.titleChild,
    this.showBackButton = true,
    this.showChatButton = true,
  });

  /// Title text style — also used by screens that pass a [titleChild] (e.g. the
  /// LIBΛS wordmark) so every header title is the same size and weight.
  static TextStyle titleStyle(bool isDark) => AppTypography.heading2.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black,
      );

  @override
  State<MainTopBar> createState() => _MainTopBarState();
}

class _MainTopBarState extends State<MainTopBar> {
  Future<void> _goToCart() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  Future<void> _goToProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _goToLiked() async {
    if (widget.isLikedScreen) return;
    // Clear immediately on tap — before navigation — so the postframe
    // rebuild triggered by _TabNavObserver doesn't race against the clear.
    BadgeNotifier.instance.clearNewLiked();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LikedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final canPop = widget.showBackButton && Navigator.canPop(context);
    // The partner shell keeps its own Chat tab (and its chat list is a
    // non-poppable tab root), so the header entry point is for shoppers only.
    final showChat =
        widget.showChatButton && !getIt<ApiClient>().isPartnerLogin();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button — shown when this bar is inside a pushed route
          if (canPop)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: iconColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: widget.titleChild ??
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MainTopBar.titleStyle(isDark),
                ),
          ),
          ...widget.extraActions,
          // Cart with its reactive count badge
          ValueListenableBuilder<int>(
            valueListenable: BadgeNotifier.instance.cartCount,
            builder: (context, count, _) => TopBarAction(
              icon: Icons.shopping_bag_outlined,
              color: iconColor,
              onPressed: _goToCart,
              badge: count > 0 ? _CountBadge(count) : null,
            ),
          ),
          // Liked, with a dot while there are new items
          ValueListenableBuilder<bool>(
            valueListenable: BadgeNotifier.instance.hasNewLiked,
            builder: (context, hasNew, _) => TopBarAction(
              icon: widget.isLikedScreen
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: widget.isLikedScreen
                  ? const Color(0xFFFF3B5C)
                  : iconColor,
              onPressed: _goToLiked,
              badge: hasNew && !widget.isLikedScreen ? const _DotBadge() : null,
            ),
          ),
          // Profile (hidden on sub-routes to avoid re-pushing it)
          if (!canPop)
            ValueListenableBuilder<bool>(
              valueListenable: BadgeNotifier.instance.hasUnreadNotifications,
              builder: (context, hasUnread, _) => TopBarAction(
                icon: Icons.person_outline,
                color: iconColor,
                onPressed: _goToProfile,
                badge: hasUnread ? const _DotBadge() : null,
              ),
            ),
          // Chat — always the last icon, on every screen. Replaces the old
          // Chat bottom tab; pushed on the root navigator.
          if (showChat)
            ValueListenableBuilder<int>(
              valueListenable:
                  getIt<ChatWebSocketService>().unreadCountNotifier,
              builder: (context, unread, _) => TopBarAction(
                icon: Icons.send_outlined,
                color: iconColor,
                tooltip: AppLocalizations.of(context)?.chat,
                onPressed: () => openChatList(context),
                badge: unread > 0 ? _CountBadge(unread) : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// One header icon: a bare 22px glyph in a 40×44 hit area, with an optional
/// badge pinned to its top-right. Screens building [MainTopBar.extraActions]
/// use this so their own buttons match the standard ones exactly.
class TopBarAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;
  final Widget? badge;

  const TopBarAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          tooltip: tooltip,
          icon: Icon(icon, size: 22, color: color),
          onPressed: onPressed,
        ),
        if (badge != null) badge!,
      ],
    );
  }
}

/// Red numeric badge pinned to a header icon's top-right (cart count, chat
/// unread count). Caps at "99+".
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 2,
      top: 6,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFFFF3B30),
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Plain red dot for "there is something new" states (liked, notifications).
class _DotBadge extends StatelessWidget {
  const _DotBadge();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      right: 5,
      top: 9,
      child: IgnorePointer(
        child: SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
