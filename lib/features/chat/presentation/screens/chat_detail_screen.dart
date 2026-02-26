import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/data/services/chat_websocket_service.dart';
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

/// Chat Detail Screen - Individual conversation with a seller
class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final ChatService _chatService;
  late final ChatWebSocketService _webSocketService;
  late final String _currentUserId;
  StreamSubscription<ChatMessageResponse>? _messageSubscription;
  Timer? _pollingTimer;

  ChatResponse? _chat;
  List<ChatMessageResponse> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isInitialized = false;
  bool _isWebSocketConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(getIt<ApiClient>());
    _webSocketService = ChatWebSocketService();
    _focusNode.addListener(() => setState(() {}));
    if (!_isInitialized) {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    try {
      // Get current user ID
      final authService = getIt<AuthService>();
      final currentUser = await authService.getCurrentUser();
      _currentUserId = currentUser.id;

      // Load chat and messages
      await _loadChat();
      await _loadMessages();

      // Mark as read
      await _chatService.markAsRead(widget.chatId);

      // Start polling for new messages (WebSocket not available on backend yet)
      _startPolling();

      _isInitialized = true;
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load chat: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _startPolling() {
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final messages = await _chatService.getMessages(widget.chatId);
        if (!mounted) return;

        final reversedMessages = messages.reversed.toList();

        // Check if there are new messages
        if (reversedMessages.length > _messages.length) {
          setState(() {
            _messages = reversedMessages;
          });

          // Scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Mark as read
          _chatService.markAsRead(widget.chatId);
        }
      } catch (e) {}
    });
  }

  Future<void> _loadChat() async {
    try {
      final chat = await _chatService.getChat(widget.chatId);
      if (mounted) {
        setState(() {
          _chat = chat;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(widget.chatId);

      if (mounted) {
        setState(() {
          // Messages come newest first from API, reverse for chat display
          _messages = messages.reversed.toList();
          _isLoading = false;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final request = SendMessageRequest(
        content: content,
        type: MessageType.text,
      );

      // Send via REST API
      final newMessage = await _chatService.sendMessage(widget.chatId, request);

      if (mounted) {
        setState(() {
          // Only add message if not already in list (in case WebSocket also delivered it)
          final exists = _messages.any((m) => m.id == newMessage.id);
          if (!exists) {
            _messages.add(newMessage);
          }
          _messageController.clear();
          _isSending = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageSubscription?.cancel();
    _webSocketService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkCardBackground
              : AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.loading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _chat == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkCardBackground
              : AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.gray400),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Chat not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(_chat!.sellerName),
                ),
              ),
              child: Center(
                child: Text(
                  _chat!.sellerName.isNotEmpty
                      ? _chat!.sellerName[0].toUpperCase()
                      : 'S',
                  style: AppTypography.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Seller info
            Expanded(
              child: Text(
                _chat!.sellerName,
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // WebSocket connection indicator
          if (_isWebSocketConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Real-time messaging active',
                child: Icon(Icons.sync, size: 20, color: Colors.green),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      l10n.noMessagesYet,
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray600,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.senderId == _currentUserId;

                      // Render based on message type
                      if (message.messageType == MessageType.product) {
                        return _ProductMessageBubble(
                          message: message,
                          isDark: isDark,
                        );
                      }

                      return _MessageBubble(
                        message: message,
                        isMine: isMine,
                        isDark: isDark,
                        senderName: message.senderName,
                      );
                    },
                  ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkMainBackground
                          : AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      hintStyle: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray600,
                      ),
                    ),
                    style: AppTypography.body2.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                GestureDetector(
                  onTap:
                      _messageController.text.trim().isNotEmpty && !_isSending
                      ? _sendMessage
                      : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          _messageController.text.trim().isNotEmpty &&
                              !_isSending
                          ? (isDark ? AppColors.white : AppColors.black)
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray400),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.black : AppColors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: _messageController.text.trim().isNotEmpty
                                ? (isDark ? AppColors.black : AppColors.white)
                                : (isDark
                                      ? AppColors.darkMainBackground
                                      : AppColors.gray600),
                            size: 20,
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

/// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final ChatMessageResponse message;
  final bool isMine;
  final bool isDark;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.senderName,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(senderName),
        ),
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar on left for other person's messages
          if (!isMine) ...[_buildAvatar(), const SizedBox(width: 8)],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMine
                    ? (isDark ? AppColors.white : AppColors.black)
                    : (isDark ? AppColors.darkCardBackground : AppColors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: !isMine
                    ? Border.all(
                        color: isDark
                            ? AppColors.darkStandardBorder
                            : AppColors.gray300,
                        width: 1,
                      )
                    : null,
                boxShadow: !isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTypography.body2.copyWith(
                      color: isMine
                          ? (isDark ? AppColors.black : AppColors.white)
                          : (isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
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
                ],
              ),
            ),
          ),
          // Avatar on right for my messages
          if (isMine) ...[const SizedBox(width: 8), _buildAvatar()],
        ],
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
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    return '$formatted UZS';
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
        Navigator.push(
          context,
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
            content: Text('Failed to load product details'),
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
      sizes: apiProduct.sizes?.map((e) => e.displayName).toList() ?? [],
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
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      cacheManager: ImageCacheManager.instance,
                      memCacheWidth: 120,
                      memCacheHeight: 160,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.productTitle != null)
                        Text(
                          message.productTitle!,
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
                        Row(
                          children: [
                            Text(
                              _formatPrice(message.productPrice!),
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.black,
                              ),
                            ),
                            if (message.color != null ||
                                message.size != null ||
                                message.quantity != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.gray600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Row(
                                  children: [
                                    if (message.color != null) ...[
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
                                      const SizedBox(width: 6),
                                    ],
                                    if (message.size != null) ...[
                                      Flexible(
                                        child: Text(
                                          '${l10n.sizeLabel} ${message.size}',
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
                              ),
                            ],
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
