import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/services/visual_search_api_service.dart';
import 'package:swipe/core/utils/local_storage_helper.dart';
import 'package:swipe/features/shop/presentation/screens/visual_search_crop_screen.dart';
import 'package:swipe/features/shop/presentation/screens/visual_search_results_screen.dart';
import 'package:swipe/features/shop/presentation/widgets/visual_search_loader.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Launches the full visual-search flow (gallery pick → crop → search → results)
/// from any [BuildContext].  Handles guest-mode gating.
Future<void> launchVisualSearch(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final storage = await LocalStorageHelper.getInstance();
  if (storage.isGuestMode()) {
    if (context.mounted) GuestLoginPrompt.show(context);
    return;
  }

  final authToken = getIt<ApiClient>().getToken();
  final visualSearchService = VisualSearchApiService();

  try {
    if (!context.mounted) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;

    if (!context.mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;
    final croppedImage = await _showCategoryPicker(context, image);
    if (croppedImage == null) return;

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (ctx) => VisualSearchLoader(image: File(croppedImage.path)),
    );

    final response = await visualSearchService.fetchRecommendations(
      image: croppedImage,
      token: authToken,
    );

    // Dismiss the loader if still visible (user may have already dismissed it).
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
    }

    // If the user dismissed the sheet while waiting, don't show results.
    if (!context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 100));

    if (context.mounted) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => VisualSearchResultsScreen(
            results: response.results,
            uploadedImage: File(croppedImage.path),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
    }
    if (context.mounted) {
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

Future<XFile?> _showCategoryPicker(BuildContext context, XFile image) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cropKey = GlobalKey<VisualSearchCropWidgetState>();

  return showModalBottomSheet<XFile>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    // Present above the main scaffold's floating bottom nav bar (the body uses
    // extendBody: true), otherwise the Search button is hidden behind it.
    useRootNavigator: true,
    builder: (ctx) {
      bool isProcessing = false;
      return PopScope(
        // Allow system back to close the sheet and return null.
        canPop: true,
        child: StatefulBuilder(
          builder: (ctx, setState) {
            // ~75 % of the screen height — big enough to crop comfortably.
            final sheetHeight = MediaQuery.of(ctx).size.height * 0.75;
            final bottomInset = MediaQuery.of(ctx).padding.bottom;
            return SizedBox(
              height: sheetHeight + bottomInset,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Text(
                            l10n.vsPickCategory,
                            style: AppTypography.heading3.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Crop widget expands to fill remaining space.
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.zero,
                              child: ColoredBox(
                                color: isDark
                                    ? const Color(0xFF0A0A10)
                                    : const Color(0xFFF0F0F5),
                                child: VisualSearchCropWidget(
                                  key: cropKey,
                                  image: image,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setState(() => isProcessing = true);
                                    try {
                                      final cropped = await cropKey
                                          .currentState!
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
                                  ? Colors.white
                                  : Colors.black,
                              disabledBackgroundColor: isDark
                                  ? const Color(0x44FFFFFF)
                                  : const Color(0x44000000),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isProcessing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.vsSearchButton,
                                    style: AppTypography.body1.copyWith(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w600,
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
    },
  );
}
