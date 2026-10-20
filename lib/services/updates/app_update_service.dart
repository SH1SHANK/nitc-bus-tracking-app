import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Representation of an attached release asset (e.g., APK or AAB).
class AppReleaseAsset {
  const AppReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.contentType,
  });

  final String name;
  final String downloadUrl;
  final int sizeBytes;
  final String contentType;

  String get sizeFormatted {
    if (sizeBytes <= 0) return '';
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory AppReleaseAsset.fromJson(Map<String, dynamic> json) {
    return AppReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: (json['size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }
}

/// Information about a GitHub release candidate or production release.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.publishedAt,
    required this.isUpdateAvailable,
    required this.assets,
    this.primaryDownloadUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String tagName;
  final String releaseName;
  final String releaseNotes;
  final String htmlUrl;
  final DateTime? publishedAt;
  final bool isUpdateAvailable;
  final List<AppReleaseAsset> assets;
  final String? primaryDownloadUrl;

  /// Returns the most suitable Android APK asset (preferring arm64-v8a or universal).
  AppReleaseAsset? get primaryApkAsset {
    if (assets.isEmpty) return null;

    // 1. Look for arm64-v8a APK (best for 95%+ modern Android devices)
    final arm64 =
        assets
            .where(
              (a) => a.name.endsWith('.apk') && a.name.contains('arm64-v8a'),
            )
            .firstOrNull;
    if (arm64 != null) return arm64;

    // 2. Look for universal APK
    final universal =
        assets
            .where(
              (a) => a.name.endsWith('.apk') && a.name.contains('universal'),
            )
            .firstOrNull;
    if (universal != null) return universal;

    // 3. Fallback to any APK
    return assets.where((a) => a.name.endsWith('.apk')).firstOrNull;
  }
}

/// Service that queries the official GitHub Releases API for app updates.
class AppUpdateService {
  AppUpdateService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String githubOwner = 'SH1SHANK';
  static const String githubRepo = 'nitc-bus-tracking-app';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// Fetches the latest release from GitHub and compares it with the running app version.
  Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final currentVersion = await _resolveCurrentVersion();

      final response = await _client
          .get(
            Uri.parse(releasesApiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'NITC-BusTracker/${AppConfig.appVersion}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('GitHub API returned status ${response.statusCode}');
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final releaseName = json['name'] as String? ?? tagName;
      final releaseNotes = json['body'] as String? ?? '';
      final htmlUrl =
          json['html_url'] as String? ??
          'https://github.com/$githubOwner/$githubRepo/releases/latest';
      final publishedAtStr = json['published_at'] as String?;
      final publishedAt =
          publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      final rawAssets = json['assets'] as List<dynamic>? ?? [];
      final assets =
          rawAssets
              .whereType<Map<String, dynamic>>()
              .map(AppReleaseAsset.fromJson)
              .toList();

      final cleanLatestVersion = _cleanVersionString(tagName);
      final isNewer = _isNewerVersion(
        current: currentVersion,
        latest: cleanLatestVersion,
      );

      // Find primary APK download URL
      final apkAsset = assets.where((a) => a.name.endsWith('.apk')).firstOrNull;
      final primaryDownloadUrl = apkAsset?.downloadUrl ?? htmlUrl;

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: cleanLatestVersion,
        tagName: tagName,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        htmlUrl: htmlUrl,
        publishedAt: publishedAt,
        isUpdateAvailable: isNewer,
        assets: assets,
        primaryDownloadUrl: primaryDownloadUrl,
      );
    } catch (e, st) {
      AppLogger.warning(
        'Failed to check for app updates: $e',
        error: e,
        stackTrace: st,
        tag: 'AppUpdateService',
      );
      rethrow;
    }
  }

  /// Resolves the installed app version from package_info_plus with fallback to AppConfig.
  Future<String> _resolveCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final ver = packageInfo.version.trim();
      if (ver.isNotEmpty) return ver;
    } catch (_) {}
    return AppConfig.appVersion;
  }

  /// Cleans strings like 'v1.0.0-rc-2' to '1.0.0-rc-2'
  static String _cleanVersionString(String v) {
    var s = v.trim();
    if (s.toLowerCase().startsWith('v')) {
      s = s.substring(1);
    }
    return s;
  }

  /// Semantic version comparison supporting semver with pre-release tags (e.g. 1.0.0-rc-1 vs 1.0.0-rc-2).
  static bool _isNewerVersion({
    required String current,
    required String latest,
  }) {
    if (current.isEmpty || latest.isEmpty) return false;
    if (current == latest) return false;

    try {
      final cParts = _parseVersion(current);
      final lParts = _parseVersion(latest);

      // Compare major, minor, patch
      for (int i = 0; i < 3; i++) {
        if (lParts.core[i] > cParts.core[i]) return true;
        if (lParts.core[i] < cParts.core[i]) return false;
      }

      // If core versions match, check pre-release (e.g. rc-1 vs rc-2, or rc vs final release)
      // If latest has no pre-release tag and current has one, latest is newer (1.0.0 > 1.0.0-rc-2)
      if (cParts.preRelease != null && lParts.preRelease == null) return true;
      if (cParts.preRelease == null && lParts.preRelease != null) return false;

      // Both have pre-release tags (e.g., rc-1 vs rc-2)
      if (cParts.preRelease != null && lParts.preRelease != null) {
        return _comparePreRelease(lParts.preRelease!, cParts.preRelease!) > 0;
      }

      return false;
    } catch (_) {
      // Direct string inequality fallback
      return current != latest;
    }
  }

  static _ParsedVersion _parseVersion(String version) {
    final clean = _cleanVersionString(version);
    final plusSplit = clean.split('+');
    final semverPart = plusSplit[0];

    final dashIdx = semverPart.indexOf('-');
    String corePart;
    String? preRelease;

    if (dashIdx != -1) {
      corePart = semverPart.substring(0, dashIdx);
      preRelease = semverPart.substring(dashIdx + 1);
    } else {
      corePart = semverPart;
    }

    final nums = corePart.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (nums.length < 3) {
      nums.add(0);
    }

    return _ParsedVersion(core: nums.take(3).toList(), preRelease: preRelease);
  }

  static int _comparePreRelease(String a, String b) {
    if (a == b) return 0;
    // Extract numbers if present, e.g. rc-2 vs rc-1
    final aNum = RegExp(r'\d+').firstMatch(a)?.group(0);
    final bNum = RegExp(r'\d+').firstMatch(b)?.group(0);
    if (aNum != null && bNum != null) {
      final aInt = int.tryParse(aNum) ?? 0;
      final bInt = int.tryParse(bNum) ?? 0;
      return aInt.compareTo(bInt);
    }
    return a.compareTo(b);
  }
}

class _ParsedVersion {
  _ParsedVersion({required this.core, this.preRelease});
  final List<int> core;
  final String? preRelease;
}
