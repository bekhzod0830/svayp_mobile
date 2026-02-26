import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Visual Search Results Screen
/// Displays recommendations from the backend with the same card style as Shop.
class VisualSearchResultsScreen extends StatelessWidget {
  final List<api_models.Product> products;
  final File? uploadedImage;

  const VisualSearchResultsScreen({
    super.key,
    required this.products,
    this.uploadedImage,
  });

  Product _toEntity(api_models.Product p) {
    final displayBrand = (p.brand == 'Unknown' || p.brand.isEmpty)
        ? (p.seller ?? p.brand)
        : p.brand;
    return Product(
      id: p.id,
      title: p.title,
      description: p.description ?? '',
      price: p.price,
      brand: displayBrand,
      category: p.originalCategoryString ?? p.category.value,
      subcategory: p.subcategory?.map((s) => s.displayName).toList(),
      images: p.images,
      sizes: p.sizes?.map((s) => s.displayName).toList() ?? [],
      colors: p.colors ?? [],
      material: p.material?.map((m) => m.displayName).toList(),
      season: p.season?.map((s) => s.displayName).toList(),
      currency: p.currency,
      rating: p.rating ?? 4.5,
      reviewCount: p.reviewCount ?? 0,
      isNew: p.isNew ?? false,
      isFeatured: p.isFeatured ?? false,
      inStock: p.inStock,
      seller: p.seller,
      sellerId: p.sellerId,
      discountPercentage: p.discountPercentage,
      originalPrice: p.originalPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkMainBackground : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.visualSearchResults,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Uploaded image preview
          if (uploadedImage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSecondaryText.withValues(alpha: 0.2)
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_camera,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.brandBlack,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.yourSearchImage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        uploadedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Results count header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.similarProductsCount(products.length),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.primaryText,
                ),
              ),
            ),
          ),

          // Empty state
          if (products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: isDark
                          ? AppColors.darkSecondaryText.withValues(alpha: 0.5)
                          : AppColors.gray400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noProductsFound,
                      style: AppTypography.heading3.copyWith(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Products grid — identical layout/card style to Shop screen
          if (products.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return _VisualSearchProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: _toEntity(product),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Product card — mirrors _TikTokProductCard from shop_screen.dart
class _VisualSearchProductCard extends StatelessWidget {
  final api_models.Product product;
  final VoidCallback onTap;

  const _VisualSearchProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sellerName = product.seller ?? 'SVAYP';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: isDark
                          ? AppColors.darkMainBackground
                          : Colors.white,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cacheWidth =
                              (constraints.maxWidth * 2).toInt();
                          return product.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.images.first,
                                  fit: BoxFit.contain,
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
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                                );
                        },
                      ),
                    ),
                  ),
                  // NEW badge
                  if (product.isNew == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
                  // Discount badge
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
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
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.formattedPrice,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.originalPrice != null &&
                      product.originalPrice! > product.price)
                    Text(
                      '${product.originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${product.currency}',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? AppColors.gray400 : AppColors.gray500,
                        decoration: TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
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
          ],
        ),
      ),
    );
  }
}

