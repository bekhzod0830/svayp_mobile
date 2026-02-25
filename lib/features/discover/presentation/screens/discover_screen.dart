import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/features/discover/domain/entities/product.dart';
import 'package:swipe/features/discover/data/mock_product_data.dart';
import 'package:swipe/features/discover/presentation/widgets/swipeable_product_card.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/cart/presentation/screens/cart_screen.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/product/presentation/screens/product_detail_screen.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/models/product.dart' as api_models;
import 'package:swipe/core/services/recommendation_cache_service.dart';

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
  bool _isLoading = true;
  int _currentCardIndex = 0;
  int _cartCount = 0;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _dragProgressNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    // First initialize services and get auth token
    await _initServices();
    // Then load products with the auth token
    await _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh cart count, don't reload products on every dependency change
    // This prevents unnecessary reloading after each swipe
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _updateCartCount();
      }
    });
  }

  Future<void> _initServices() async {
    await _cartService.init();
    await _likedService.init();

    // Get authentication token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    _updateCartCount();
  }

  void _updateCartCount() {
    setState(() {
      _cartCount = _cartService.getTotalQuantity();
    });
  }

  Future<void> _loadProducts({bool resetIndex = false}) async {
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
          // No cached data, fetch from API as usual
          try {
            print('📡 [Discover] Fetching recommendations from API...');
            final response = await _apiService.getRecommendedProducts(
              token: _authToken!,
            );

            print(
              '✅ [Discover] Received ${response.products.length} products from API',
            );

            // Convert API products to local Product entities
            int convertedCount = 0;
            int failedCount = 0;
            for (final apiProduct in response.products) {
              try {
                final product = _convertApiProduct(apiProduct);
                loadedProducts.add(product);
                convertedCount++;
              } catch (e) {
                failedCount++;
                print('⚠️ [Discover] Failed to convert product: $e');
              }
            }

            print(
              '📦 [Discover] Converted $convertedCount products, $failedCount failed',
            );
            print(
              '📦 [Discover] Total loadedProducts: ${loadedProducts.length}',
            );
          } catch (e) {
            // Don't fall back to mock data - rethrow to show error
            rethrow;
          }
        }
      } else {
        // User not authenticated, use mock data
        loadedProducts = MockProductData.getMockProducts();
      }

      // Don't filter liked/disliked products - show all products
      print('✨ [Discover] Final available products: ${loadedProducts.length}');

      setState(() {
        _products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
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
      sizes: apiProduct.sizes?.map((size) => size.displayName).toList() ?? [],
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
    );
  }

  void _onSwipeLeft() {
    if (_currentCardIndex >= _products.length) return;

    HapticFeedback.lightImpact();

    final swipedProduct = _products[_currentCardIndex];
    _swipeHistory.add({'product': swipedProduct, 'action': 'dislike'});

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
            print('⚠️ Failed to send dislike: $e');
          });
    }
  }

  Future<void> _onSwipeRight() async {
    if (_currentCardIndex >= _products.length) return;

    HapticFeedback.mediumImpact();

    final swipedProduct = _products[_currentCardIndex];
    _swipeHistory.add({'product': swipedProduct, 'action': 'like'});

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
            print('⚠️ Failed to send like: $e');
          });
    }
  }

  Future<void> _onSwipeUp() async {
    if (_currentCardIndex >= _products.length) return;

    HapticFeedback.heavyImpact();

    final swipedProduct = _products[_currentCardIndex];
    final l10n = AppLocalizations.of(context)!;

    // If product has sizes, show size selection dialog
    if (swipedProduct.sizes.isNotEmpty) {
      // Don't advance card yet - let user select size first
      String? selectedSize;
      String? selectedColor;

      // Show size/color selection dialog
      final shouldAddToCart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.selectSizeAndColor),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Size selection
              Text(
                l10n.size,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: swipedProduct.sizes.map((size) {
                  return ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (selected) {
                      if (selected) {
                        selectedSize = size;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Color selection (if available)
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
                        selectedColor = color;
                        (context as Element).markNeedsBuild();
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
              onPressed: () {
                if (selectedSize != null) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(l10n.addToCart),
            ),
          ],
        ),
      );

      if (shouldAddToCart != true || selectedSize == null) {
        return; // User cancelled or didn't select size
      }

      // User selected size, proceed with adding to cart
      _swipeHistory.add({'product': swipedProduct, 'action': 'superlike'});

      setState(() {
        _currentCardIndex++;
        _dragProgressNotifier.value = 0.0;
      });

      // Clean up old card key
      _cardKeys.remove(swipedProduct.id);

      _showToast(l10n.addedToCart);

      await _cartService.addToCart(
        swipedProduct,
        selectedSize: selectedSize!,
        selectedColor: selectedColor,
      );

      // Send to backend API if authenticated
      if (_authToken != null && _authToken!.isNotEmpty) {
        try {
          // Convert color from display format ("Light Blue") to backend format ("light_blue")
          final backendColor = selectedColor?.toLowerCase().replaceAll(
            ' ',
            '_',
          );

          await _apiService.addToCart(
            productId: swipedProduct.id,
            selectedSize: selectedSize!,
            selectedColor: backendColor,
            quantity: 1,
            token: _authToken!,
          );

          // Only update cart count after successful API call
          _updateCartCount();
        } catch (e) {
          print('⚠️ Failed to sync cart with backend: $e');

          // Rollback local cart on API failure
          await _cartService.removeByMatch(
            productId: swipedProduct.id,
            selectedSize: selectedSize!,
            selectedColor: selectedColor,
          );

          // Show error toast
          _showToast('Failed to add to cart');
        }
      } else {
        // Not authenticated - just update local cart count
        _updateCartCount();
      }
    } else {
      // No sizes available - just add with "One Size"
      _swipeHistory.add({'product': swipedProduct, 'action': 'superlike'});

      setState(() {
        _currentCardIndex++;
        _dragProgressNotifier.value = 0.0;
      });

      // Clean up old card key
      _cardKeys.remove(swipedProduct.id);

      _showToast(l10n.addedToCart);

      await _cartService.addToCart(swipedProduct, selectedSize: l10n.oneSize);

      // Send to backend API if authenticated
      if (_authToken != null && _authToken!.isNotEmpty) {
        try {
          await _apiService.addToCart(
            productId: swipedProduct.id,
            selectedSize: l10n.oneSize,
            quantity: 1,
            token: _authToken!,
          );

          // Only update cart count after successful API call
          _updateCartCount();
        } catch (e) {
          print('⚠️ Failed to sync cart with backend: $e');

          // Rollback local cart on API failure
          await _cartService.removeByMatch(
            productId: swipedProduct.id,
            selectedSize: l10n.oneSize,
            selectedColor: null,
          );

          // Show error toast
          _showToast('Failed to add to cart');
        }
      } else {
        // Not authenticated - just update local cart count
        _updateCartCount();
      }
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
      _updateCartCount();
    }
  }

  /// Refresh the product list (useful when returning from other screens)
  Future<void> refreshProducts() async {
    await _loadProducts(resetIndex: true);
    _updateCartCount();
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
      body: SafeArea(
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
                  // Cart Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, size: 28),
                        onPressed: () async {
                          // Navigate to cart screen
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CartScreen(),
                            ),
                          );
                          // Update cart count when returning
                          _updateCartCount();
                        },
                      ),
                      // Badge showing cart item count
                      if (_cartCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
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
                              _cartCount > 99 ? '99+' : _cartCount.toString(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
            color: (isDark ? AppColors.white : AppColors.black).withOpacity(
              0.05,
            ),
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
                  color: (isDark ? AppColors.darkPrimaryText : AppColors.black)
                      .withOpacity(0.3),
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
