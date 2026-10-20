import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:tracklet/services/updates/app_update_service.dart';

void main() {
  group('AppUpdateService Tests', () {
    test(
      'parses latest release with apk assets and flags update if newer',
      () async {
        final mockJson = jsonEncode({
          'tag_name': 'v1.0.0-rc-3',
          'name': 'BusTracker v1.0.0-rc-3',
          'body': 'Bug fixes and performance improvements.',
          'html_url':
              'https://github.com/SH1SHANK/nitc-bus-tracking-app/releases/tag/v1.0.0-rc-3',
          'published_at': '2026-10-20T00:00:00Z',
          'assets': [
            {
              'name': 'BusTracker-v1.0.0-rc-3-arm64-v8a.apk',
              'browser_download_url':
                  'https://github.com/.../BusTracker-v1.0.0-rc-3-arm64-v8a.apk',
              'size': 33554432,
              'content_type': 'application/vnd.android.package-archive',
            },
            {
              'name': 'BusTracker-v1.0.0-rc-3-universal.apk',
              'browser_download_url':
                  'https://github.com/.../BusTracker-v1.0.0-rc-3-universal.apk',
              'size': 75497472,
              'content_type': 'application/vnd.android.package-archive',
            },
          ],
        });

        final mockClient = MockClient((request) async {
          return http.Response(
            mockJson,
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = AppUpdateService(httpClient: mockClient);
        final update = await service.checkForUpdate();

        expect(update.tagName, 'v1.0.0-rc-3');
        expect(update.latestVersion, '1.0.0-rc-3');
        expect(update.assets.length, 2);
        expect(
          update.primaryApkAsset?.name,
          'BusTracker-v1.0.0-rc-3-arm64-v8a.apk',
        );
        expect(update.primaryApkAsset?.sizeFormatted, '32.0 MB');
      },
    );

    test('primaryApkAsset prefers arm64-v8a over universal', () {
      const assets = [
        AppReleaseAsset(
          name: 'BusTracker-universal.apk',
          downloadUrl: 'https://example.com/universal.apk',
          sizeBytes: 70000000,
          contentType: 'apk',
        ),
        AppReleaseAsset(
          name: 'BusTracker-arm64-v8a.apk',
          downloadUrl: 'https://example.com/arm64.apk',
          sizeBytes: 30000000,
          contentType: 'apk',
        ),
      ];

      const update = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        tagName: 'v1.0.1',
        releaseName: 'v1.0.1',
        releaseNotes: 'notes',
        htmlUrl: 'https://example.com',
        publishedAt: null,
        isUpdateAvailable: true,
        assets: assets,
      );

      expect(update.primaryApkAsset?.name, 'BusTracker-arm64-v8a.apk');
      expect(
        update.primaryApkAsset?.downloadUrl,
        'https://example.com/arm64.apk',
      );
    });
  });
}
