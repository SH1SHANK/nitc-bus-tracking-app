import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/services/maps/offline_map_manager.dart';

class MockAssetBundle extends AssetBundle {
  MockAssetBundle({this.assetBytes, this.throwOnLoad = false});

  final Uint8List? assetBytes;
  final bool throwOnLoad;
  int loadCallCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCallCount++;
    if (throwOnLoad) {
      throw FlutterError('Unable to load asset: $key');
    }
    final bytes = assetBytes ?? Uint8List.fromList([1, 2, 3, 4, 5]);
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_map_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OfflineMapManager Unit Tests', () {
    test('initializes and copies bundled asset to local directory', () async {
      final mockBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final mockBundle = MockAssetBundle(assetBytes: mockBytes);

      final manager = OfflineMapManager(
        bundle: mockBundle,
        destinationDirectoryProvider: () async => tempDir,
      );

      expect(manager.isReady, isFalse);
      expect(manager.localFilePath, isNull);

      final path = await manager.initialize();

      expect(manager.isReady, isTrue);
      expect(path, manager.localFilePath);

      final destinationFile = File(path);
      expect(await destinationFile.exists(), isTrue);
      expect(await destinationFile.readAsBytes(), mockBytes);
      expect(mockBundle.loadCallCount, 1);
    });

    test(
      'avoids repeated copying when destination file is already valid and matches asset length',
      () async {
        final mockBytes = Uint8List.fromList([1, 2, 3, 4]);
        final mockBundle = MockAssetBundle(assetBytes: mockBytes);

        final manager = OfflineMapManager(
          bundle: mockBundle,
          destinationDirectoryProvider: () async => tempDir,
        );

        // First run copies
        final firstPath = await manager.initialize();
        expect(mockBundle.loadCallCount, 1);

        // Reset internal in-memory cache to simulate new app session
        manager.reset();
        expect(manager.isReady, isFalse);

        // Second run detects existing file matching byte length
        final secondPath = await manager.initialize();
        expect(secondPath, firstPath);
        expect(manager.isReady, isTrue);
        // It loaded metadata from bundle to check size, but file wasn't rewritten
        expect(mockBundle.loadCallCount, 2);
      },
    );

    test('re-copies when existing file size differs from asset size', () async {
      final existingFile = File('${tempDir.path}/nitc_campus.mbtiles');
      await existingFile.writeAsBytes([9, 9, 9]); // 3 bytes

      final newBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]); // 6 bytes
      final mockBundle = MockAssetBundle(assetBytes: newBytes);

      final manager = OfflineMapManager(
        bundle: mockBundle,
        destinationDirectoryProvider: () async => tempDir,
      );

      final path = await manager.initialize();
      final updatedFile = File(path);

      expect(await updatedFile.length(), 6);
      expect(await updatedFile.readAsBytes(), newBytes);
    });

    test(
      'concurrent initialize() calls share the same initialization Future',
      () async {
        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockBundle = MockAssetBundle(assetBytes: mockBytes);

        final manager = OfflineMapManager(
          bundle: mockBundle,
          destinationDirectoryProvider: () async => tempDir,
        );

        final futures = await Future.wait([
          manager.initialize(),
          manager.initialize(),
          manager.initialize(),
        ]);

        expect(futures[0], futures[1]);
        expect(futures[1], futures[2]);
        expect(mockBundle.loadCallCount, 1);
      },
    );

    test('throws OfflineMapException when asset fails to load', () async {
      final mockBundle = MockAssetBundle(throwOnLoad: true);

      final manager = OfflineMapManager(
        bundle: mockBundle,
        destinationDirectoryProvider: () async => tempDir,
      );

      expect(
        () => manager.initialize(),
        throwsA(
          isA<OfflineMapException>().having(
            (e) => e.message,
            'message',
            contains('Failed to load bundled MBTiles asset'),
          ),
        ),
      );
      expect(manager.isReady, isFalse);
    });

    test('throws OfflineMapException when asset is empty', () async {
      final mockBundle = MockAssetBundle(assetBytes: Uint8List(0));

      final manager = OfflineMapManager(
        bundle: mockBundle,
        destinationDirectoryProvider: () async => tempDir,
      );

      expect(
        () => manager.initialize(),
        throwsA(
          isA<OfflineMapException>().having(
            (e) => e.message,
            'message',
            contains('empty (0 bytes)'),
          ),
        ),
      );
      expect(manager.isReady, isFalse);
    });
  });
}
