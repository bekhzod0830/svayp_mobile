import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/liked/data/models/liked_product_model.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/discover/data/mock_product_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/services/product_api_service.dart';

/// Interface for refreshable screens
abstract class Refreshable {
  void refresh();
}

/// Liked Screen - Shows all liked/saved products
/// Users can view, remove, and shop their favorite items
class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => LikedScreenState();
}

class LikedScreenState extends State<LikedScreen>
    with AutomaticKeepAliveClientMixin
    implements Refreshable {
  final LikedService _likedService = LikedService();
  final ProductApiService _apiService = ProductApiService();
  List<LikedProductModel> _likedProducts = [];
  final Map<String, Product> _fullProducts = {}; // Store full products by ID
  bool _isLoading = true;
  String? _authToken;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Get auth token
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    print(
      '🔑 Auth token in Liked Screen: ${_authToken != null ? "Present (${_authToken!.substring(0, 10)}...)" : "Not found"}',
    );

    // Load liked products
    await _loadLikedProducts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Public method to refresh liked products (can be called from parent)
  @override
  void refresh() {
    if (mounted) {
      // Force reload to pick up newly liked items from other screens
      _loadLikedProducts();
    }
  }

  Future<void> _loadLikedProducts() async {
    setState(() {
      _isLoading = true;
    });

    await _likedService.init();

    // First, load from local storage
    final localLikedProducts = _likedService.getLikedProducts();
    print('💾 Loaded ${localLikedProducts.length} products from local storage');

    // If user is authenticated, try to fetch favorites from API
    if (_authToken != null && _authToken!.isNotEmpty) {
      print('📡 Fetching favorites from API...');
      try {
        final response = await _apiService.getFavoriteProducts(
          token: _authToken!,
        );

        print('✅ Received ${response.products.length} favorites from API');

        // Sync backend favorites with local storage
        // This ensures the local storage is up-to-date with backend
        for (final apiProduct in response.products) {
          final product = Product(
            id: apiProduct.id,
            title: apiProduct.title,
            description: apiProduct.description ?? '',
            price: apiProduct.price,
            brand: apiProduct.brand,
            category: apiProduct.category.displayName,
            subcategory: apiProduct.subcategory
                ?.map((sc) => sc.displayName)
                .toList(),
            images: apiProduct.images.isNotEmpty
                ? apiProduct.images
                : ['placeholder'],
            sizes:
                apiProduct.sizes?.map((size) => size.displayName).toList() ??
                [],
            colors: apiProduct.colors ?? [],
            material: apiProduct.material?.map((m) => m.displayName).toList(),
            season: apiProduct.season?.map((s) => s.displayName).toList(),
            currency: apiProduct.currency ?? 'UZS',
            rating: apiProduct.rating ?? 4.5,
            reviewCount: apiProduct.reviewCount ?? 0,
            isNew: apiProduct.isNew ?? false,
            isFeatured: apiProduct.isFeatured ?? false,
            inStock: apiProduct.inStock,
            seller: apiProduct.seller,
            discountPercentage: apiProduct.discountPercentage,
            originalPrice: apiProduct.originalPrice,
          );

          // Add to local if not already there
          if (!_likedService.isLiked(product.id)) {
            await _likedService.addLike(product);
          }

          // Store full product in map
          _fullProducts[product.id] = product;
        }

        // Reload from local storage after sync
        setState(() {
          _likedProducts = _likedService.getLikedProducts();
          _isLoading = false;
        });
      } catch (e) {
        // If API call fails, use local data
        print('⚠️ Failed to fetch favorites from API: $e');
        setState(() {
          _likedProducts = localLikedProducts;
          _isLoading = false;
        });
      }
    } else {
      // Not authenticated, use local data only
      setState(() {
        _likedProducts = localLikedProducts;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeLikedProduct(LikedProductModel product, int index) async {
    final l10n = AppLocalizations.of(context)!;

    // If user is authenticated, send dislike request to API
    if (_authToken != null && _authToken!.isNotEmpty) {
      try {
        print('📡 Sending dislike request for product ${product.productId}...');
        await _apiService.dislikeProduct(
          productId: product.productId,
          token: _authToken!,
        );
        print('✅ Product disliked successfully');
      } catch (e) {
        print('⚠️ Failed to dislike product via API: $e');
        // Continue with local removal even if API fails
      }
    }

    // Remove from local storage
    await _likedService.removeLikeAt(index);
    await _loadLikedProducts();
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAll),
        content: Text(
          'Are you sure you want to remove all ${_likedProducts.length} liked items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // If user is authenticated, send dislike requests for all products
    if (_authToken != null && _authToken!.isNotEmpty) {
      print(
        '📡 Sending dislike requests for all ${_likedProducts.length} products...',
      );

      // Send dislike requests in parallel (but don't wait for all to complete)
      final futures = _likedProducts.map((product) {
        return _apiService
            .dislikeProduct(productId: product.productId, token: _authToken!)
            .catchError((e) {
              print('⚠️ Failed to dislike product ${product.productId}: $e');
            });
      }).toList();

      // Wait for all requests to complete (or fail)
      await Future.wait(futures);
      print('✅ All dislike requests completed');
    }

    // Clear local storage
    await _likedService.clearAllLiked();
    await _loadLikedProducts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.clearedAllLikedItems),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onProductTap(LikedProductModel likedProduct) {
    // Try to get the full product from our stored map
    final fullProduct = _fullProducts[likedProduct.productId];

    if (fullProduct != null) {
      // We have the full product, navigate directly
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: fullProduct),
        ),
      );
    } else {
      // Fallback: create product from liked product model data
      print('⚠️ Full product not found in cache for ${likedProduct.productId}');
      final fallbackProduct = Product(
        id: likedProduct.productId,
        brand: likedProduct.brand,
        title: likedProduct.title,
        category: likedProduct.category,
        price: likedProduct.price,
        currency: 'UZS',
        images: [likedProduct.imageUrl],
        sizes: [],
        colors: [],
        description: '',
        rating: likedProduct.rating,
        reviewCount: 0,
        isNew: likedProduct.isNew,
        discountPercentage: likedProduct.discountPercentage,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: fallbackProduct),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.likedItems,
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_likedProducts.length} ${_likedProducts.length == 1 ? "item" : "items"}',
                          style: AppTypography.body2.copyWith(
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
            const SizedBox(height: 8),
            // Product Grid (TikTok-style 2-column)
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    )
                  : _likedProducts.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadLikedProducts,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: _buildEmptyState(l10n),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLikedProducts,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _likedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _likedProducts[index];
                          return _TikTokLikedProductCard(
                            product: product,
                            onTap: () => _onProductTap(product),
                            onRemove: () => _removeLikedProduct(product, index),
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 100, color: AppColors.gray400),
            const SizedBox(height: 24),
            Text(
              l10n.noLikedItemsYet,
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.startSwipingAndSave,
              style: AppTypography.body1.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to discover tab
                DefaultTabController.of(context).animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.startExploring),
            ),
          ],
        ),
      ),
    );
  }
}

