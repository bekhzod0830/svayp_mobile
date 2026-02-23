import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;

/// Shop Search Results Screen - TikTok Shop style
class ShopSearchResultsScreen extends StatelessWidget {
  final String query;
  final List<Product> searchResults;
  final List<Product> allProducts;
  final TextEditingController searchController;

  const ShopSearchResultsScreen({
    super.key,
    required this.query,
    required this.searchResults,
    required this.allProducts,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find matching sellers
    final matchingSellers = _findMatchingSellers();
    final hasResults = searchResults.isNotEmpty || matchingSellers.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${l10n.searchResults}: "$query"',
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
        ),
      ),
      body: !hasResults
          ? _buildEmptyState(context, l10n, isDark)
          : CustomScrollView(
              slivers: [
                // Sellers section
                if (matchingSellers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        l10n.sellers,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: matchingSellers.length,
                        itemBuilder: (context, index) {
                          final seller = matchingSellers[index];
                          return _SellerCard(
                            sellerName: seller['name'] as String,
                            productCount: seller['count'] as int,
                            products: seller['products'] as List<Product>,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],

                // Products section
                if (searchResults.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        '${searchResults.length} ${l10n.productsFound}',
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                      ),
                    ),
                  ),

                  // Products grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = searchResults[index];
                        return _TikTokProductCard(
                          product: product,
                          isDark: isDark,
                        );
                      }, childCount: searchResults.length),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _findMatchingSellers() {
    // Get all unique sellers
    final sellerMap = <String, List<Product>>{};

    for (final product in allProducts) {
      final seller = product.seller ?? 'SVAYP';
      sellerMap.putIfAbsent(seller, () => []).add(product);
    }

    // Filter sellers that match the query
    final matchingSellers = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    sellerMap.forEach((sellerName, products) {
      if (sellerName.toLowerCase().contains(queryLower)) {
        matchingSellers.add({
          'name': sellerName,
          'count': products.length,
          'products': products,
        });
      }
    });

    return matchingSellers;
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: isDark
                  ? AppColors.darkSecondaryText.withOpacity(0.5)
                  : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProductsFound,
              style: AppTypography.heading3.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryDifferentSearch,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seller Card Widget
class _SellerCard extends StatelessWidget {
  final String sellerName;
  final int productCount;
  final List<Product> products;
  final bool isDark;

  const _SellerCard({
    required this.sellerName,
    required this.productCount,
    required this.products,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SellerProfileScreen(sellerName: sellerName, products: products),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
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
                border: Border.all(
                  color: isDark ? AppColors.darkMainBackground : Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  sellerName[0].toUpperCase(),
                  style: AppTypography.body1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Seller Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sellerName,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$productCount ${l10n.products.toLowerCase()}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                      fontSize: 11,
                    ),
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

/// TikTok-style Product Card
class _TikTokProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _TikTokProductCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sellerName = product.seller ?? 'SVAYP';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
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
            // Product Image with Seller Avatar
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
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images.first,
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
                            )
                          : Container(
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
                  // Seller Avatar (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _navigateToSeller(context, sellerName),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getGradientColors(sellerName),
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            sellerName[0].toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // NEW Badge
                  if (product.isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NEW',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  // Sale Badge
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
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
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    _formatPrice(product.price),
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Rating & Seller
                  Row(
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
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• $sellerName',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  void _navigateToSeller(BuildContext context, String sellerName) async {
    final apiService = ProductApiService();

    try {
      // Fetch all products
      final response = await apiService.getProducts(skip: 0, limit: 100);

      // Filter products by seller
      final sellerProducts = response.products
          .where((p) => p.seller == sellerName)
          .map(
            (apiProduct) => Product(
              id: apiProduct.id,
              title: apiProduct.title,
              description: apiProduct.description ?? '',
              price: apiProduct.price,
              brand: apiProduct.brand,
              category: apiProduct.category.displayName,
              images: apiProduct.images.isNotEmpty
                  ? apiProduct.images
                  : ['placeholder'],
              sizes:
                  apiProduct.sizes?.map((size) => size.displayName).toList() ??
                  [],
              colors: apiProduct.colors ?? [],
              rating: apiProduct.rating ?? 4.5,
              reviewCount: apiProduct.reviewCount ?? 0,
              isNew: apiProduct.isNew ?? false,
              isFeatured: apiProduct.isFeatured ?? false,
              inStock: apiProduct.inStock,
              seller: apiProduct.seller,
              discountPercentage: apiProduct.discountPercentage,
              originalPrice: apiProduct.originalPrice,
            ),
          )
          .toList();

      if (sellerProducts.isEmpty) return;

      // Navigate to seller profile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SellerProfileScreen(
            sellerName: sellerName,
            products: sellerProducts,
          ),
        ),
      );
    } catch (e) {
      print('Error loading seller products: $e');
    }
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

  String _formatPrice(int priceInCents) {
    final price = priceInCents ~/ 100;
    final priceStr = price.toString();

    // Add thousand separators (e.g., 1234567 -> 1 234 567)
    final buffer = StringBuffer();
    final length = priceStr.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(priceStr[i]);
    }

    return '${buffer.toString()} сўм';
  }
}
