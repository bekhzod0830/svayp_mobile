import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Read-only product detail screen used in the partner cashback flow.
/// Does NOT show like, cart, "Check Availability", or "Add to Cart" buttons.
class PartnerProductDetailScreen extends StatefulWidget {
  final Product product;

  const PartnerProductDetailScreen({super.key, required this.product});

  @override
  State<PartnerProductDetailScreen> createState() =>
      _PartnerProductDetailScreenState();
}

class _PartnerProductDetailScreenState
    extends State<PartnerProductDetailScreen> {
  final PageController _pageController = PageController();
  final ProductApiService _apiService = ProductApiService();

  String? _authToken;
  SellerInfo? _sellerInfo;
  bool _isLoadingSellerInfo = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _authToken = getIt<ApiClient>().getToken();
    final sellerId = widget.product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      setState(() => _isLoadingSellerInfo = true);
      _apiService
          .getSeller(sellerId: sellerId, token: _authToken)
          .then((info) {
            if (mounted) {
              setState(() {
                _sellerInfo = info;
                _isLoadingSellerInfo = false;
              });
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _isLoadingSellerInfo = false);
          });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(),
                  const SizedBox(height: 16),
                  _buildPriceSection(),
                  if (widget.product.colors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildColorsDisplay(),
                  ],
                  if (widget.product.sizes.isNotEmpty &&
                      !_isUniversalSizeOnly()) ...[
                    const SizedBox(height: 24),
                    _buildSizesDisplay(),
                  ],
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildDetails(),
                  const SizedBox(height: 24),
                  _buildLocationsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUniversalSizeOnly() {
    const universalSizes = {'One Size', 'Free Size', 'one_size', 'free_size'};
    return widget.product.sizes.every((s) => universalSizes.contains(s));
  }

  // ── Image Carousel ────────────────────────────────────────────────────────

  Widget _buildImageCarousel() {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double imageHeight = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: (screenSize.height * 0.5).clamp(300.0, 400.0),
      tablet: (screenSize.height * 0.6).clamp(400.0, 600.0),
      desktop: (screenSize.height * 0.6).clamp(500.0, 700.0),
    );

    if (widget.product.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: imageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              final imagePath = widget.product.images[index];
              final isAsset =
                  imagePath.startsWith('assets/') ||
                  imagePath.startsWith('lib/');
              return Container(
                color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
                child: isAsset
                    ? Image.asset(imagePath, fit: BoxFit.contain)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.contain,
                            cacheManager: ImageCacheManager.instance,
                            memCacheWidth: (constraints.maxWidth * 2).toInt(),
                            placeholder: (_, __) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.black,
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
              );
            },
          ),
        ),
        if (widget.product.images.length > 1) ...[
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
              dotColor: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.gray300,
            ),
          ),
        ],
      ],
    );
  }

  // ── Product Header ────────────────────────────────────────────────────────

  Widget _buildProductHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.brand,
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.localizedTitle(langCode),
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Price ─────────────────────────────────────────────────────────────────

  Widget _buildPriceSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDiscount =
        widget.product.discountPercentage != null &&
        widget.product.discountPercentage! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.product.formattedPrice,
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 8),
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
        ),
        if (hasDiscount && widget.product.formattedDiscountPrice != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.product.formattedDiscountPrice!,
            style: AppTypography.heading4.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ── Colors (read-only) ────────────────────────────────────────────────────

  Widget _buildColorsDisplay() {
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
            final isHex = color.startsWith('#');
            if (isHex) {
              Color c;
              try {
                c = Color(int.parse(color.replaceFirst('#', '0xFF')));
              } catch (_) {
                c = Colors.grey;
              }
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkStandardBorder
                        : AppColors.gray300,
                    width: 2,
                  ),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                color,
                style: AppTypography.body2.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Sizes (read-only) ─────────────────────────────────────────────────────

  Widget _buildSizesDisplay() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formatSize(String size) {
      if (size.toUpperCase().startsWith('SIZE_')) return size.substring(5);
      return size;
    }

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
            return Container(
              constraints: const BoxConstraints(
                minWidth: 56,
                maxWidth: 80,
                minHeight: 46,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray400,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? AppColors.darkCardBackground : AppColors.white,
              ),
              child: Center(
                child: Text(
                  formatSize(size),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTypography.body2.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Description ───────────────────────────────────────────────────────────

  Widget _buildDescription() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final desc = widget.product.localizedDescription(langCode);
    if (desc.isEmpty) return const SizedBox.shrink();

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
          desc,
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Details ───────────────────────────────────────────────────────────────

  Widget _buildDetails() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productDetails,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: l10n.category,
          value: _translatedCategory(widget.product.category, l10n),
        ),
        if (widget.product.subcategory != null &&
            widget.product.subcategory!.isNotEmpty)
          _DetailRow(
            label: l10n.subcategory,
            value: widget.product.subcategory!.join(', '),
          ),
        if (widget.product.material != null &&
            widget.product.material!.isNotEmpty)
          _DetailRow(
            label: l10n.material,
            value: widget.product.material!
                .map((m) => _translatedMaterial(m, l10n))
                .join(', '),
          ),
        if (widget.product.season != null && widget.product.season!.isNotEmpty)
          _DetailRow(
            label: l10n.season,
            value: widget.product.season!
                .map((s) => _translatedSeason(s, l10n))
                .join(', '),
          ),
        if (widget.product.countryOfOrigin != null &&
            widget.product.countryOfOrigin!.isNotEmpty)
          _DetailRow(
            label: l10n.countryOfOrigin,
            value: widget.product.countryOfOrigin!,
          ),
        _DetailRow(
          label: l10n.availability,
          value: widget.product.inStock ? l10n.inStock : l10n.outOfStock,
        ),
      ],
    );
  }

  // ── Locations ─────────────────────────────────────────────────────────────

  Widget _buildLocationsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final locations = _sellerInfo?.locations ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whereToBuy,
          style: AppTypography.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildSellerCard(),
        const SizedBox(height: 12),
        if (_isLoadingSellerInfo)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
          )
        else if (locations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 18,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
                const SizedBox(width: 10),
                Text(
                  'Contact the seller for store location',
                  style: AppTypography.body2.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
              ],
            ),
          )
        else
          ...locations.map(_buildLocationCard),
      ],
    );
  }

  Widget _buildSellerCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    String sellerName = widget.product.seller ?? widget.product.brand;
    if (sellerName == 'Unknown' || sellerName.isEmpty) sellerName = 'SVAYP';

    return GestureDetector(
      onTap: () {
        final sellerId = widget.product.sellerId;
        if (sellerId != null) _navigateToSellerProfile(sellerId, sellerName);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
          ),
        ),
        child: Row(
          children: [
            Builder(
              builder: (_) {
                final logo = _sellerInfo?.logoImg;
                if (logo != null && logo.isNotEmpty) {
                  return ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: logo,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _gradientAvatar(sellerName),
                      errorWidget: (_, __, ___) => _gradientAvatar(sellerName),
                    ),
                  );
                }
                return _gradientAvatar(sellerName);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.visitShop,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientAvatar(String name) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFF5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
    ];
    final colors = gradients[name.hashCode.abs() % gradients.length];
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: AppTypography.heading4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(SellerLocation location) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.name != null && location.name!.isNotEmpty)
            Text(
              location.name!,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          if (location.address != null && location.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.address!,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (location.phoneNumber != null &&
              location.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('tel:${location.phoneNumber}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location.phoneNumber!,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (location.hasCoordinates ||
              (location.address != null && location.address!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openMaps(
                location.latitude,
                location.longitude,
                location.address,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_outlined,
                      size: 16,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.getDirections,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.black : AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openMaps(double? lat, double? lon, String? address) async {
    Uri uri;
    if (lat != null && lon != null) {
      final l = lat.toStringAsFixed(6);
      final g = lon.toStringAsFixed(6);
      uri = Platform.isIOS
          ? Uri.parse('https://maps.apple.com/?ll=$l,$g&q=$l,$g')
          : Uri.parse('https://www.google.com/maps/search/?api=1&query=$l,$g');
    } else if (address != null && address.isNotEmpty) {
      final enc = Uri.encodeQueryComponent(address);
      uri = Platform.isIOS
          ? Uri.parse('https://maps.apple.com/?q=$enc')
          : Uri.parse('https://www.google.com/maps/search/?api=1&query=$enc');
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _navigateToSellerProfile(
    String sellerId,
    String sellerName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
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
      final response = await _apiService
          .getBrandDetail(brandId: sellerId, token: _authToken)
          .timeout(const Duration(seconds: 10));

      final sellerProducts = <Product>[];
      for (final p in response.products) {
        try {
          sellerProducts.add(_convertApiProduct(p));
        } catch (_) {}
      }

      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {
          Navigator.of(context).pop();
        }
      }
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(
              sellerId: sellerId,
              sellerName: sellerName,
              products: sellerProducts,
              sellerInfo: _sellerInfo,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 100));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load seller products. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Product _convertApiProduct(api_models.Product p) {
    final brand = (p.brand == 'Unknown' || p.brand.isEmpty)
        ? (p.seller ?? p.brand)
        : p.brand;
    return Product(
      id: p.id,
      title: p.title,
      description: p.description ?? '',
      price: p.price,
      brand: brand,
      category: p.originalCategoryString ?? p.category.value,
      subcategory: p.subcategory?.map((s) => s.displayName).toList(),
      images: p.images.isNotEmpty ? p.images : ['placeholder'],
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
      countryOfOrigin: p.countryOfOrigin,
      titleLocalized: p.titleLocalized,
      descriptionLocalized: p.descriptionLocalized,
    );
  }

  // ── Translation helpers (mirrors product_detail_screen.dart) ──────────────

  String _translatedCategory(String v, AppLocalizations l10n) {
    switch (v.toLowerCase().trim()) {
      case 'dress':
      case 'dresses':
        return l10n.categoryDress;
      case 'hijab':
        return l10n.categoryHijab;
      case 'abaya':
        return l10n.categoryAbaya;
      case 'tunic':
        return l10n.categoryTunic;
      case 'top':
      case 'tops':
        return l10n.categoryTop;
      case 'blouse':
        return l10n.categoryBlouse;
      case 'shirt':
        return l10n.categoryShirt;
      case 'pants':
        return l10n.categoryPants;
      case 'jeans':
        return l10n.categoryJeans;
      case 'skirt':
        return l10n.categorySkirt;
      case 'jacket':
        return l10n.categoryJacket;
      case 'coat':
        return l10n.categoryCoat;
      case 'cardigan':
        return l10n.categoryCardigan;
      case 'sweater':
        return l10n.categorySweater;
      case 'activewear':
        return l10n.categoryActivewear;
      case 'jumpsuit':
        return l10n.categoryJumpsuit;
      case 'scarf':
      case 'scarves':
        return l10n.categoryScarf;
      case 'shawl':
        return l10n.categoryShawl;
      case 'accessories':
        return l10n.categoryAccessories;
      case 'shoes':
        return l10n.categoryShoes;
      case 'bags':
      case 'bag':
        return l10n.categoryBags;
      case 'jewelry':
      case 'jewellery':
        return l10n.categoryJewelry;
      case 'underwear':
        return l10n.categoryUnderwear;
      case 'outerwear':
        return l10n.categoryOuterwear;
      default:
        return v.isNotEmpty ? v[0].toUpperCase() + v.substring(1) : v;
    }
  }

  String _translatedMaterial(String v, AppLocalizations l10n) {
    switch (v.toLowerCase().trim()) {
      case 'cotton':
        return l10n.materialCotton;
      case 'polyester':
        return l10n.materialPolyester;
      case 'silk':
        return l10n.materialSilk;
      case 'linen':
        return l10n.materialLinen;
      case 'wool':
        return l10n.materialWool;
      case 'chiffon':
        return l10n.materialChiffon;
      case 'satin':
        return l10n.materialSatin;
      case 'velvet':
        return l10n.materialVelvet;
      case 'denim':
        return l10n.materialDenim;
      case 'leather':
        return l10n.materialLeather;
      case 'viscose':
        return l10n.materialViscose;
      case 'mixed':
        return l10n.materialMixed;
      default:
        return v.isNotEmpty ? v[0].toUpperCase() + v.substring(1) : v;
    }
  }

  String _translatedSeason(String v, AppLocalizations l10n) {
    switch (v.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'spring':
        return l10n.seasonSpring;
      case 'summer':
        return l10n.seasonSummer;
      case 'fall':
      case 'autumn':
        return l10n.seasonFall;
      case 'winter':
        return l10n.seasonWinter;
      case 'all_season':
        return l10n.seasonAllSeason;
      default:
        return v.isNotEmpty ? v[0].toUpperCase() + v.substring(1) : v;
    }
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

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
