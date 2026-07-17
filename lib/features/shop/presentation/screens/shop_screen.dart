import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/services/seller_cache_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/features/shop/presentation/screens/sellers_list_screen.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/shared/widgets/main_top_bar.dart';
import 'dart:ui';
import 'package:swipe/core/analytics/analytics_events.dart';
import 'package:swipe/core/analytics/analytics_service.dart';
import 'package:swipe/features/shop/presentation/utils/visual_search_launcher.dart';
import 'package:flutter/services.dart';
import 'package:swipe/features/tryon/presentation/tryon_sheet.dart';
import 'package:swipe/features/tryon/presentation/widgets/try_on_pill.dart';

// Pre-computed colors to avoid withOpacity() allocations during rebuilds
const _kShadowBlack08 = Color(0x14000000); // black.withOpacity(0.08)
const _kShadowBlack30 = Color(0x4D000000); // black.withOpacity(0.30)

/// Shop Screen - Browse and search for products (TikTok Shop style)
/// Features: 2-column grid, seller info, tabs, ChatGPT-style search
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ProductApiService _apiService = ProductApiService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  List<Product> _trendingProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  static const int _trendingLimit = 20;
  // Trending-specific pagination
  int _trendingSkip = 0;
  bool _hasMoreTrending = true;
  bool _isLoadingMoreTrending = false;
  String? _errorMessage;
  int _selectedTab = 0; // 0: Trending, 1: All, 2+: Category
  bool _hasLoadedOnce = false;
  String? _authToken;

  // Category tab state – active display
  List<Product> _categoryProducts = [];
  int _categoryPage = 0;
  bool _hasMoreCategory = true;
  bool _isLoadingMoreCategory = false;
  String? _currentCategory;

  // ── Cache ────────────────────────────────────────────────
  static const Duration _kCacheTtl = Duration(hours: 24);

  // Trending cache
  DateTime? _trendingLoadedAt;

  // All-products cache
  DateTime? _allLoadedAt;

  // Per-category cache: key = API category string
  final Map<String, List<Product>> _categoryProductCache = {};
  final Map<String, DateTime> _categoryLoadedAt = {};
  final Map<String, int> _categoryPageCache = {};
  final Map<String, bool> _categoryHasMoreCache = {};
  // ─────────────────────────────────────────────────────────

  // ── Seller / shop filter ─────────────────────────────────
  List<SellerInfo> _sellers = [];
  String? _selectedSellerId; // null = All Shops
  List<Product> _sellerProducts = [];
  bool _isLoadingSellers = false;
  // ─────────────────────────────────────────────────────────

  // Ordered list of category API values matching tab indices 2..
  // Order must match the chips built in the ListView below.
  static const List<String> _kCategoryApiValues = [
    'TOPWEAR', // tab 2
    'BOTTOMWEAR', // tab 3
    'ISLAMIC_MODEST_WEAR', // tab 4
    'DRESSES', // tab 5
    'ONE_PIECE', // tab 6
    'TWO_PIECE_SET', // tab 7
    'THREE_PIECE_SET', // tab 8
    'FOOTWEAR', // tab 9
    'OUTERWEAR', // tab 10
    'ACTIVEWEAR', // tab 11
    'HOMEWEAR', // tab 12
    'UNDERWEAR', // tab 13
    'ACCESSORIES', // tab 14
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initAuth();
    _loadTrendingProducts(); // fire independently so it never blocked by _loadProducts
    _loadSellers();
  }

  Future<void> _initAuth() async {
    try {
      // Get authentication token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      // Load products after auth is initialized
      if (!_hasLoadedOnce) {
        _hasLoadedOnce = true;
        await _loadProducts();
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      if (_selectedTab == 0) {
        // Trending tab
        if (!_isLoadingMoreTrending && _hasMoreTrending) {
          _loadMoreTrendingProducts();
        }
      } else if (_selectedTab == 1) {
        // All tab
        if (!_isLoadingMore && _hasMoreProducts) {
          _loadMoreProducts();
        }
      } else {
        // Category tab
        if (!_isLoadingMoreCategory && _hasMoreCategory) {
          _loadMoreCategoryProducts();
        }
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
      _hasMoreProducts = true;
    });

    try {
      // Fetch products from API with pagination
      final response = await _apiService.getProducts(
        page: 0,
        size: _pageSize,
        token: _authToken,
      );

      // Convert API products to local Product entities
      final products = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          products.add(product);
        } catch (e) {
          // Skip products that fail to convert
        }
      }

      setState(() {
        _products = products;
        _isLoading = false;
        _hasMoreProducts = products.length >= _pageSize;
        if (products.isNotEmpty) _currentPage = 1;
        _allLoadedAt = DateTime.now();
      });
      _filterProducts();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load products. Please check your connection and try again.';
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _apiService.getProducts(
        page: _currentPage,
        size: _pageSize,
        token: _authToken,
      );

      final newProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          newProducts.add(product);
        } catch (e) {}
      }

      // Filter out duplicates
      final existingIds = _products.map((p) => p.id).toSet();
      final uniqueProducts = newProducts
          .where((p) => !existingIds.contains(p.id))
          .toList();

      setState(() {
        _products.addAll(uniqueProducts);
        _isLoadingMore = false;
        _hasMoreProducts = newProducts.length >= _pageSize;
        if (uniqueProducts.isNotEmpty) _currentPage++;
      });
      _filterProducts();
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Fetch trending products from GET /feed/trending?skip=0&limit=20
  Future<void> _loadTrendingProducts() async {
    setState(() {
      _trendingSkip = 0;
      _hasMoreTrending = true;
      _trendingProducts = [];
    });
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>(
        '/feed/trending',
        queryParameters: {'limit': '$_trendingLimit', 'skip': '0'},
      );
      final trending = _parseTrendingResponse(response.data);
      if (mounted) {
        setState(() {
          _trendingProducts = trending;
          _hasMoreTrending = trending.length >= _trendingLimit;
          _trendingSkip = trending.length;
          _trendingLoadedAt = DateTime.now();
        });
        _filterProducts();
      }
    } catch (_) {}
  }

  /// Load next page of trending products
  Future<void> _loadMoreTrendingProducts() async {
    if (_isLoadingMoreTrending || !_hasMoreTrending) return;
    setState(() => _isLoadingMoreTrending = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>(
        '/feed/trending',
        queryParameters: {'limit': '$_trendingLimit', 'skip': '$_trendingSkip'},
      );
      final newItems = _parseTrendingResponse(response.data);
      final existingIds = _trendingProducts.map((p) => p.id).toSet();
      final unique = newItems
          .where((p) => !existingIds.contains(p.id))
          .toList();
      if (mounted) {
        setState(() {
          _trendingProducts.addAll(unique);
          _isLoadingMoreTrending = false;
          _hasMoreTrending = newItems.length >= _trendingLimit;
          _trendingSkip += newItems.length;
        });
        _filterProducts();
      }
    } catch (_) {
      setState(() => _isLoadingMoreTrending = false);
    }
  }

  /// Load initial products for a category tab
  Future<void> _loadCategoryProducts(String category) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _categoryProducts = [];
      _categoryPage = 0;
      _hasMoreCategory = true;
      _currentCategory = category;
    });

    try {
      final response = await _apiService.getProducts(
        page: 0,
        size: _pageSize,
        category: category,
        token: _authToken,
      );

      final products = <Product>[];
      for (final apiProduct in response.products) {
        try {
          products.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }

      if (mounted) {
        // Persist in cache
        _categoryProductCache[category] = products;
        _categoryLoadedAt[category] = DateTime.now();
        _categoryPageCache[category] = products.isNotEmpty ? 1 : 0;
        _categoryHasMoreCache[category] = products.length >= _pageSize;
        setState(() {
          _categoryProducts = products;
          _isLoading = false;
          _hasMoreCategory = _categoryHasMoreCache[category]!;
          _categoryPage = _categoryPageCache[category]!;
        });
        _filterProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load products. Please check your connection and try again.';
        });
      }
    }
  }

  /// Load next page for the current category tab
  Future<void> _loadMoreCategoryProducts() async {
    if (_isLoadingMoreCategory ||
        !_hasMoreCategory ||
        _currentCategory == null) {
      return;
    }
    setState(() => _isLoadingMoreCategory = true);
    try {
      final response = await _apiService.getProducts(
        page: _categoryPage,
        size: _pageSize,
        category: _currentCategory,
        token: _authToken,
      );
      final newProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          newProducts.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }
      final existingIds = _categoryProducts.map((p) => p.id).toSet();
      final unique = newProducts
          .where((p) => !existingIds.contains(p.id))
          .toList();
      if (mounted) {
        setState(() {
          _categoryProducts.addAll(unique);
          _isLoadingMoreCategory = false;
          _hasMoreCategory = newProducts.length >= _pageSize;
          if (unique.isNotEmpty) _categoryPage++;
        });
        // Keep cache in sync with the newly extended list
        if (_currentCategory != null) {
          _categoryProductCache[_currentCategory!] = List.of(_categoryProducts);
          _categoryPageCache[_currentCategory!] = _categoryPage;
          _categoryHasMoreCache[_currentCategory!] = _hasMoreCategory;
        }
        _filterProducts();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreCategory = false);
    }
  }

  // ── Cache helpers ─────────────────────────────────────────

  bool _isCacheFresh(DateTime? loadedAt) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _kCacheTtl;
  }

  /// Silent background refresh for the Trending tab (no spinner).
  Future<void> _backgroundRefreshTrending() async {
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>(
        '/feed/trending',
        queryParameters: {'limit': '$_trendingLimit', 'skip': '0'},
      );
      final fresh = _parseTrendingResponse(response.data);
      if (mounted) {
        setState(() {
          _trendingProducts = fresh;
          _hasMoreTrending = fresh.length >= _trendingLimit;
          _trendingSkip = fresh.length;
          _trendingLoadedAt = DateTime.now();
        });
        if (_selectedTab == 0) _filterProducts();
      }
    } catch (_) {}
  }

  /// Silent background refresh for the All tab (no spinner).
  Future<void> _backgroundRefreshAll() async {
    try {
      final response = await _apiService.getProducts(
        page: 0,
        size: _pageSize,
        token: _authToken,
      );
      final products = <Product>[];
      for (final apiProduct in response.products) {
        try {
          products.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _products = products;
          _hasMoreProducts = products.length >= _pageSize;
          _currentPage = products.isNotEmpty ? 1 : 0;
          _allLoadedAt = DateTime.now();
        });
        if (_selectedTab == 1) _filterProducts();
      }
    } catch (_) {}
  }

  /// Silent background refresh for a category tab (no spinner).
  Future<void> _backgroundRefreshCategory(String category) async {
    try {
      final response = await _apiService.getProducts(
        page: 0,
        size: _pageSize,
        category: category,
        token: _authToken,
      );
      final products = <Product>[];
      for (final apiProduct in response.products) {
        try {
          products.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }
      if (mounted) {
        _categoryProductCache[category] = products;
        _categoryLoadedAt[category] = DateTime.now();
        _categoryPageCache[category] = products.isNotEmpty ? 1 : 0;
        _categoryHasMoreCache[category] = products.length >= _pageSize;
        // Only update active display if still on this category
        if (_currentCategory == category) {
          setState(() {
            _categoryProducts = products;
            _categoryPage = _categoryPageCache[category]!;
            _hasMoreCategory = _categoryHasMoreCache[category]!;
          });
          if (_selectedTab >= 2) _filterProducts();
        }
      }
    } catch (_) {}
  }

  /// Pull-to-refresh: always force a full reload of the current tab.
  Future<void> _refreshCurrentTab() async {
    if (_selectedSellerId != null) {
      await _loadSellerProducts(_selectedSellerId!);
      return;
    }
    if (_selectedTab == 0) {
      await _loadTrendingProducts();
    } else if (_selectedTab == 1) {
      await _loadProducts();
    } else {
      final category = _kCategoryApiValues[_selectedTab - 2];
      await _loadCategoryProducts(category);
    }
  }

  Future<void> _loadSellers() async {
    if (_isLoadingSellers) return;
    setState(() => _isLoadingSellers = true);
    try {
      final results = await _apiService.getSellers(
        skip: 0,
        limit: 100,
        token: _authToken,
      );
      // Seed the shared cache — ProductDetail then opens sellers for free.
      results.forEach(SellerCacheService.instance.put);
      if (mounted) setState(() => _sellers = results);
    } catch (_) {
      // Sellers list is optional – failure is non-fatal
    } finally {
      if (mounted) setState(() => _isLoadingSellers = false);
    }
  }

  Future<void> _loadSellerProducts(String sellerId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getBrandDetail(
        brandId: sellerId,
        skip: 0,
        limit: 60,
        token: _authToken,
      );
      final products = <Product>[];
      for (final apiProduct in response.products) {
        try {
          products.add(_convertApiProduct(apiProduct));
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _sellerProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onShopSelected(String? sellerId) {
    if (_selectedSellerId == sellerId) return;
    setState(() => _selectedSellerId = sellerId);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (sellerId == null) {
      _refreshCurrentTab();
    } else {
      _loadSellerProducts(sellerId);
    }
  }

  /// Parse raw response data into a list of Products
  List<Product> _parseTrendingResponse(dynamic data) {
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['products'] ?? data['content'];
      if (inner is List) raw = inner;
    }
    final result = <Product>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(_convertApiProduct(api_models.Product.fromJson(item)));
        } catch (_) {}
      }
    }
    return result;
  }

  /// Convert API product model to local Product entity
  Product _convertApiProduct(api_models.Product apiProduct) {
    // Use seller if brand is "Unknown" or if seller is available
    final displayBrand =
        (apiProduct.brand == 'Unknown' || apiProduct.brand.isEmpty)
        ? (apiProduct.seller ?? apiProduct.brand)
        : apiProduct.brand;

    return Product(
      id: apiProduct.id,
      title: apiProduct.title,
      description: apiProduct.description ?? '',
      price: apiProduct.price,
      brand: displayBrand,
      category:
          apiProduct.originalCategoryString ??
          apiProduct.category.value, // Use original string if available
      subcategory: apiProduct.subcategory?.map((s) => s.displayName).toList(),
      images: apiProduct.images.isNotEmpty
          ? apiProduct.images
          : ['placeholder'],
      // Convert enum lists to string lists for the old Product entity
      sizes: apiProduct.sizes ?? [],
      colors: apiProduct.colors ?? [],
      material: apiProduct.material?.map((m) => m.displayName).toList(),
      season: apiProduct.season?.map((s) => s.displayName).toList(),
      currency: apiProduct.currency,
      rating: apiProduct.rating ?? 4.5,
      reviewCount: apiProduct.reviewCount ?? 0,
      isNew: apiProduct.isNew ?? false,
      isFeatured: apiProduct.isFeatured ?? false,
      inStock: apiProduct.inStock,
      catalogReady: apiProduct.catalogReady,
      seller: apiProduct.seller,
      sellerId: apiProduct.sellerId,
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
      titleLocalized: apiProduct.titleLocalized,
      descriptionLocalized: apiProduct.descriptionLocalized,
    );
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      AnalyticsService.instance.logEvent(AnalyticsEvents.searchInitiated);
    }
    setState(() {
      // Seller mode: filter seller products locally
      if (_selectedSellerId != null) {
        _filteredProducts = _sellerProducts.where((product) {
          return query.isEmpty ||
              product.title.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query);
        }).toList();
        return;
      }

      // Trending tab: show _trendingProducts directly (different source from _products)
      if (_selectedTab == 0) {
        final source = _trendingProducts.isNotEmpty
            ? _trendingProducts
            : _products;
        _filteredProducts = source.where((product) {
          return query.isEmpty ||
              product.title.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
        }).toList();
        return;
      }

      // Category tab (index >= 2)
      if (_selectedTab >= 2) {
        _filteredProducts = _categoryProducts.where((product) {
          return query.isEmpty ||
              product.title.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
        }).toList();
        return;
      }

      // All tab (index == 1)
      _filteredProducts = _products.where((product) {
        return query.isEmpty ||
            product.title.toLowerCase().contains(query) ||
            product.brand.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onProductTap(Product product) {
    // Navigate to product detail screen
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _onSellerTap(String sellerName) {
    // Filter products by seller
    final sellerProducts = _products
        .where((p) => (p.seller ?? 'LIBAS') == sellerName)
        .toList();

    if (sellerProducts.isEmpty) return;

    // Get sellerId from first product (all products from same seller should have same sellerId)
    final sellerId = sellerProducts.first.sellerId ?? 'unknown';

    // Navigate to seller profile
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(
          sellerId: sellerId,
          sellerName: sellerName,
          products: sellerProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Glass Header with title
                MainTopBar(
                  title: l10n.shop,
                  extraActions: const [],
                  showBackButton: false,
                ),

                // Filter row: Categories (left) + Shops (right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterRow(isDark, l10n),
                ),

                const SizedBox(height: 12),

                // Product Grid (TikTok-style 2-column)
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark, l10n)
                      : _errorMessage != null
                      ? RefreshIndicator(
                          onRefresh: _refreshCurrentTab,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: _buildErrorState(l10n),
                            ),
                          ),
                        )
                      : _filteredProducts.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _refreshCurrentTab,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: _buildEmptyState(l10n),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshCurrentTab,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final product = _filteredProducts[index];
                                    return RepaintBoundary(
                                      child: _TikTokProductCard(
                                        product: product,
                                        onTap: () => _onProductTap(product),
                                        onSellerTap: () => _onSellerTap(
                                          product.seller ?? 'LIBAS',
                                        ),
                                      ),
                                    );
                                  }, childCount: _filteredProducts.length),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: () {
                                          // Grid padding: 16 each side + 12 cross-spacing → 44px total
                                          final cardW =
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  44) /
                                              2;
                                          // Image: 4:5 → height = cardW * 5/4; info section: 88px fixed
                                          return cardW / (cardW * 5 / 4 + 88);
                                        }(),
                                      ),
                                ),
                              ),
                              if (_isLoadingMore ||
                                  _isLoadingMoreTrending ||
                                  _isLoadingMoreCategory)
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
                              SliverToBoxAdapter(
                                // Extra clearance so last card scrolls above
                                // the search bar (52px) + navbar (60px) + gaps.
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(
                                        context,
                                      ).viewPadding.bottom +
                                      160,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // Visual Search — floating button in the bottom-right corner.
            // Moved here from the bottom nav bar's center slot.
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 84,
              child: _AnimatedVisualSearchButton(
                label: l10n.visualSearch,
                onTap: () {
                  AnalyticsService.instance.logEvent(
                    AnalyticsEvents.visualSearchOpened,
                  );
                  launchVisualSearch(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    if (index >= 2) {
      final kCategoryLabels = [
        'TOPWEAR', 'BOTTOMWEAR', 'ISLAMIC_MODEST_WEAR', 'DRESSES',
        'ONE_PIECE', 'TWO_PIECE_SET', 'THREE_PIECE_SET', 'FOOTWEAR',
        'OUTERWEAR', 'ACTIVEWEAR', 'HOMEWEAR', 'UNDERWEAR', 'ACCESSORIES',
      ];
      final catIdx = index - 2;
      if (catIdx < kCategoryLabels.length) {
        AnalyticsService.instance.logEvent(
          AnalyticsEvents.categoryFilterSelected,
          parameters: {AnalyticsEvents.paramCategory: kCategoryLabels[catIdx]},
        );
      }
    }

    if (index == 0) {
      // ── Trending ──────────────────────────────────────────
      if (_trendingProducts.isNotEmpty && _isCacheFresh(_trendingLoadedAt)) {
        // Cache is valid: show immediately, refresh silently
        _filterProducts();
        _backgroundRefreshTrending();
      } else {
        _loadTrendingProducts();
      }
    } else if (index == 1) {
      // ── All ───────────────────────────────────────────────
      if (_products.isNotEmpty && _isCacheFresh(_allLoadedAt)) {
        _filterProducts();
        _backgroundRefreshAll();
      } else {
        _loadProducts();
      }
    } else {
      // ── Category ──────────────────────────────────────────
      final category = _kCategoryApiValues[index - 2];
      final cached = _categoryProductCache[category];
      if (cached != null &&
          cached.isNotEmpty &&
          _isCacheFresh(_categoryLoadedAt[category])) {
        // Restore pagination state & show immediately
        setState(() {
          _currentCategory = category;
          _categoryProducts = cached;
          _categoryPage = _categoryPageCache[category] ?? 1;
          _hasMoreCategory = _categoryHasMoreCache[category] ?? false;
        });
        _filterProducts();
        _backgroundRefreshCategory(category);
      } else {
        _loadCategoryProducts(category);
      }
    }
  }

  Widget _buildFilterRow(bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: _buildCategoryButton(isDark, l10n)),
        const SizedBox(width: 10),
        Expanded(child: _buildShopsButton(isDark, l10n)),
      ],
    );
  }

  Widget _buildShopsButton(bool isDark, AppLocalizations l10n) {
    final isActive = _selectedSellerId != null;
    final label = isActive
        ? (_sellers.where((s) => s.id == _selectedSellerId).firstOrNull?.name ??
              l10n.shops)
        : l10n.shops;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => const SellersListScreen()));
        AnalyticsService.instance.logEvent(AnalyticsEvents.sellerFilterApplied);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? (isDark ? Colors.white54 : Colors.black54)
                : (isDark ? AppColors.darkStandardBorder : AppColors.gray200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 16,
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(bool isDark, AppLocalizations l10n) {
    final categoryLabels = [
      l10n.trending,
      l10n.all,
      l10n.vsCatTopwear,
      l10n.vsCatBottomwear,
      l10n.vsCatModestWear,
      l10n.vsCatDresses,
      l10n.vsCatOnePiece,
      l10n.vsCatTwoPieceSet,
      l10n.vsCatThreePieceSet,
      l10n.vsCatFootwear,
      l10n.vsCatOuterwear,
      l10n.vsCatActivewear,
      l10n.vsCatHomewear,
      l10n.vsCatUnderwear,
      l10n.vsCatAccessories,
    ];
    final label = l10n.categories;

    return GestureDetector(
      onTap: () async {
        final picked = await Navigator.of(context, rootNavigator: true)
            .push<int>(
              MaterialPageRoute(
                builder: (_) => _CategoryPickerScreen(
                  selectedIndex: _selectedTab,
                  categories: categoryLabels,
                ),
              ),
            );
        if (picked != null && mounted) _onTabSelected(picked);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 16,
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shopLoadingProducts,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.shopErrorTitle,
              style: AppTypography.heading3.copyWith(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.shopErrorSubtitle,
              style: AppTypography.body2.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                l10n.shopRetry,
                style: AppTypography.body1.copyWith(
                  color: isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.gray400),
            const SizedBox(height: 24),
            Text(
              l10n.noProductsFound,
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tryAdjustingFilters,
              style: AppTypography.body1.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// TikTok-style Product Card with Seller Info
class _TikTokProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onSellerTap;

  const _TikTokProductCard({
    required this.product,
    required this.onTap,
    required this.onSellerTap,
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
                  // Seller Avatar (TikTok-style - bottom left, tappable)
                  // COMMENTED OUT - TikTok style circle
                  // Positioned(
                  //   bottom: 8,
                  //   left: 8,
                  //   child: GestureDetector(
                  //     onTap: onSellerTap,
                  //     child: Container(
                  //       width: 32,
                  //       height: 32,
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         gradient: LinearGradient(
                  //           begin: Alignment.topLeft,
                  //           end: Alignment.bottomRight,
                  //           colors: _getGradientColors(sellerName),
                  //         ),
                  //         border: Border.all(color: Colors.white, width: 2),
                  //       ),
                  //       child: Center(
                  //         child: Text(
                  //           sellerName[0].toUpperCase(),
                  //           style: AppTypography.caption.copyWith(
                  //             color: Colors.white,
                  //             fontWeight: FontWeight.bold,
                  //             fontSize: 12,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
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

  // COMMENTED OUT - Helper methods for TikTok-style features
  // String _formatPrice(int price) {
  //   return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} UZS';
  // }

  // List<Color> _getGradientColors(String name) {
  //   final hash = name.hashCode;
  //   final gradients = [
  //     [const Color(0xFF667eea), const Color(0xFF764ba2)],
  //     [const Color(0xFFf093fb), const Color(0xFFF5576c)],
  //     [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
  //     [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
  //     [const Color(0xFFfa709a), const Color(0xFFfee140)],
  //     [const Color(0xFF30cfd0), const Color(0xFF330867)],
  //     [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
  //     [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
  //   ];
  //   return gradients[hash.abs() % gradients.length];
  // }
}

// ── Animated Visual Search Button ─────────────────────────────────────────────

class _AnimatedVisualSearchButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _AnimatedVisualSearchButton({required this.onTap, required this.label});

  @override
  State<_AnimatedVisualSearchButton> createState() =>
      _AnimatedVisualSearchButtonState();
}

class _AnimatedVisualSearchButtonState
    extends State<_AnimatedVisualSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Smooth sine pulse: 0.0 → 1.0 → 0.0 over one cycle
        final pulse =
            (math.sin(_controller.value * math.pi * 2 - math.pi / 2) + 1) / 2;
        final glow = 8.0 + pulse * 18.0;
        final scale = 1.0 + pulse * 0.04;
        // Shimmer sweeps from left to right once per cycle
        final shimmer = _controller.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(240, 147, 251, 0.4 + pulse * 0.3),
                  blurRadius: glow,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Color.fromRGBO(245, 87, 108, 0.35 + pulse * 0.25),
                  blurRadius: glow * 0.7,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Shimmer sweep overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-2.5 + shimmer * 5.0, -0.5),
                            end: Alignment(-1.8 + shimmer * 5.0, 0.5),
                            colors: const [
                              Color(0x00FFFFFF),
                              Color(0x3DFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen category picker — returns the selected tab index on pop.
class _CategoryPickerScreen extends StatelessWidget {
  final int selectedIndex;
  final List<String> categories;

  const _CategoryPickerScreen({
    required this.selectedIndex,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    l10n.categories,
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Category list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: categories.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkStandardBorder
                      : AppColors.gray200,
                ),
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categories[index],
                              style: AppTypography.body1.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
