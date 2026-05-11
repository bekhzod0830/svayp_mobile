import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_cache_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
import 'package:swipe/features/chat/presentation/widgets/chat_emoji_panel.dart';
import 'package:swipe/features/chat/presentation/widgets/chat_attachment_sheet.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/app/routes.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper function to format size label by removing SIZE_ prefix
String _formatSizeLabel(String size) {
  // Remove SIZE_ prefix if present (e.g., "SIZE_46" -> "46")
  if (size.toUpperCase().startsWith('SIZE_')) {
    return size.substring(5);
  }
  return size;
}

/// Chat Detail Screen - Individual conversation with a seller
class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  /// If set, sent via WS immediately after the room is opened.
  /// Used when navigating from ChatComposeScreen so the message goes through
  /// WebSocket and is broadcast to the seller in real time.
  final String? pendingMessage;

  /// When true, the back button navigates to the chat list instead of popping.
  /// Set this when the screen is opened directly from a notification.
  final bool fromNotification;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    this.pendingMessage,
    this.fromNotification = false,
  });

  /// Appends [message] to the in-memory message cache for [chatId].
  /// Called from the chat list screen when a new WS message arrives so
  /// that opening the detail screen shows it instantly from cache.
  static void appendToCache(String chatId, ChatMessageResponse message) {
    final cache = _ChatDetailScreenState._messagesCache;
    final existing = cache[chatId];
    if (existing == null) {
      cache[chatId] = [message];
      return;
    }
    // Avoid duplicates
    if (existing.any((m) => m.id == message.id)) return;
    existing.add(message);
  }

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  // In-memory caches: chatId → messages/chat, so re-opening shows instantly
  static final Map<String, List<ChatMessageResponse>> _messagesCache = {};
  static final Map<String, ChatResponse> _chatCache = {};
  // Cached user ID so initState can apply caches synchronously
  static String? _cachedCurrentUserId;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final ChatService _chatService;
  late final ChatWebSocketService _webSocketService;
  late final ChatCacheService _chatCacheService;
  String _currentUserId = '';
  bool _isAdmin = false;
  StreamSubscription<ChatMessageResponse>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<Map<String, dynamic>>? _readSubscription;
  StreamSubscription<PresenceResponse>? _presenceSubscription;
  StreamSubscription<bool>? _connectionStateSubscription;

  ChatResponse? _chat;
  List<ChatMessageResponse> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isInitialized = false;
  bool _hasRetried = false;

  // Emoji & attachment state
  bool _showEmojiPanel = false;
  List<File> _pendingImageFiles = [];
  dynamic _pendingLocation;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 30;

  // Presence & typing state
  bool _isOtherOnline = false;
  DateTime? _otherLastSeen = null;
  bool _isOtherTyping = false;
  Timer? _typingClearTimer;
  DateTime? _lastTypingSentAt;

  // Pending message (from ChatComposeScreen) — sent via WS once room is open
  bool _pendingMessageSent = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(getIt<ApiClient>());
    _webSocketService = getIt<ChatWebSocketService>();
    _chatCacheService = ChatCacheService();
    _isAdmin = getIt<ApiClient>().isPartnerLogin();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPanel) {
        setState(() => _showEmojiPanel = false);
      } else {
        setState(() {});
      }
    });
    // Rebuild send-button state for ANY controller change — including
    // emoji insertions that bypass TextField's onChanged callback.
    _messageController.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    AnalyticsService.instance.logEvent(AnalyticsEvents.chatConversationOpened);
    // Apply caches synchronously before first build — no spinner/error flash on re-open
    if (_cachedCurrentUserId != null) {
      _currentUserId = _cachedCurrentUserId!;
      // Apply message cache
      final cachedMessages = _messagesCache[widget.chatId];
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        _messages = List.of(cachedMessages);
        _isLoading = false;
        // Scroll to latest cached message immediately after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      // Apply chat cache
      final cachedChat = _chatCache[widget.chatId];
      if (cachedChat != null) {
        _chat = cachedChat;
      }
    }
    if (!_isInitialized) {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    try {
      // Resolve current user ID (use static cache to avoid async on re-opens)
      if (_cachedCurrentUserId != null) {
        _currentUserId = _cachedCurrentUserId!;
      } else {
        final authService = getIt<AuthService>();
        final currentUser = await authService.getCurrentUser();
        _currentUserId = currentUser.id;
        _cachedCurrentUserId = _currentUserId;
        // First open: apply caches now that we have the user ID
        final cachedMessages = _messagesCache[widget.chatId];
        if (cachedMessages != null && cachedMessages.isNotEmpty && mounted) {
          setState(() {
            _messages = List.of(cachedMessages);
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
        final cachedChat = _chatCache[widget.chatId];
        if (cachedChat != null && mounted) {
          setState(() {
            _chat = cachedChat;
          });
        }
      }

      // Load chat and messages in parallel — neither depends on the other.
      // markAsRead also fires immediately alongside them (no need to block).
      // WebSocket is connected right after _loadChat so we have otherUserId.
      await Future.wait([
        _loadChat().then((_) {
          // Connect WS as soon as we have chat metadata (for otherUserId).
          // This allows real-time messages to start arriving ASAP.
          if (mounted) _connectWebSocket();
          // Initialise presence from REST response
          if (_chat != null && mounted) {
            setState(() {
              _isOtherOnline = _isAdmin
                  ? _chat!.userOnline
                  : _chat!.sellerOnline;
              _otherLastSeen = _isAdmin
                  ? _chat!.userLastSeen
                  : _chat!.sellerLastSeen;
            });
          }
        }),
        _loadMessages(),
        _chatService.markAsRead(widget.chatId).catchError((_) {}),
      ]);

      _isInitialized = true;
    } catch (e) {
      // When opened from a notification on a cold-start the 500 ms delay may
      // fire before auth fully settles. Retry once before showing the error.
      if (widget.fromNotification && !_hasRetried) {
        _hasRetried = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
            _initializeChat();
          }
        });
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load chat: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Connect to STOMP WebSocket and subscribe to all real-time topics.
  void _connectWebSocket() {
    final token = getIt<ApiClient>().getToken();
    if (token == null) return;

    // Determine the other party's user ID for presence subscription.
    // Admin (seller staff) → subscribe to buyer's userId.
    // User (buyer) → subscribe to sellerUserId (staff member's personal UUID),
    //   NOT sellerId which is the shop entity UUID and has no WS session.
    final otherUserId = _isAdmin
        ? (_chat?.userId ?? '')
        : (_chat?.sellerUserId ?? '');

    // Incoming messages
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      if (!mounted) {
        return;
      }
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        // Message already in list (added locally after REST send).
        // Replace it with the WS version which may have richer fields
        // (e.g. latitude/longitude populated by the server).
        final existing = _messages[existingIndex];
        final merged = existing.copyWith(
          latitude: message.latitude ?? existing.latitude,
          longitude: message.longitude ?? existing.longitude,
          messageType: message.messageType != MessageType.text
              ? message.messageType
              : existing.messageType,
          attachments: message.attachments.isNotEmpty
              ? message.attachments
              : existing.attachments,
        );
        setState(() => _messages[existingIndex] = merged);
        _messagesCache[widget.chatId] = List.of(_messages);
        return;
      }
      setState(() {
        // Mark message as read locally so UI reflects it immediately
        final readMessage = message.copyWith(isRead: true);
        _messages.add(readMessage);
      });
      _messagesCache[widget.chatId] = List.of(_messages);
      _scrollToBottom();
      _webSocketService.markAsRead();
    });

    // Typing indicator
    _typingSubscription = _webSocketService.typingStream.listen((data) {
      if (!mounted) return;
      final typingUserId = data['userId'] as String? ?? '';
      if (typingUserId == _currentUserId) return; // ignore self
      setState(() => _isOtherTyping = true);
      // Auto-clear after 3 s of silence
      _typingClearTimer?.cancel();
      _typingClearTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isOtherTyping = false);
      });
    });

    // Read receipts
    _readSubscription = _webSocketService.readStream.listen((data) {
      if (!mounted) return;
    });

    // Presence
    _presenceSubscription = _webSocketService.presenceStream.listen((presence) {
      if (!mounted) return;
      setState(() {
        _isOtherOnline = presence.online;
        _otherLastSeen = presence.lastSeen;
      });
    });

    // Connection state
    _connectionStateSubscription = _webSocketService.connectionStateStream.listen((
      connected,
    ) {
      if (!connected || !mounted) return;
      _webSocketService.markAsRead();
      // Send pending message (from ChatComposeScreen) once on first connect
      if (!_pendingMessageSent) {
        _sendPendingMessage();
      }
      // One-time presence snapshot: the WS presence topic only fires on
      // connect/disconnect events. If the other user was already online before
      // we subscribed, we would miss that broadcast. Fetch current status once.
      if (otherUserId.isNotEmpty) {
        _chatService
            .getPresence(otherUserId)
            .then((p) {
              if (!mounted) return;
              setState(() {
                _isOtherOnline = p.online;
                _otherLastSeen = p.lastSeen;
              });
            })
            .catchError((e) {
            });
      }
    });

    // Connect then open the chat room
    _webSocketService.connect(token);
    _webSocketService.openChat(widget.chatId, otherUserId);

    // If WS is already connected (singleton), mark as read and send pending
    // message now. Otherwise both will be handled when connectionStateStream
    // fires with connected=true.
    if (_webSocketService.isConnected) {
      _webSocketService.markAsRead();
      if (!_pendingMessageSent) {
        _sendPendingMessage();
      }
    }
  }

  void _sendPendingMessage() {
    final msg = widget.pendingMessage;
    if (msg == null || msg.isEmpty || _pendingMessageSent) return;
    _pendingMessageSent = true;
    // Small delay to ensure subscription is active before sending
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _webSocketService.sendMessage(msg);
      // Message will be marked as read when it arrives via WS listener
    });
  }

  Future<void> _loadChat() async {
    try {
      // Try cache first (sync)
      final cached = await _chatCacheService.getCachedChat(widget.chatId);
      if (cached != null && mounted && _chat == null) {
        setState(() {
          _chat = cached;
        });
      }
      // Fetch fresh from API (background)
      final chat = await _chatService.getChat(widget.chatId);
      if (mounted) {
        setState(() {
          _chat = chat;
        });
        // Update cache
        await _chatCacheService.updateSingleChat(chat);
        // Update in-memory cache
        _chatCache[widget.chatId] = chat;
      }
    } catch (e) {
      // If cache exists, don't throw; silently use it
      if (_chat != null) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(
        widget.chatId,
        page: 0,
        size: _pageSize,
      );

      if (mounted) {
        // Build a map of locally cached messages with their modified read status
        final localMessageMap = <String, ChatMessageResponse>{};
        for (final localMsg in _messages) {
          localMessageMap[localMsg.id] = localMsg;
        }

        // Merge API messages with locally modified read status
        final mergedMessages = messages.map((apiMsg) {
          final localMsg = localMessageMap[apiMsg.id];
          if (localMsg != null && localMsg.isRead && !apiMsg.isRead) {
            // Preserve local 'isRead: true' if message was modified locally
            return apiMsg.copyWith(isRead: true);
          }
          return apiMsg;
        }).toList();

        setState(() {
          // Messages come newest first from API, reverse for chat display
          _messages = mergedMessages.reversed.toList();
          _currentPage = 0;
          _hasMoreMessages = messages.length >= _pageSize;
          _isLoading = false;
        });
        // Persist to cache for instant display on next open
        _messagesCache[widget.chatId] = List.of(_messages);
        // Scroll to the latest message after the list renders
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final messages = await _chatService.getMessages(
        widget.chatId,
        page: nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      if (messages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }
      // Preserve scroll position when prepending older messages
      final oldOffset = _scrollController.hasClients
          ? _scrollController.offset
          : 0.0;

      // Build a map of locally cached messages to preserve their read status
      final localMessageMap = <String, ChatMessageResponse>{};
      for (final localMsg in _messages) {
        localMessageMap[localMsg.id] = localMsg;
      }

      setState(() {
        // API returns newest-first; reversed = oldest-first; prepend to front
        final older = messages.reversed.toList();

        // Preserve local read status for older messages too
        final mergedOlder = older.map((apiMsg) {
          final localMsg = localMessageMap[apiMsg.id];
          if (localMsg != null && localMsg.isRead && !apiMsg.isRead) {
            return apiMsg.copyWith(isRead: true);
          }
          return apiMsg;
        }).toList();

        _messages = [...mergedOlder, ..._messages];
        _currentPage = nextPage;
        _hasMoreMessages = messages.length >= _pageSize;
        _isLoadingMore = false;
      });
      // Restore scroll so the view doesn't jump
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(oldOffset);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // reverse:true → maxScrollExtent is the "top" of the chat (oldest messages)
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMoreMessages();
    }
  }

  Future<void> _reloadChat() async {
    try {
      await _loadChat();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatFailedToReload),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasImage = _pendingImageFiles.isNotEmpty;
    final hasLocation = _pendingLocation != null;

    // Attachment messages go via multipart REST (WS doesn't support files)
    if (hasImage || hasLocation) {
      if (_isSending) return;
      setState(() {
        _isSending = true;
        _messageController.clear();
      });

      final imageFiles = List<File>.from(_pendingImageFiles);
      final location = _pendingLocation;
      setState(() {
        _pendingImageFiles = [];
        _pendingLocation = null;
      });

      try {
        final msg = await _chatService.sendMultipartMessage(
          widget.chatId,
          files: imageFiles.isNotEmpty ? imageFiles : null,
          content: content.isNotEmpty ? content : null,
          latitude: location?.latitude,
          longitude: location?.longitude,
        );
        if (mounted) {
          setState(() {
            // Avoid duplicate if WS broadcast already added this message
            if (!_messages.any((m) => m.id == msg.id)) {
              _messages.add(msg.copyWith(isRead: true));
            }
          });
          _messagesCache[widget.chatId] = List.of(_messages);
          _scrollToBottom();
          AnalyticsService.instance.logEvent(AnalyticsEvents.messageSent);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.chatFailedToReload),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      // Don't also send via WS — REST already broadcasts via backend
      return;
    }

    if (content.isEmpty || _isSending) return;

    if (!_webSocketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatReconnecting),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    _webSocketService.sendMessage(content);
    AnalyticsService.instance.logEvent(AnalyticsEvents.messageSent);
    // Message will arrive back through /topic/chat/{id} subscription
    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  // ── Controller listener (for emoji send-button activation) ──────────────

  void _onControllerChanged() => setState(() {});

  // ── Emoji panel ──────────────────────────────────────────────────────────

  void _toggleEmojiPanel() {
    if (_showEmojiPanel) {
      // Hide panel and restore keyboard
      setState(() => _showEmojiPanel = false);
      _focusNode.requestFocus();
    } else {
      // Dismiss keyboard, then show panel
      FocusScope.of(context).unfocus();
      setState(() => _showEmojiPanel = true);
    }
  }

  // ── Attachment sheet ─────────────────────────────────────────────────────

  Future<void> _openAttachmentSheet() async {
    // Dismiss keyboard + emoji panel before opening the sheet
    FocusScope.of(context).unfocus();
    if (_showEmojiPanel) setState(() => _showEmojiPanel = false);

    final result = await showChatAttachmentSheet(context);
    if (result == null || !mounted) return;

    if (result is ImageAttachment) {
      setState(() => _pendingImageFiles = List.from(result.files));
    } else if (result is LocationAttachment) {
      setState(() => _pendingLocation = result.latLng);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readSubscription?.cancel();
    _presenceSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _typingClearTimer?.cancel();
    _webSocketService.closeChat();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _webSocketService.closeChat();
    } else if (state == AppLifecycleState.resumed) {
      // MainScreen handles reconnecting the STOMP session.
      // We only need to re-open the chat room subscriptions.
      if (_chat != null) {
        final otherUserId = _isAdmin
            ? (_chat!.userId ?? '')
            : (_chat!.sellerUserId ?? '');
        _webSocketService.openChat(widget.chatId, otherUserId);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMessageTextChanged(String value) {
    setState(() {});
    if (value.isEmpty) return;
    // Throttle typing events to at most once every 2 s
    final now = DateTime.now();
    if (_lastTypingSentAt == null ||
        now.difference(_lastTypingSentAt!) > const Duration(seconds: 2)) {
      _webSocketService.sendTyping();
      _lastTypingSentAt = now;
    }
  }

  /// When opened from a notification, go to the chat list instead of popping.
  void _onBack() {
    if (widget.fromNotification) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.chatList);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topPadding = MediaQuery.of(context).padding.top;
    const headerHeight = 56.0;
    final headerTotal = topPadding + headerHeight + 8.0;

    // Reusable floating glass header builder
    Widget glassHeader({required Widget child}) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: headerTotal,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xD0050508)
                    : const Color(0xB8FFFFFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x28000000),
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage == null &&
        (_isLoading || (!_isInitialized && _chat == null))) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.pageBackground,
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            glassHeader(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                    onPressed: _onBack,
                  ),
                  Expanded(
                    child: Text(
                      l10n.loading,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _chat == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.pageBackground,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: headerTotal),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage != null
                          ? l10n.chatFailedToLoad
                          : l10n.chatNotFound,
                    ),
                  ],
                ),
              ),
            ),
            glassHeader(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                    onPressed: _onBack,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Column(
            children: [
              // Top spacer so messages start below the glass header
              SizedBox(height: headerTotal),
              // Messages List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reloadChat,
                  child: _messages.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Text(
                                  l10n.noMessagesYet,
                                  style: AppTypography.body1.copyWith(
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          itemCount:
                              _messages.length + (_hasMoreMessages ? 1 : 0),
                          itemBuilder: (context, index) {
                            // The extra item at the top shows a loading spinner
                            if (index == _messages.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // reverse: true means index 0 = last message (newest)
                            final reversedIndex = _messages.length - 1 - index;
                            final message = _messages[reversedIndex];
                            // Use senderType for reliable bubble alignment:
                            // - Seller view (_isAdmin): seller/admin messages are mine
                            // - User view: only user messages are mine
                            final isMine = _isAdmin
                                ? message.senderType != SenderType.user
                                : message.senderType == SenderType.user;

                            // Check if a date separator is needed
                            bool showDateSeparator = false;
                            if (reversedIndex == 0) {
                              showDateSeparator = true;
                            } else {
                              final prev =
                                  _messages[reversedIndex - 1].createdAt;
                              final curr = message.createdAt;
                              showDateSeparator =
                                  prev.year != curr.year ||
                                  prev.month != curr.month ||
                                  prev.day != curr.day;
                            }

                            Widget msgWidget;
                            if (message.messageType == MessageType.product) {
                              msgWidget = _ProductMessageBubble(
                                message: message,
                                isDark: isDark,
                              );
                            } else if (message.messageType == MessageType.image ||
                                (message.messageType != MessageType.location &&
                                    message.attachments.isNotEmpty)) {
                              msgWidget = _ImageMessageBubble(
                                message: message,
                                isMine: isMine,
                                isDark: isDark,
                              );
                            } else if (message.messageType == MessageType.location ||
                                (message.latitude != null &&
                                    message.longitude != null)) {
                              msgWidget = _LocationMessageBubble(
                                message: message,
                                isMine: isMine,
                                isDark: isDark,
                              );
                            } else {
                              msgWidget = _MessageBubble(
                                message: message,
                                isMine: isMine,
                                isDark: isDark,
                                senderName: isMine
                                    ? message.senderName
                                    : (_isAdmin
                                          ? (_chat!.userName ?? 'User')
                                          : _chat!.sellerName),
                                avatarUrl: isMine
                                    ? null
                                    : (_isAdmin
                                          ? _chat!.userAvatar
                                          : _chat!.sellerLogo),
                              );
                            }

                            if (showDateSeparator) {
                              return Column(
                                children: [
                                  _DateSeparator(
                                    date: message.createdAt,
                                    isDark: isDark,
                                  ),
                                  msgWidget,
                                ],
                              );
                            }
                            return msgWidget;
                          },
                        ),
                ),
              ),

              // ── Attachment preview bar ─────────────────────────
              if (_pendingImageFiles.isNotEmpty || _pendingLocation != null)
                _AttachmentPreviewBar(
                  isDark: isDark,
                  imageFiles: _pendingImageFiles,
                  location: _pendingLocation,
                  onRemove: () => setState(() {
                    _pendingImageFiles = [];
                    _pendingLocation = null;
                  }),
                ),

              // ── Message Input ───────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  _showEmojiPanel ? 8 : (MediaQuery.of(context).padding.bottom + 8),
                ),
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkStandardBorder
                          : AppColors.gray200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ── Emoji button (left) ─────────────────────
                      EmojiToggleButton(
                        isActive: _showEmojiPanel,
                        isDark: isDark,
                        onTap: _toggleEmojiPanel,
                      ),
                      // ── Text field ──────────────────────────────
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: l10n.typeMessage,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.fromLTRB(
                              4,
                              10,
                              8,
                              10,
                            ),
                            hintStyle: AppTypography.body2.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.gray500,
                            ),
                          ),
                          style: AppTypography.body2.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: _onMessageTextChanged,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      // ── Attachment (clip) button ─────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 2, 4),
                        child: GestureDetector(
                          onTap: _openAttachmentSheet,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (_pendingImageFiles.isNotEmpty ||
                                      _pendingLocation != null)
                                  ? (isDark
                                        ? AppColors.white
                                        : AppColors.black)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.attach_file_rounded,
                              color: (_pendingImageFiles.isNotEmpty ||
                                      _pendingLocation != null)
                                  ? (isDark
                                        ? AppColors.black
                                        : AppColors.white)
                                  : (isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray500),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // ── Send button ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: (_messageController.text.trim().isNotEmpty ||
                                      _pendingImageFiles.isNotEmpty ||
                                      _pendingLocation != null) &&
                                  !_isSending
                              ? _sendMessage
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (_messageController.text.trim().isNotEmpty ||
                                          _pendingImageFiles.isNotEmpty ||
                                          _pendingLocation != null) &&
                                      !_isSending
                                  ? (isDark ? AppColors.white : AppColors.black)
                                  : (isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray300),
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? AppColors.black
                                            : AppColors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: isDark
                                        ? AppColors.black
                                        : AppColors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Emoji panel (replaces keyboard space) ───────────
              if (_showEmojiPanel) ...[
                ChatEmojiPanel(
                  controller: _messageController,
                  onClose: () {
                    setState(() => _showEmojiPanel = false);
                    _focusNode.requestFocus();
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ],
          ),
          // ── Floating glass header ─────────────────────────────
          glassHeader(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                  onPressed: _onBack,
                ),
                // Avatar + online dot
                Stack(
                  children: [
                    _buildAppBarAvatar(),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOtherOnline
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade400,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xD0050508)
                                : const Color(0xB8FFFFFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Name + presence
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isAdmin
                            ? (_chat!.userName ?? 'Unknown User')
                            : _chat!.sellerName,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isOtherTyping
                            ? l10n.chatPresenceTyping
                            : _isOtherOnline
                            ? l10n.chatPresenceOnline
                            : _otherLastSeen != null
                            ? _formatLastSeen(_otherLastSeen!, l10n)
                            : l10n.chatPresenceOffline,
                        style: AppTypography.caption.copyWith(
                          color: _isOtherTyping
                              ? (_isAdmin
                                    ? AppColors.gray500
                                    : const Color(0xFF4CAF50))
                              : _isOtherOnline
                              ? const Color(0xFF4CAF50)
                              : (isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.gray500),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Refresh action
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                  onPressed: _reloadChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAvatar() {
    final displayName = _isAdmin
        ? (_chat!.userName ?? 'User')
        : _chat!.sellerName;
    final imageUrl = _isAdmin ? _chat!.userAvatar : _chat!.sellerLogo;
    final Widget fallback = Container(
      width: 38,
      height: 38,
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
          style: AppTypography.body2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: ImageCacheManager.instance,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
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

  String _formatLastSeen(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return l10n.chatLastSeenJustNow;
    if (diff.inMinutes < 60) return l10n.chatLastSeenMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.chatLastSeenHours(diff.inHours);
    return l10n.chatLastSeenDays(diff.inDays);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Attachment Preview Bar
// ──────────────────────────────────────────────────────────────────────────────

/// Thin bar above the input that shows a selected image thumbnail or location.
class _AttachmentPreviewBar extends StatelessWidget {
  final bool isDark;
  final List<File> imageFiles;
  final dynamic location;
  final VoidCallback onRemove;

  const _AttachmentPreviewBar({
    required this.isDark,
    required this.imageFiles,
    required this.location,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = imageFiles.isNotEmpty;
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBackground
            : AppColors.gray100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
            width: 0.5,
          ),
          left: BorderSide(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
            width: 0.5,
          ),
          right: BorderSide(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail or location icon
          if (hasImages) ...[
            // Show up to 3 overlapping thumbnails
            SizedBox(
              width: imageFiles.length > 1 ? 40 + (imageFiles.length.clamp(1, 3) - 1) * 16.0 : 40,
              height: 40,
              child: Stack(
                children: [
                  for (int i = imageFiles.length.clamp(1, 3) - 1; i >= 0; i--)
                    Positioned(
                      left: i * 16.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFiles[i],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              imageFiles.length > 1
                  ? '${l10n.chatAttachPhoto} (${imageFiles.length})'
                  : l10n.chatAttachPhoto,
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ] else if (location != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 22,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.chatAttachLocation,
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
          const Spacer(),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final ChatMessageResponse message;
  final bool isMine;
  final bool isDark;
  final String senderName;
  final String? avatarUrl;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.senderName,
    this.avatarUrl,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildAvatar() {
    final fallback = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getAvatarGradient(senderName),
        ),
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          cacheManager: ImageCacheManager.instance,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
  }

  List<Color> _getAvatarGradient(String name) {
    final hash = name.hashCode;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFF5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];
    return gradients[hash.abs() % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for incoming messages
          if (!isMine) ...[_buildAvatar(), const SizedBox(width: 6)],
          // Message bubble with name inside
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.86,
            ),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: isMine
                      ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1C1C1C))
                      : (isDark ? AppColors.darkCardBackground : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Telegram-style: text + invisible trailing spacer so the
                    // last line never slides under the timestamp, then the
                    // timestamp is pinned to the bottom-right of the Stack.
                    Stack(
                      children: [
                        Padding(
                          // Reserve bottom-right space for the timestamp.
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: message.content,
                                  style: AppTypography.body2.copyWith(
                                    color: isMine
                                        ? (isDark
                                              ? AppColors.black
                                              : AppColors.white)
                                        : (isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.black),
                                    height: 1.4,
                                  ),
                                ),
                                // Invisible spacer that matches the timestamp width
                                // so the last text line never collides with the time.
                                const TextSpan(
                                  text:
                                      '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _formatTime(message.createdAt),
                              style: AppTypography.caption.copyWith(
                                color: isMine
                                    ? (isDark
                                          ? AppColors.black.withOpacity(0.5)
                                          : AppColors.white.withOpacity(0.6))
                                    : (isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.gray500),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date separator between messages on different days
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateSeparator({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    final String label;
    if (msgDay == today) {
      label = l10n.chatToday;
    } else if (msgDay == yesterday) {
      label = l10n.yesterday;
    } else {
      final months = [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december,
      ];
      final monthName = months[date.month - 1];
      label = date.year == now.year
          ? '$monthName ${date.day}'
          : '$monthName ${date.day}, ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Image Message Bubble
// ──────────────────────────────────────────────────────────────────────────────

class _ImageMessageBubble extends StatelessWidget {
  final ChatMessageResponse message;
  final bool isMine;
  final bool isDark;

  const _ImageMessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _openViewer(BuildContext context, int index) {
    final urls = message.attachments.map((a) => a.fileUrl).toList();
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenImageViewer(
        imageUrls: urls,
        initialIndex: index,
      ),
    ));
  }

  Widget _imageTile(
    BuildContext context,
    int index, {
    bool showExtraCount = false,
    int extraCount = 0,
  }) {
    final url = message.attachments[index].fileUrl;
    return GestureDetector(
      onTap: () => _openViewer(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            cacheManager: ImageCacheManager.instance,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray200,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray200,
              child: Icon(Icons.broken_image_rounded,
                  color: isDark ? Colors.white38 : Colors.black26),
            ),
          ),
          if (showExtraCount)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final count = message.attachments.length;
    const gap = 2.0;

    Widget timestampChip() => Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(message.createdAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

    // 1 image: full-width, natural aspect ratio
    if (count == 1) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => _openViewer(context, 0),
            child: CachedNetworkImage(
              imageUrl: message.attachments[0].fileUrl,
              cacheManager: ImageCacheManager.instance,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              placeholder: (_, __) => Container(
                height: 220,
                color: isDark ? AppColors.darkCardBackground : AppColors.gray200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 220,
                color: isDark ? AppColors.darkCardBackground : AppColors.gray200,
                child: Icon(Icons.broken_image_rounded,
                    color: isDark ? Colors.white38 : Colors.black26),
              ),
            ),
          ),
          if (message.content.isEmpty) timestampChip(),
        ],
      );
    }

    // 2 images: side by side
    if (count == 2) {
      return Stack(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _imageTile(context, 0)),
                Container(width: gap, color: Colors.black12),
                Expanded(child: _imageTile(context, 1)),
              ],
            ),
          ),
          if (message.content.isEmpty) timestampChip(),
        ],
      );
    }

    // 3 images: left tall + right two stacked
    if (count == 3) {
      return Stack(
        children: [
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _imageTile(context, 0)),
                Container(width: gap, color: Colors.black12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _imageTile(context, 1)),
                      Container(height: gap, color: Colors.black12),
                      Expanded(child: _imageTile(context, 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.content.isEmpty) timestampChip(),
        ],
      );
    }

    // 4+ images: 2×2 grid, "+N" overlay on tile [3] if more than 4
    const maxVisible = 4;
    final extra = count - maxVisible;
    return Stack(
      children: [
        SizedBox(
          height: 222,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _imageTile(context, 0)),
                    Container(width: gap, color: Colors.black12),
                    Expanded(child: _imageTile(context, 1)),
                  ],
                ),
              ),
              Container(height: gap, color: Colors.black12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _imageTile(context, 2)),
                    Container(width: gap, color: Colors.black12),
                    Expanded(
                      child: _imageTile(
                        context,
                        3,
                        showExtraCount: extra > 0,
                        extraCount: extra,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (message.content.isEmpty) timestampChip(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isMine
                    ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1C1C1C))
                    : (isDark ? AppColors.darkCardBackground : AppColors.gray100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Images grid ────────────────────────────────
                  _buildGrid(context),
                  // ── Caption + timestamp (only when text is present) ────
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: message.content,
                                    style: TextStyle(
                                      color: isMine
                                          ? (isDark ? AppColors.black : AppColors.white)
                                          : (isDark ? AppColors.darkPrimaryText : AppColors.black),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                color: isMine
                                    ? (isDark
                                        ? AppColors.black.withValues(alpha: 0.5)
                                        : AppColors.white.withValues(alpha: 0.6))
                                    : (isDark ? AppColors.darkSecondaryText : AppColors.gray500),
                                fontSize: 10,
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
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Location Message Bubble
// ──────────────────────────────────────────────────────────────────────────────

class _LocationMessageBubble extends StatelessWidget {
  final ChatMessageResponse message;
  final bool isMine;
  final bool isDark;

  const _LocationMessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openInMaps() async {
    final lat = message.latitude;
    final lon = message.longitude;
    if (lat == null || lon == null) return;
    final latStr = lat.toStringAsFixed(6);
    final lonStr = lon.toStringAsFixed(6);
    // geo: URI triggers the system app picker on both iOS and Android
    final geoUri = Uri.parse('geo:$latStr,$lonStr?q=$latStr,$lonStr');
    final googleMapsBrowser = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latStr,$lonStr');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(googleMapsBrowser,
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = message.latitude;
    final lon = message.longitude;
    final hasCoords = lat != null && lon != null;
    final hasContent = message.content.isNotEmpty;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: GestureDetector(
              onTap: _openInMaps,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isMine
                      ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1C1C1C))
                      : (isDark ? AppColors.darkCardBackground : AppColors.gray100),
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Map ─────────────────────────────────────────────
                    SizedBox(
                      height: 160,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasCoords)
                            AbsorbPointer(
                              child: GoogleMap(
                                liteModeEnabled: true,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(lat, lon),
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('location'),
                                    position: LatLng(lat, lon),
                                  ),
                                },
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                                compassEnabled: false,
                                rotateGesturesEnabled: false,
                                scrollGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                              ),
                            )
                          else
                            Container(
                              color: isDark
                                  ? AppColors.darkCardBackground
                                  : AppColors.gray200,
                              child: Center(
                                child: Icon(
                                  Icons.location_off_rounded,
                                  size: 40,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black26,
                                ),
                              ),
                            ),
                          // Timestamp chip when no caption below
                          if (!hasContent)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTime(message.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ── Caption + timestamp (only when text is present) ──
                    if (hasContent)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: message.content,
                                      style: TextStyle(
                                        color: isMine
                                            ? (isDark ? AppColors.black : AppColors.white)
                                            : (isDark ? AppColors.darkPrimaryText : AppColors.black),
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    // invisible spacer
                                    const TextSpan(
                                      text:
                                          '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  color: isMine
                                      ? (isDark
                                          ? AppColors.black.withValues(alpha: 0.5)
                                          : AppColors.white.withValues(alpha: 0.6))
                                      : (isDark ? AppColors.darkSecondaryText : AppColors.gray500),
                                  fontSize: 10,
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen image viewer (supports swipe between multiple images)
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;
  double _backgroundOpacity = 1;
  bool _isDragging = false;

  static const double _dismissThreshold = 120;
  static const double _velocityThreshold = 800;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) => setState(() => _isDragging = true);

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      final progress =
          (_dragOffset.abs() / _dismissThreshold).clamp(0.0, 1.0);
      _backgroundOpacity = 1 - progress * 0.8;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > _dismissThreshold ||
        (_dragOffset > 30 && velocity > _velocityThreshold)) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _backgroundOpacity = 1;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imageUrls.length > 1;
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _backgroundOpacity),
      body: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            // ── PageView — swipe horizontally between images ───
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) => Center(
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    panEnabled: !_isDragging,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      cacheManager: ImageCacheManager.instance,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Top bar: close + "N / total" counter ──────────
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.black45),
                    ),
                    const Spacer(),
                    if (hasMultiple)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            // ── Dot indicators at bottom ───────────────────────
            if (hasMultiple)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentIndex ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Product Message Bubble (for PRODUCT type messages)
class _ProductMessageBubble extends StatelessWidget {
  final ChatMessageResponse message;
  final bool isDark;

  const _ProductMessageBubble({required this.message, required this.isDark});

  String _formatPrice(int price) {
    // Intelligently detect currency based on price range
    // USD prices are typically < 1000, UZS prices are typically > 1000
    if (price < 1000) {
      // Likely USD
      return '\$$price';
    } else {
      // Likely UZS
      final formatted = price.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
      return '$formatted UZS';
    }
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      String hexColor = colorString.replaceAll('#', '');
      // Add FF for opacity if not present
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Return gray for invalid colors
      return AppColors.gray400;
    }
  }

  Future<void> _openProductDetails(BuildContext context) async {
    if (message.productId == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Fetch product details
      final apiService = ProductApiService();
      final apiProduct = await apiService.getProductById(
        message.productId!,
        token: token,
      );

      // Convert API product to domain product
      final product = _convertToDomainProduct(apiProduct);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Navigate to product detail screen
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.chatFailedToLoadProduct,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Product _convertToDomainProduct(api_models.Product apiProduct) {
    // Safely handle rating to avoid NaN or Infinity
    double safeRating = 0.0;
    if (apiProduct.rating != null &&
        !apiProduct.rating!.isNaN &&
        !apiProduct.rating!.isInfinite) {
      safeRating = apiProduct.rating!.clamp(0.0, 5.0);
    }

    // Use seller as brand fallback
    String brand = apiProduct.brand;
    if (brand.isEmpty || brand == 'Unknown') {
      brand = apiProduct.seller ?? 'Unknown';
    }

    return Product(
      id: apiProduct.id,
      brand: brand,
      title: apiProduct.title,
      description: apiProduct.description ?? '',
      price: apiProduct.price,
      images: apiProduct.images.isNotEmpty ? apiProduct.images : [''],
      rating: safeRating,
      reviewCount: apiProduct.reviewCount ?? 0,
      category:
          apiProduct.originalCategoryString ??
          apiProduct.category.value, // Use original string if available
      subcategory: apiProduct.subcategory?.map((e) => e.displayName).toList(),
      sizes: apiProduct.sizes ?? [],
      colors: apiProduct.colors ?? [],
      material: apiProduct.material?.map((e) => e.displayName).toList(),
      season: apiProduct.season?.map((e) => e.displayName).toList(),
      currency: apiProduct.currency,
      seller: apiProduct.seller ?? 'Unknown Seller',
      sellerId: apiProduct.sellerId,
      isNew: apiProduct.isNew ?? false,
      isFeatured: apiProduct.isFeatured ?? false,
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
      inStock: apiProduct.inStock,
      titleLocalized: apiProduct.titleLocalized,
      descriptionLocalized: apiProduct.descriptionLocalized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: InkWell(
          onTap: message.productId != null
              ? () => _openProductDetails(context)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: message.productImage!,
                      width: 70,
                      height: 95,
                      fit: BoxFit.cover,
                      cacheManager: ImageCacheManager.instance,
                      memCacheWidth: 140,
                      memCacheHeight: 190,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.productTitle != null ||
                          message.productTitleLocalized != null)
                        Text(
                          message.localizedTitle(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (message.productPrice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(message.productPrice!),
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ],
                      if (message.color != null ||
                          message.size != null ||
                          message.quantity != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (message.color != null) ...[
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${l10n.color}: ',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray600,
                                      ),
                                    ),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _parseColor(message.color!),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.gray300,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (message.size != null ||
                                  message.quantity != null)
                                const SizedBox(width: 6),
                            ],
                            if (message.size != null) ...[
                              Flexible(
                                child: Text(
                                  '${l10n.sizeLabel} ${_formatSizeLabel(message.size!)}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (message.quantity != null)
                                const SizedBox(width: 6),
                            ],
                            if (message.quantity != null)
                              Flexible(
                                child: Text(
                                  '${l10n.qtyLabel} ${message.quantity}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
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
