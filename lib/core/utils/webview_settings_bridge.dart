import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/core/globals.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/services/theme_service.dart';
import 'package:swipe/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/widgets.dart';

/// Keeps the native app in sync with language/theme changes made inside the
/// web view. The web pages post `set_language` / `set_theme` messages over the
/// "FlutterBridge" JavascriptChannel whenever the user toggles either setting;
/// applying them here means both surfaces always show the same language and
/// theme.
///
/// Returns true when [map] was a recognised settings message (so callers that
/// multiplex other message types can stop processing it).
Future<bool> applyWebViewSetting(
  Map<String, dynamic> map,
  BuildContext context,
) async {
  final type = map['type'] as String? ?? '';
  switch (type) {
    case 'set_language':
      final code = map['code'] as String?;
      if (code == null || !LanguageService.supportedCodes.contains(code)) {
        return true;
      }
      await LanguageService().saveLanguage(code);
      if (!context.mounted) return true;
      context
          .findAncestorStateOfType<SwipeAppState>()
          ?.setLocale(Locale(code));
      return true;

    // Открыть ссылку СИСТЕМОЙ, а не внутри WebView. Нужно для оплаты: WLCM отдаёт
    // настоящие адреса провайдеров (checkout.paycom.uz, my.click.uz), а приложения
    // Payme и Click регистрируют эти домены как App Links. Внутри WebView App Links
    // не срабатывают — ссылку обязана открыть ОС, иначе пользователь остаётся на
    // веб-странице провайдера вместо его приложения.
    //
    // Запускаем без предварительного canLaunchUrl: на Android 11+ он отвечает false
    // для схем и пакетов, не объявленных в <queries>, хотя сам запуск разрешён.
    case 'open_external':
      final raw = map['url'] as String?;
      if (raw == null || raw.isEmpty) return true;
      final uri = Uri.tryParse(raw);
      if (uri == null) return true;
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Ни приложения, ни браузера — молча остаёмся в вебвью: оно уже ушло
        // на экран ожидания оплаты и покажет статус опросом.
      }
      return true;

    case 'set_theme':
      final theme = map['theme'] as String?;
      if (theme != 'dark' && theme != 'light') return true;
      if (!context.mounted) return true;
      await context.read<ThemeService>().setThemeMode(
            theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
          );
      return true;

    case 'save_image':
      // The web "Save Look" button can't download inside a WebView, so it
      // hands us the rendered image to write into the device photo gallery.
      await _saveImageToGallery(map, context);
      return true;

    case 'share_image':
      // The web "Share" button can't use the Web Share API inside a WebView, so
      // it hands us the rendered image to open the native system share sheet.
      await _shareImage(map, context);
      return true;

    case 'open_chat':
      // The marketplace WebView started a C2C chat — open it in the NATIVE chat
      // module (same screen as the C2B "Проверить наличие" flow). Pushed on the
      // root navigator so Back returns to the marketplace WebView.
      final chatId = (map['chatId'] as String?)?.trim() ?? '';
      if (chatId.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chatId),
          ),
        );
      }
      return true;

    default:
      return false;
  }
}

/// Decodes the base64 image from a `save_image` bridge message and writes it to
/// the device photo gallery, showing a success/error snackbar. Failures (bad
/// payload, denied permission, write error) are swallowed after notifying the
/// user — they must never crash the WebView host.
Future<void> _saveImageToGallery(
  Map<String, dynamic> map,
  BuildContext context,
) async {
  final base64Str = map['base64'] as String?;
  if (base64Str == null || base64Str.isEmpty) return;

  final l10n = AppLocalizations.of(context);
  try {
    final bytes = base64Decode(base64Str);
    final rawName = (map['filename'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'libas-look';

    final hasAccess = await Gal.requestAccess(toAlbum: true);
    if (!hasAccess) {
      if (context.mounted && l10n != null) {
        SnackBarHelper.showError(context, l10n.genericError);
      }
      return;
    }

    await Gal.putImageBytes(bytes, name: name);

    if (context.mounted && l10n != null) {
      SnackBarHelper.showSuccess(context, l10n.saved);
    }
  } catch (_) {
    if (context.mounted && l10n != null) {
      SnackBarHelper.showError(context, l10n.genericError);
    }
  }
}

/// Decodes the base64 image from a `share_image` bridge message, writes it to a
/// temporary file, and hands it to the OS share sheet (share_plus) on BOTH
/// platforms. Android used to show an in-app chooser with the installed social
/// apps first, but users expect the real system panel — the extra step just hid
/// every target that wasn't in our hardcoded list. Failures are swallowed after
/// notifying the user — they must never crash the WebView.
Future<void> _shareImage(
  Map<String, dynamic> map,
  BuildContext context,
) async {
  final base64Str = map['base64'] as String?;
  if (base64Str == null || base64Str.isEmpty) return;

  final l10n = AppLocalizations.of(context);
  try {
    final bytes = base64Decode(base64Str);
    final rawName = (map['filename'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'libas-look.png';
    final mimeType = (map['mimeType'] as String?)?.trim() ?? 'image/png';

    // Written under cacheDir/share_images — MUST stay covered by
    // res/xml/share_paths.xml, which the FileProvider exposes to share intents.
    final dir = await getTemporaryDirectory();
    final shareDir = Directory('${dir.path}/share_images');
    if (!shareDir.existsSync()) shareDir.createSync(recursive: true);
    final file = File('${shareDir.path}/$name');
    await file.writeAsBytes(bytes);

    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
  } catch (_) {
    if (context.mounted && l10n != null) {
      SnackBarHelper.showError(context, l10n.genericError);
    }
  }
}

/// Convenience wrapper that decodes a raw bridge message string and applies it.
/// Used by web views that don't otherwise parse the message themselves.
Future<bool> handleWebViewSettingsMessage(
  String rawMessage,
  BuildContext context,
) async {
  Map<String, dynamic> map;
  try {
    map = jsonDecode(rawMessage) as Map<String, dynamic>;
  } catch (_) {
    return false;
  }
  return applyWebViewSetting(map, context);
}
