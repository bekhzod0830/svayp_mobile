import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/services/seller_cache_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/tryon/presentation/tryon_sheet.dart';
import 'package:swipe/features/tryon/presentation/widgets/try_on_pill.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/shared/widgets/map_preview_card.dart';

const _kShadowBlack08 = Color(0x14000000);
const _kShadowBlack30 = Color(0x4D000000);

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final List<Product> products;
  final SellerInfo? sellerInfo;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.products,
    this.sellerInfo,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final ProductApiService _apiService = ProductApiService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  SellerInfo? _sellerInfo;
  bool _isLoadingMore = false;
  bool _isLoadingInitial = true;
  bool _hasMore = true;
  // Skip pointer advances by _pageSize each successful batch.
  int _skip = 0;
  // Server-reported total — set on first response, drives hasMore reliably
  // regardless of how many items the server actually returns per batch.
  int _serverTotal = 0;
  String? _authToken;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _sellerInfo = widget.sellerInfo;
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) setState(() => _authToken = token);
    // Seller info passed in by the caller is already complete — refetching it
    // on every open is a wasted GET /sellers/{id}. Seed the shared cache so
    // other screens (ProductDetail) reuse it too.
    final passedInfo = widget.sellerInfo;
    if (passedInfo != null) {
      SellerCacheService.instance.put(passedInfo);
    }
    await Future.wait([
      if (passedInfo == null) _fetchSellerInfo(token),
      _fetchInitialProducts(token),
    ]);
  }

  Future<void> _fetchSellerInfo(String? token) async {
    try {
      final info = await SellerCacheService.instance.getSeller(
        sellerId: widget.sellerId,
        token: token,
      );
      if (mounted) setState(() => _sellerInfo = info);
    } catch (_) {}
  }

  Future<void> _fetchInitialProducts(String? token) async {
    try {
      final response = await _apiService.getBrandDetail(
        brandId: widget.sellerId,
        skip: 0,
        limit: _pageSize,
        token: token,
      );

      final loaded = <Product>[];
      for (final p in response.products) {
        try {
          loaded.add(_convertApiProduct(p));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _products = loaded;
          _skip = loaded.length;
          if (response.total > 0) _serverTotal = response.total;
          _hasMore = _serverTotal > _skip;
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  void _onScroll() {
    if (_isLoadingInitial) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 600 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    // Capture and advance skip before the async gap so concurrent scroll
    // events cannot fire two requests for the same offset.
    final skip = _skip;
    _skip += _pageSize;
    try {
      final response = await _apiService.getBrandDetail(
        brandId: widget.sellerId,
        skip: skip,
        limit: _pageSize,
        token: _authToken,
      );

      final newProducts = <Product>[];
      for (final p in response.products) {
        try {
          newProducts.add(_convertApiProduct(p));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _products.addAll(newProducts);
          if (response.total > 0) _serverTotal = response.total;
          _hasMore = _serverTotal > _skip;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      _skip = skip; // rewind on failure so the page can be retried
      if (mounted) setState(() => _isLoadingMore = false);
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
      inStock: p.inStock,
      catalogReady: p.catalogReady,
      isNew: p.isNew ?? false,
      isFeatured: p.isFeatured ?? false,
      seller: p.seller,
      sellerId: p.sellerId,
      discountPercentage: p.discountPercentage,
      originalPrice: p.originalPrice,
      titleLocalized: p.titleLocalized,
      descriptionLocalized: p.descriptionLocalized,
    );
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkMainBackground
        : const Color(0xFFF4F4F6);
    final topPadding = MediaQuery.of(context).padding.top;
    const headerHeight = 56.0;
    final headerTotal = topPadding + headerHeight + 8.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // ── Top spacing to clear floating glass header ────────
              SliverToBoxAdapter(child: SizedBox(height: headerTotal)),

              // ── Profile Header ──────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(isDark, theme)),

              // ── About / Contact ─────────────────────────────────
              if (_sellerInfo != null)
                SliverToBoxAdapter(
                  child: _buildAboutSection(isDark, theme, l10n),
                ),

              // ── Locations (where to buy) ─────────────────────────
              if (_sellerInfo != null && _sellerInfo!.locations.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildLocationsSection(isDark, theme, l10n),
                ),

              // ── Products header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        l10n.allProducts,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (_isLoadingInitial) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Initial loading ──────────────────────────────────
              if (_isLoadingInitial)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),

              // ── Products Grid ────────────────────────────────────
              if (!_isLoadingInitial)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: () {
                        // 16+16+12 = 44px total horizontal space (matches shop_screen)
                        final cardW =
                            (MediaQuery.of(context).size.width - 44) / 2;
                        return cardW / (cardW * 5 / 4 + 88);
                      }(),
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _products[index];
                      return RepaintBoundary(
                        child: _TikTokProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          ),
                          onSellerTap: () {},
                        ),
                      );
                    }, childCount: _products.length),
                  ),
                ),

              // ── Load more spinner ────────────────────────────────
              if (_isLoadingMore)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              // ── Bottom clearance for floating nav bar ────────────
              SliverToBoxAdapter(
                child: Builder(
                  builder: (ctx) => SizedBox(
                    height: MediaQuery.of(ctx).viewPadding.bottom + 80,
                  ),
                ),
              ),
            ],
          ),

          // ── Floating liquid glass header ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: headerTotal,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xD0050508)
                        : const Color(0xB8FFFFFF),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x28000000),
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.sellerName,
                            style: AppTypography.body1.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────

  Widget _buildHeader(bool isDark, ThemeData theme) {
    final logoUrl = _sellerInfo?.logoImg;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      cacheManager: ImageCacheManager.instance,
                      placeholder: (_, __) =>
                          _avatarFallback(widget.sellerName),
                      errorWidget: (_, __, ___) =>
                          _avatarFallback(widget.sellerName),
                    )
                  : _avatarFallback(widget.sellerName),
            ),
          ),
          const SizedBox(height: 14),
          // Name
          Text(
            widget.sellerName,
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Product count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkMainBackground
                  : const Color(0xFFF4F4F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_sellerInfo?.productCount ?? _products.length}',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' ${AppLocalizations.of(context)!.products}',
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
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors(name),
        ),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: AppTypography.heading1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
      ),
    );
  }

  // ── About / Contact ─────────────────────────────────────────

  Widget _buildAboutSection(
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final info = _sellerInfo!;
    final hasDesc = info.description != null && info.description!.isNotEmpty;
    final hasPhone = info.phoneNumber != null && info.phoneNumber!.isNotEmpty;
    if (!hasDesc && !hasPhone) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDesc)
            Text(
              info.description!,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
                height: 1.5,
              ),
            ),
          if (hasDesc && hasPhone)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray200,
              ),
            ),
          if (hasPhone)
            GestureDetector(
              onTap: () => _callPhone(info.phoneNumber!),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.phoneNumber!,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                        decoration: TextDecoration.underline,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray400,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Locations ───────────────────────────────────────────────

  Widget _buildLocationsSection(
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.whereToBuy,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        ..._sellerInfo!.locations.map(
          (loc) => _buildLocationCard(loc, isDark, theme),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    SellerLocation location,
    bool isDark,
    ThemeData theme,
  ) {
    final hasMap =
        location.hasCoordinates ||
        (location.address != null && location.address!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMap)
            MapPreviewCard(
              latitude: location.latitude,
              longitude: location.longitude,
              address: location.address,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.name != null && location.name!.isNotEmpty)
                  Text(
                    location.name!,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (location.address != null &&
                    location.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
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
                            height: 1.4,
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
                    onTap: () => _callPhone(location.phoneNumber!),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 15,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  List<Color> _gradientColors(String name) {
    const gradients = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFFf093fb), Color(0xFFF5576c)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
      [Color(0xFFfa709a), Color(0xFFfee140)],
      [Color(0xFF30cfd0), Color(0xFF330867)],
      [Color(0xFFa8edea), Color(0xFFfed6e3)],
      [Color(0xFFff9a9e), Color(0xFFfecfef)],
    ];
    return gradients[name.hashCode.abs() % gradients.length];
  }
}

// ── Product Card (matches shop_screen exactly) ────────────────────────────────

class _TikTokProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onSellerTap;

  const _TikTokProductCard({
    required this.product,
    required this.onTap,
    required this.onSellerTap,
  });

  /// Open the virtual try-on for any product. Если каноничная вещь не готова,
  /// бэкенд подставит фото товара как гармент. Mirrors the discovery deck.
  void _handleTryOn(BuildContext context) {
    HapticFeedback.selectionClick();
    showProductTryOnSheet(
      context,
      productId: product.id,
      previewImage: product.images.isNotEmpty ? product.images.first : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sellerName = product.seller ?? 'LIBAS';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? _kShadowBlack30 : _kShadowBlack08,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
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
                          return CachedNetworkImage(
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : 'https://via.placeholder.com/400',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            cacheManager: ImageCacheManager.instance,
                            memCacheWidth: cacheWidth,
                            placeholder: (_, __) => Container(
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
                            errorWidget: (_, __, ___) => Container(
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
                  // Try-on pill — bottom-right of the image (matches discovery).
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: TryOnPill(
                      compact: true,
                      showCost: false,
                      onTap: () => _handleTryOn(context),
                    ),
                  ),
                ],
              ),
            ),
            // Info section — fixed 88px (matches shop_screen)
            SizedBox(
              height: 88,
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price + optional crossed-out original
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
                      // Seller name
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
