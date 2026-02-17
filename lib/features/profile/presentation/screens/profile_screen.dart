import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _currentLanguage = 'English';
  final LanguageService _languageService = LanguageService();
  bool _isLoading = true;
  UserProfileResponse? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentLanguage();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = getIt<ProfileService>();
      final authService = getIt<AuthService>();

      // Fetch both user data and profile data
      final user = await authService.getCurrentUser();
      final profile = await profileService.getProfile();

      setState(() {
        _userProfile = profile;
        _userName = user.fullName ?? 'User';
        _userPhone = user.phoneNumber;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showError(
          context,
          'Failed to load profile: ${e.toString()}',
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
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.responsive<double>(
                    context: context,
                    mobile: double.infinity,
                    tablet: 700,
                    desktop: 900,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getHorizontalPadding(
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
                              color: (isDark ? Colors.white : AppColors.black)
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
                                      ? [AppColors.gray700, AppColors.gray600]
                                      : [AppColors.gray400, AppColors.gray500],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _userName
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .join('')
                                      .toUpperCase(),
                                  style: AppTypography.heading3.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Name and Phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    style: AppTypography.heading4.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.gray600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _userPhone,
                                        style: AppTypography.body2.copyWith(
                                          color: isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      _buildSection(
                        title: l10n.account,
                        items: [
                          _ProfileMenuItem(
                            icon: Icons.shopping_bag_outlined,
                            title: l10n.myOrders,
                            onTap: () {
                              // Navigate to Orders tab (index 3)
                              final mainScreenState = context
                                  .findAncestorStateOfType<MainScreenState>();
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
                                  .findAncestorStateOfType<MainScreenState>();
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

                      // Preferences Section
                      _buildSection(
                        title: l10n.preferences,
                        items: [
                          _ProfileMenuItem(
                            icon: Icons.dark_mode_outlined,
                            title: l10n.darkMode,
                            trailing: Consumer<ThemeService>(
                              builder: (context, themeService, child) {
                                return Switch(
                                  value: themeService.isDarkMode,
                                  onChanged: (_) => themeService.toggleTheme(),
                                  activeColor: AppColors.white,
                                  activeTrackColor: AppColors.gray700,
                                );
                              },
                            ),
                            onTap: () {
                              context.read<ThemeService>().toggleTheme();
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
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCardBackground : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

    return ListTile(
      leading: Icon(
        icon,
        color:
            textColor ?? (isDark ? AppColors.darkPrimaryText : AppColors.black),
      ),
      title: Text(
        title,
        style: AppTypography.body1.copyWith(
          color:
              textColor ??
              (isDark ? AppColors.darkPrimaryText : AppColors.black),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray500,
          ),
      onTap: onTap,
    );
  }
}
