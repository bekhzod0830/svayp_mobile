import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:intl/intl.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/services/theme_service.dart';
import 'package:swipe/core/services/sound_service.dart';
import 'package:swipe/features/address/presentation/screens/address_list_screen.dart';
import 'package:swipe/features/profile/presentation/screens/language_settings_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_information_screen.dart';
import 'package:swipe/features/orders/presentation/screens/orders_screen.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/profile/data/services/profile_service.dart';
import 'package:swipe/features/profile/data/models/profile_models.dart';
import 'package:swipe/features/auth/data/services/auth_service.dart';
import 'package:swipe/shared/widgets/widgets.dart';
// TODO: Import payment methods screen when created
// import 'package:swipe/features/payment/presentation/screens/payment_methods_screen.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/cart/data/services/cart_service.dart';
import 'package:swipe/features/liked/data/services/liked_service.dart';
import 'package:swipe/features/liked/presentation/screens/liked_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swipe/features/chat/data/services/chat_cache_service.dart';
import 'package:swipe/core/services/recommendation_cache_service.dart';
import 'package:swipe/core/services/seen_products_service.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/shared/widgets/main_top_bar.dart';
import 'dart:ui';

/// Profile Screen - User profile and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String _userName = 'User';
  String _userPhone = '';
  String _userId = '';
  String _username = '';
  String _userRole = '';
  double _cashbackBalance = 0.0;
  String _currentLanguage = 'English';
  final LanguageService _languageService = LanguageService();
  bool _isLoading = true;
  bool _isPartner = false;
  bool _isRedirecting = false; // prevents re-entry after a navigation decision
  bool _soundEnabled = true;
  UserProfileResponse? _userProfile;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadCurrentLanguage();
    _loadSoundPref();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-load profile data whenever the app is brought back to the foreground.
  /// This ensures the token-refresh interceptor fires and keeps the session alive.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted || _isRedirecting) return;

    // Skip API calls for guest users – tab-tap gating handles the prompt
    final storage = await LocalStorageHelper.getInstance();
    if (storage.isGuestMode()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = getIt<ProfileService>();
      final authService = getIt<AuthService>();
      final apiClient = getIt<ApiClient>();
      final isPartner = apiClient.isPartnerLogin();

      // Fetch user data
      final user = await authService.getCurrentUser();

      // Fetch profile for non-partners.
      // If profile doesn't exist (404) → redirect to login so they go through
      // the full auth + onboarding flow again.
      UserProfileResponse? profile;
      if (!isPartner) {
        try {
          profile = await profileService.getProfile();
        } on ApiException catch (profileError) {
          if (profileError.statusCode == 404) {
            _isRedirecting = true;
            await apiClient.clearToken();
            await apiClient.clearRefreshToken();
            if (!mounted) return;
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamedAndRemoveUntil('/phone-auth', (route) => false);
            return;
          }
          // Other profile errors (500, network) — continue without profile data
        }
      }

      if (!mounted) return;

      setState(() {
        _isPartner = isPartner;
        _userProfile = profile;
        _userName = user.fullName ?? 'User';
        _userPhone = user.phoneNumber;
        _username = user.username ?? '';
        _userRole = user.role;
        _userId = user.id;
        _cashbackBalance = user.cashbackBalance;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final apiClient = getIt<ApiClient>();

      // Redirect to login if:
      // 1. Token was cleared (expired + refresh failed), OR
      // 2. Server rejected the token with 401 (invalid/revoked), OR
      // 3. Server returned 403 (account deleted or deactivated)
      final statusCode = e is ApiException ? e.statusCode : null;
      final isAuthFailure = statusCode == 401 || statusCode == 403;
      if (!apiClient.isAuthenticated() || isAuthFailure) {
        _isRedirecting = true;
        await apiClient.clearToken();
        await apiClient.clearRefreshToken();
        if (!mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/phone-auth', (route) => false);
        return;
      }

      // For other errors (network issues, server errors), show retry message.
      setState(() {
        _isLoading = false;
        _userName = 'User';
        _userPhone = '';
        _userId = '';
        _cashbackBalance = 0.0;
      });
      SnackBarHelper.showError(
        context,
        'Failed to load user data. Please try again.',
      );
    }
  }

  Future<void> _loadSoundPref() async {
    await SoundService.instance.loadPreference();
    if (mounted) {
      setState(() => _soundEnabled = SoundService.instance.soundEnabledSync);
    }
  }

  Future<void> _loadCurrentLanguage() async {
    final languageCode = await _languageService.getCurrentLanguageCode();
    setState(() {
      _currentLanguage = _languageService.getLanguageName(languageCode);
    });
  }

  void _onDeleteAccount() async {
    final uri = Uri.parse('https://svaypai.com/en/account-deletion');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onLogout() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Clear all user data and authentication
              final storage = await LocalStorageHelper.getInstance();
              final apiClient = getIt<ApiClient>();

              // Clear auth tokens and onboarding flags
              await storage.clearOnboarding();
              await storage.clearAuthData();
              await apiClient.clearToken();

              // Clear Hive caches (cart, liked, chat)
              await CartService().clearCart();
              await LikedService().clearAllLiked();
              await ChatCacheService().clearCache();

              // Clear recommendation cache and seen products list
              await RecommendationCacheService.clearCache();
              await SeenProductsService.clear();

              // Clear image disk & memory cache
              await ImageCacheManager.instance.emptyCache();
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();

              if (mounted) {
                // Navigate directly to phone auth screen and clear navigation stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/phone-auth', (route) => false);
              }
            },
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Glass Header
            MainTopBar(title: l10n.profile),
            // Content
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                ),
              ),
            if (!_isLoading)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Ensure constraints are valid
                    if (!constraints.hasBoundedHeight) {
                      return const Center(child: Text('Loading...'));
                    }

                    return Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.responsive<double>(
                            context: context,
                            mobile: double.infinity,
                            tablet: 700,
                            desktop: 900,
                          ),
                        ),
                        child: RefreshIndicator(
                          onRefresh: _loadUserData,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    // Profile Header
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            ResponsiveUtils.getHorizontalPadding(
                                              context,
                                            ),
                                        vertical: 16,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 20,
                                            sigmaY: 20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xD0050508)
                                                  : const Color(0xEAFFFFFF),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0x22FFFFFF)
                                                    : const Color(0x18000000),
                                                width: 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDark
                                                      ? const Color(0x40000000)
                                                      : const Color(0x12000000),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                // Avatar
                                                Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: isDark
                                                          ? [
                                                              AppColors.gray700,
                                                              AppColors.gray600,
                                                            ]
                                                          : [
                                                              AppColors.gray400,
                                                              AppColors.gray500,
                                                            ],
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      _userName
                                                          .split(' ')
                                                          .map(
                                                            (e) => e.isNotEmpty
                                                                ? e[0]
                                                                : '',
                                                          )
                                                          .join('')
                                                          .toUpperCase(),
                                                      style: AppTypography
                                                          .heading3
                                                          .copyWith(
                                                            color:
                                                                AppColors.white,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),

                                                // Name and Phone/Username+Role
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _userName,
                                                        style: AppTypography
                                                            .heading4
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      if (_isPartner) ...[
                                                        // Show username and role for admins
                                                        if (_username
                                                            .isNotEmpty)
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .alternate_email,
                                                                size: 16,
                                                                color: isDark
                                                                    ? AppColors
                                                                          .darkSecondaryText
                                                                    : AppColors
                                                                          .gray600,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  _username,
                                                                  style: AppTypography
                                                                      .body2
                                                                      .copyWith(
                                                                        color:
                                                                            isDark
                                                                            ? AppColors.darkSecondaryText
                                                                            : AppColors.gray600,
                                                                      ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        if (_username
                                                            .isNotEmpty)
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .badge_outlined,
                                                              size: 16,
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkSecondaryText
                                                                  : AppColors
                                                                        .gray600,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                _userRole
                                                                    .toUpperCase(),
                                                                style: AppTypography.body2.copyWith(
                                                                  color: isDark
                                                                      ? AppColors
                                                                            .darkSecondaryText
                                                                      : AppColors
                                                                            .gray600,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ] else ...[
                                                        // Show phone for regular users
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .phone_outlined,
                                                              size: 16,
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkSecondaryText
                                                                  : AppColors
                                                                        .gray600,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                _userPhone,
                                                                style: AppTypography
                                                                    .body2
                                                                    .copyWith(
                                                                      color:
                                                                          isDark
                                                                          ? AppColors.darkSecondaryText
                                                                          : AppColors.gray600,
                                                                    ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        // Show cashback balance
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .account_balance_wallet_outlined,
                                                              size: 16,
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkPrimaryText
                                                                  : AppColors
                                                                        .black,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                '${NumberFormat('#,###').format(_cashbackBalance.toInt())} ${l10n.points}',
                                                                style: AppTypography.body2.copyWith(
                                                                  color: isDark
                                                                      ? AppColors
                                                                            .darkPrimaryText
                                                                      : AppColors
                                                                            .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Liquid Glass QR Card (non-partners only)
                                    if (!_isPartner && _userId.isNotEmpty)
                                      _LiquidGlassQrCard(
                                        userId: _userId,
                                        userName: _userName,
                                        balance: _cashbackBalance,
                                      ),

                                    const SizedBox(height: 16),

                                    // Profile Information Section
                                    if (_userProfile != null) ...[
                                      _buildSection(
                                        title: '',
                                        items: [
                                          _ProfileMenuItem(
                                            icon: Icons.person_outline,
                                            title: l10n.profileInformation,
                                            onTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfileInformationScreen(
                                                        profile: _userProfile!,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Account Section
                                    if (!_isPartner) ...[
                                      _buildSection(
                                        title: l10n.account,
                                        items: [
                                          _ProfileMenuItem(
                                            icon: Icons.shopping_bag_outlined,
                                            title: l10n.myOrders,
                                            onTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const OrdersScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          _ProfileMenuItem(
                                            icon: Icons.favorite_border,
                                            title: l10n.savedItems,
                                            onTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LikedScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          _ProfileMenuItem(
                                            icon: Icons.location_on_outlined,
                                            title: l10n.addresses,
                                            onTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddressListScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                    ],

                                    // Preferences Section
                                    _buildSection(
                                      title: l10n.preferences,
                                      items: [
                                        _ProfileMenuItem(
                                          icon: Icons.dark_mode_outlined,
                                          title: l10n.darkMode,
                                          trailing: Consumer<ThemeService>(
                                            builder:
                                                (context, themeService, child) {
                                                  return Switch(
                                                    value:
                                                        themeService.isDarkMode,
                                                    onChanged: (_) =>
                                                        themeService
                                                            .toggleTheme(),
                                                    activeThumbColor:
                                                        AppColors.white,
                                                    activeTrackColor:
                                                        AppColors.gray700,
                                                  );
                                                },
                                          ),
                                          onTap: () {
                                            context
                                                .read<ThemeService>()
                                                .toggleTheme();
                                          },
                                        ),
                                        _ProfileMenuItem(
                                          icon: Icons.volume_up_outlined,
                                          title: l10n.soundEffects,
                                          trailing: Switch(
                                            value: _soundEnabled,
                                            onChanged: (value) async {
                                              setState(
                                                () => _soundEnabled = value,
                                              );
                                              await SoundService.instance
                                                  .setSoundEnabled(value);
                                            },
                                            activeThumbColor: AppColors.white,
                                            activeTrackColor: AppColors.gray700,
                                          ),
                                          onTap: () async {
                                            final next = !_soundEnabled;
                                            setState(
                                              () => _soundEnabled = next,
                                            );
                                            await SoundService.instance
                                                .setSoundEnabled(next);
                                          },
                                        ),
                                        _ProfileMenuItem(
                                          icon: Icons.language_outlined,
                                          title: l10n.language,
                                          trailing: Text(_currentLanguage),
                                          onTap: () async {
                                            await Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LanguageSettingsScreen(),
                                              ),
                                            );
                                            // Reload language after returning
                                            _loadCurrentLanguage();
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Spacer to push logout to bottom (for partners/admins)
                                    if (_isPartner) const Spacer(),

                                    // Logout + Delete Account Section
                                    _buildSection(
                                      title: '',
                                      items: [
                                        _ProfileMenuItem(
                                          icon: Icons.logout,
                                          title: l10n.logout,
                                          textColor: Colors.red,
                                          onTap: _onLogout,
                                        ),
                                        if (!_isPartner)
                                          _ProfileMenuItem(
                                            icon: Icons.delete_forever_outlined,
                                            title: l10n.deleteAccount,
                                            textColor: Colors.red,
                                            onTap: _onDeleteAccount,
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // App Version
                                    Text(
                                      l10n.version(_appVersion),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(
                                            context,
                                          ).viewPadding.bottom +
                                          96,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildSection({required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hPad = ResponsiveUtils.getHorizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xD0050508) : const Color(0xEAFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x18000000),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x40000000)
                      : const Color(0x12000000),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Text(
                      title,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ...items,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? textColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  textColor ??
                  (isDark ? AppColors.darkPrimaryText : AppColors.black),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body1.copyWith(
                  color:
                      textColor ??
                      (isDark ? AppColors.darkPrimaryText : AppColors.black),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Liquid Glass QR Card ───────────────────────────────────────────────────

class _LiquidGlassQrCard extends StatefulWidget {
  final String userId;
  final String userName;
  final double balance;

  const _LiquidGlassQrCard({
    required this.userId,
    required this.userName,
    required this.balance,
  });

  @override
  State<_LiquidGlassQrCard> createState() => _LiquidGlassQrCardState();
}

class _LiquidGlassQrCardState extends State<_LiquidGlassQrCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _pressDown() {
    HapticFeedback.lightImpact();
    _scaleCtrl.animateTo(0.97, curve: Curves.easeOut);
  }

  void _pressUp() => _scaleCtrl.animateTo(1.0, curve: Curves.easeOut);

  void _openFullQr(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => _FullPageQrView(
          userId: widget.userId,
          userName: widget.userName,
          points: widget.balance,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            reverseCurve: Curves.easeIn,
          );
          final scale = Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final horizontalPad = ResponsiveUtils.getHorizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 4),
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _scaleCtrl.value, child: child!),
        child: GestureDetector(
          onTapDown: (_) => _pressDown(),
          onTapUp: (_) {
            _pressUp();
            _openFullQr(context);
          },
          onTapCancel: _pressUp,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xD0050508)
                      : const Color(0xEAFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x22FFFFFF)
                        : const Color(0x18000000),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x40000000)
                          : const Color(0x12000000),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Left 60% ──────────────────────────────────
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            l10n.svaypCardTitle,
                            style: AppTypography.heading4.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0D0D12),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Balance
                          Text(
                            '${NumberFormat('#,###').format(widget.balance.toInt())} ${l10n.points}',
                            style: AppTypography.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: isDark
                                  ? const Color(0xCCFFFFFF)
                                  : const Color(0xCC0D0D12),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Glass CTA button
                          _GlassButton(
                            isDark: isDark,
                            label: l10n.openQrButton,
                            onTap: () => _openFullQr(context),
                          ),
                          const SizedBox(height: 10),
                          // Description
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: l10n.qrCashbackPrefix),
                                TextSpan(
                                  text: l10n.qrCashbackHighlight,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? const Color(0xB3FFFFFF)
                                  : const Color(0xB3000000),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ── Right 40%: QR block ────────────────────────
                    Expanded(
                      flex: 4,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xF5FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x22000000),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: widget.userId,
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.black,
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
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.animateTo(0.94, curve: Curves.easeOut),
      onTapUp: (_) {
        _ctrl.animateTo(1.0, curve: Curves.easeOut);
        widget.onTap();
      },
      onTapCancel: () => _ctrl.animateTo(1.0, curve: Curves.easeOut),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0x30FFFFFF)
                    : const Color(0x18000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark
                      ? const Color(0x44FFFFFF)
                      : const Color(0x28000000),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Full Page QR View ──────────────────────────────────────────────────────

/// Full-page QR code view with maximum brightness
class _FullPageQrView extends StatefulWidget {
  final String userId;
  final String userName;
  final double points;

  const _FullPageQrView({
    required this.userId,
    required this.userName,
    required this.points,
  });

  @override
  State<_FullPageQrView> createState() => _FullPageQrViewState();
}

class _FullPageQrViewState extends State<_FullPageQrView>
    with SingleTickerProviderStateMixin {
  double? _originalBrightness;
  bool _brightnessChanged = false;
  late final AnimationController _enterCtrl;
  late final Animation<double> _qrScale;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _qrScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack));
    _contentFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _enterCtrl.forward();
    _setMaxBrightness();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _setMaxBrightness() async {
    try {
      final screenBrightness = ScreenBrightness();
      // Try to get original brightness, but don't fail if unavailable
      try {
        _originalBrightness = await screenBrightness.current;
      } catch (e) {
        // Continue without storing original brightness
      }

      // Try to set maximum brightness
      try {
        await screenBrightness.setScreenBrightness(1.0);
        _brightnessChanged = true;
      } catch (e) {
        // Continue without brightness control
      }
    } catch (_) {
      // ignore: brightness not supported on this device
    }
  }

  Future<void> _restoreBrightness() async {
    if (!_brightnessChanged || _originalBrightness == null) return;

    try {
      await ScreenBrightness().setScreenBrightness(_originalBrightness!);
    } catch (_) {
      // ignore: brightness not supported on this device
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        widget.userName,
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: l10n.qrCashbackPrefix),
                              TextSpan(
                                text: l10n.qrCashbackHighlight,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          style: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.gray600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ScaleTransition(
                        scale: _qrScale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSecondaryText.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.gray300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: widget.userId,
                            version: QrVersions.auto,
                            size: 260,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        NumberFormat('#,###').format(widget.points.toInt()),
                        style: AppTypography.heading1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.black,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.points,
                        style: AppTypography.body1.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 20,
            child: FadeTransition(
              opacity: _contentFade,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    size: 26,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
