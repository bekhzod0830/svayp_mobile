import 'package:package_info_plus/package_info_plus.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/core/network/api_config.dart';

/// Version info returned by the backend.
class AppVersionInfo {
  final String minRequiredVersion;
  final String latestVersion;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      minRequiredVersion: json['min_required_version'] as String? ?? '0.0.0',
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }
}

/// Result of a version check.
class VersionCheckResult {
  /// Whether the user must update (current < latest).
  final bool needsUpdate;
  /// Latest version string to display on the screen.
  final String latestVersion;

  const VersionCheckResult({
    required this.needsUpdate,
    required this.latestVersion,
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
      final response = await _apiClient.get(ApiConfig.appVersion);

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final info = AppVersionInfo.fromJson(data);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final needsUpdate =
          _compareVersions(currentVersion, info.latestVersion) < 0;

      return VersionCheckResult(
        needsUpdate: needsUpdate,
        latestVersion: info.latestVersion,
      );
    } catch (_) {
      // Never block the user due to a version-check failure.
      return null;
    }
  }

  /// Compares two semver strings (e.g. "1.2.3").
  /// Returns -1 if [v1] < [v2], 0 if equal, 1 if [v1] > [v2].
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.trim().split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final parts2 = v2.trim().split('.').map((s) => int.tryParse(s) ?? 0).toList();
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
