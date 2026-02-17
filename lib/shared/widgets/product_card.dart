import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/formatters.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

/// Product Card for Swipe Interface
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String brand;
  final String name;
  final int price;
  final String? originalPrice;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final List<String>? tags;
  final VoidCallback? onTap;
  final bool showDetails;
  final double? width;
  final double? height;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.brand,
    required this.name,
    required this.price,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.category,
    this.tags,
    this.onTap,
    this.showDetails = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? screenWidth * 0.9;
    final cardHeight = height ?? screenWidth * 1.3;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withOpacity(
                isDark ? 0.05 : 0.16,
              ),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Product Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  cacheManager: ImageCacheManager.instance,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.gray100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.gray100,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray400,
                      size: 64,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay at Bottom
              if (showDetails)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),

              // Product Details
              if (showDetails)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Text(
                        brand.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Product Name
                      Text(
                        name,
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price Row
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatUzs(price),
                            style: AppTypography.heading4.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              originalPrice!,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.gray300,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Rating & Category
                      Row(
                        children: [
                          if (rating != null) ...[
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: AppTypography.body2.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            if (reviewCount != null)
                              Text(
                                ' ($reviewCount)',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.gray300,
                                ),
                              ),
                            const SizedBox(width: 12),
                          ],
                          if (category != null)
                            Expanded(
                              child: Text(
                                category!,
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.gray300,
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

              // Tags at Top
              if (tags != null && tags!.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Product Card for Lists/Grids
class ProductCardCompact extends StatelessWidget {
  final String imageUrl;
  final String brand;
  final String name;
  final int price;
  final String? originalPrice;
  final double? rating;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  const ProductCardCompact({
    super.key,
    required this.imageUrl,
    required this.brand,
    required this.name,
    required this.price,
    this.originalPrice,
    this.rating,
    this.isLiked = false,
    this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Like Button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.75,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      cacheManager: ImageCacheManager.instance,
                      placeholder: (context, url) =>
                          Container(color: AppColors.gray100),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onLikeTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onLikeTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : AppColors.gray700,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Text(
                    brand.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    name,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price & Rating
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.formatUzs(price),
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (originalPrice != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                originalPrice!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.gray500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
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

/// Horizontal Product Card for Carts/Orders
class ProductCardHorizontal extends StatelessWidget {
  final String imageUrl;
  final String brand;
  final String name;
  final int price;
  final String? size;
  final String? color;
  final int? quantity;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductCardHorizontal({
    super.key,
    required this.imageUrl,
    required this.brand,
    required this.name,
    required this.price,
    this.size,
    this.color,
    this.quantity,
    this.onTap,
    this.onRemove,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder, width: 1),
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                cacheManager: ImageCacheManager.instance,
                placeholder: (context, url) =>
                    Container(color: AppColors.gray100),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.gray100,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.gray400,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Text(
                    brand.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    name,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Size & Color
                  if (size != null || color != null)
                    Text(
                      [
                        if (size != null) 'Size: $size',
                        if (color != null) 'Color: $color',
                      ].join(' • '),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Price & Quantity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.formatUzs(
                            quantity != null ? price * quantity! : price,
                          ),
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (quantity != null &&
                          onIncrement != null &&
                          onDecrement != null)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: onDecrement,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.standardBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              quantity.toString(),
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: onIncrement,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
