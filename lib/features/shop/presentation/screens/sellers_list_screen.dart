import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/services/product_api_service.dart';
import 'package:swipe/core/services/seller_cache_service.dart';
import 'package:swipe/features/shop/presentation/screens/seller_profile_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';

// Pre-computed shadow colors to avoid withOpacity allocations during rebuilds
const _kShadowBlack08 = Color(0x14000000);

/// Displays a searchable, paginated list of all active sellers/shops.
class SellersListScreen extends StatefulWidget {
  const SellersListScreen({super.key});

  @override
  State<SellersListScreen> createState() => _SellersListScreenState();
}

class _SellersListScreenState extends State<SellersListScreen> {
  final ProductApiService _apiService = ProductApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SellerInfo> _sellers = [];
  List<SellerInfo> _filteredSellers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _authToken;

  static const int _pageSize = 50;
  static const String _cacheKey = 'sellers_list_cache';
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _initAndLoad();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    // Show cached data immediately if available
    final cached = _readCache(prefs);
    if (cached != null && mounted) {
      setState(() {
        _sellers = cached;
        _isLoading = false;
        _skip = cached.length;
        _hasMore = cached.length >= _pageSize;
        _applyFilter();
      });
      // Refresh in background — no loading spinner
      _refreshInBackground(prefs);
    } else {
      // No cache — show loading spinner for first open
      await _loadSellers(reset: true, prefs: prefs);
    }
  }

  List<SellerInfo>? _readCache(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SellerInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(
    SharedPreferences prefs,
    List<SellerInfo> sellers,
  ) async {
    try {
      await prefs.setString(
        _cacheKey,
        jsonEncode(sellers.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _refreshInBackground(SharedPreferences prefs) async {
    try {
      final results = await _apiService.getSellers(
        skip: 0,
        limit: _pageSize,
        token: _authToken,
      );
      if (!mounted) return;
      results.forEach(SellerCacheService.instance.put);
      await _saveCache(prefs, results);
      if (mounted) {
        setState(() {
          _sellers = results;
          _skip = results.length;
          _hasMore = results.length >= _pageSize;
          _applyFilter();
        });
      }
    } catch (_) {
      // Silently ignore — cached data remains visible
    }
  }

  Future<void> _loadSellers({
    bool reset = false,
    SharedPreferences? prefs,
  }) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _skip = 0;
          _hasMore = true;
        });
      }
    }

    try {
      final results = await _apiService.getSellers(
        skip: reset ? 0 : _skip,
        limit: _pageSize,
        token: _authToken,
      );
      results.forEach(SellerCacheService.instance.put);

      final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();

      if (reset) {
        await _saveCache(resolvedPrefs, results);
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _sellers = results;
          } else {
            _sellers.addAll(results);
          }
          _skip = _sellers.length;
          _hasMore = results.length >= _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchController.text.isEmpty) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadSellers();
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSellers = query.isEmpty
          ? List.of(_sellers)
          : _sellers
                .where(
                  (s) =>
                      s.name.toLowerCase().contains(query) ||
                      (s.description?.toLowerCase().contains(query) ?? false) ||
                      (s.primaryAddress?.toLowerCase().contains(query) ??
                          false),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ─────────────────────────────────────
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
                  Expanded(
                    child: Text(
                      l10n.sellers,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkStandardBorder
                        : AppColors.gray200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kShadowBlack08,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchSellers,
                          hintStyle: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray500,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray500,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark, l10n)
                  : _errorMessage != null
                  ? _buildErrorState(isDark, l10n)
                  : _filteredSellers.isEmpty
                  ? _buildEmptyState(isDark, l10n)
                  : RefreshIndicator(
                      onRefresh: () => _loadSellers(reset: true),
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount:
                            _filteredSellers.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _filteredSellers.length) {
                            return _buildShimmerCard(isDark);
                          }
                          return _SellerCard(
                            seller: _filteredSellers[index],
                            isDark: isDark,
                            onTap: () => _openSeller(_filteredSellers[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSeller(SellerInfo seller) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: seller.id,
          sellerName: seller.name,
          products: const [],
          sellerInfo: seller,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, AppLocalizations l10n) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => _buildShimmerCard(isDark),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    final base = isDark ? AppColors.darkCardBackground : AppColors.gray200;
    return Container(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shopErrorTitle,
              style: AppTypography.heading3.copyWith(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadSellers(reset: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSellersFound,
              style: AppTypography.heading3.copyWith(
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noSellersFoundSubtitle,
              style: AppTypography.body2.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for a single seller in the grid.
class _SellerCard extends StatelessWidget {
  final SellerInfo seller;
  final bool isDark;
  final VoidCallback onTap;

  const _SellerCard({
    required this.seller,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kShadowBlack08,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Avatar
              _SellerAvatar(logoUrl: seller.logoImg, name: seller.name),

              const SizedBox(height: 12),

              // Name
              Text(
                seller.name,
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.primaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Product count
              if (seller.productCount != null && seller.productCount! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.productsCount(seller.productCount!),
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
              ],

              // Address
              if (seller.primaryAddress != null &&
                  seller.primaryAddress!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray500,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        seller.primaryAddress!,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular seller logo with fallback initials.
class _SellerAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;

  const _SellerAvatar({this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              _Fallback(initial: initial, isDark: isDark),
          placeholder: (_, __) => _Fallback(initial: initial, isDark: isDark),
        ),
      );
    }
    return _Fallback(initial: initial, isDark: isDark);
  }
}

class _Fallback extends StatelessWidget {
  final String initial;
  final bool isDark;

  const _Fallback({required this.initial, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkStandardBorder : AppColors.gray200,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.heading2.copyWith(
          color: isDark ? AppColors.darkPrimaryText : AppColors.gray700,
        ),
      ),
    );
  }
}
