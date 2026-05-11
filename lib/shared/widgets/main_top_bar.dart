import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:swipe/features/profile/presentation/screens/notifications_screen.dart';

/// Consistent glass top bar used across all main tab screens.
///
/// Shows [title] on the left and a cart icon (with badge) + liked heart icon
/// on the right.  [extraActions] are rendered between the title and the
/// standard icons (e.g. the Sellers button on the shop screen).
///
/// Set [isLikedScreen] to true when this bar is rendered on the Liked screen
/// itself so the heart icon shows filled (active) and pressing it is a no-op.
class MainTopBar extends StatefulWidget {
  final String title;
  final bool isLikedScreen;
  final List<Widget> extraActions;

  const MainTopBar({
    super.key,
    required this.title,
    this.isLikedScreen = false,
    this.extraActions = const [],
  });

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

  Future<void> _goToNotifications() async {
    BadgeNotifier.instance.clearUnreadNotifications();
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xD0050508) : const Color(0xB8FFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x28000000),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                ...widget.extraActions,
                // Cart icon with reactive badge
                ValueListenableBuilder<int>(
                  valueListenable: BadgeNotifier.instance.cartCount,
                  builder: (context, count, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          size: 24,
                          color: iconColor,
                        ),
                        onPressed: _goToCart,
                      ),
                      if (count > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
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
                        ),
                    ],
                  ),
                ),
                // Liked heart icon with reactive new-item dot
                ValueListenableBuilder<bool>(
                  valueListenable: BadgeNotifier.instance.hasNewLiked,
                  builder: (context, hasNew, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          widget.isLikedScreen
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 24,
                          color: widget.isLikedScreen
                              ? const Color(0xFFFF3B5C)
                              : iconColor,
                        ),
                        onPressed: _goToLiked,
                      ),
                      if (hasNew && !widget.isLikedScreen)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IgnorePointer(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Notification bell icon — far right
                ValueListenableBuilder<bool>(
                  valueListenable: BadgeNotifier.instance.hasUnreadNotifications,
                  builder: (context, hasUnread, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          hasUnread
                              ? Icons.notifications
                              : Icons.notifications_outlined,
                          size: 24,
                          color: iconColor,
                        ),
                        onPressed: _goToNotifications,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IgnorePointer(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
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
