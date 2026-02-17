import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';

/// Message Model
class Message {
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}

/// Chat Detail Screen - Individual conversation with a seller
class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;
  final Product? product;

  const ChatDetailScreen({super.key, required this.chat, this.product});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final List<Message> _messages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Listen to focus changes to update border
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadInitialMessages();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadInitialMessages() async {
    final l10n = AppLocalizations.of(context)!;

    // If product is provided, this is a new chat about availability
    // Pre-fill the text field instead of sending automatically
    if (widget.product != null) {
      _messageController.text = l10n.interestedInProduct;
    } else {
      // Load messages from storage for existing chats
      final savedMessages = await _chatService.getMessages(widget.chat.id);

      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(
            savedMessages.map(
              (m) => Message(
                text: m['text'] as String,
                isSentByMe: m['isSentByMe'] as bool,
                timestamp: DateTime.parse(m['timestamp'] as String),
              ),
            ),
          );
        });
      }
    }

    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // If this is the first message, save the chat
    if (_messages.isEmpty) {
      // Update chat with the actual message being sent
      final updatedChat = widget.chat.copyWith(
        lastMessage: text,
        lastMessageTime: DateTime.now(),
      );
      await _chatService.saveChat(updatedChat);
    }

    setState(() {
      _messages.add(
        Message(text: text, isSentByMe: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
    });

    // Save messages to storage
    await _saveMessages();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate seller response after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _messages.add(
            Message(
              text: l10n.sellerAutoResponse,
              isSentByMe: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        // Save messages after simulated response
        _saveMessages();

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  /// Save messages to storage
  Future<void> _saveMessages() async {
    final messagesData = _messages
        .map(
          (m) => {
            'text': m.text,
            'isSentByMe': m.isSentByMe,
            'timestamp': m.timestamp.toIso8601String(),
          },
        )
        .toList();

    await _chatService.saveMessages(widget.chat.id, messagesData);

    // Update chat with last message
    final updatedChat = widget.chat.copyWith(
      lastMessage: _messages.last.text,
      lastMessageTime: _messages.last.timestamp,
    );
    await _chatService.saveChat(updatedChat);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          onPressed: () {
            // If coming from product, navigate to Orders tab
            if (widget.product != null) {
              // Pop back to MainScreen
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Switch to Orders tab (index 3) and refresh
              MainScreen.globalKey.currentState?.navigateToTab(3);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            // Avatar with gradient
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(widget.chat.sellerName),
                ),
              ),
              child: Center(
                child: Text(
                  widget.chat.sellerAvatar,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.sellerName,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (widget.chat.productName != null)
                    Text(
                      widget.chat.productName!,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product Card (if product info is available)
          if (widget.product != null)
            _ProductCard(product: widget.product!, isDark: isDark)
          else if (widget.chat.productImage != null &&
              widget.chat.productName != null)
            _ChatProductCard(
              productImage: widget.chat.productImage!,
              productName: widget.chat.productName!,
              productPrice: widget.chat.productPrice,
              productOriginalPrice: widget.chat.productOriginalPrice,
              isDark: isDark,
              product: widget.product, // Pass product if available
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message, isDark: isDark);
              },
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.white : AppColors.black)
                      .withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
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
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.white : AppColors.black,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
                      onChanged: (value) {
                        setState(() {}); // Update send button state
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send Button
                GestureDetector(
                  onTap: _messageController.text.trim().isNotEmpty
                      ? _sendMessage
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _messageController.text.trim().isNotEmpty
                          ? (isDark ? AppColors.white : AppColors.black)
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray400),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
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
  final Message message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSentByMe) ...[const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isSentByMe
                    ? (isDark ? AppColors.white : AppColors.black)
                    : (isDark
                          ? AppColors.darkCardBackground
                          : AppColors.gray200),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isSentByMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isSentByMe ? 4 : 20),
                ),
                border: !message.isSentByMe && !isDark
                    ? Border.all(color: AppColors.gray300, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTypography.body2.copyWith(
                      color: message.isSentByMe
                          ? (isDark ? AppColors.black : AppColors.white)
                          : (isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTypography.caption.copyWith(
                      color: message.isSentByMe
                          ? (isDark
                                ? AppColors.black.withOpacity(0.6)
                                : AppColors.white.withOpacity(0.7))
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isSentByMe) ...[const SizedBox(width: 8)],
        ],
      ),
    );
  }
}

/// Product Card Widget - Shows product details at the top of chat
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _ProductCard({required this.product, required this.isDark});

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} UZS';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: isDark ? AppColors.darkMainBackground : Colors.white,
                child: CachedNetworkImage(
                  imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.gray100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? AppColors.darkMainBackground
                        : AppColors.gray100,
                    child: Icon(
                      Icons.image_outlined,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatPrice(product.price),
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatPrice(product.originalPrice!),
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                            decoration: TextDecoration.lineThrough,
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
    );
  }
}

class _ChatProductCard extends StatelessWidget {
  final String productImage;
  final String productName;
  final int? productPrice;
  final int? productOriginalPrice;
  final bool isDark;
  final Product? product; // Optional full product for navigation

  const _ChatProductCard({
    required this.productImage,
    required this.productName,
    this.productPrice,
    this.productOriginalPrice,
    required this.isDark,
    this.product,
  });

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} UZS';
  }

  @override
  Widget build(BuildContext context) {
    // Extract brand from product name (assuming format: "Brand - Product Name")
    final parts = productName.split(' - ');
    final brand = parts.length > 1 ? parts[0] : 'Product';
    final title = parts.length > 1 ? parts.sublist(1).join(' - ') : productName;

    final cardWidget = Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: isDark ? AppColors.darkMainBackground : Colors.white,
              child: CachedNetworkImage(
                imageUrl: productImage,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: isDark
                      ? AppColors.darkMainBackground
                      : AppColors.gray100,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark
                      ? AppColors.darkMainBackground
                      : AppColors.gray100,
                  child: Icon(
                    Icons.image_outlined,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.body2.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (productPrice != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatPrice(productPrice!),
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (productOriginalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatPrice(productOriginalPrice!),
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                            decoration: TextDecoration.lineThrough,
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
    );

    // Make card tappable only if product is available
    if (product != null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product!),
            ),
          );
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
