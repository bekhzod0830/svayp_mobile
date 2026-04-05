import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/discover/presentation/widgets/swipeable_product_card.dart';
import 'package:swipe/features/discover/presentation/widgets/swipe_tutorial_overlay.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/core/services/badge_notifier.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/services/recommendation_cache_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/services/notification_service.dart';
import 'package:swipe/core/services/sound_service.dart';
import 'package:swipe/shared/widgets/swipe_feedback_banner.dart';

/// Helper function to format size label by removing SIZE_ prefix
String _formatSizeLabel(String size) {
  // Remove SIZE_ prefix if present (e.g., "SIZE_46" -> "46")
  if (size.toUpperCase().startsWith('SIZE_')) {
    return size.substring(5);
  }
  return size;
}

/// Discover Screen - Main swipe feed
/// Primary feature of the app where users discover and swipe products
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  final CartService _cartService = CartService();
  final LikedService _likedService = LikedService();
  final ProductApiService _apiService = ProductApiService();
  final ValueNotifier<double> _dragProgressNotifier = ValueNotifier<double>(
    0.0,
  );
  final Map<String, GlobalKey<SwipeableProductCardState>> _cardKeys = {};

  List<Product> _products = [];
  final List<Map<String, dynamic>> _swipeHistory =
      []; // For undo functionality: stores {product, action}
  // Product IDs to exclude from the feed (already in cart, ordered, or swiped)
  Set<String> _excludedProductIds = {};
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreProducts = true;
  int _emptyRetryCount = 0;
  static const int _maxEmptyRetries = 2;
  String? _nextCursor;
  OverlayEntry? _tutorialOverlayEntry;
  int _currentCardIndex = 0;
  String? _authToken;
  // Prevents double sound+banner when the Like button triggers animateSwipe
  // which in turn calls _onSwipeRight (which would play again).
  bool _suppressNextFeedback = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    // Warm up the audio player + write temp WAV now so first tap has 0 ms latency.
    unawaited(SoundService.instance.preload());
    // Request notification permission here — after login/registration.
    // iOS shows the system dialog only once; subsequent calls are instant & silent.
    NotificationService.instance.requestPermissionAndRegisterToken().ignore();
  }

  @override
  void dispose() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry = null;
    _dragProgressNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    // ── 1. Get the auth token synchronously – no network call needed ──
    _authToken = getIt<ApiClient>().getToken();

    // ── 2. Init Hive services in parallel (cart & liked are independent) ──
    await Future.wait([_cartService.init(), _likedService.init()]);

    // ── 3. Show cart count from local Hive immediately (zero-latency) ──
    final localCount = _cartService.getTotalQuantity();
    BadgeNotifier.instance.setCartCount(localCount);

    // ── 3b. Build exclusion set: cart IDs (local/free) + previously seen IDs ──
    final cartIds = _cartService
        .getCartItems()
        .map((item) => item.productId)
        .toSet();
    final seenIds = await SeenProductsService.getSeenIds();
    _excludedProductIds = {...cartIds, ...seenIds};

    // ── 4. Start product loading right away — don't wait for cart API ──
    await _loadProducts();

    // ── 5. Refresh cart count from API in background (doesn't block products) ──
    unawaited(_updateCartCount());

    // ── 6. Show swipe tutorial for first-time users ──
    final show = await shouldShowSwipeTutorial();
    if (mounted && show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTutorialOverlay();
      });
    }
  }

  void _showTutorialOverlay() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: SwipeTutorialOverlay(
          onDismiss: () {
            _tutorialOverlayEntry?.remove();
            _tutorialOverlayEntry = null;
          },
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_tutorialOverlayEntry!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh auth token and cart count when screen becomes visible
    // This ensures we get the latest token if user just completed onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Get fresh token from ApiClient
        final newToken = getIt<ApiClient>().getToken();
        if (newToken != _authToken && newToken != null && newToken.isNotEmpty) {
          // Token changed (user just logged in), reload products
          setState(() {
            _authToken = newToken;
          });
          await _loadProducts(resetIndex: true);
        }
        await _updateCartCount();
      }
    });
  }

  Future<void> _updateCartCount() async {
    if (!mounted) return;

    try {
      // If user is authenticated, fetch cart count from API (source of truth)
      if (_authToken != null && _authToken!.isNotEmpty) {
        final cartData = await _apiService.getCart(token: _authToken!);
        final summary = cartData['summary'] as Map<String, dynamic>;
        final totalItems = summary['total_items'] as int;
        if (!mounted) return;
        BadgeNotifier.instance.setCartCount(totalItems);
      } else {
        // Fallback to local storage if not authenticated
        await _cartService.init();
        if (!mounted) return;
        BadgeNotifier.instance.setCartCount(_cartService.getTotalQuantity());
      }
    } catch (e) {
      // If API call fails, fallback to local storage
      await _cartService.init();
      if (!mounted) return;
      BadgeNotifier.instance.setCartCount(_cartService.getTotalQuantity());
    }
  }

  Future<void> _loadProducts({bool resetIndex = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (resetIndex) {
        _currentCardIndex = 0;
        _swipeHistory.clear();
        _dragProgressNotifier.value = 0.0;
        _nextCursor = null;
        _hasMoreProducts = true;
        _emptyRetryCount = 0;
      }
    });

    try {
      List<Product> loadedProducts = [];

      // Wrap the entire loading logic in a timeout to prevent infinite loading
      await Future.any([
        Future.delayed(const Duration(seconds: 30), () {
          throw TimeoutException('Product loading timed out after 30 seconds');
        }),
        _loadProductsInternal().then((products) {
          loadedProducts = products;
        }),
      ]);

      if (!mounted) return;

      setState(() {
        _products = loadedProducts;
        _isLoading = false;
      });

      // ── Preload images for the top 3 cards immediately after products arrive ──
      // This kicks off HTTP fetches into ImageCacheManager before the widgets
      // even build, so the first swipeable cards appear with images already cached.
      _preloadTopCardImages(loadedProducts);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadProducts),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<List<Product>> _loadProductsInternal() async {
    List<Product> loadedProducts = [];

    // Try to load recommended products if user is authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      // First, check if we have cached recommendations (first-time user after onboarding)
      final cachedProducts =
          await RecommendationCacheService.getCachedRecommendations();

      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        // Use cached recommendations and convert to Product entities
        for (final apiProduct in cachedProducts) {
          try {
            final product = _convertApiProduct(apiProduct);
            loadedProducts.add(product);
          } catch (e) {
            // Silently skip failed conversions
          }
        }

        // Mark cache as used so we fetch fresh recommendations next time
        await RecommendationCacheService.markCacheAsUsed();
      } else {
        // No cached data, fetch from personalized feed
        final response = await _apiService.getFeed(
          token: _authToken!,
          limit: 10,
        );
        _nextCursor = response.nextCursor;
        // Consider more products available unless the server explicitly signals otherwise
        _hasMoreProducts = true;

        // Convert API products to local Product entities
        for (final apiProduct in response.products) {
          try {
            final product = _convertApiProduct(apiProduct);
            loadedProducts.add(product);
          } catch (e) {
            // Skip products that fail to convert
          }
        }
      }
    } else {
      // User not authenticated - try fetching products without auth token
      try {
        final response = await _apiService.getProducts(page: 0, size: 20);
        for (final apiProduct in response.products) {
          try {
            final product = _convertApiProduct(apiProduct);
            loadedProducts.add(product);
          } catch (e) {
            // Skip failed conversions
          }
        }
      } catch (e) {
        // If API fails for unauthenticated users, return empty list
        // The outer error handler will show the error message
      }
    }

    // ── Client-side filter: remove products the user already interacted with ──
    if (_excludedProductIds.isNotEmpty) {
      loadedProducts = loadedProducts
          .where((p) => !_excludedProductIds.contains(p.id))
          .toList();
    }

    return loadedProducts;
  }

  /// Load the next page of products and append to the existing list.
  Future<void> _loadMoreProducts() async {
    if (_isFetchingMore || !_hasMoreProducts) return;
    if (_authToken == null || _authToken!.isEmpty) return;

    setState(() => _isFetchingMore = true);

    try {
      final response = await _apiService.getFeed(
        token: _authToken!,
        limit: 10,
        cursor: _nextCursor, // null = fresh batch; non-null = cursor page
      );

      final newProducts = <Product>[];
      for (final apiProduct in response.products) {
        try {
          final product = _convertApiProduct(apiProduct);
          if (!_excludedProductIds.contains(product.id)) {
            newProducts.add(product);
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _products.addAll(newProducts);
        _nextCursor = response.nextCursor;
        // Stop only when server truly returns nothing
        _hasMoreProducts = response.products.isNotEmpty;
        if (!_hasMoreProducts)
          _emptyRetryCount = 0; // reset for next manual retry
        _isFetchingMore = false;
      });

      // Preload images for the newly added cards
      _preloadTopCardImages(newProducts, count: 5);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFetchingMore = false);
    }
  }

  /// Trigger a background fetch when the user is getting close to the end.
  void _checkAndLoadMore() {
    final remaining = _products.length - _currentCardIndex;
    if (remaining <= 5 && !_isFetchingMore && _hasMoreProducts) {
      unawaited(_loadMoreProducts());
    }
  }

  /// swipe stack renders. Runs in the background — never blocks the UI.
  void _preloadTopCardImages(List<Product> products, {int count = 5}) {
    final toPreload = products.take(count).toList();
    for (final product in toPreload) {
      if (product.images.isEmpty) continue;
      // Only preload the first (hero) image of each card.
      final url = product.images.first;
      if (url.isEmpty) continue;
      unawaited(() async {
        try {
          await ImageCacheManager.instance.downloadFile(url);
        } catch (_) {}
      }());
    }
  }

  /// Convert API product model to local Product entity
  Product _convertApiProduct(api_models.Product apiProduct) {
    // Use seller if brand is "Unknown" or if seller is available
    String displayBrand =
        (apiProduct.brand == 'Unknown' || apiProduct.brand.isEmpty)
        ? (apiProduct.seller ?? apiProduct.brand)
        : apiProduct.brand;

    // If still "Unknown" or empty, use SVAYP as default
    if (displayBrand == 'Unknown' || displayBrand.isEmpty) {
      displayBrand = 'SVAYP';
    }

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
          : ['https://via.placeholder.com/400'],
      sizes: apiProduct.sizes ?? [],
      colors: apiProduct.colors ?? [],
      material: apiProduct.material?.map((m) => m.displayName).toList(),
      season: apiProduct.season?.map((s) => s.displayName).toList(),
      currency: apiProduct.currency,
      rating: apiProduct.rating ?? 4.5,
      reviewCount: apiProduct.reviewCount ?? 0,
      inStock: apiProduct.inStock,
      isNew: apiProduct.isNew ?? false,
      isFeatured: false, // API doesn't have this field
      seller: apiProduct.seller,
      sellerId: apiProduct.sellerId, // Include sellerId from API
      discountPercentage: apiProduct.discountPercentage,
      originalPrice: apiProduct.originalPrice,
      titleLocalized: apiProduct.titleLocalized,
      descriptionLocalized: apiProduct.descriptionLocalized,
    );
  }

  void _onSwipeLeft() {
    if (_currentCardIndex >= _products.length) return;

    HapticFeedback.lightImpact();

    final swipedProduct = _products[_currentCardIndex];
    _swipeHistory.add({'product': swipedProduct, 'action': 'dislike'});
    _excludedProductIds.add(swipedProduct.id);

    setState(() {
      _currentCardIndex++;
      // Reset drag progress in the same setState for atomic update
      _dragProgressNotifier.value = 0.0;
    });

    // Clean up old card key
    _cardKeys.remove(swipedProduct.id);
    // Persist seen ID and pre-fetch next batch if running low
    unawaited(SeenProductsService.addSeenIds([swipedProduct.id]));
    _checkAndLoadMore();

    // Send dislike to backend if user is authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      _apiService
          .dislikeProduct(productId: swipedProduct.id, token: _authToken!)
          .catchError((e) {
            // Silently handle error - don't interrupt user experience
          });
      // Log swipe event
      _apiService.logEvent(
        productId: swipedProduct.id,
        eventType: 'SWIPE',
        swipeAction: 'DISLIKE',
        token: _authToken,
      );
    }
  }

  Future<void> _onSwipeRight() async {
    if (_currentCardIndex >= _products.length) return;

    // Feedback only for direct gesture swipes (button taps pre-fire it).
    if (!_suppressNextFeedback) {
      HapticFeedback.lightImpact();
      unawaited(SoundService.instance.playTing());
      if (mounted) SwipeFeedbackBanner.show(context, SwipeFeedbackType.liked);
    }
    _suppressNextFeedback = false;

    final swipedProduct = _products[_currentCardIndex];
    _swipeHistory.add({'product': swipedProduct, 'action': 'like'});
    _excludedProductIds.add(swipedProduct.id);

    // Update UI immediately
    setState(() {
      _currentCardIndex++;
      // Reset drag progress in the same setState for atomic update
      _dragProgressNotifier.value = 0.0;
    });

    // Clean up old card key
    _cardKeys.remove(swipedProduct.id);
    // Persist seen ID and pre-fetch next batch if running low
    unawaited(SeenProductsService.addSeenIds([swipedProduct.id]));
    _checkAndLoadMore();

    // Add to liked items in background (don't block UI)
    _likedService.addLike(swipedProduct);
    BadgeNotifier.instance.markNewLiked();

    // Send like to backend if user is authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      _apiService
          .likeProduct(productId: swipedProduct.id, token: _authToken!)
          .catchError((e) {
            // Silently handle error - don't interrupt user experience
          });
      // Log swipe event
      _apiService.logEvent(
        productId: swipedProduct.id,
        eventType: 'SWIPE',
        swipeAction: 'LIKE',
        token: _authToken,
      );
    }
  }

  Future<void> _onSwipeUp() async {
    if (_currentCardIndex >= _products.length) return;

    HapticFeedback.lightImpact();

    final swipedProduct = _products[_currentCardIndex];
    final l10n = AppLocalizations.of(context)!;

    // Auto-select size if only one option (or universal), auto-select color if only one
    final universalSizes = {'One Size', 'Free Size', 'one_size', 'free_size'};
    String? selectedSize;
    String? selectedColor;

    if (swipedProduct.sizes.length == 1) {
      selectedSize = swipedProduct.sizes.first;
    } else if (swipedProduct.sizes.isNotEmpty &&
        swipedProduct.sizes.every((s) => universalSizes.contains(s))) {
      selectedSize = swipedProduct.sizes.first;
    }

    if (swipedProduct.colors.length == 1) {
      selectedColor = swipedProduct.colors.first;
    }

    // Only show dialog if user still needs to choose size or color
    final needsSizeChoice =
        selectedSize == null && swipedProduct.sizes.isNotEmpty;
    final needsColorChoice =
        selectedColor == null && swipedProduct.colors.length > 1;

    if (needsSizeChoice || needsColorChoice) {
      // Show liquid glass size/color selection bottom sheet
      final shouldAddToCart = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final canConfirm =
                (swipedProduct.sizes.isEmpty || selectedSize != null) &&
                (swipedProduct.colors.isEmpty || selectedColor != null);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xF2050508)
                            : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x22FFFFFF)
                              : const Color(0x28000000),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x44000000)
                                : const Color(0x18000000),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            l10n.selectSizeAndColor,
                            style: AppTypography.heading3.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Size selection
                          if (swipedProduct.sizes.isNotEmpty) ...[
                            Text(
                              l10n.size,
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xAAFFFFFF)
                                    : const Color(0xAA000000),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: swipedProduct.sizes.map((size) {
                                  final isSelected = selectedSize == size;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setSheetState(
                                        () => selectedSize = size,
                                      ),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 52,
                                          minHeight: 52,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : (isDark
                                                    ? const Color(0x22FFFFFF)
                                                    : const Color(0x0F000000)),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : (isDark
                                                      ? const Color(0x33FFFFFF)
                                                      : const Color(
                                                          0x22000000,
                                                        )),
                                            width: 0.75,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _formatSizeLabel(size),
                                            style: AppTypography.body2.copyWith(
                                              color: isSelected
                                                  ? (isDark
                                                        ? Colors.black
                                                        : Colors.white)
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Color selection
                          if (swipedProduct.colors.isNotEmpty) ...[
                            Text(
                              l10n.color,
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xAAFFFFFF)
                                    : const Color(0xAA000000),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: swipedProduct.colors.map((color) {
                                final isSelected = selectedColor == color;
                                final isHexColor = color.startsWith('#');
                                return GestureDetector(
                                  onTap: () => setSheetState(
                                    () => selectedColor = color,
                                  ),
                                  child: isHexColor
                                      ? _buildColorCircle(
                                          color,
                                          isSelected,
                                          sheetContext,
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                : (isDark
                                                      ? const Color(0x22FFFFFF)
                                                      : const Color(
                                                          0x0F000000,
                                                        )),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.transparent
                                                  : (isDark
                                                        ? const Color(
                                                            0x33FFFFFF,
                                                          )
                                                        : const Color(
                                                            0x22000000,
                                                          )),
                                              width: 0.75,
                                            ),
                                          ),
                                          child: Text(
                                            color,
                                            style: AppTypography.body2.copyWith(
                                              color: isSelected
                                                  ? (isDark
                                                        ? Colors.black
                                                        : Colors.white)
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Add to cart button
                          GestureDetector(
                            onTap: canConfirm
                                ? () => Navigator.pop(sheetContext, true)
                                : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: canConfirm
                                    ? (isDark ? Colors.white : Colors.black)
                                    : (isDark
                                          ? const Color(0x33FFFFFF)
                                          : const Color(0x1A000000)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.addToCart,
                                  style: AppTypography.body1.copyWith(
                                    color: canConfirm
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark
                                              ? const Color(0x66FFFFFF)
                                              : const Color(0x66000000)),
                                    fontWeight: FontWeight.w600,
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
              ),
            );
          },
        ),
      );

      if (shouldAddToCart != true) return;
    }

    // If no sizes at all, use one_size fallback
    final resolvedSize = selectedSize ?? l10n.oneSize;

    // Proceed with adding to cart
    _swipeHistory.add({'product': swipedProduct, 'action': 'superlike'});
    _excludedProductIds.add(swipedProduct.id);

    setState(() {
      _currentCardIndex++;
      _dragProgressNotifier.value = 0.0;
    });

    _cardKeys.remove(swipedProduct.id);
    // Persist seen ID and pre-fetch next batch if running low
    unawaited(SeenProductsService.addSeenIds([swipedProduct.id]));
    _checkAndLoadMore();
    // Sound + top banner feedback (replaces bottom toast)
    unawaited(SoundService.instance.playTing());
    if (mounted)
      SwipeFeedbackBanner.show(context, SwipeFeedbackType.addedToCart);

    await _cartService.addToCart(
      swipedProduct,
      selectedSize: resolvedSize,
      selectedColor: selectedColor,
    );

    // Send to backend API if authenticated
    if (_authToken != null && _authToken!.isNotEmpty) {
      try {
        // Use sizes directly as strings (no enum conversion needed)
        final backendSize = resolvedSize;
        final backendColor = selectedColor;

        await _apiService.addToCart(
          productId: swipedProduct.id,
          selectedSize: backendSize,
          selectedColor: backendColor,
          quantity: 1,
          token: _authToken!,
        );

        // Notify the recommendation engine so this product is excluded from future feed results
        _apiService.logEvent(
          productId: swipedProduct.id,
          eventType: 'CART_ADD',
          token: _authToken,
        );

        await _updateCartCount();
      } catch (e) {
        await _cartService.removeByMatch(
          productId: swipedProduct.id,
          selectedSize: resolvedSize,
          selectedColor: selectedColor,
        );
        _showToast('Failed to add to cart');
      }
    } else {
      await _updateCartCount();
    }
  }

  void _onUndo() {
    if (_swipeHistory.isEmpty) return;

    HapticFeedback.selectionClick();

    final lastSwipe = _swipeHistory.last;
    final product = lastSwipe['product'] as Product;
    final action = lastSwipe['action'] as String;

    // If it was a like or superlike, remove from liked items and call DELETE /favorite
    if (action == 'like' || action == 'superlike') {
      _likedService.removeLike(product.id);
      if (_authToken != null && _authToken!.isNotEmpty) {
        _apiService
            .dislikeProduct(productId: product.id, token: _authToken!)
            .catchError((e) {});
      }
    }

    setState(() {
      _currentCardIndex--;
      _swipeHistory.removeLast();
    });

    if (mounted) {
      SwipeFeedbackBanner.show(context, SwipeFeedbackType.undo);
    }
  }

  Future<void> _onCardTap() async {
    if (_currentCardIndex >= _products.length) return;

    final product = _products[_currentCardIndex];
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );

    // Update cart count whenever we return from the product detail screen
    await _updateCartCount();
  }

  /// Refresh the product list (useful when returning from other screens)
  Future<void> refreshProducts() async {
    await _loadProducts(resetIndex: true);
    await _updateCartCount();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Liquid Glass gradient background
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Stack(
        children: [
          // ── Gradient background mesh ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF0A0A0A), Color(0xFF111111)]
                      : const [Colors.white, Colors.white],
                ),
              ),
            ),
          ),
          // ── Ambient glow blobs for Liquid Glass depth ──
          Positioned(
            top: -80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? const [Color(0x00000000), Color(0x00000000)]
                        : const [Color(0x00FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? const [Color(0x00000000), Color(0x00000000)]
                        : const [Color(0x00FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Glass Header
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: ResponsiveUtils.getCardWidth(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xD0050508)
                                  : const Color(0xB8FFFFFF),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x22FFFFFF)
                                    : const Color(0x28000000),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SVΛYP',
                                  style: AppTypography.heading2.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                // Right side action icons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Cart Button with reactive badge
                                    ValueListenableBuilder<int>(
                                      valueListenable:
                                          BadgeNotifier.instance.cartCount,
                                      builder: (context, count, _) => Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 24,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            onPressed: () async {
                                              // Navigate to cart screen
                                              await Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CartScreen(),
                                                ),
                                              );
                                              // Update cart count when returning
                                              await _updateCartCount();
                                            },
                                          ),
                                          // Badge showing cart item count
                                          if (count > 0)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: IgnorePointer(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFFF3B30,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 16,
                                                        minHeight: 16,
                                                      ),
                                                  child: Text(
                                                    count > 99
                                                        ? '99+'
                                                        : count.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Liked icon button with reactive dot
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          BadgeNotifier.instance.hasNewLiked,
                                      builder: (context, hasNew, _) => Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 44,
                                              minHeight: 44,
                                            ),
                                            icon: Icon(
                                              Icons.favorite_border,
                                              size: 24,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            onPressed: () async {
                                              BadgeNotifier.instance
                                                  .clearNewLiked();
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => LikedScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          if (hasNew)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: IgnorePointer(
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFFF3B30,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0x18FFFFFF)
                                  : const Color(0xDDFFFFFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x22FFFFFF)
                                    : const Color(0x28000000),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.black12,
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _currentCardIndex >= _products.length
                      ? _buildDeckEnd(isDark)
                      : _buildCardStack(),
                ),
              ],
            ),
          ),
          // Swipe tutorial overlay is now shown via root OverlayEntry (covers bottom nav)
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Card Stack Area - flexible space
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Show 3 cards in stack
                    for (int i = 2; i >= 0; i--)
                      if (_currentCardIndex + i < _products.length)
                        Builder(
                          builder: (context) {
                            final product = _products[_currentCardIndex + i];
                            final cardKey = i == 0
                                ? (_cardKeys[product.id] ??=
                                      GlobalKey<SwipeableProductCardState>())
                                : null;

                            return SwipeableProductCard(
                              key: cardKey ?? ValueKey('card_${product.id}'),
                              product: product,
                              isTopCard: i == 0,
                              stackIndex: i,
                              onSwipeLeft: i == 0 ? _onSwipeLeft : null,
                              onSwipeRight: i == 0 ? _onSwipeRight : null,
                              onSwipeUp: i == 0 ? _onSwipeUp : null,
                              onTap: i == 0 ? _onCardTap : null,
                              // Pass drag progress notifier to top card and second card
                              dragProgressNotifier: (i == 0 || i == 1)
                                  ? _dragProgressNotifier
                                  : null,
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),

            // Gap between card and floating button bar
            const SizedBox(height: 12),
            // Action Buttons — floating glass pill, same width as card
            SizedBox(
              width: ResponsiveUtils.getCardWidth(context),
              child: _buildActionButtons(),
            ),
            // Spacer so buttons clear the floating navbar
            SizedBox(
              height:
                  MediaQuery.of(context).viewPadding.bottom.clamp(16.0, 60.0) +
                  78,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Floating glass pill — independent from card ──
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF0050508) : const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x28000000),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x44000000)
                    : const Color(0x18000000),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Undo — fixed 56px, neutral glass circle
              SizedBox(
                width: 56,
                child: _ActionButton(
                  icon: Icons.replay_rounded,
                  color: _swipeHistory.isEmpty
                      ? (isDark
                            ? const Color(0x44FFFFFF)
                            : const Color(0x44000000))
                      : Colors.black,
                  backgroundColor: _swipeHistory.isEmpty
                      ? (isDark
                            ? const Color(0x22FFFFFF)
                            : const Color(0x0F000000))
                      : Colors.white,
                  borderColor: isDark
                      ? const Color(0x44FFFFFF)
                      : const Color(0x28000000),
                  size: 56,
                  isCompact: true,
                  onPressed: _swipeHistory.isEmpty ? null : _onUndo,
                ),
              ),
              const SizedBox(width: 12),
              // Dislike — dark mode: dark-grey bg + white icon + subtle border | light mode: white bg + black icon
              Expanded(
                child: _ActionButton(
                  icon: Icons.thumb_down_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  backgroundColor: isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderColor: isDark
                      ? const Color(0x55FFFFFF)
                      : const Color(0x33000000),
                  size: 56,
                  isCompact: true,
                  onPressed: () {
                    if (_currentCardIndex < _products.length) {
                      final topProduct = _products[_currentCardIndex];
                      final topCardKey = _cardKeys[topProduct.id];
                      topCardKey?.currentState?.animateSwipe(
                        SwipeDirection.left,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Like — dark mode: white bg + black icon | light mode: black bg + white icon
              Expanded(
                child: _ActionButton(
                  icon: Icons.favorite_rounded,
                  color: isDark ? Colors.black : Colors.white,
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  borderColor: Colors.transparent,
                  size: 56,
                  isCompact: true,
                  onPressed: () {
                    if (_currentCardIndex < _products.length) {
                      final topProduct = _products[_currentCardIndex];
                      final topCardKey = _cardKeys[topProduct.id];
                      // Immediate feedback before animation fires
                      _suppressNextFeedback = true;
                      HapticFeedback.lightImpact();
                      unawaited(SoundService.instance.playTing());
                      SwipeFeedbackBanner.show(
                        context,
                        SwipeFeedbackType.liked,
                      );
                      topCardKey?.currentState?.animateSwipe(
                        SwipeDirection.right,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when the visible deck runs out of cards.
  /// • If more pages exist → auto-fetches and shows a spinner.
  /// • If truly exhausted → shows a minimal "all caught up" glass card.
  Widget _buildDeckEnd(bool isDark) {
    // Auto-trigger fetch when more content is expected, but cap retries on
    // empty responses to avoid hammering the API when the server has nothing.
    if (!_isFetchingMore &&
        _hasMoreProducts &&
        _emptyRetryCount < _maxEmptyRetries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emptyRetryCount++;
          unawaited(_loadMoreProducts());
        }
      });
    }

    if (_isFetchingMore) {
      return Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0x18FFFFFF) : const Color(0xDDFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x28000000),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black12,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x14FFFFFF)
                    : const Color(0x99FFFFFF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0xCCFFFFFF),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: isDark
                        ? const Color(0x44FFFFFF)
                        : const Color(0x44000000),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.thatsAllForNow,
                    style: AppTypography.display2.copyWith(
                      color: isDark ? Colors.white : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.findingMoreItems,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? const Color(0xAAFFFFFF)
                          : const Color(0x88000000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      _emptyRetryCount = 0;
                      setState(() {
                        _hasMoreProducts = true;
                      });
                      unawaited(_loadMoreProducts());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xDDFFFFFF)
                            : const Color(0xDD000000),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.black12,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: isDark ? Colors.black : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.refreshFeed,
                            style: AppTypography.body1.copyWith(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a color circle widget for hex colors
  Widget _buildColorCircle(
    String hexColor,
    bool isSelected,
    BuildContext context,
  ) {
    Color color;
    try {
      color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      color = Colors.grey;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryText : AppColors.black)
              : (isDark ? AppColors.darkStandardBorder : AppColors.gray300),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: isDark
                      ? const Color(
                          0x4DFFFFFF,
                        ) // darkPrimaryText.withOpacity(0.3)
                      : const Color(0x4D000000), // black.withOpacity(0.3)
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? Icon(Icons.check, color: _getContrastColor(color), size: 20)
          : null,
    );
  }

  /// Get contrasting color for checkmark visibility
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Action Button Widget
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color borderColor;
  final double size;
  final bool isCompact;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    required this.size,
    this.isCompact = true,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  void _pulse() async {
    if (!mounted || widget.onPressed == null) return;
    setState(() => _scale = 1.22);
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = widget.size;
    final buttonHeight = widget.size;

    return GestureDetector(
      onTap: widget.onPressed == null
          ? null
          : () {
              _pulse();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            border: widget.isCompact
                ? Border.all(color: widget.borderColor, width: 0.75)
                : null,
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: widget.onPressed == null
                  ? widget.color.withValues(alpha: 0.35)
                  : widget.color,
              size: widget.size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}
