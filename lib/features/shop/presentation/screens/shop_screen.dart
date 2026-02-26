import 'package:flutter/material.dart';
import 'dart:io';
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
import 'package:swipe/features/shop/presentation/screens/visual_search_results_screen.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/features/shop/presentation/screens/shop_search_results_screen.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _errorMessage;
  int _selectedTab = 0; // 0: All, 1: Trending, 2: New, 3: Sale
  bool _hasLoadedOnce = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initAuth();
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
    if (_isLoadingMore || !_hasMoreProducts) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more when 80% scrolled

    if (currentScroll >= threshold) {
      _loadMoreProducts();
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
        _filteredProducts = products;
        _isLoading = false;
        _hasMoreProducts = products.length >= _pageSize;
        if (products.isNotEmpty) _currentPage = 1;
      });
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

        // Apply current search filter inside setState
        final query = _searchController.text.toLowerCase();

        _filteredProducts = _products.where((product) {
          return query.isEmpty ||
              product.title.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
        }).toList();
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
      sizes: apiProduct.sizes?.map((size) => size.displayName).toList() ?? [],
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
        size: 100, // Get more results for search
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
      var filtered = _products.where((product) {
        final matchesSearch =
            query.isEmpty ||
            product.title.toLowerCase().contains(query) ||
            product.brand.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        // Apply tab filtering
        switch (_selectedTab) {
          case 1: // Trending (high rating)
            return matchesSearch && product.rating >= 4.5;
          case 2: // New
            return matchesSearch && product.isNew;
          case 3: // Sale (has discount)
            return matchesSearch &&
                product.discountPercentage != null &&
                product.discountPercentage! > 0;
          default: // All
            return matchesSearch;
        }
      }).toList();

      _filteredProducts = filtered;
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
    try {
      // Pick image from gallery (without showing dialog first)
      final image = await _visualSearchService.pickImage();

      if (image == null) {
        // User cancelled image selection
        return;
      }

      // Show loading dialog AFTER image is selected
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.brandBlack),
                const SizedBox(height: 16),
                Text(
                  l10n.analyzingImageWithAI,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch recommendations from the backend
      final response = await _visualSearchService.fetchRecommendations(
        image: image,
        token: _authToken,
        limit: 10,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Small delay to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to results screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisualSearchResultsScreen(
              products: response.products,
              uploadedImage: File(image.path),
            ),
          ),
        );
      }
    } catch (e) {
      // Close any open dialogs
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }

      // Show error message
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.visualSearchFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
                      // Visual Search Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFf093fb).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleVisualSearch,
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
                                    l10n.aiScan,
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
                      ),
                    ],
                  ),
                ),

                // TikTok-style Tabs
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTab(l10n.all, 0, isDark),
                      _buildTab(l10n.trending, 1, isDark),
                      _buildTab(l10n.newItems, 2, isDark),
                      _buildTab(l10n.sale, 3, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Product Grid (TikTok-style 2-column)
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : _errorMessage != null
                      ? RefreshIndicator(
                          onRefresh: _loadProducts,
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
                          onRefresh: _loadProducts,
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
                          onRefresh: _loadProducts,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.68,
                                ),
                            itemCount:
                                _filteredProducts.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredProducts.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                      color: isDark
                                          ? AppColors.darkPrimaryText
                                          : AppColors.black,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final product = _filteredProducts[index];
                              return _TikTokProductCard(
                                product: product,
                                onTap: () => _onProductTap(product),
                                onSellerTap: () =>
                                    _onSellerTap(product.seller ?? 'SVAYP'),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

            // ChatGPT-style Search Bar (unchanged)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFFf093fb),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
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
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.4),
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
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                          _filterProducts();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.5),
                            size: 16,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _searchController.text.isNotEmpty
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
                          color: _searchController.text.isNotEmpty
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.1)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: _searchController.text.isNotEmpty
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.3)),
                          size: 20,
                        ),
                      ),
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

  Widget _buildTab(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          _filterProducts();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.black : Colors.white)
                  : (isDark ? AppColors.darkSecondaryText : AppColors.gray600),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
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
            'Loading products...',
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Error Loading Products',
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTypography.body2.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                'Retry',
                style: AppTypography.body1.copyWith(color: AppColors.white),
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
                  // Price with optional discount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.hasDiscount)
                        Text(
                          product.formattedDiscountPrice ?? '',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray500,
                            decoration: TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                  // COMMENTED OUT - Rating display
                  // Row(
                  //   children: [
                  //     Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                  //     const SizedBox(width: 2),
                  //     Text(
                  //       product.rating.toStringAsFixed(1),
                  //       style: AppTypography.caption.copyWith(
                  //         fontWeight: FontWeight.w600,
                  //         color: isDark
                  //             ? AppColors.darkSecondaryText
                  //             : AppColors.gray600,
                  //         fontSize: 11,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 6),
                  //     Flexible(
                  //       child: GestureDetector(
                  //         onTap: onSellerTap,
                  //         child: Text(
                  //           '• $sellerName',
                  //           style: AppTypography.caption.copyWith(
                  //             color: isDark
                  //                 ? AppColors.darkSecondaryText
                  //                 : AppColors.gray600,
                  //             fontSize: 11,
                  //           ),
                  //           maxLines: 1,
                  //           overflow: TextOverflow.ellipsis,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
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
