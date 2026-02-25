import 'package:flutter/material.dart';
import 'dart:io';
import 'package:swipe/core/models/visual_search.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/discover/domain/entities/product.dart' as domain;
import 'package:swipe/l10n/app_localizations.dart';

/// Visual Search Results Screen
class VisualSearchResultsScreen extends StatelessWidget {
  final VisualSearchResponse searchResults;
  final File? uploadedImage;

  const VisualSearchResultsScreen({
    super.key,
    required this.searchResults,
    this.uploadedImage,
  });

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
            : AppColors.cardBackground,
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
          // Uploaded Image Section
          if (uploadedImage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSecondaryText.withOpacity(0.2)
                        : AppColors.lightBorder,
                    width: 1,
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
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Results Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.similarProductsCount(searchResults.totalMatches),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '${searchResults.searchTimeSeconds.toStringAsFixed(1)}s',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products Grid (TikTok-style 2-column)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final match = searchResults.matches[index];
                return _buildProductCard(context, match, isDark);
              }, childCount: searchResults.matches.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummary(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final analysis = searchResults.analysis;
    final confidence = (analysis.confidence * 100).round();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkSecondaryText.withOpacity(0.2)
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.brandBlack,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aiAnalysis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.primaryText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: confidence >= 80
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: confidence >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: confidence >= 80 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$confidence%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: confidence >= 80 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getTranslatedDescription(l10n),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (analysis.category != null)
                _buildChip(analysis.category!, Icons.category, isDark),
              if (analysis.colors.isNotEmpty)
                _buildChip(
                  analysis.colors.take(2).join(', '),
                  Icons.palette,
                  isDark,
                ),
              if (analysis.patterns.isNotEmpty)
                _buildChip(analysis.patterns.first, Icons.texture, isDark),
              if (analysis.isHijabAppropriate == true)
                _buildChip(
                  l10n.hijabAppropriate,
                  Icons.check_circle,
                  isDark,
                  highlighted: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    bool isDark, {
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? (isDark
                  ? AppColors.darkPrimaryText.withOpacity(0.1)
                  : AppColors.brandBlack.withOpacity(0.1))
            : (isDark
                  ? AppColors.darkMainBackground
                  : AppColors.pageBackground),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? (isDark ? AppColors.darkPrimaryText : AppColors.brandBlack)
              : (isDark
                    ? AppColors.darkSecondaryText.withOpacity(0.3)
                    : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted
                ? (isDark ? AppColors.darkPrimaryText : AppColors.brandBlack)
                : (isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlighted
                  ? (isDark ? AppColors.darkPrimaryText : AppColors.brandBlack)
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    VisualSearchMatch match,
    bool isDark,
  ) {
    final product = match.product;
    final similarity = match.similarityPercentage;
    final sellerName = product.seller ?? 'SVAYP';

    // Convert to domain Product for navigation
    final domainProduct = domain.Product(
      id: product.id,
      title: product.title,
      brand: product.brand,
      price: product.price,
      images: product.images,
      description: product.description ?? '',
      category: product.category.displayName,
      subcategory: product.subcategory?.map((s) => s.displayName).toList(),
      sizes: product.sizes?.map((s) => s.displayName).toList() ?? [],
      colors: product.colors ?? [],
      material: product.material?.map((m) => m.displayName).toList(),
      season: product.season?.map((s) => s.displayName).toList(),
      currency: product.currency,
      rating: product.rating ?? 4.5,
      reviewCount: product.reviewCount ?? 0,
      inStock: product.inStock,
      isNew: product.isNew ?? false,
      isFeatured: product.isFeatured ?? false,
      seller: product.seller,
      sellerId: product.sellerId,
      discountPercentage: product.discountPercentage,
      originalPrice: product.originalPrice,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: domainProduct),
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
            // Product Image with Seller Avatar & Similarity Badge
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
                          ? Image.asset(
                              product.images.first,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
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
                  // Similarity Badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: similarity >= 80
                            ? Colors.green
                            : similarity >= 60
                            ? Colors.orange
                            : const Color(0xFFf093fb),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$similarity%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // NEW Badge
                  if (product.isNew ?? false)
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
                ],
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  // COMMENTED OUT - Rating display (for future use)
                  // Rating & Seller
                  Row(
                    children: [
                      // const Icon(
                      //   Icons.star_rounded,
                      //   size: 12,
                      //   color: Colors.amber,
                      // ),
                      // const SizedBox(width: 2),
                      // Text(
                      //   (product.rating ?? 4.5).toStringAsFixed(1),
                      //   style: AppTypography.caption.copyWith(
                      //     fontWeight: FontWeight.w600,
                      //     color: isDark
                      //         ? AppColors.darkSecondaryText
                      //         : AppColors.gray600,
                      //     fontSize: 11,
                      //   ),
                      // ),
                      // const SizedBox(width: 6),
                      Flexible(
                        child: Text(
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

  /// Format price with thousand separators (e.g., 269 000)
  String _formatPrice(int priceInCents) {
    final price = priceInCents ~/ 100;
    final priceStr = price.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(priceStr[i]);
    }

    return buffer.toString();
  }

  /// Get translated AI analysis description based on locale
  String _getTranslatedDescription(AppLocalizations l10n) {
    final locale = l10n.localeName;

    switch (locale) {
      case 'ru':
        return 'Стильный повседневный блейзер в оливковых/хаки тонах с расслабленным кроем. Идеально подходит для повседневно-деловых случаев благодаря комфортному материалу из льняной смеси.';
      case 'uz':
        return "Zaytun/xaki rangdagi zamonaviy kundalik blazer, erkin o'lchamda. Qulay zig'ir aralashmasidan tayyorlangan material bilan smart-casual tadbirlar uchun juda mos.";
      default: // 'en'
        return 'A stylish casual blazer in olive/khaki tones with a relaxed fit. Perfect for smart-casual occasions with its comfortable linen blend material.';
    }
  }
}
