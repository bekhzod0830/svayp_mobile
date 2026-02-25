import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:intl/intl.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/utils/responsive_utils.dart';
import 'package:swipe/core/services/theme_service.dart';
import 'package:swipe/features/address/presentation/screens/address_list_screen.dart';
import 'package:swipe/features/profile/presentation/screens/language_settings_screen.dart';
import 'package:swipe/features/profile/presentation/screens/profile_information_screen.dart';
import 'package:swipe/features/main/presentation/screens/main_screen.dart';
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

/// Profile Screen - User profile and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  UserProfileResponse? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentLanguage();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

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

      print('📊 [ProfileScreen] Raw user data from API:');
      print('   - User ID: ${user.id}');
      print('   - Full Name: ${user.fullName}');
      print('   - Phone: ${user.phoneNumber}');
      print('   - Cashback Balance: ${user.cashbackBalance}');
      print('   - Role: ${user.role}');
      print('   - Is Active: ${user.isActive}');

      // Try to fetch profile for non-partners, but don't fail if it doesn't exist
      UserProfileResponse? profile;
      if (!isPartner) {
        try {
          profile = await profileService.getProfile();
        } catch (e) {
          // Continue without profile - user might not have completed onboarding
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

      print('✅ [ProfileScreen] User data loaded successfully');
      print('   Profile available: ${profile != null}');
      print('   Cashback balance: $_cashbackBalance');
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set default values if loading fails
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
  }

  Future<void> _loadCurrentLanguage() async {
    final languageCode = await _languageService.getCurrentLanguageCode();
    setState(() {
      _currentLanguage = _languageService.getLanguageName(languageCode);
    });
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

              await storage.clearOnboarding();
              await storage.clearAuthData();
              await apiClient.clearToken();

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
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        title: Text(
          l10n.profile,
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            )
          : SafeArea(
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
                                  GestureDetector(
                                    onTap: !_isPartner && _userId.isNotEmpty
                                        ? () {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              barrierColor: Colors.black
                                                  .withOpacity(0.9),
                                              builder: (_) => _FullPageQrView(
                                                userId: _userId,
                                                userName: _userName,
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal:
                                            ResponsiveUtils.getHorizontalPadding(
                                              context,
                                            ),
                                        vertical: 16,
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCardBackground
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isDark
                                                        ? Colors.white
                                                        : AppColors.black)
                                                    .withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
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
                                                end: Alignment.bottomRight,
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
                                                style: AppTypography.heading3
                                                    .copyWith(
                                                      color: AppColors.white,
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
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _userName,
                                                  style: AppTypography.heading4
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                if (_isPartner) ...[
                                                  // Show username and role for admins
                                                  if (_username.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.alternate_email,
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
                                                        Text(
                                                          _username,
                                                          style: AppTypography
                                                              .body2
                                                              .copyWith(
                                                                color: isDark
                                                                    ? AppColors
                                                                          .darkSecondaryText
                                                                    : AppColors
                                                                          .gray600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (_username.isNotEmpty)
                                                    const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.badge_outlined,
                                                        size: 16,
                                                        color: isDark
                                                            ? AppColors
                                                                  .darkSecondaryText
                                                            : AppColors.gray600,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _userRole.toUpperCase(),
                                                        style: AppTypography
                                                            .body2
                                                            .copyWith(
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkSecondaryText
                                                                  : AppColors
                                                                        .gray600,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ] else ...[
                                                  // Show phone for regular users
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.phone_outlined,
                                                        size: 16,
                                                        color: isDark
                                                            ? AppColors
                                                                  .darkSecondaryText
                                                            : AppColors.gray600,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _userPhone,
                                                        style: AppTypography
                                                            .body2
                                                            .copyWith(
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkSecondaryText
                                                                  : AppColors
                                                                        .gray600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
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
                                                            : AppColors.black,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${NumberFormat('#,###').format(_cashbackBalance.toInt())} ${l10n.points}',
                                                        style: AppTypography
                                                            .body2
                                                            .copyWith(
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkPrimaryText
                                                                  : AppColors
                                                                        .black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),

                                          // QR Code preview (for non-partners)
                                          if (!_isPartner &&
                                              _userId.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Container(
                                              width: 76,
                                              height: 76,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDark
                                                      ? AppColors.gray700
                                                      : AppColors.gray300,
                                                  width: 1,
                                                ),
                                              ),
                                              child: QrImageView(
                                                data: _userId,
                                                version: QrVersions.auto,
                                                size: 60,
                                                backgroundColor:
                                                    AppColors.white,
                                                eyeStyle: const QrEyeStyle(
                                                  eyeShape: QrEyeShape.square,
                                                  color: AppColors.black,
                                                ),
                                                dataModuleStyle:
                                                    const QrDataModuleStyle(
                                                      dataModuleShape:
                                                          QrDataModuleShape
                                                              .square,
                                                      color: AppColors.black,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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
                                            Navigator.of(context).push(
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
                                            // Navigate to Orders tab (index 3)
                                            final mainScreenState = context
                                                .findAncestorStateOfType<
                                                  MainScreenState
                                                >();
                                            if (mainScreenState != null) {
                                              mainScreenState.navigateToTab(3);
                                            }
                                          },
                                        ),
                                        _ProfileMenuItem(
                                          icon: Icons.favorite_border,
                                          title: l10n.savedItems,
                                          onTap: () {
                                            // Navigate to Liked tab (index 1)
                                            final mainScreenState = context
                                                .findAncestorStateOfType<
                                                  MainScreenState
                                                >();
                                            if (mainScreenState != null) {
                                              mainScreenState.navigateToTab(1);
                                            }
                                          },
                                        ),
                                        _ProfileMenuItem(
                                          icon: Icons.location_on_outlined,
                                          title: l10n.addresses,
                                          onTap: () {
                                            Navigator.of(context).push(
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
                                                  onChanged: (_) => themeService
                                                      .toggleTheme(),
                                                  activeColor: AppColors.white,
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
                                        icon: Icons.language_outlined,
                                        title: l10n.language,
                                        trailing: Text(_currentLanguage),
                                        onTap: () async {
                                          await Navigator.of(context).push(
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

                                  // Logout Section
                                  _buildSection(
                                    title: '',
                                    items: [
                                      _ProfileMenuItem(
                                        icon: Icons.logout,
                                        title: l10n.logout,
                                        textColor: Colors.red,
                                        onTap: _onLogout,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // App Version
                                  Text(
                                    l10n.version('1.0.0'),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
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
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    textColor ??
                    (isDark ? AppColors.darkPrimaryText : AppColors.black),
                size: 24,
              ),
              const SizedBox(width: 16),
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
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray500,
                  size: 24,
                ),
            ],
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

  const _FullPageQrView({required this.userId, required this.userName});

  @override
  State<_FullPageQrView> createState() => _FullPageQrViewState();
}

class _FullPageQrViewState extends State<_FullPageQrView> {
  double? _originalBrightness;
  bool _brightnessChanged = false;

  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
  }

  @override
  void dispose() {
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
        debugPrint('Could not get current brightness: $e');
        // Continue without storing original brightness
      }

      // Try to set maximum brightness
      try {
        await screenBrightness.setScreenBrightness(1.0);
        _brightnessChanged = true;
      } catch (e) {
        debugPrint('Could not set brightness: $e');
        // Continue without brightness control
      }
    } catch (e) {
      debugPrint('Brightness control not available: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    if (!_brightnessChanged || _originalBrightness == null) return;

    try {
      await ScreenBrightness().setScreenBrightness(_originalBrightness!);
    } catch (e) {
      debugPrint('Failed to restore brightness: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkMainBackground : AppColors.white,
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      widget.userName,
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        l10n.scanQrForCashback,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSecondaryText.withOpacity(0.3)
                              : AppColors.gray300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.white : AppColors.black)
                                .withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: widget.userId,
                        version: QrVersions.auto,
                        size: 280,
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
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'ID: ${widget.userId}',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.gray500,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Close button at top
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : AppColors.black)
                          .withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
