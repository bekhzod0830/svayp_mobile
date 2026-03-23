import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_cache_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';

/// Chat List Screen - Shows conversations with sellers
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  late final ChatService _chatService;
  late final ChatCacheService _chatCacheService;
  late final ApiClient _apiClient;
  List<ChatResponse> _chats = [];
  bool _isLoading = false; // Start with false to show cached data immediately
  bool _isFetchingFromApi = false; // Guard against concurrent API calls
  String? _errorMessage;
  bool _isAdmin = false;
  StreamSubscription? _listMessageSub;

  /// Called from parent (MainScreen / PartnerMainScreen) when the chat tab
  /// becomes active so newly created conversations are fetched immediately.
  void refresh() => _loadChats();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatService = ChatService(getIt<ApiClient>());
    _chatCacheService = ChatCacheService();
    _apiClient = getIt<ApiClient>();
    _checkUserRole();
    _loadChats();
  }

  void _checkUserRole() {
    _isAdmin = _apiClient.isPartnerLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Do NOT call _loadChats() here — it fires after initState too,
    // which would cause duplicate concurrent API calls.
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do NOT call _loadChats() here — key changes already create a fresh
    // State via dispose+initState, so this would cause duplicate calls.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listMessageSub?.cancel();
    getIt<ChatWebSocketService>().closeList();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChats();
    }
  }

  Future<void> _loadChats() async {
    if (!mounted) return;

    await _chatCacheService.init();

    // Show cached data immediately (no spinner flash).
    // Merge with current in-memory unreadCounts so that an already-cleared
    // badge (optimistic reset when opening a chat) is never overwritten by
    // stale cache data before the API response arrives.
    final cachedChats = await _chatCacheService.getCachedChats();
    if (!mounted) return;
    final currentUnreadMap = {for (final c in _chats) c.id: c.unreadCount};
    setState(() {
      _chats = cachedChats.map((c) {
        final current = currentUnreadMap[c.id];
        if (current != null && current < c.unreadCount) {
          return c.copyWith(unreadCount: current);
        }
        return c;
      }).toList();
      _errorMessage = null;
    });
    // Do NOT call _syncBadge() here — cache may have stale 0 unreadCounts,
    // which would momentarily zero the badge before the API response arrives.
    // The badge is kept by _badgeListSub and will be corrected from API data.

    // Guard: only one live API call at a time
    if (_isFetchingFromApi) return;
    _isFetchingFromApi = true;

    try {
      final chats = await _chatService.getChats();
      if (!mounted) return;

      await _chatCacheService.updateChatsCache(chats);

      // Capture the current in-memory unreadCounts (updated by WS events)
      // so they aren't lost when API data lands. Take the higher of the two —
      // API may lag behind WS increments.
      final inMemoryMap = {for (final c in _chats) c.id: c.unreadCount};
      setState(() {
        _chats = chats.map((c) {
          final mem = inMemoryMap[c.id];
          if (mem != null && mem > c.unreadCount) {
            return c.copyWith(unreadCount: mem);
          }
          return c;
        }).toList();
        _isLoading = false;
        _errorMessage = null;
      });
      _syncBadge();

      _openListSubscription();
    } catch (e) {
      if (!mounted) return;
      if (_chats.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to load chats: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      _isFetchingFromApi = false;
    }
  }

  Future<void> _refreshChats() async {
    await _loadChats();
  }

  /// Keeps the global bottom-nav badge in sync with the actual total of
  /// unread messages across all loaded chats.
  void _syncBadge() {
    final total = _chats.fold<int>(0, (sum, c) => sum + c.unreadCount);
    getIt<ChatWebSocketService>().unreadCountNotifier.value = total;
  }

  Future<void> _openChat(ChatResponse chat) async {
    // Optimistically reset unread count before entering the chat
    final idx = _chats.indexWhere((c) => c.id == chat.id);
    if (idx != -1 && _chats[idx].unreadCount > 0 && mounted) {
      setState(() {
        _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
      });
      _syncBadge();
    }
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chat.id),
      ),
    );
    // Background refresh after returning so the list is accurate
    _refreshChats();
  }

  /// Subscribe to all loaded chat rooms for real-time list updates via WS.
  void _openListSubscription() {
    if (!mounted) return;
    final wsService = getIt<ChatWebSocketService>();
    if (_chats.isNotEmpty) {
      wsService.openList(_chats.map((c) => c.id).toList());
    }

    // Set up the stream listener only once; cancel previous if re-loading.
    _listMessageSub?.cancel();
    _listMessageSub = wsService.listMessageStream.listen((event) {
      if (!mounted) return;
      final idx = _chats.indexWhere((c) => c.id == event.chatId);
      if (idx == -1) {
        // A message arrived for an unknown chat (e.g. the first ever message
        // after an empty list). Reload so the new conversation appears.
        _refreshChats();
        return;
      }
      final isOpen = wsService.activeChatId == event.chatId;

      // Pre-warm the detail screen's in-memory cache so the new message
      // appears instantly when the conversation is opened.
      ChatDetailScreen.appendToCache(event.chatId, event.message);

      setState(() {
        _chats[idx] = _chats[idx].copyWith(
          lastMessagePreview: event.message.content,
          lastMessageAt: event.message.createdAt,
          unreadCount: isOpen ? 0 : _chats[idx].unreadCount + 1,
        );
        // Bubble updated chat to top
        final updated = _chats.removeAt(idx);
        _chats.insert(0, updated);
      });
      _syncBadge();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isAdmin,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkStandardBorder
                          : const Color(0xFFE0E0E0),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.chat,
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                      )
                    : _errorMessage != null
                    ? RefreshIndicator(
                        onRefresh: _refreshChats,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.65,
                              child: _buildErrorState(l10n, isDark),
                            ),
                          ],
                        ),
                      )
                    : _chats.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshChats,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.65,
                              child: _buildEmptyState(l10n, isDark),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshChats,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            return _ChatListItem(
                              chat: chat,
                              isDark: isDark,
                              l10n: l10n,
                              isAdmin: _isAdmin,
                              onChatDeleted: _refreshChats,
                              onTap: () => _openChat(chat),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorGenericTitle,
              style: AppTypography.heading3.copyWith(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorGenericSubtitle,
              style: AppTypography.body2.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                l10n.errorRetry,
                style: AppTypography.body1.copyWith(
                  color: isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noMessagesYet,
              style: AppTypography.heading3.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contactSellersFromProduct,
              style: AppTypography.body1.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat List Item Widget
class _ChatListItem extends StatelessWidget {
  final ChatResponse chat;
  final bool isDark;
  final AppLocalizations l10n;
  final bool isAdmin;
  final VoidCallback onChatDeleted;
  final VoidCallback? onTap;

  const _ChatListItem({
    required this.chat,
    required this.isDark,
    required this.l10n,
    required this.isAdmin,
    required this.onChatDeleted,
    this.onTap,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return l10n.chatLastSeenJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastMessageTime = chat.lastMessageAt ?? chat.createdAt;

    return Material(
      color: isDark ? AppColors.darkMainBackground : AppColors.white,
      child: InkWell(
        onTap: onTap,
        // Navigation and unread-count reset is handled by the parent.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar - shows real image if available, else initials
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Display name based on user role
                            // Admin/Seller sees user name, User sees seller name
                            Expanded(
                              child: Text(
                                isAdmin
                                    ? (chat.userName ?? 'Unknown User')
                                    : chat.sellerName,
                                style: AppTypography.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time
                            Text(
                              _formatTime(lastMessageTime),
                              style: AppTypography.caption.copyWith(
                                color: chat.unreadCount > 0
                                    ? (isDark
                                          ? AppColors.darkPrimaryText
                                          : AppColors.black)
                                    : (isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.gray500),
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Last message
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.lastMessagePreview ?? 'No messages yet',
                                style: AppTypography.body2.copyWith(
                                  color: chat.unreadCount > 0
                                      ? (isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.black)
                                      : (isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray500),
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  chat.unreadCount > 99
                                      ? '99+'
                                      : chat.unreadCount.toString(),
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.black
                                        : AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 82,
              color: isDark
                  ? AppColors.darkStandardBorder
                  : const Color(0xFFE0E0E0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final displayName = isAdmin ? (chat.userName ?? 'User') : chat.sellerName;
    final imageUrl = isAdmin ? chat.userAvatar : chat.sellerLogo;
    final isOnline = isAdmin ? chat.userOnline : chat.sellerOnline;

    final Widget avatar = imageUrl != null && imageUrl.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              cacheManager: ImageCacheManager.instance,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildAvatarFallback(displayName),
              errorWidget: (_, __, ___) => _buildAvatarFallback(displayName),
            ),
          )
        : _buildAvatarFallback(displayName);

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? const Color(0xFF4CAF50) : Colors.grey.shade400,
              border: Border.all(
                color: isDark ? AppColors.darkMainBackground : AppColors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(displayName),
        ),
      ),
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: AppTypography.heading4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String name) {
    final hash = name.hashCode;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFF5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
      [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
    ];
    return gradients[hash.abs() % gradients.length];
  }
}
