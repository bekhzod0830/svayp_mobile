import 'package:flutter/services.dart';

/// Android-only targeted sharing: check which social apps are installed and
/// share an image file DIRECTLY into one of them (ACTION_SEND + setPackage),
/// instead of the full system sharesheet. Backed by the "svayp/targeted_share"
/// MethodChannel in MainActivity.kt.
class TargetedShare {
  static const MethodChannel _channel = MethodChannel('svayp/targeted_share');

  /// Returns the subset of [packages] that is installed on the device.
  static Future<List<String>> installedOf(List<String> packages) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getInstalled',
        {'packages': packages},
      );
      return result?.cast<String>() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Shares the file at [path] directly into [package]. Returns false when the
  /// intent could not be launched (caller should fall back to the system sheet).
  static Future<bool> shareTo(
    String package,
    String path,
    String mimeType,
  ) async {
    try {
      await _channel.invokeMethod<bool>('shareTo', {
        'package': package,
        'path': path,
        'mimeType': mimeType,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
