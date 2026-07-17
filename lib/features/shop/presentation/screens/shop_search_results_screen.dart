import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/tryon/presentation/tryon_sheet.dart';
import 'package:swipe/features/tryon/presentation/widgets/try_on_pill.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';

/// Shop Search Results Screen - TikTok Shop style
class ShopSearchResultsScreen extends StatefulWidget {
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
  State<ShopSearchResultsScreen> createState() =>
      _ShopSearchResultsScreenState();
}

class _ShopSearchResultsScreenState extends State<ShopSearchResultsScreen> {
  final LikedService _likedService = LikedService();

  @override
  void initState() {
    super.initState();
    _likedService.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find matching sellers
    final matchingSellers = _findMatchingSellers();
    final hasResults =
        widget.searchResults.isNotEmpty || matchingSellers.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${l10n.searchResults}: "${widget.query}"',
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
                if (widget.searchResults.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        '${widget.searchResults.length} ${l10n.productsFound}',
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: () {
                          final cardW =
                              (MediaQuery.of(context).size.width - 36) / 2;
                          return cardW / (cardW * 5 / 4 + 88);
                        }(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = widget.searchResults[index];
                        return _TikTokProductCard(
                          product: product,
                          isDark: isDark,
                          onTap: () async {
                            // Navigate and await result to trigger rebuild
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                            // Trigger rebuild after returning
                            if (mounted) setState(() {});
                          },
                        );
                      }, childCount: widget.searchResults.length),
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

    for (final product in widget.allProducts) {
      final seller = product.seller ?? 'LIBAS';
      sellerMap.putIfAbsent(seller, () => []).add(product);
    }

    // Filter sellers that match the query
    final matchingSellers = <Map<String, dynamic>>[];
    final queryLower = widget.query.toLowerCase();

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
        // Get sellerId from first product
        final sellerId = products.isNotEmpty
            ? (products.first.sellerId ?? 'unknown')
            : 'unknown';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(
              sellerId: sellerId,
              sellerName: sellerName,
              products: products,
            ),
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

/// TikTok-style Product Card (matching shop_screen.dart)
class _TikTokProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const _TikTokProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  /// Open the virtual try-on for prepared products; otherwise show a
  /// "coming soon" note. Mirrors the discovery deck behaviour.
  void _handleTryOn(BuildContext context) {
    HapticFeedback.selectionClick();
    if (!product.catalogReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.tryOnComingSoon)),
      );
      return;
    }
    showProductTryOnSheet(
      context,
      productId: product.id,
      previewImage: product.images.isNotEmpty ? product.images.first : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = product.seller ?? 'LIBAS';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Seller Avatar
            AspectRatio(
              aspectRatio: 4 / 5,
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
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : 'https://via.placeholder.com/400',
                            fit: BoxFit.cover,
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
                  // Discount Badge
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
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
                          ),
                        ),
                      ),
                    ),
                  // Try-on pill (top-right) — label + diamond cost, same as the
                  // discovery deck.
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TryOnPill(
                      compact: true,
                      onTap: () => _handleTryOn(context),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            SizedBox(
              height: 88,
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title — 1 line with ellipsis
                      Text(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price with optional discount in a Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.formattedPrice,
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
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                product.formattedDiscountPrice ?? '',
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
                      const SizedBox(height: 4),
                      // Seller Name
                      Text(
                        sellerName,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
