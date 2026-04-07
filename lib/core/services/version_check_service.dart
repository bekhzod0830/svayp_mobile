import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';

/// Version info returned by the backend.
/// Response shape: {"data": {"forceUpdate": bool, "latestVersion": "x.y.z",
///   "minVersion": "x.y.z", "softUpdate": bool, "storeUrl": "..."},
///   "message": "OK"}
class AppVersionInfo {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final bool softUpdate;
  final String storeUrl;

  const AppVersionInfo({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.softUpdate,
    required this.storeUrl,
  });

  /// The backend wraps fields inside a ["data"] key.
  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    // Support both wrapped {"data": {...}} and unwrapped responses.
    final d = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return AppVersionInfo(
      minVersion: d['minVersion'] as String? ?? '0.0.0',
      latestVersion: d['latestVersion'] as String? ?? '0.0.0',
      forceUpdate: d['forceUpdate'] as bool? ?? false,
      softUpdate: d['softUpdate'] as bool? ?? false,
      storeUrl: d['storeUrl'] as String? ?? '',
    );
  }
}

/// Result of a version check.
class VersionCheckResult {
  /// Whether the user must update.
  final bool needsUpdate;

  /// Latest version string to display on the screen.
  final String latestVersion;

  /// Store URL provided by the backend (platform-specific).
  final String storeUrl;

  const VersionCheckResult({
    required this.needsUpdate,
    required this.latestVersion,
    required this.storeUrl,
  });
}

/// Checks the running app version against the backend-reported latest version.
class VersionCheckService {
  final ApiClient _apiClient;

  const VersionCheckService(this._apiClient);

  /// Returns [VersionCheckResult] when a version check succeeds.
  /// Returns `null` on any network / parse error so the app never gets blocked
  /// by a failing version endpoint.
  Future<VersionCheckResult?> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = _getPlatform();

      final response = await _apiClient.get(
        ApiConfig.appVersion,
        queryParameters: {'platform': platform, 'version': currentVersion},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final info = AppVersionInfo.fromJson(data);

      // Use the backend's forceUpdate flag as the primary signal,
      // and fall back to a local version comparison as a safety net.
      final needsUpdate =
          info.forceUpdate ||
          _compareVersions(currentVersion, info.latestVersion) < 0;

      return VersionCheckResult(
        needsUpdate: needsUpdate,
        latestVersion: info.latestVersion,
        storeUrl: info.storeUrl,
      );
    } catch (_) {
      // Never block the user due to a version-check failure.
      return null;
    }
  }

  /// Returns the platform string expected by the backend.
  static String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Compares two semver strings (e.g. "1.2.3").
  /// Returns -1 if [v1] < [v2], 0 if equal, 1 if [v1] > [v2].
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1
        .trim()
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final parts2 = v2
        .trim()
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final len = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < len; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }
}
