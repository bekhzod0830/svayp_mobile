import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/discover/presentation/widgets/swipeable_product_card.dart';
import 'package:swipe/features/discover/presentation/widgets/swipe_tutorial_overlay.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/services/recommendation_cache_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/services/notification_service.dart';

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
  List<Map<String, dynamic>> _swipeHistory =
      []; // For undo functionality: stores {product, action}
  // Product IDs to exclude from the feed (already in cart, ordered, or swiped)
  Set<String> _excludedProductIds = {};
  bool _isLoading = true;
  OverlayEntry? _tutorialOverlayEntry;
  int _currentCardIndex = 0;
  int _cartCount = 0;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
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
    if (mounted) {
      setState(() {
        _cartCount = _cartService.getTotalQuantity();
      });
    }

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
        setState(() {
          _cartCount = totalItems;
        });
      } else {
        // Fallback to local storage if not authenticated
        await _cartService.init();
        if (!mounted) return;
        setState(() {
          _cartCount = _cartService.getTotalQuantity();
        });
      }
    } catch (e) {
      // If API call fails, fallback to local storage
      await _cartService.init();
      if (!mounted) return;
      setState(() {
        _cartCount = _cartService.getTotalQuantity();
      });
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

  /// Preload images for the first N cards so they appear instantly when the
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

    HapticFeedback.mediumImpact();

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

    // Add to liked items in background (don't block UI)
    _likedService.addLike(swipedProduct);

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

    HapticFeedback.heavyImpact();

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
      // Show size/color selection dialog
      final shouldAddToCart = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.selectSizeAndColor),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Size selection – always shown when sizes exist; pre-selected if only one
                if (swipedProduct.sizes.isNotEmpty) ...[
                  Text(
                    l10n.size,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: swipedProduct.sizes.map((size) {
                      final isSelected = selectedSize == size;
                      return ChoiceChip(
                        label: Text(
                          _formatSizeLabel(size),
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.black,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => selectedSize = size);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Color selection – always shown when colors exist; pre-selected if only one
                if (swipedProduct.colors.isNotEmpty) ...[
                  Text(
                    l10n.color,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: swipedProduct.colors.map((color) {
                      final isSelected = selectedColor == color;
                      final isHexColor = color.startsWith('#');

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        child: isHexColor
                            ? _buildColorCircle(color, isSelected, context)
                            : Chip(
                                label: Text(color),
                                backgroundColor: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed:
                    (swipedProduct.sizes.isEmpty || selectedSize != null) &&
                        (swipedProduct.colors.isEmpty || selectedColor != null)
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(l10n.addToCart),
              ),
            ],
          ),
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
    _showToast(l10n.addedToCart);

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

    // If it was a like or superlike, remove from liked items
    if (action == 'like' || action == 'superlike') {
      _likedService.removeLike(product.id);
    }

    setState(() {
      _currentCardIndex--;
      _swipeHistory.removeLast();
    });

    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.undo);
  }

  Future<void> _onCardTap() async {
    if (_currentCardIndex >= _products.length) return;

    final product = _products[_currentCardIndex];
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );

    // Update cart count if something was added
    if (result == true) {
      await _updateCartCount();
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Minimal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SVΛYP',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Right side action icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cart Button
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  // Navigate to cart screen
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CartScreen(),
                                    ),
                                  );
                                  // Update cart count when returning
                                  await _updateCartCount();
                                },
                              ),
                              // Badge showing cart item count
                              if (_cartCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        _cartCount > 99
                                            ? '99+'
                                            : _cartCount.toString(),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        )
                      : _currentCardIndex >= _products.length
                      ? _buildEmptyState()
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
              child: Center(
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

            // Action Buttons - no fixed spacing above
            _buildActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    // Get responsive sizing
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x0DFFFFFF) // white.withOpacity(0.05)
                : const Color(0x0D000000), // black.withOpacity(0.05)
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Undo Button (left) - smaller width
          SizedBox(
            width: 56,
            child: _ActionButton(
              icon: Icons.replay,
              color: _swipeHistory.isEmpty
                  ? (isDark ? AppColors.darkSecondaryText : AppColors.gray400)
                  : (isDark ? AppColors.darkPrimaryText : AppColors.gray700),
              backgroundColor: isDark
                  ? AppColors.darkMainBackground
                  : AppColors.white,
              borderColor: isDark
                  ? AppColors.darkStandardBorder
                  : AppColors.gray300,
              size: 56,
              isCompact: true,
              onPressed: _swipeHistory.isEmpty ? null : _onUndo,
            ),
          ),

          const SizedBox(width: 12),

          // Dislike Button
          Expanded(
            child: _ActionButton(
              icon: Icons.thumb_down_outlined,
              color: isDark ? AppColors.darkPrimaryText : AppColors.gray700,
              backgroundColor: isDark
                  ? AppColors.darkMainBackground
                  : AppColors.white,
              borderColor: isDark
                  ? AppColors.darkStandardBorder
                  : AppColors.gray300,
              size: 56,
              isCompact: true,
              onPressed: () {
                if (_currentCardIndex < _products.length) {
                  final topProduct = _products[_currentCardIndex];
                  final topCardKey = _cardKeys[topProduct.id];
                  topCardKey?.currentState?.animateSwipe(SwipeDirection.left);
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // Like Button (right)
          Expanded(
            child: _ActionButton(
              icon: Icons.favorite,
              color: isDark ? AppColors.black : AppColors.white,
              backgroundColor: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.black,
              borderColor: Colors.transparent,
              size: 56,
              isCompact: true,
              onPressed: () {
                if (_currentCardIndex < _products.length) {
                  final topProduct = _products[_currentCardIndex];
                  final topCardKey = _cardKeys[topProduct.id];
                  topCardKey?.currentState?.animateSwipe(SwipeDirection.right);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.thatsAllForNow,
              style: AppTypography.display2.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.findingMoreItems,
              style: AppTypography.body1.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: refreshProducts,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refreshFeed),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
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
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color borderColor;
  final double size;
  final bool isCompact;
  final double? width;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    required this.size,
    this.isCompact = true,
    this.width,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? size;
    final buttonHeight = size;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.white,
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            border: isCompact ? Border.all(color: borderColor, width: 1) : null,
          ),
          child: Center(
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
