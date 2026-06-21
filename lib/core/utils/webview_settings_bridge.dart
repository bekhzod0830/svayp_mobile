import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe/app/app.dart';
import 'package:swipe/core/localization/services/language_service.dart';
import 'package:swipe/core/services/theme_service.dart';

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

    case 'set_theme':
      final theme = map['theme'] as String?;
      if (theme != 'dark' && theme != 'light') return true;
      if (!context.mounted) return true;
      await context.read<ThemeService>().setThemeMode(
            theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
          );
      return true;

    default:
      return false;
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
