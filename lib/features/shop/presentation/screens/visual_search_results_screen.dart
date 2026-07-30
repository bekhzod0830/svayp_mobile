import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/services/visual_search_api_service.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';

/// Visual Search Results Screen
/// Displays recommendations from the backend with the same card style as Shop.
class VisualSearchResultsScreen extends StatefulWidget {
  final List<VisualSearchResult> results;
  final File? uploadedImage;

  const VisualSearchResultsScreen({
    super.key,
    required this.results,
    this.uploadedImage,
  });

  @override
  State<VisualSearchResultsScreen> createState() =>
      _VisualSearchResultsScreenState();
}

class _VisualSearchResultsScreenState extends State<VisualSearchResultsScreen> {
  final LikedService _likedService = LikedService();

  @override
  void initState() {
    super.initState();
    _likedService.init();
    // Показ результатов — это и есть использование визуального поиска. До сих пор
    // экран не был инструментирован вовсе, поэтому функция выглядела мёртвой.
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.visualSearchResults,
      parameters: {'result_count': widget.results.length.toString()},
    );
  }

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
      sizes: p.sizes ?? [],
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
      titleLocalized: p.titleLocalized,
      descriptionLocalized: p.descriptionLocalized,
    );
  }

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
        scrolledUnderElevation: 0,
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
          // Uploaded image preview with scanning frame
          if (widget.uploadedImage != null)
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
                    // Image with scanning frame overlay
                    _ScannedImageFrame(
                      image: widget.uploadedImage!,
                      isDark: isDark,
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
                l10n.similarProductsCount(widget.results.length),
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
          if (widget.results.isEmpty)
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

          // Products grid
          if (widget.results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: () {
                    final cardW = (MediaQuery.of(context).size.width - 36) / 2;
                    return cardW / (cardW * 5 / 4 + 88);
                  }(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final result = widget.results[index];
                  return _VisualSearchProductCard(
                    result: result,
                    onTap: () async {
                      // Navigate and await result to trigger rebuild
                      await Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: _toEntity(result.product),
                          ),
                        ),
                      );
                      // Trigger rebuild after returning
                      if (mounted) setState(() {});
                    },
                  );
                }, childCount: widget.results.length),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanning frame overlay on the uploaded image
// ─────────────────────────────────────────────────────────────────────────────
class _ScannedImageFrame extends StatefulWidget {
  final File image;
  final bool isDark;

  const _ScannedImageFrame({required this.image, required this.isDark});

  @override
  State<_ScannedImageFrame> createState() => _ScannedImageFrameState();
}

class _ScannedImageFrameState extends State<_ScannedImageFrame> {
  Size? _naturalSize;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    final stream = FileImage(widget.image).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _naturalSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  /// Compute the rect where BoxFit.contain places the image inside [container].
  static Rect _containedRect(Size container, Size image) {
    final imgAspect = image.width / image.height;
    final ctnAspect = container.width / container.height;
    double w, h;
    if (imgAspect > ctnAspect) {
      w = container.width;
      h = container.width / imgAspect;
    } else {
      h = container.height;
      w = container.height * imgAspect;
    }
    final dx = (container.width - w) / 2;
    final dy = (container.height - h) / 2;
    return Rect.fromLTWH(dx, dy, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const containerHeight = 220.0;
          final containerSize = Size(constraints.maxWidth, containerHeight);

          final imageRect = _naturalSize != null
              ? _containedRect(containerSize, _naturalSize!)
              : null;

          return SizedBox(
            width: double.infinity,
            height: containerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                ColoredBox(
                  color: widget.isDark
                      ? AppColors.darkMainBackground
                      : AppColors.gray100,
                  child: Image.file(widget.image, fit: BoxFit.contain),
                ),
                // Corner brackets — only drawn once we know the image rect
                if (imageRect != null)
                  CustomPaint(painter: _LensScanPainter(imageRect: imageRect)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Draws transparent corner bracket markers at the actual image corners.
class _LensScanPainter extends CustomPainter {
  final Rect imageRect;

  const _LensScanPainter({required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    const armLen = 22.0;
    const strokeW = 2.5;
    const inset = 6.0;
    const cr = 14.0; // corner radius on the elbow of each bracket

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.90)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final l = imageRect.left + inset;
    final t = imageRect.top + inset;
    final r = imageRect.right - inset;
    final b = imageRect.bottom - inset;

    // [top-left, top-right, bottom-right, bottom-left]
    // Each entry: corner origin, horizontal direction, vertical direction
    final corners = [
      (Offset(l, t), 1.0, 1.0),
      (Offset(r, t), -1.0, 1.0),
      (Offset(r, b), -1.0, -1.0),
      (Offset(l, b), 1.0, -1.0),
    ];

    for (final (origin, sx, sy) in corners) {
      // Draw the bracket as a single continuous path so the corner can be
      // rounded: horizontal arm → arc → vertical arm.
      // clockwise direction alternates per corner to always give the 90° arc.
      final path = Path()
        ..moveTo(origin.dx + sx * armLen, origin.dy)
        ..lineTo(origin.dx + sx * cr, origin.dy)
        ..arcToPoint(
          Offset(origin.dx, origin.dy + sy * cr),
          radius: Radius.circular(cr),
          clockwise: sx * sy < 0,
        )
        ..lineTo(origin.dx, origin.dy + sy * armLen);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LensScanPainter old) => old.imageRect != imageRect;
}

// ─────────────────────────────────────────────────────────────────────────────
// Product card
// ─────────────────────────────────────────────────────────────────────────────
class _VisualSearchProductCard extends StatelessWidget {
  final VisualSearchResult result;
  final VoidCallback onTap;

  const _VisualSearchProductCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = result.product;
    final sellerName = product.seller ?? 'LIBAS';
    final displayImage =
        result.matchedImageUrl ??
        (product.images.isNotEmpty ? product.images.first : null);

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
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
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
                          return displayImage != null
                              ? CachedNetworkImage(
                                  imageUrl: displayImage,
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
                  // Similarity badge
                  if (result.similarity > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.amber,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              result.similarityLabel,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
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
            // Product info
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
                          color: theme.colorScheme.onSurface,
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
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                product.currency == 'USD'
                                    ? '\$${product.originalPrice}'
                                    : '${product.originalPrice!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
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
