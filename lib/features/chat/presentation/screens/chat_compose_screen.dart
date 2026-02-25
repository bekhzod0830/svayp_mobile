import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
import 'package:swipe/features/chat/data/services/chat_service.dart';
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';

/// Chat Compose Screen - Compose first message before creating chat
class ChatComposeScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerLogo;
  final String productId;
  final String productTitle;
  final String? productImage;
  final String productBrand;
  final String? color;
  final String? size;
  final String initialMessage;

  const ChatComposeScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerLogo,
    required this.productId,
    required this.productTitle,
    this.productImage,
    required this.productBrand,
    this.color,
    this.size,
    required this.initialMessage,
  });

  @override
  State<ChatComposeScreen> createState() => _ChatComposeScreenState();
}

class _ChatComposeScreenState extends State<ChatComposeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.initialMessage;
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _openProductDetails() async {
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
        widget.productId,
        token: token,
      );

      // Convert API product to domain product
      final product = _convertToDomainProduct(apiProduct);

      // Close loading dialog
      if (mounted) {
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
      print('❌ Error opening product details: $e');
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
      category: apiProduct.category.toString().split('.').last,
      subcategory: apiProduct.subcategory
          ?.map((e) => e.toString().split('.').last)
          .toList(),
      sizes:
          apiProduct.sizes?.map((e) => e.toString().split('.').last).toList() ??
          [],
      colors: apiProduct.colors ?? [],
      material: apiProduct.material
          ?.map((e) => e.toString().split('.').last)
          .toList(),
      season: apiProduct.season
          ?.map((e) => e.toString().split('.').last)
          .toList(),
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
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendAndCreateChat() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final chatService = ChatService(getIt<ApiClient>());
      final request = CreateChatRequest(
        sellerId: widget.sellerId,
        productId: widget.productId,
        subject: '${widget.productBrand} - ${widget.productTitle}',
        message: content,
        color: widget.color,
        size: widget.size,
        quantity: 1,
      );

      print('📱 Creating chat with first message...');
      final chat = await chatService.createChat(request);
      print('✅ Chat created: ${chat.id}');

      if (mounted) {
        // Navigate to the actual chat screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chatId: chat.id),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error creating chat: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create chat: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Seller Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.black, AppColors.gray800],
                ),
              ),
              child: widget.sellerLogo != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.sellerLogo!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            widget.sellerName[0].toUpperCase(),
                            style: AppTypography.body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.sellerName[0].toUpperCase(),
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
                    widget.sellerName,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'New Message',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Spacer to push content to bottom
          const Spacer(),

          // Product Card
          InkWell(
            onTap: _openProductDetails,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray200,
                ),
              ),
              child: Row(
                children: [
                  // Product Image
                  if (widget.productImage != null)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.gray100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: widget.productImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                          widget.productBrand,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productTitle,
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.color != null || widget.size != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (widget.color != null) widget.color,
                              if (widget.size != null) widget.size,
                            ].join(' • '),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.gray600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message Input
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray200,
              ),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              minLines: 4,
              maxLines: 8,
              textAlignVertical: TextAlignVertical.top,
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: AppTypography.body1.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          // Send Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray200,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendAndCreateChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.gray300,
                  ),
                  child: _isSending
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.sendMessage,
                              style: AppTypography.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
