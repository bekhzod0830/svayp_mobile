import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/liked/data/models/liked_product_model.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';

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
  int? _totalLikedCount; // Total count from API (may be > locally cached items)
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _apiLoadedCount = 0; // tracks items fetched from API across pages
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Get auth token
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    // Load liked products
    await _loadLikedProducts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    await _likedService.init();

    // Reset pagination
    _currentPage = 0;
    _hasMore = false;
    _apiLoadedCount = 0;

    // Show local cache immediately (hides loading spinner as soon as we have anything)
    final localLikedProducts = _likedService.getLikedProducts();

    // Fetch fresh data from API (keep spinner until API responds to avoid reorder flash)
    if (_authToken != null && _authToken!.isNotEmpty) {
      try {
        final response = await _apiService.getFavoriteProducts(
          token: _authToken!,
          page: 0,
        );

        final apiItems = _buildLikedModels(response.products);

        // Cache to Hive in background for next cold start
        _cacheToHive(response.products);

        if (mounted) {
          setState(() {
            _likedProducts = apiItems;
            _totalLikedCount = response.total;
            _currentPage = 0;
            _apiLoadedCount = apiItems.length;
            _hasMore = response.total > _apiLoadedCount;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading favorites: $e');
        // On API failure, fall back to local cache
        if (mounted) {
          setState(() {
            _likedProducts = localLikedProducts;
            _isLoading = false;
          });
        }
      }
    } else {
      // Not authenticated — just show local cache
      setState(() {
        _likedProducts = localLikedProducts;
        _isLoading = false;
      });
    }
  }

  /// Cache API products to Hive in background (fire-and-forget)
  void _cacheToHive(List<dynamic> apiProducts) {
    Future(() async {
      try {
        for (final ap in apiProducts) {
          if (!_likedService.isLiked(ap.id)) {
            // Build a minimal discover Product just for Hive caching
            String brand = (ap.brand == 'Unknown' || ap.brand.isEmpty)
                ? (ap.seller ?? 'SVAYP')
                : ap.brand;
            if (brand == 'Unknown' || brand.isEmpty) brand = 'SVAYP';

            final images = (ap.images as List).cast<String>();
            final product = Product(
              id: ap.id,
              brand: brand,
              title: ap.title,
              description: ap.description ?? '',
              price: ap.price,
              images: images.isNotEmpty ? images : ['placeholder'],
              category: ap.category.displayName,
              sizes: List<String>.from((ap.sizes ?? []) as List),
              colors: List<String>.from((ap.colors ?? []) as List),
              currency: ap.currency ?? 'UZS',
              rating: ap.rating ?? 4.5,
              reviewCount: ap.reviewCount ?? 0,
              isNew: ap.isNew ?? false,
              isFeatured: ap.isFeatured ?? false,
              inStock: ap.inStock,
              seller: ap.seller ?? brand,
              sellerId: ap.sellerId,
              discountPercentage: ap.discountPercentage,
              originalPrice: ap.originalPrice,
              titleLocalized: ap.titleLocalized,
              descriptionLocalized: ap.descriptionLocalized,
            );
            await _likedService.addLike(product);
          }
        }
      } catch (e) {
        debugPrint('Background Hive cache error (non-critical): $e');
      }
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _authToken == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getFavoriteProducts(
        token: _authToken!,
        page: nextPage,
      );

      final newItems = _buildLikedModels(response.products);

      if (mounted) {
        setState(() {
          _likedProducts = [..._likedProducts, ...newItems];
          _totalLikedCount = response.total;
          _currentPage = nextPage;
          _apiLoadedCount += newItems.length;
          _hasMore = response.total > _apiLoadedCount;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more favorites: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// Build LikedProductModel list directly from API products (no Hive write/read)
  List<LikedProductModel> _buildLikedModels(List<dynamic> apiProducts) {
    final result = <LikedProductModel>[];
    for (final ap in apiProducts) {
      try {
        String displayBrand = (ap.brand == 'Unknown' || ap.brand.isEmpty)
            ? (ap.seller ?? ap.brand)
            : ap.brand;
        if (displayBrand == 'Unknown' || displayBrand.isEmpty)
          displayBrand = 'SVAYP';

        final images = (ap.images as List).cast<String>();

        // Populate _fullProducts for detail navigation
        _fullProducts[ap.id] = Product(
          id: ap.id,
          title: ap.title,
          description: ap.description ?? '',
          price: ap.price,
          brand: displayBrand,
          category: ap.category.displayName,
          subcategory: (ap.subcategory as List?)
              ?.map((sc) => sc.displayName as String)
              .toList(),
          images: images.isNotEmpty ? images : ['placeholder'],
          sizes: List<String>.from((ap.sizes ?? []) as List),
          colors: List<String>.from((ap.colors ?? []) as List),
          material: (ap.material as List?)
              ?.map((m) => m.displayName as String)
              .toList(),
          season: (ap.season as List?)
              ?.map((s) => s.displayName as String)
              .toList(),
          currency: ap.currency ?? 'UZS',
          rating: ap.rating ?? 4.5,
          reviewCount: ap.reviewCount ?? 0,
          isNew: ap.isNew ?? false,
          isFeatured: ap.isFeatured ?? false,
          inStock: ap.inStock,
          seller: ap.seller ?? displayBrand,
          sellerId: ap.sellerId,
          discountPercentage: ap.discountPercentage,
          originalPrice: ap.originalPrice,
          titleLocalized: ap.titleLocalized,
          descriptionLocalized: ap.descriptionLocalized,
        );

        result.add(
          LikedProductModel(
            productId: ap.id,
            brand: displayBrand,
            title: ap.title,
            price: ap.price,
            imageUrl: images.isNotEmpty ? images.first : '',
            category: ap.category.displayName,
            rating: ap.rating ?? 4.5,
            isNew: ap.isNew ?? false,
            discountPercentage: ap.discountPercentage,
            originalPrice: ap.originalPrice,
            sellerId: ap.sellerId,
            currency: ap.currency ?? 'UZS',
            titleLocalized: ap.titleLocalized,
            descriptionLocalized: ap.descriptionLocalized,
          ),
        );
      } catch (e) {
        debugPrint('Skipping product ${ap.id}: $e');
      }
    }
    return result;
  }

  Future<void> _removeLikedProduct(LikedProductModel product, int index) async {
    // If user is authenticated, send dislike request to API
    if (_authToken != null && _authToken!.isNotEmpty) {
      try {
        await _apiService.dislikeProduct(
          productId: product.productId,
          token: _authToken!,
        );
      } catch (e) {
        // Continue with local removal even if API fails
      }
    }

    // Remove from local storage (best-effort)
    await _likedService.removeLike(product.productId).catchError((_) {});

    // Update display list directly without full reload
    if (mounted) {
      setState(() {
        _likedProducts = _likedProducts
            .where((p) => p.productId != product.productId)
            .toList();
        _totalLikedCount = (_totalLikedCount ?? _likedProducts.length + 1) - 1;
        _apiLoadedCount = _likedProducts.length;
      });
    }
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
      // Send dislike requests in parallel (but don't wait for all to complete)
      final futures = _likedProducts.map((product) {
        return _apiService
            .dislikeProduct(productId: product.productId, token: _authToken!)
            .catchError((e) {});
      }).toList();

      // Wait for all requests to complete (or fail)
      await Future.wait(futures);
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

      // Use SVAYP if brand is Unknown
      final sellerName =
          (likedProduct.brand == 'Unknown' || likedProduct.brand.isEmpty)
          ? 'SVAYP'
          : likedProduct.brand;

      final fallbackProduct = Product(
        id: likedProduct.productId,
        brand: sellerName,
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
        seller: sellerName, // Use same name for seller
        sellerId: likedProduct.sellerId,
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
                          l10n.itemsCount(
                            _totalLikedCount ?? _likedProducts.length,
                          ),
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
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount:
                            _likedProducts.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _likedProducts.length) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.black,
                                strokeWidth: 2,
                              ),
                            );
                          }
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
                MainScreen.globalKey.currentState?.navigateToTab(0);
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
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: isDark
                          ? AppColors.darkMainBackground
                          : Colors.white,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cacheWidth = (constraints.maxWidth * 2).toInt();
                          return CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            cacheManager: ImageCacheManager.instance,
                            memCacheWidth: cacheWidth,
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
                          );
                        },
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    product.localizedTitle(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price with optional discount in a Row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.currency == 'USD'
                              ? '\$${product.price}'
                              : '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
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
                      if (product.originalPrice != null &&
                          product.originalPrice! > product.price) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            product.currency == 'USD'
                                ? '\$${product.originalPrice}'
                                : '${product.originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Seller Name
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                      fontSize: 11,
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
                      fit: BoxFit.cover,
                      width: 100,
                      height: 120,
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
                    // Title
                    Flexible(
                      child: Text(
                        product.localizedTitle(
                          Localizations.localeOf(context).languageCode,
                        ),
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

                    // Price with optional discount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price)
                          Text(
                            '${product.originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UZS',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                            ),
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
