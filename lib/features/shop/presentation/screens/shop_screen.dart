import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/services/visual_search_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe/features/shop/presentation/screens/visual_search_results_screen.dart';
import 'package:swipe/features/shop/presentation/widgets/visual_search_loader.dart';
import 'package:swipe/features/shop/presentation/screens/visual_search_crop_screen.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/features/shop/presentation/screens/sellers_list_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_search_results_screen.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/shared/widgets/widgets.dart';

// Pre-computed colors to avoid withOpacity() allocations during rebuilds
const _kShadowBlack08 = Color(0x14000000); // black.withOpacity(0.08)
const _kShadowBlack25 = Color(0x40000000); // black.withOpacity(0.25)
const _kShadowBlack30 = Color(0x4D000000); // black.withOpacity(0.30)
const _kWhite12 = Color(0x1FFFFFFF); // white.withOpacity(0.12)
const _kBlack08 = Color(0x14000000); // black.withOpacity(0.08)
const _kBlack05 = Color(0x0D000000); // black.withOpacity(0.05)
const _kBlack10 = Color(0x1A000000); // black.withOpacity(0.1)
const _kWhite10 = Color(0x1AFFFFFF); // white.withOpacity(0.1)
const _kWhite15 = Color(0x26FFFFFF); // white.withOpacity(0.15)
const _kWhite40 = Color(0x66FFFFFF); // white.withOpacity(0.4)
const _kWhite30 = Color(0x4DFFFFFF); // white.withOpacity(0.3)
const _kWhite60 = Color(0x99FFFFFF); // white.withOpacity(0.6)
const _kBlack40 = Color(0x66000000); // black.withOpacity(0.4)
const _kBlack50 = Color(0x80000000); // black.withOpacity(0.5)
const _kBlack30 = Color(0x4D000000); // black.withOpacity(0.3)

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
  final VisualSearchApiService _visualSearchService = VisualSearchApiService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  List<Product> _trendingProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  // Trending-specific pagination
  int _trendingPage = 0;
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

  /// Fetch trending products from GET /feed/trending?limit=20&page=0
  Future<void> _loadTrendingProducts() async {
    setState(() {
      _trendingPage = 0;
      _hasMoreTrending = true;
      _trendingProducts = [];
    });
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<dynamic>(
        '/feed/trending',
        queryParameters: {'limit': '$_pageSize', 'page': '0'},
      );
      final trending = _parseTrendingResponse(response.data);
      if (mounted) {
        setState(() {
          _trendingProducts = trending;
          _hasMoreTrending = trending.length >= _pageSize;
          if (trending.isNotEmpty) _trendingPage = 1;
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
        queryParameters: {'limit': '$_pageSize', 'page': '$_trendingPage'},
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
          _hasMoreTrending = newItems.length >= _pageSize;
          if (unique.isNotEmpty) _trendingPage++;
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
        queryParameters: {'limit': '$_pageSize', 'page': '0'},
      );
      final fresh = _parseTrendingResponse(response.data);
      if (mounted) {
        setState(() {
          _trendingProducts = fresh;
          _hasMoreTrending = fresh.length >= _pageSize;
          _trendingPage = fresh.isNotEmpty ? 1 : 0;
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
    if (_selectedTab == 0) {
      await _loadTrendingProducts();
    } else if (_selectedTab == 1) {
      await _loadProducts();
    } else {
      final category = _kCategoryApiValues[_selectedTab - 2];
      await _loadCategoryProducts(category);
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
      seller: apiProduct.seller,
      sellerId: apiProduct.sellerId,
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
      titleLocalized: apiProduct.titleLocalized,
      descriptionLocalized: apiProduct.descriptionLocalized,
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      // Get auth token if available
      final apiClient = getIt<ApiClient>();
      final token = apiClient.getToken();

      // Call the search API
      final response = await _apiService.searchProductsApi(
        query: query,
        size: 20, // Get search results
        token: token,
      );

      // Convert API products to local Product entities
      final searchResults = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          searchResults.add(product);
        } catch (e) {}
      }

      // Navigate to search results screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopSearchResultsScreen(
              query: query,
              searchResults: searchResults,
              allProducts: _products,
              searchController: _searchController,
            ),
          ),
        );
      }
    } catch (e) {
      // Fallback to local filtering if API fails
      final searchResults = _products.where((product) {
        return product.title.toLowerCase().contains(query.toLowerCase()) ||
            product.brand.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopSearchResultsScreen(
              query: query,
              searchResults: searchResults,
              allProducts: _products,
              searchController: _searchController,
            ),
          ),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();

    setState(() {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _onSellerTap(String sellerName) {
    // Filter products by seller
    final sellerProducts = _products
        .where((p) => (p.seller ?? 'SVAYP') == sellerName)
        .toList();

    if (sellerProducts.isEmpty) return;

    // Get sellerId from first product (all products from same seller should have same sellerId)
    final sellerId = sellerProducts.first.sellerId ?? 'unknown';

    // Navigate to seller profile
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(
          sellerId: sellerId,
          sellerName: sellerName,
          products: sellerProducts,
        ),
      ),
    );
  }

  /// Handle visual search button tap
  Future<void> _handleVisualSearch() async {
    final l10n = AppLocalizations.of(context)!;

    // Gate for guest users
    final storage = await LocalStorageHelper.getInstance();
    if (storage.isGuestMode()) {
      if (mounted) GuestLoginPrompt.show(context);
      return;
    }

    try {
      // 1. Open photo library for the user to pick an image
      if (!mounted) return;
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      // 2. Let the widget tree settle after the picker closes
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Let the user crop the image
      if (!mounted) return;
      final croppedImage = await _showCategoryPicker(image);
      if (croppedImage == null) return; // dismissed

      // 4. Show loading dialog AFTER crop is confirmed
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: VisualSearchLoader(image: File(croppedImage.path)),
        ),
      );

      // 5. Fetch recommendations from the backend
      final response = await _visualSearchService.fetchRecommendations(
        image: croppedImage,
        token: _authToken,
      );

      // 6. Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Small delay to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 100));

      // 7. Navigate to results screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisualSearchResultsScreen(
              results: response.results,
              uploadedImage: File(croppedImage.path),
            ),
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog if open
      if (mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.visualSearchError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<XFile?> _showCategoryPicker(XFile image) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cropKey = GlobalKey<VisualSearchCropWidgetState>();

    // Category selection removed — no category is sent with the request
    // final categories = <(String, String, IconData)>[
    //   ('TOPWEAR', l10n.vsCatTopwear, Icons.checkroom_outlined),
    //   ('BOTTOMWEAR', l10n.vsCatBottomwear, Icons.airline_seat_legroom_extra),
    //   ('DRESSES', l10n.vsCatDresses, Icons.dry_cleaning_outlined),
    //   ('OUTERWEAR', l10n.vsCatOuterwear, Icons.layers_outlined),
    //   ('ONE_PIECE', l10n.vsCatOnePiece, Icons.person_outline),
    //   ('ACTIVEWEAR', l10n.vsCatActivewear, Icons.sports_outlined),
    //   ('ACCESSORIES', l10n.vsCatAccessories, Icons.watch_outlined),
    //   ('FOOTWEAR', l10n.vsCatFootwear, Icons.directions_walk_outlined),
    //   ('UNDERWEAR', l10n.vsCatUnderwear, Icons.spa_outlined),
    //   ('ISLAMIC_MODEST_WEAR', l10n.vsCatModestWear, Icons.woman_outlined),
    //   ('TWO_PIECE_SET', l10n.vsCatTwoPieceSet, Icons.looks_two_outlined),
    //   ('THREE_PIECE_SET', l10n.vsCatThreePieceSet, Icons.looks_3_outlined),
    //   ('BODYSUITS_TRIKO', l10n.vsCatBodysuits, Icons.accessibility_new_outlined),
    //   ('HOMEWEAR', l10n.vsCatHomewear, Icons.home_outlined),
    // ];

    return showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (ctx) {
        // String? selected; // Category selection removed
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (ctx, setState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkStandardBorder
                            : AppColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title + Reset row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.vsPickCategory,
                          style: AppTypography.heading3.copyWith(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cropKey.currentState?.resetSelection(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            l10n.resetSelection,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Crop-enabled image preview
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: isDark
                            ? AppColors.darkMainBackground
                            : AppColors.gray100,
                        child: VisualSearchCropWidget(
                          key: cropKey,
                          image: image,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category dropdown removed — no category is sent with the request
                  // DropdownButtonFormField<String>(
                  //   value: selected,
                  //   isExpanded: true,
                  //   hint: Text(l10n.vsPickCategory, ...),
                  //   items: [...categories...],
                  //   onChanged: (v) => setState(() => selected = v),
                  // ),
                  const SizedBox(height: 16),
                  // Search button
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setState(() => isProcessing = true);
                            try {
                              final cropped = await cropKey.currentState!
                                  .cropImage();
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop(cropped);
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                setState(() => isProcessing = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      disabledBackgroundColor: isDark
                          ? AppColors.darkButtonDisabled
                          : AppColors.gray300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.vsSearchButton,
                            style: AppTypography.body1.copyWith(
                              color: isDark ? AppColors.black : AppColors.white,
                              fontWeight: FontWeight.w600,
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
                // Header with title and AI scan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.shop,
                              style: AppTypography.heading2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _filteredProducts.isEmpty && !_isLoading
                                  ? l10n.searchForClothes
                                  : '${_filteredProducts.length} ${l10n.products.toLowerCase()}',
                              style: AppTypography.body2.copyWith(
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Browse Sellers Button
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SellersListScreen(),
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBackground
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkStandardBorder
                                  : AppColors.gray200,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: _kShadowBlack08,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ),
                      // Visual Search Button – animated
                      _AnimatedVisualSearchButton(
                        onTap: _handleVisualSearch,
                        label: l10n.aiScan,
                      ),
                    ],
                  ),
                ),

                // Category dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCategoryDropdown(isDark, l10n),
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
                                  12,
                                  0,
                                  12,
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
                                          product.seller ?? 'SVAYP',
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
                                          // Grid padding: 12 each side + 12 cross-spacing → 36px total
                                          final cardW =
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  36) /
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

            // ChatGPT-style Search Bar — sits above the floating glass navbar
            // Navbar pill = 60px + safe-area padding; SafeArea already absorbs the
            // system bottom inset, so we only need to clear the pill itself.
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 76,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: isDark ? _kWhite12 : _kBlack08),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? _kShadowBlack25 : _kShadowBlack08,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFf093fb),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _performSearch(),
                        cursorColor: isDark ? Colors.white : Colors.black,
                        enableSuggestions: false,
                        autocorrect: false,
                        enableIMEPersonalizedLearning: false,
                        scribbleEnabled: false,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchForClothes,
                          hintStyle: TextStyle(
                            color: isDark ? _kWhite40 : _kBlack40,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    // Only rebuild these buttons when text changes, not the whole screen
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        final hasText = value.text.isNotEmpty;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasText)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _filterProducts();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? _kWhite10 : _kBlack05,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: isDark ? _kWhite60 : _kBlack50,
                                    size: 16,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: hasText
                                  ? () {
                                      _performSearch();
                                      FocusScope.of(context).unfocus();
                                    }
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: hasText
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark ? _kWhite15 : _kBlack10),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: hasText
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? _kWhite30 : _kBlack30),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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

  Widget _buildCategoryDropdown(bool isDark, AppLocalizations l10n) {
    final items = [
      (0, l10n.trending),
      (1, l10n.all),
      (2, l10n.vsCatTopwear),
      (3, l10n.vsCatBottomwear),
      (4, l10n.vsCatModestWear),
      (5, l10n.vsCatDresses),
      (6, l10n.vsCatOnePiece),
      (7, l10n.vsCatTwoPieceSet),
      (8, l10n.vsCatThreePieceSet),
      (9, l10n.vsCatFootwear),
      (10, l10n.vsCatOuterwear),
      (11, l10n.vsCatActivewear),
      (12, l10n.vsCatHomewear),
      (13, l10n.vsCatUnderwear),
      (14, l10n.vsCatAccessories),
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTab,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          style: AppTypography.body2.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.$1,
                  child: Text(
                    item.$2,
                    style: AppTypography.body2.copyWith(
                      fontSize: 13,
                      fontWeight: _selectedTab == item.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (index) {
            if (index != null) _onTabSelected(index);
          },
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
