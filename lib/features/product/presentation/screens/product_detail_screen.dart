import 'package:flutter/material.dart';
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
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
  SellerInfo? _sellerInfo;
  bool _isLoadingSellerInfo = false;

  @override
  void initState() {
    super.initState();
    _initServices();

    // Debug: Print product seller information
  }

  Future<void> _initServices() async {
    await _cartService.init();
    await _likedService.init();

    // Get authentication token from ApiClient (authoritative source)
    _authToken = getIt<ApiClient>().getToken();

    // Auto-select size when there's only one option or it's a universal size
    // (e.g. "One Size", "Free Size") — no real choice to make
    final sizes = widget.product.sizes;
    final universalSizes = {'One Size', 'Free Size', 'one_size', 'free_size'};
    String? autoSize;
    if (sizes.length == 1) {
      autoSize = sizes.first;
    } else if (sizes.isNotEmpty &&
        sizes.every((s) => universalSizes.contains(s))) {
      autoSize = sizes.first;
    }

    // Auto-select color when there's only one option
    final colors = widget.product.colors;
    final String? autoColor = colors.length == 1 ? colors.first : null;

    setState(() {
      _isLiked = _likedService.isLiked(widget.product.id);
      if (autoSize != null) _selectedSize = autoSize;
      if (autoColor != null) _selectedColor = autoColor;
    });

    // Update cart count from API
    await _updateCartCount();

    // Fetch seller info (logo + locations) in background
    final sellerId = widget.product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      setState(() => _isLoadingSellerInfo = true);
      _apiService
          .getSeller(sellerId: sellerId, token: _authToken)
          .then((info) {
            if (mounted) {
              setState(() {
                _sellerInfo = info;
                _isLoadingSellerInfo = false;
              });
            }
          })
          .catchError((e) {
            if (mounted) setState(() => _isLoadingSellerInfo = false);
          });
    }
  }

  Future<void> _updateCartCount() async {
    if (!mounted) return;

    try {
      // If user is authenticated, fetch cart count from API (source of truth)
      if (_authToken != null && _authToken!.isNotEmpty) {
        final cartData = await _apiService.getCart(token: _authToken!);
        final summary = cartData['summary'] as Map<String, dynamic>;
        final totalItems = summary['total_items'] as int;

        if (!mounted) return;
        setState(() {
          _cartCount = totalItems;
        });
      } else {
        // Fallback to local storage if not authenticated
        await _cartService.init();
        if (!mounted) return;
        setState(() {
          _cartCount = _cartService.getTotalQuantity();
        });
      }
    } catch (e) {
      // If API call fails, fallback to local storage
      await _cartService.init();
      if (!mounted) return;
      setState(() {
        _cartCount = _cartService.getTotalQuantity();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final l10n = AppLocalizations.of(context)!;

    // Gate for guest users
    final storage = await LocalStorageHelper.getInstance();
    if (storage.isGuestMode()) {
      if (mounted) GuestLoginPrompt.show(context);
      return;
    }

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
        // Use sizes directly as strings (no enum conversion needed)
        final backendSize = _selectedSize ?? 'One Size';
        final backendColor = _selectedColor;

        await _apiService.addToCart(
          productId: widget.product.id,
          selectedSize: backendSize,
          selectedColor: backendColor,
          quantity: _quantity,
          token: _authToken!,
        );

        // Only update cart count after successful API call
        await _updateCartCount();
      } catch (e) {
        // Rollback local cart on API failure

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
      await _updateCartCount();
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(l10n.addedToCart),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
                child: Text(
                  l10n.viewCart,
                  style: const TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.black,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
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
            .catchError((e) {});
      } else {
        // User unliked the product - send dislike
        _apiService
            .dislikeProduct(productId: widget.product.id, token: _authToken!)
            .catchError((e) {});
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
                  // Gate for guest users
                  final storage = await LocalStorageHelper.getInstance();
                  if (storage.isGuestMode()) {
                    if (mounted) GuestLoginPrompt.show(context);
                    return;
                  }
                  if (!mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                  // Update cart count when returning
                  await _updateCartCount();
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
                        if (widget.product.colors.isNotEmpty) ...[
                          _buildColorSelector(),
                          const SizedBox(height: 24),
                        ],
                        _buildSizeSelector(),
                        const SizedBox(height: 24),
                        _buildQuantitySelector(),
                        const SizedBox(height: 32),
                        _buildDescription(),
                        const SizedBox(height: 24),
                        _buildDetails(),
                        const SizedBox(height: 24),
                        _buildLocationsSection(),
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final cacheWidth = (constraints.maxWidth * 2).toInt();
                          return CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.contain,
                            cacheManager: ImageCacheManager.instance,
                            memCacheWidth: cacheWidth,
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
                          );
                        },
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
        Text(
          widget.product.brand,
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.localizedTitle(
            Localizations.localeOf(context).languageCode,
          ),
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
                widget.product.formattedPrice,
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
            widget.product.formattedDiscountPrice ?? '',
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
      onTap: () async {
        // Gate for guest users
        final storage = await LocalStorageHelper.getInstance();
        if (storage.isGuestMode()) {
          if (mounted) GuestLoginPrompt.show(context);
          return;
        }
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
            // Seller Avatar - show logo if available, fallback to gradient
            Builder(
              builder: (_) {
                final logoUrl = _sellerInfo?.logoImg;
                if (logoUrl != null && logoUrl.isNotEmpty) {
                  return ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _buildAvatarFallback(sellerName, isDark),
                      errorWidget: (_, __, ___) =>
                          _buildAvatarFallback(sellerName, isDark),
                    ),
                  );
                }
                return _buildAvatarFallback(sellerName, isDark);
              },
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

  /// Format size label by removing SIZE_ prefix for numeric sizes
  String _formatSizeLabel(String size) {
    // Remove SIZE_ prefix if present (e.g., "SIZE_46" -> "46")
    if (size.toUpperCase().startsWith('SIZE_')) {
      return size.substring(5);
    }
    return size;
  }

  Widget _buildSizeSelector() {
    if (widget.product.sizes.isEmpty) return const SizedBox.shrink();
    // Hide selector for universal sizes — they're auto-selected, no chip needed
    final universalSizes = {'One Size', 'Free Size', 'one_size', 'free_size'};
    if (widget.product.sizes.every((s) => universalSizes.contains(s))) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasStdSize = widget.product.sizes.any(
      (s) => s.toUpperCase() == 'STD',
    );

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
                constraints: const BoxConstraints(
                  minWidth: 56,
                  maxWidth: 80,
                  minHeight: 56,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
                        : (isDark
                              ? AppColors.darkStandardBorder
                              : AppColors.gray400),
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
                    _formatSizeLabel(size),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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
        if (hasStdSize) ...[
          const SizedBox(height: 8),
          Text(
            'STD = Standard',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
                // Navigate to the corresponding image index
                final colorIndex = widget.product.colors.indexOf(color);
                if (colorIndex >= 0 &&
                    colorIndex < widget.product.images.length &&
                    _pageController.hasClients) {
                  _pageController.animateToPage(
                    colorIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
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
                  color: isDark
                      ? const Color(
                          0x4DFFFFFF,
                        ) // darkPrimaryText.withOpacity(0.3)
                      : const Color(0x4D000000), // black.withOpacity(0.3)
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
          widget.product.localizedDescription(
            Localizations.localeOf(context).languageCode,
          ),
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
            value: widget.product.material!
                .map((m) => _getTranslatedMaterial(m, l10n))
                .join(', '),
          ),
        if (widget.product.season != null && widget.product.season!.isNotEmpty)
          _DetailRow(
            label: l10n.season,
            value: widget.product.season!
                .map((s) => _translateSeason(s, l10n))
                .join(', '),
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

  /// Translate season value to localized string
  String _translateSeason(String value, AppLocalizations l10n) {
    switch (value.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'spring':
        return l10n.seasonSpring;
      case 'summer':
        return l10n.seasonSummer;
      case 'fall':
      case 'autumn':
        return l10n.seasonFall;
      case 'winter':
        return l10n.seasonWinter;
      case 'all_season':
      case 'all season':
        return l10n.seasonAllSeason;
      default:
        return value[0].toUpperCase() + value.substring(1);
    }
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
      case 'topwear':
        return l10n.categoryTopwear;
      case 'bottomwear':
        return l10n.categoryBottomwear;
      case 'one-piece':
      case 'one_piece':
      case 'onepiece':
        return l10n.categoryOnePiece;
      case 'islamic_modest_wear':
      case 'islamic/modest wear':
      case 'islamic wear':
      case 'modest wear':
        return l10n.categoryIslamicModestWear;
      case 'footwear':
        return l10n.categoryFootwear;
      case 'two-piece set':
      case 'two_piece_set':
      case 'two piece set':
        return l10n.categoryTwoPieceSet;
      case 'three-piece set':
      case 'three_piece_set':
      case 'three piece set':
        return l10n.categoryThreePieceSet;
      case 'bodysuits_triko':
      case 'bodysuits & triko':
      case 'bodysuits':
      case 'triko':
        return l10n.categoryBodysuitsTriko;
      case 'homewear':
        return l10n.categoryHomewear;
      default:
        // Fallback to capitalized value if translation not found
        return categoryValue[0].toUpperCase() + categoryValue.substring(1);
    }
  }

  /// Translate material from enum value to localized string
  String _getTranslatedMaterial(String materialValue, AppLocalizations l10n) {
    final lowerValue = materialValue.toLowerCase().trim();

    switch (lowerValue) {
      case 'cotton':
        return l10n.materialCotton;
      case 'polyester':
        return l10n.materialPolyester;
      case 'silk':
        return l10n.materialSilk;
      case 'linen':
        return l10n.materialLinen;
      case 'wool':
        return l10n.materialWool;
      case 'chiffon':
        return l10n.materialChiffon;
      case 'satin':
        return l10n.materialSatin;
      case 'velvet':
        return l10n.materialVelvet;
      case 'denim':
        return l10n.materialDenim;
      case 'leather':
        return l10n.materialLeather;
      case 'suede':
        return l10n.materialSuede;
      case 'jersey':
        return l10n.materialJersey;
      case 'modal':
        return l10n.materialModal;
      case 'rayon':
        return l10n.materialRayon;
      case 'spandex':
        return l10n.materialSpandex;
      case 'lycra':
        return l10n.materialLycra;
      case 'nylon':
        return l10n.materialNylon;
      case 'viscose':
        return l10n.materialViscose;
      case 'bamboo':
        return l10n.materialBamboo;
      case 'cashmere':
        return l10n.materialCashmere;
      case 'mixed':
        return l10n.materialMixed;
      default:
        // Fallback to capitalized value if translation not found
        return materialValue[0].toUpperCase() + materialValue.substring(1);
    }
  }

  /// Navigate to seller profile with all their products
  Future<void> _navigateToSellerProfile(
    String sellerId,
    String sellerName,
  ) async {
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
      // Fetch seller details using the seller detail endpoint
      final response = await _apiService
          .getBrandDetail(brandId: sellerId, token: _authToken)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      // Convert API products to local Product entities
      final sellerProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          sellerProducts.add(product);
        } catch (e) {}
      }

      // Close loading dialog - try multiple methods to ensure it closes
      if (mounted) {
        // First try popping with root navigator
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          // Fallback to regular pop
          try {
            Navigator.of(context).pop();
          } catch (e2) {}
        }
      }

      // Wait for dialog to fully close
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to seller profile if we have products
      if (mounted) {
        if (sellerProducts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No products found for $sellerName'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SellerProfileScreen(
              sellerId: sellerId,
              sellerName: sellerName,
              products: sellerProducts,
              sellerInfo: _sellerInfo,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog - use root navigator to ensure it closes
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (popError) {}
      }

      // Small delay before showing error
      await Future.delayed(const Duration(milliseconds: 100));

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Could not load seller products. Please try again.',
            ),
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
      sizes: apiProduct.sizes ?? [],
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
      titleLocalized: apiProduct.titleLocalized,
      descriptionLocalized: apiProduct.descriptionLocalized,
    );
  }

  // COMMENTED OUT - Reviews section (for future use)
  // Widget _buildReviews() {

  /// Gradient circle avatar – used as fallback when no logo is available
  Widget _buildAvatarFallback(String name, bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(name),
        ),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: AppTypography.heading4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // WHERE TO BUY – seller location map section
  // ──────────────────────────────────────────────────────────

  Widget _buildLocationsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locations = _sellerInfo?.locations ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.whereToBuy,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildSellerSection(),
        const SizedBox(height: 12),
        if (_isLoadingSellerInfo)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
          )
        else if (locations.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
                const SizedBox(width: 10),
                Text(
                  'Contact the seller for store location',
                  style: AppTypography.body2.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
              ],
            ),
          )
        else
          ...locations.map(_buildLocationCard),
      ],
    );
  }

  Widget _buildLocationCard(SellerLocation location) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + primary badge
                if (location.name != null && location.name!.isNotEmpty)
                  Text(
                    location.name!,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                // Address
                if (location.address != null &&
                    location.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.address!,
                          style: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Phone
                if (location.phoneNumber != null &&
                    location.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _callPhone(location.phoneNumber!),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.phoneNumber!,
                          style: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Directions button – always shown if any location info exists
                if (location.hasCoordinates ||
                    (location.address != null &&
                        location.address!.isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openInMapsOrAddress(
                      location.latitude,
                      location.longitude,
                      location.address,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_outlined,
                            size: 16,
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.getDirections,
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.black : AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMapsOrAddress(
    double? lat,
    double? lon,
    String? address,
  ) async {
    Uri uri;
    if (lat != null && lon != null) {
      // Use coordinates — format so it always drops a visible pin
      final latStr = lat.toStringAsFixed(6);
      final lonStr = lon.toStringAsFixed(6);
      uri = Platform.isIOS
          ? Uri.parse(
              'https://maps.apple.com/?ll=$latStr,$lonStr&q=$latStr,$lonStr',
            )
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$latStr,$lonStr',
            );
    } else if (address != null && address.isNotEmpty) {
      final encoded = Uri.encodeQueryComponent(address);
      uri = Platform.isIOS
          ? Uri.parse('https://maps.apple.com/?q=$encoded')
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$encoded',
            );
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
            color: isDark
                ? const Color(0x0DFFFFFF) // white.withOpacity(0.05)
                : const Color(0x0D000000), // black.withOpacity(0.05)
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
                onPressed: () async {
                  // Gate for guest users
                  final storage = await LocalStorageHelper.getInstance();
                  if (storage.isGuestMode()) {
                    if (mounted) GuestLoginPrompt.show(context);
                    return;
                  }
                  // Navigate to chat compose screen
                  if (!mounted) return;
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
                        color: _selectedColor,
                        size: _selectedSize,
                        quantity: _quantity,
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