/// TikTok-style Liked Product Card Widget - Vertical Layout
class _TikTokLikedProductCard extends StatelessWidget {
  final LikedProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool isDark;

  const _TikTokLikedProductCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Remove Button
            Expanded(
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: isDark
                          ? AppColors.darkMainBackground
                          : Colors.white,
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.contain,
                        cacheManager: ImageCacheManager.instance,
                        placeholder: (context, url) => Container(
                          color: isDark
                              ? AppColors.darkMainBackground
                              : AppColors.gray100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.gray400,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark
                              ? AppColors.darkMainBackground
                              : AppColors.gray100,
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Remove/Unlike Button (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Text(
                    product.brand.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    product.title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Flexible(
                        child: Text(
                          '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.gray600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

/// Old horizontal card widget (kept for reference but no longer used)
class _LikedProductCard extends StatelessWidget {
  final LikedProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _LikedProductCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkSecondaryText.withOpacity(0.1)
                : AppColors.gray200.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image (Left)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 100,
                height: 120,
                color: isDark ? AppColors.darkMainBackground : Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.contain,
                      cacheManager: ImageCacheManager.instance,
                      placeholder: (context, url) => Container(
                        color: isDark
                            ? AppColors.darkMainBackground
                            : AppColors.gray100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.gray400,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark
                            ? AppColors.darkMainBackground
                            : AppColors.gray100,
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray400,
                        ),
                      ),
                    ),
                    // Remove Button Overlay
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Info (Center)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand
                    Text(
                      product.brand.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Flexible(
                      child: Text(
                        product.title,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price and Rating
                    Row(
                      children: [
                        // Price
                        Flexible(
                          child: Text(
                            '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UZS',
                            style: AppTypography.body2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Rating Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.gray600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron Arrow (Right)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
