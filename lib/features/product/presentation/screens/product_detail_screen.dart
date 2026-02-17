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
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:swipe/features/chat/data/models/chat_model.dart';
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

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _cartService.init();
    await _likedService.init();
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

    await _cartService.addToCart(
      widget.product,
      selectedSize: _selectedSize ?? l10n.oneSize,
      selectedColor: _selectedColor,
      quantity: _quantity,
    );

    // Update cart count
    setState(() {
      _cartCount = _cartService.getTotalQuantity();
    });

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
                        const SizedBox(height: 24),
                        _buildReviews(),
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              widget.product.rating.toStringAsFixed(1),
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(
                context,
              )!.reviewsCount(widget.product.reviewCount),
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        if (widget.product.discountPercentage != null) ...[
          Text(
            '${widget.product.originalPrice?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UZS',
            style: AppTypography.heading4.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          '${widget.product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UZS',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (widget.product.discountPercentage != null) ...[
          const SizedBox(width: 12),
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
    );
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
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                child: Text(
                  color,
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
            );
          }).toList(),
        ),
      ],
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.productDetails,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: AppLocalizations.of(context)!.category,
          value: widget.product.category,
        ),
        if (widget.product.seller != null)
          _SellerRow(
            label: AppLocalizations.of(context)!.seller,
            value: widget.product.seller!,
            onTap: () => _navigateToSellerProfile(widget.product.seller!),
          ),
        _DetailRow(
          label: AppLocalizations.of(context)!.availability,
          value: widget.product.inStock
              ? AppLocalizations.of(context)!.inStock
              : AppLocalizations.of(context)!.outOfStock,
        ),
        if (widget.product.fitMatch != null)
          _DetailRow(
            label: AppLocalizations.of(context)!.fitMatch,
            value: widget.product.fitMatch!,
          ),
        if (widget.product.styleMatch != null)
          _DetailRow(
            label: AppLocalizations.of(context)!.styleMatch,
            value: widget.product.styleMatch!,
          ),
      ],
    );
  }

  /// Navigate to seller profile with all their products
  Future<void> _navigateToSellerProfile(String sellerName) async {
    print('🔍 Navigating to seller profile: $sellerName');

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
      print('📡 Fetching products from API...');

      // Fetch all products with timeout
      final response = await _apiService
          .getProducts(skip: 0, limit: 100)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ API request timed out');
              throw Exception('Request timed out');
            },
          );

      print('✅ Received ${response.products.length} products from API');

      // Filter products by seller
      final sellerProducts = <Product>[];
      for (final apiProduct in response.products) {
        if (apiProduct.seller == sellerName) {
          try {
            final product = _convertApiProduct(apiProduct);
            sellerProducts.add(product);
          } catch (e) {
            print('❌ Failed to convert product: ${apiProduct.id}, error: $e');
          }
        }
      }

      print(
        '🎯 Found ${sellerProducts.length} products for seller: $sellerName',
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
    return Product(
      id: apiProduct.id,
      title: apiProduct.title,
      description: apiProduct.description ?? '',
      price: apiProduct.price,
      brand: apiProduct.brand,
      category: apiProduct.category.displayName,
      images: apiProduct.images.isNotEmpty
          ? apiProduct.images
          : ['placeholder'],
      sizes: apiProduct.sizes?.map((size) => size.displayName).toList() ?? [],
      colors:
          apiProduct.colors?.map((color) => color.displayName).toList() ?? [],
      rating: apiProduct.rating ?? 4.5,
      reviewCount: apiProduct.reviewCount ?? 0,
      isNew: apiProduct.isNew ?? false,
      isFeatured: apiProduct.isFeatured ?? false,
      inStock: apiProduct.inStock,
      seller: apiProduct.seller,
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
    );
  }

  Widget _buildReviews() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.reviews,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to reviews screen
              },
              child: Text(
                AppLocalizations.of(context)!.seeAll,
                style: AppTypography.body1.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.product.rating.toStringAsFixed(1),
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.product.reviewCount} reviews',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.customerReviewPrompt,
                style: AppTypography.caption.copyWith(color: AppColors.gray600),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                onPressed: () async {
                  // Create chat model
                  final chat = ChatModel(
                    id: 'product_${widget.product.id}',
                    sellerName: widget.product.seller ?? 'SVAYP',
                    sellerAvatar: (widget.product.seller ?? 'SVAYP')[0]
                        .toUpperCase(),
                    lastMessage: l10n.interestedInProduct,
                    lastMessageTime: DateTime.now(),
                    unreadCount: 0,
                    productImage: widget.product.images.isNotEmpty
                        ? widget.product.images[0]
                        : null,
                    productName:
                        '${widget.product.brand} - ${widget.product.title}',
                    productPrice: widget.product.price,
                    productOriginalPrice: widget.product.originalPrice,
                  );

                  // Navigate to chat with seller about this product
                  // Chat will be saved only when user sends first message
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chat: chat,
                          product: widget.product,
                        ),
                      ),
                    );
                  }
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

/// Tappable Seller Row for navigation to seller profile
class _SellerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SellerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: AppTypography.body2.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Gradient seller avatar
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getGradientColors(value),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        value[0].toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.body2.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ],
              ),
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
}
