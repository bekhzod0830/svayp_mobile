import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/chat/presentation/screens/chat_compose_screen.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;

/// Product Detail Screen - Full product information
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  final CartService _cartService = CartService();
  final LikedService _likedService = LikedService();
  final ProductApiService _apiService = ProductApiService();

  String? _selectedSize;
  String? _selectedColor;
  bool _isLiked = false;
  int _quantity = 1;
  int _cartCount = 0;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initServices();

    // Debug: Print product seller information
    print('🏪 Product Seller Info:');
    print('   Seller Name: ${widget.product.seller}');
    print('   Seller ID: ${widget.product.sellerId}');
    print('   Brand: ${widget.product.brand}');
  }

  Future<void> _initServices() async {
    await _cartService.init();
    await _likedService.init();

    // Get authentication token
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    setState(() {
      _isLiked = _likedService.isLiked(widget.product.id);
      _cartCount = _cartService.getTotalQuantity();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final l10n = AppLocalizations.of(context)!;

    // Debug: Print product colors and selected color
    print('🎨 Product colors: ${widget.product.colors}');
    print('🎨 Selected color: $_selectedColor');

    if (_selectedSize == null && widget.product.sizes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectSize),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedColor == null && widget.product.colors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectColor),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Add to local cart first (optimistic update)
    await _cartService.addToCart(
      widget.product,
      selectedSize: _selectedSize ?? l10n.oneSize,
      selectedColor: _selectedColor,
      quantity: _quantity,
    );

    // Send to backend API if authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      try {
        // Convert color from display format ("Light Blue") to backend format ("light_blue")
        // Only send color if one was selected
        final backendColor = _selectedColor != null
            ? _selectedColor!.toLowerCase().replaceAll(' ', '_')
            : null;

        print('🎨 Sending to backend - Color: $backendColor');

        await _apiService.addToCart(
          productId: widget.product.id,
          selectedSize: _selectedSize ?? l10n.oneSize,
          selectedColor: backendColor,
          quantity: _quantity,
          token: _authToken!,
        );

        // Only update cart count after successful API call
        setState(() {
          _cartCount = _cartService.getTotalQuantity();
        });
      } catch (e) {
        // Rollback local cart on API failure
        print('⚠️ Failed to sync cart with backend: $e');

        // Remove the exact item we just added
        await _cartService.removeByMatch(
          productId: widget.product.id,
          selectedSize: _selectedSize ?? l10n.oneSize,
          selectedColor: _selectedColor,
        );

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add to cart. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return; // Exit early, don't show success message
      }
    } else {
      // Not authenticated - just update local cart count
      setState(() {
        _cartCount = _cartService.getTotalQuantity();
      });
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedToCart),
          backgroundColor: AppColors.black,
          action: SnackBarAction(
            label: l10n.viewCart,
            textColor: Colors.white,
            onPressed: () {
              // Navigate to cart screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    final newLikeState = await _likedService.toggleLike(widget.product);
    setState(() {
      _isLiked = newLikeState;
    });

    // Send like/dislike to backend if user is authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      if (_isLiked) {
        // User liked the product
        _apiService
            .likeProduct(productId: widget.product.id, token: _authToken!)
            .catchError((e) {
              print('⚠️ Failed to send like: $e');
            });
      } else {
        // User unliked the product - send dislike
        _apiService
            .dislikeProduct(productId: widget.product.id, token: _authToken!)
            .catchError((e) {
              print('⚠️ Failed to send dislike: $e');
            });
      }
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLiked ? l10n.addedToLikedItems : l10n.removedFromLikedItems,
          ),
          backgroundColor: AppColors.black,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked
                  ? Colors.red
                  : (isDark ? AppColors.darkPrimaryText : AppColors.black),
            ),
            onPressed: _toggleLike,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  size: 28,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                  // Update cart count when returning
                  setState(() {
                    _cartCount = _cartService.getTotalQuantity();
                  });
                },
              ),
              // Badge showing cart item count
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartCount > 99 ? '99+' : _cartCount.toString(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  _buildImageCarousel(),

                  const SizedBox(height: 24),

                  // Product info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(),
                        const SizedBox(height: 16),
                        _buildPriceSection(),
                        const SizedBox(height: 24),
                        _buildSellerSection(),
                        const SizedBox(height: 24),
                        _buildSizeSelector(),
                        if (widget.product.colors.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildColorSelector(),
                        ],
                        const SizedBox(height: 24),
                        _buildQuantitySelector(),
                        const SizedBox(height: 32),
                        _buildDescription(),
                        const SizedBox(height: 24),
                        _buildDetails(),
                        // COMMENTED OUT - Reviews section (for future use)
                        // const SizedBox(height: 24),
                        // _buildReviews(),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageCarousel() {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate responsive image height
    // Mobile: 50% of screen height (max 400px)
    // Tablet/Desktop: 60% of screen height (max 600px)
    final double imageHeight = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: (screenSize.height * 0.5).clamp(300.0, 400.0),
      tablet: (screenSize.height * 0.6).clamp(400.0, 600.0),
      desktop: (screenSize.height * 0.6).clamp(500.0, 700.0),
    );

    return Column(
      children: [
        SizedBox(
          height: imageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              final imagePath = widget.product.images[index];
              // Check if it's a local asset (starts with assets/ or lib/)
              final isAsset =
                  imagePath.startsWith('assets/') ||
                  imagePath.startsWith('lib/');

              return Container(
                color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.contain,
                        cacheManager: ImageCacheManager.instance,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _pageController,
          count: widget.product.images.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: isDark
                ? AppColors.darkPrimaryText
                : AppColors.black,
            dotColor: isDark ? AppColors.darkSecondaryText : AppColors.gray300,
          ),
        ),
      ],
    );
  }

  Widget _buildProductHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.product.brand,
                style: AppTypography.body2.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.product.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(
                      l10n.newLabel,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.black : AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.title,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        // COMMENTED OUT - Rating display (for future use)
        // const SizedBox(height: 8),
        // Row(
        //   children: [
        //     const Icon(Icons.star, color: Colors.amber, size: 20),
        //     const SizedBox(width: 4),
        //     Text(
        //       widget.product.rating.toStringAsFixed(1),
        //       style: AppTypography.body1.copyWith(
        //         fontWeight: FontWeight.w600,
        //         color: theme.colorScheme.onSurface,
        //       ),
        //     ),
        //     const SizedBox(width: 4),
        //     Flexible(
        //       child: Text(
        //         AppLocalizations.of(
        //           context,
        //         )!.reviewsCount(widget.product.reviewCount),
        //         style: AppTypography.body1.copyWith(
        //           color: isDark
        //               ? AppColors.darkSecondaryText
        //               : AppColors.gray600,
        //         ),
        //         maxLines: 1,
        //         overflow: TextOverflow.ellipsis,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDiscount =
        widget.product.discountPercentage != null &&
        widget.product.discountPercentage! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Final price and discount badge in a row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Final price
            Flexible(
              child: Text(
                '${widget.product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${widget.product.currency}',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Discount badge next to final price
            if (hasDiscount) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-${widget.product.discountPercentage}%',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Original price below (strikethrough)
        if (hasDiscount) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.product.originalPrice?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${widget.product.currency}',
            style: AppTypography.heading4.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSellerSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Use seller field if available, otherwise fall back to brand, or SVAYP as final fallback
    String sellerName = widget.product.seller ?? widget.product.brand;
    // If still "Unknown" or empty, use SVAYP as default
    if (sellerName == 'Unknown' || sellerName.isEmpty) {
      sellerName = 'SVAYP';
    }

    // Get sellerId - use the sellerId field if available
    final sellerId = widget.product.sellerId;

    return GestureDetector(
      onTap: () {
        if (sellerId != null) {
          _navigateToSellerProfile(sellerId, sellerName);
        } else {
          // Show message if no sellerId available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seller information not available yet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
          ),
        ),
        child: Row(
          children: [
            // Seller Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(sellerName),
                ),
              ),
              child: Center(
                child: Text(
                  sellerName[0].toUpperCase(),
                  style: AppTypography.heading4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Seller Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.visitShop,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
          ],
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

  Widget _buildSizeSelector() {
    if (widget.product.sizes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.size,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.product.sizes.map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                });
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
                        : (isDark
                              ? AppColors.darkStandardBorder
                              : AppColors.gray300),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
                      : (isDark
                            ? AppColors.darkCardBackground
                            : AppColors.white),
                ),
                child: Center(
                  child: Text(
                    size,
                    style: AppTypography.body2.copyWith(
                      color: isSelected
                          ? (isDark ? AppColors.black : AppColors.white)
                          : (isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.color,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.product.colors.map((color) {
            final isSelected = _selectedColor == color;
            final isHexColor = color.startsWith('#');

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: isHexColor
                  ? _buildHexColorSwatch(color, isSelected, isDark)
                  : _buildTextColorOption(color, isSelected, isDark, theme),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHexColorSwatch(String hexColor, bool isSelected, bool isDark) {
    Color color;
    try {
      color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
              : (isDark ? AppColors.darkStandardBorder : AppColors.gray300),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isDark ? AppColors.darkPrimaryText : AppColors.black)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? Icon(Icons.check, color: _getContrastColor(color), size: 24)
          : null,
    );
  }

  Widget _buildTextColorOption(
    String color,
    bool isSelected,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
              : (isDark ? AppColors.darkStandardBorder : AppColors.gray300),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
            : (isDark ? AppColors.darkCardBackground : AppColors.white),
      ),
      child: Text(
        color,
        style: AppTypography.body2.copyWith(
          color: isSelected
              ? (isDark ? AppColors.black : AppColors.white)
              : (isDark ? AppColors.darkPrimaryText : AppColors.black),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need dark or light text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildQuantitySelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quantity,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuantityButton(
              icon: Icons.remove,
              onPressed: () {
                if (_quantity > 1) {
                  setState(() {
                    _quantity--;
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            Text(
              _quantity.toString(),
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            _QuantityButton(
              icon: Icons.add,
              onPressed: () {
                if (_quantity < 10) {
                  setState(() {
                    _quantity++;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.description,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.description,
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productDetails,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: l10n.category,
          value: _getTranslatedCategory(widget.product.category, l10n),
        ),
        if (widget.product.subcategory != null &&
            widget.product.subcategory!.isNotEmpty)
          _DetailRow(
            label: l10n.subcategory,
            value: widget.product.subcategory!.join(', '),
          ),
        if (widget.product.material != null &&
            widget.product.material!.isNotEmpty)
          _DetailRow(
            label: l10n.material,
            value: widget.product.material!.join(', '),
          ),
        if (widget.product.season != null && widget.product.season!.isNotEmpty)
          _DetailRow(
            label: l10n.season,
            value: widget.product.season!.join(', '),
          ),
        if (widget.product.countryOfOrigin != null &&
            widget.product.countryOfOrigin!.isNotEmpty)
          _DetailRow(
            label: l10n.countryOfOrigin,
            value: widget.product.countryOfOrigin!,
          ),
        _DetailRow(
          label: l10n.availability,
          value: widget.product.inStock ? l10n.inStock : l10n.outOfStock,
        ),
        if (widget.product.fitMatch != null)
          _DetailRow(label: l10n.fitMatch, value: widget.product.fitMatch!),
        if (widget.product.styleMatch != null)
          _DetailRow(label: l10n.styleMatch, value: widget.product.styleMatch!),
      ],
    );
  }

  /// Translate category from enum value to localized string
  String _getTranslatedCategory(String categoryValue, AppLocalizations l10n) {
    // Convert category value to translated string
    // Handle both lowercase enum values and display names
    final lowerValue = categoryValue.toLowerCase().trim();

    switch (lowerValue) {
      case 'dress':
      case 'dresses':
        return l10n.categoryDress;
      case 'hijab':
      case 'hijabs':
        return l10n.categoryHijab;
      case 'abaya':
      case 'abayas':
        return l10n.categoryAbaya;
      case 'tunic':
      case 'tunics':
        return l10n.categoryTunic;
      case 'top':
      case 'tops':
        return l10n.categoryTop;
      case 'blouse':
      case 'blouses':
        return l10n.categoryBlouse;
      case 'shirt':
      case 'shirts':
        return l10n.categoryShirt;
      case 'pants':
        return l10n.categoryPants;
      case 'jeans':
        return l10n.categoryJeans;
      case 'skirt':
      case 'skirts':
        return l10n.categorySkirt;
      case 'jacket':
      case 'jackets':
        return l10n.categoryJacket;
      case 'coat':
      case 'coats':
        return l10n.categoryCoat;
      case 'cardigan':
      case 'cardigans':
        return l10n.categoryCardigan;
      case 'sweater':
      case 'sweaters':
        return l10n.categorySweater;
      case 'activewear':
        return l10n.categoryActivewear;
      case 'jumpsuit':
      case 'jumpsuits':
        return l10n.categoryJumpsuit;
      case 'scarf':
      case 'scarves':
      case 'scarfs':
        return l10n.categoryScarf;
      case 'shawl':
      case 'shawls':
        return l10n.categoryShawl;
      case 'accessories':
      case 'accessory':
        return l10n.categoryAccessories;
      case 'shoes':
      case 'shoe':
        return l10n.categoryShoes;
      case 'bags':
      case 'bag':
        return l10n.categoryBags;
      case 'jewelry':
      case 'jewellery':
        return l10n.categoryJewelry;
      case 'underwear':
        return l10n.categoryUnderwear;
      case 'outerwear':
        return l10n.categoryOuterwear;
      default:
        // Fallback to capitalized value if translation not found
        return categoryValue[0].toUpperCase() + categoryValue.substring(1);
    }
  }

  /// Navigate to seller profile with all their products
  Future<void> _navigateToSellerProfile(
    String sellerId,
    String sellerName,
  ) async {
    print('🔍 Navigating to seller profile: $sellerName (ID: $sellerId)');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCardBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkPrimaryText
                    : AppColors.black,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading seller products...',
                style: AppTypography.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      print('📡 Fetching seller details from API...');

      // Fetch seller details using the seller detail endpoint
      final response = await _apiService
          .getBrandDetail(brandId: sellerId, token: _authToken)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ API request timed out');
              throw Exception('Request timed out');
            },
          );

      print(
        '✅ Received ${response.products.length} products for seller: $sellerName (ID: $sellerId)',
      );

      // Convert API products to local Product entities
      final sellerProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          sellerProducts.add(product);
        } catch (e) {
          print('❌ Failed to convert product: ${apiProduct.id}, error: $e');
        }
      }

      print(
        '🎯 Converted ${sellerProducts.length} products for seller: $sellerName (ID: $sellerId)',
      );

      // Close loading dialog - try multiple methods to ensure it closes
      if (mounted) {
        // First try popping with root navigator
        try {
          Navigator.of(context, rootNavigator: true).pop();
          print('✓ Dialog closed with rootNavigator');
        } catch (e) {
          print('Failed to close with rootNavigator: $e');
          // Fallback to regular pop
          try {
            Navigator.of(context).pop();
            print('✓ Dialog closed with regular navigator');
          } catch (e2) {
            print('Failed to close with regular navigator: $e2');
          }
        }
      }

      // Wait for dialog to fully close
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to seller profile if we have products
      if (mounted) {
        if (sellerProducts.isEmpty) {
          print('⚠️ No products found for seller');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No products found for $sellerName'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print('🚀 Navigating to seller profile screen');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SellerProfileScreen(
              sellerId: sellerId,
              sellerName: sellerName,
              products: sellerProducts,
            ),
          ),
        );
        print('✅ Returned from seller profile screen');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _navigateToSellerProfile: $e');
      print('Stack trace: $stackTrace');

      // Close loading dialog - use root navigator to ensure it closes
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (popError) {
          print('Error closing dialog: $popError');
        }
      }

      // Small delay before showing error
      await Future.delayed(const Duration(milliseconds: 100));

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading seller products: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Convert API product model to local Product entity
  Product _convertApiProduct(api_models.Product apiProduct) {
    // Use seller if brand is "Unknown" or if seller is available
    final displayBrand =
        (apiProduct.brand == 'Unknown' || apiProduct.brand.isEmpty)
        ? (apiProduct.seller ?? apiProduct.brand)
        : apiProduct.brand;

    return Product(
      id: apiProduct.id,
      title: apiProduct.title,
      description: apiProduct.description ?? '',
      price: apiProduct.price,
      brand: displayBrand,
      category:
          apiProduct.originalCategoryString ??
          apiProduct.category.value, // Use original string if available
      subcategory: apiProduct.subcategory?.map((s) => s.displayName).toList(),
      images: apiProduct.images.isNotEmpty
          ? apiProduct.images
          : ['placeholder'],
      sizes: apiProduct.sizes?.map((size) => size.displayName).toList() ?? [],
      colors: apiProduct.colors ?? [],
      material: apiProduct.material?.map((m) => m.displayName).toList(),
      season: apiProduct.season?.map((s) => s.displayName).toList(),
      currency: apiProduct.currency,
      rating: apiProduct.rating ?? 4.5,
      reviewCount: apiProduct.reviewCount ?? 0,
      isNew: apiProduct.isNew ?? false,
      isFeatured: apiProduct.isFeatured ?? false,
      inStock: apiProduct.inStock,
      seller: apiProduct.seller,
      sellerId: apiProduct.sellerId,
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
      countryOfOrigin: apiProduct.countryOfOrigin,
    );
  }

  // COMMENTED OUT - Reviews section (for future use)
  // Widget _buildReviews() {
  //   final theme = Theme.of(context);
  //   final isDark = theme.brightness == Brightness.dark;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             AppLocalizations.of(context)!.reviews,
  //             style: AppTypography.body1.copyWith(
  //               fontWeight: FontWeight.w600,
  //               color: theme.colorScheme.onSurface,
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               // TODO: Navigate to reviews screen
  //             },
  //             child: Text(
  //               AppLocalizations.of(context)!.seeAll,
  //               style: AppTypography.body1.copyWith(
  //                 color: isDark ? AppColors.darkPrimaryText : AppColors.black,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 const Icon(Icons.star, color: Colors.amber, size: 16),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   widget.product.rating.toStringAsFixed(1),
  //                   style: AppTypography.body1.copyWith(
  //                     fontWeight: FontWeight.w600,
  //                     color: theme.colorScheme.onSurface,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   '${widget.product.reviewCount} reviews',
  //                   style: AppTypography.caption.copyWith(
  //                     color: isDark
  //                         ? AppColors.darkSecondaryText
  //                         : AppColors.gray600,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               AppLocalizations.of(context)!.customerReviewPrompt,
  //               style: AppTypography.caption.copyWith(color: AppColors.gray600),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to chat compose screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatComposeScreen(
                        sellerId: widget.product.sellerId ?? 'default-seller',
                        sellerName: widget.product.seller ?? 'Seller',
                        sellerLogo: null, // Add seller logo if available
                        productId: widget.product.id,
                        productTitle: widget.product.title,
                        productImage: widget.product.images.isNotEmpty
                            ? widget.product.images[0]
                            : null,
                        productBrand: widget.product.brand,
                        color: widget.product.colors.isNotEmpty
                            ? widget.product.colors[0]
                            : null,
                        size: widget.product.sizes.isNotEmpty
                            ? widget.product.sizes[0]
                            : null,
                        initialMessage: l10n.interestedInProduct,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    width: 1.5,
                  ),
                  foregroundColor: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.checkAvailability,
                  style: AppTypography.body1.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.black,
                  foregroundColor: isDark ? AppColors.black : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.addToCart,
                  style: AppTypography.body1.copyWith(
                    color: isDark ? AppColors.black : AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: isDark ? AppColors.darkPrimaryText : AppColors.black,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body2.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
