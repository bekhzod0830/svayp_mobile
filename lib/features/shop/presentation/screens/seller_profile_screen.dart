import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

/// Seller Profile Screen - Shows all products from a specific seller
/// Similar to TikTok Shop seller pages
class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final List<Product> products;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.products,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  int _selectedTab = 0; // 0: Products, 1: About (for future)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock seller data
    // final sellerRating = 4.8; // COMMENTED OUT - for future use
    final totalProducts = widget.products.length;
    final totalSold = totalProducts * 156; // Mock sold count

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      body: CustomScrollView(
        slivers: [
          // App Bar with Seller Info
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Seller Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getGradientColors(widget.sellerName),
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkPrimaryText.withOpacity(0.2)
                                : AppColors.gray200,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.sellerName[0].toUpperCase(),
                            style: AppTypography.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Seller Name
                      Text(
                        widget.sellerName,
                        style: AppTypography.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // COMMENTED OUT - Seller rating (for future use)
                          // _buildStatChip(
                          //   icon: Icons.star_rounded,
                          //   label: sellerRating.toStringAsFixed(1),
                          //   color: Colors.amber,
                          //   isDark: isDark,
                          // ),
                          // const SizedBox(width: 16),
                          _buildStatChip(
                            icon: Icons.inventory_2_outlined,
                            label: '$totalProducts',
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 16),
                          _buildStatChip(
                            icon: Icons.shopping_bag_outlined,
                            label: '${(totalSold / 1000).toStringAsFixed(1)}K',
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              child: Container(
                color: isDark
                    ? AppColors.darkMainBackground
                    : const Color(0xFFF7F7F8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 0
                                    ? (isDark
                                          ? AppColors.darkPrimaryText
                                          : AppColors.black)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.allProducts,
                            textAlign: TextAlign.center,
                            style: AppTypography.body1.copyWith(
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? theme.colorScheme.onSurface
                                  : (isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.gray600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = widget.products[index];
                return _TikTokProductCard(
                  product: product,
                  showSeller: false, // Don't show seller on seller page
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(product: product),
                      ),
                    );
                  },
                );
              }, childCount: widget.products.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMainBackground : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
          ),
        ],
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

// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// TikTok-style Product Card (reusable component)
class _TikTokProductCard extends StatelessWidget {
  final Product product;
  final bool showSeller;
  final VoidCallback onTap;

  const _TikTokProductCard({
    required this.product,
    this.showSeller = true,
    required this.onTap,
  });

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
                      child: CachedNetworkImage(
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : 'https://via.placeholder.com/400',
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
                  // Seller Avatar (TikTok-style - bottom left)
                  if (showSeller)
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
                  // NEW Badge
                  if (product.isNew)
                    Positioned(
                      top: 8,
                      right: 8,
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
                      color: theme.colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.formattedPrice,
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatPrice(product.originalPrice!),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
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
                  const SizedBox(height: 6),
                  // COMMENTED OUT - Product rating (for future use)
                  // Rating & Seller
                  Row(
                    children: [
                      // Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                      // const SizedBox(width: 2),
                      // Text(
                      //   product.rating.toStringAsFixed(1),
                      //   style: AppTypography.caption.copyWith(
                      //     fontWeight: FontWeight.w600,
                      //     color: isDark
                      //         ? AppColors.darkSecondaryText
                      //         : AppColors.gray600,
                      //     fontSize: 11,
                      //   ),
                      // ),
                      if (showSeller) ...[
                        // const SizedBox(width: 6),
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

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} UZS';
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
