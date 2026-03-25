import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

/// Seller Profile Screen – redesigned with logo, about, locations and products grid
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

  late List<Product> _products;
  SellerInfo? _sellerInfo;
  bool _isLoadingMore = false;
  bool _isLoadingInitial = true;
  bool _hasMore = false;
  String? _authToken;
  static const int _pageSize = 20;

  // Cache keys scoped to this seller
  String get _infoCacheKey => 'seller_info_${widget.sellerId}';
  String get _productsCacheKey => 'seller_products_${widget.sellerId}';

  @override
  void initState() {
    super.initState();
    _products = List.of(widget.products);
    _sellerInfo = widget.sellerInfo; // may be null; always refreshed below
    _scrollController.addListener(_onScroll);
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) setState(() => _authToken = token);

    // Load from cache immediately, then refresh in background
    final hadCache = _loadFromCache(prefs);

    if (hadCache) {
      // Show cached data right away, refresh silently
      _refreshInBackground(token, prefs);
    } else {
      // No cache — fetch with loading indicator
      await Future.wait([
        _fetchSellerInfo(token, prefs: prefs),
        _loadInitialProducts(token, prefs: prefs),
      ]);
    }
  }

  /// Returns true if cache was found and applied.
  bool _loadFromCache(SharedPreferences prefs) {
    bool found = false;

    // Seller info
    final infoRaw = prefs.getString(_infoCacheKey);
    if (infoRaw != null) {
      try {
        final info = SellerInfo.fromJson(
          jsonDecode(infoRaw) as Map<String, dynamic>,
        );
        if (mounted) setState(() => _sellerInfo = info);
        found = true;
      } catch (_) {}
    }

    // Products
    final productsRaw = prefs.getString(_productsCacheKey);
    if (productsRaw != null) {
      try {
        final list = jsonDecode(productsRaw) as List<dynamic>;
        final cached = list
            .map((e) => api_models.Product.fromJson(e as Map<String, dynamic>))
            .map(_convertApiProduct)
            .toList();
        if (mounted) {
          setState(() {
            _products = cached;
            _hasMore = cached.length >= _pageSize;
            _isLoadingInitial = false;
          });
        }
        found = true;
      } catch (_) {}
    }

    return found;
  }

  Future<void> _refreshInBackground(
    String? token,
    SharedPreferences prefs,
  ) async {
    // Fire both requests in parallel, silently update UI when they complete
    await Future.wait([
      _fetchSellerInfo(token, prefs: prefs),
      _loadInitialProducts(token, prefs: prefs),
    ]);
  }

  Future<void> _fetchSellerInfo(
    String? token, {
    SharedPreferences? prefs,
  }) async {
    try {
      final info = await _apiService.getSeller(
        sellerId: widget.sellerId,
        token: token,
      );
      final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
      try {
        await resolvedPrefs.setString(_infoCacheKey, jsonEncode(info.toJson()));
      } catch (_) {}
      if (mounted) setState(() => _sellerInfo = info);
    } catch (_) {
      // Keep whatever was passed from the previous screen as fallback
    }
  }

  Future<void> _loadInitialProducts(
    String? token, {
    SharedPreferences? prefs,
  }) async {
    try {
      final response = await _apiService.getBrandDetail(
        brandId: widget.sellerId,
        skip: 0,
        limit: _pageSize,
        token: token,
      );
      final loaded = <Product>[];
      for (final apiProduct in response.products) {
        try {
          loaded.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }

      // Save raw api products to cache
      try {
        final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
        await resolvedPrefs.setString(
          _productsCacheKey,
          jsonEncode(response.products.map((p) => p.toJson()).toList()),
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (loaded.isNotEmpty) _products = loaded;
          _hasMore = loaded.length >= _pageSize;
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      // Fall back to whatever products were passed at navigation time
      if (mounted) {
        setState(() {
          _hasMore = widget.products.length >= _pageSize;
          _isLoadingInitial = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final response = await _apiService.getBrandDetail(
        brandId: widget.sellerId,
        skip: _products.length,
        limit: _pageSize,
        token: _authToken,
      );

      final newProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          newProducts.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }

      setState(() {
        _products.addAll(newProducts);
        _hasMore = newProducts.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Product _convertApiProduct(api_models.Product p) {
    final brand = (p.brand == 'Unknown' || p.brand.isEmpty)
        ? (p.seller ?? 'SVAYP')
        : p.brand;
    return Product(
      id: p.id,
      title: p.title,
      description: p.description ?? '',
      price: p.price,
      brand: brand,
      category: p.originalCategoryString ?? p.category.value,
      subcategory: p.subcategory?.map((s) => s.displayName).toList(),
      images: p.images.isNotEmpty
          ? p.images
          : ['https://via.placeholder.com/400'],
      sizes: p.sizes ?? [],
      colors: p.colors ?? [],
      material: p.material?.map((m) => m.displayName).toList(),
      season: p.season?.map((s) => s.displayName).toList(),
      currency: p.currency,
      rating: p.rating ?? 4.5,
      reviewCount: p.reviewCount ?? 0,
      inStock: p.inStock,
      isNew: p.isNew ?? false,
      isFeatured: false,
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
    final bgColor = isDark
        ? AppColors.darkMainBackground
        : const Color(0xFFF4F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky App Bar ─────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? AppColors.darkCardBackground
                : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.sellerName,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
          ),

          // ── Profile header ──────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(isDark, theme)),

          // ── About / Contact ─────────────────────────────────
          if (_sellerInfo != null)
            SliverToBoxAdapter(child: _buildAboutSection(isDark, theme, l10n)),

          // ── Locations ───────────────────────────────────────
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
                  const SizedBox(width: 8),
                  if (_isLoadingInitial)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkStandardBorder
                            : AppColors.gray200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_products.length}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Initial loading indicator ──────────────────────
          if (_isLoadingInitial)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          // ── Products Grid ──────────────────────────────────
          if (!_isLoadingInitial)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return _TikTokProductCard(
                    product: product,
                    showSeller: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    ),
                  );
                }, childCount: _products.length),
              ),
            ),

          // ── Load more indicator ───────────────────────────
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

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
                  color: Colors.black.withOpacity(0.1),
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
          // Stats
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
          colors: _getGradientColors(name),
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

  // ── About / Contact section ──────────────────────────────

  Widget _buildAboutSection(
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final info = _sellerInfo!;
    final hasDescription =
        info.description != null && info.description!.isNotEmpty;
    final hasPhone = info.phoneNumber != null && info.phoneNumber!.isNotEmpty;

    if (!hasDescription && !hasPhone) {
      return const SizedBox.shrink();
    }

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
          if (hasDescription) ...[
            Text(
              info.description!,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
                height: 1.5,
              ),
            ),
          ],
          if (hasDescription && hasPhone)
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
            _contactRow(
              icon: Icons.phone_outlined,
              text: info.phoneNumber!,
              isDark: isDark,
              theme: theme,
              onTap: () => _callPhone(info.phoneNumber!),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationsSection(
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final locations = _sellerInfo!.locations;
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
        ...locations.map((loc) => _buildLocationCard(loc, isDark, theme, l10n)),
      ],
    );
  }

  Widget _buildLocationCard(
    SellerLocation location,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          if (location.name != null && location.name!.isNotEmpty)
            Text(
              location.name!,
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          // Address
          if (location.address != null && location.address!.isNotEmpty) ...[
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
          // Phone
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
          // Directions button
          if (location.hasCoordinates ||
              (location.address != null && location.address!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openInMapsOrAddress(
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
                      l10n.getDirections,
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

  Widget _contactRow({
    required IconData icon,
    required String text,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                decoration: TextDecoration.underline,
                height: 1.4,
              ),
            ),
          ),
          Icon(
            Icons.open_in_new,
            size: 14,
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
          ),
        ],
      ),
    );
  }

  // ── Map / phone helpers ───────────────────────────────────

  Future<void> _openInMapsOrAddress(
    double? lat,
    double? lon,
    String? address,
  ) async {
    Uri uri;
    if (lat != null && lon != null) {
      // Use coordinates — format so it always drops a visible pin
      final latStr = lat.toStringAsFixed(6);
      final lonStr = lon.toStringAsFixed(6);
      uri = Platform.isIOS
          ? Uri.parse(
              'https://maps.apple.com/?ll=$latStr,$lonStr&q=$latStr,$lonStr',
            )
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$latStr,$lonStr',
            );
    } else if (address != null && address.isNotEmpty) {
      final encoded = Uri.encodeQueryComponent(address);
      uri = Platform.isIOS
          ? Uri.parse('https://maps.apple.com/?q=$encoded')
          : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$encoded',
            );
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
            Expanded(
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
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
                      if (product.originalPrice != null &&
                          product.originalPrice != product.price) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatPrice(
                              product.originalPrice!,
                              product.currency,
                            ),
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
                  const Spacer(),
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
          ),
        ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price, String? currency) {
    if (currency == 'USD') return '\$$price';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} UZS';
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
