import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';

/// Chat List Screen - Shows conversations with sellers
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  late final ChatService _chatService;
  late final ApiClient _apiClient;
  List<ChatResponse> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatService = ChatService(getIt<ApiClient>());
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
    // Reload chats when dependencies change
    _loadChats();
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload chats when widget is rebuilt
    _loadChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chats = await _chatService.getChats();

      if (!mounted) return;

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e, stackTrace) {

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load chats: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshChats() async {
    await _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(l10n, isDark);
    }

    if (_chats.isEmpty) {
      return _buildEmptyState(l10n, isDark);
    }

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _ChatListItem(
            chat: chat,
            isDark: isDark,
            l10n: l10n,
            isAdmin: _isAdmin,
            onChatDeleted: _refreshChats,
          );
        },
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
              Icons.error_outline,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Error loading chats',
              style: AppTypography.body1.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshChats, child: Text(l10n.retry)),
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

  const _ChatListItem({
    required this.chat,
    required this.isDark,
    required this.l10n,
    required this.isAdmin,
    required this.onChatDeleted,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(chatId: chat.id),
              ),
            );
            // Refresh chat list when returning from chat detail
            onChatDeleted();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with first letter - shows user/seller based on role
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getGradientColors(
                        isAdmin ? (chat.userName ?? 'User') : chat.sellerName,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      () {
                        final displayName = isAdmin
                            ? (chat.userName ?? 'U')
                            : chat.sellerName;
                        return displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : (isAdmin ? 'U' : 'S');
                      }(),
                      style: AppTypography.heading4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
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
                          Text(
                            isAdmin
                                ? (chat.userName ?? 'Unknown User')
                                : chat.sellerName,
                            style: AppTypography.body1.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                          ),
                          // Time
                          Text(
                            _formatTime(lastMessageTime),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                                          : AppColors.gray600),
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.black
                                      : AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
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
