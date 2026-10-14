import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import 'offline_map_manager.dart';

/// Native implementation of [OfflineMapManager] using `dart:io`.
class OfflineMapManagerImpl implements OfflineMapManager {
  OfflineMapManagerImpl({
    this.assetPath = OfflineMapManager.defaultAssetPath,
    AssetBundle? bundle,
    dynamic destinationDirectoryProvider,
  }) : _bundle = bundle,
       _destinationDirectoryProvider = destinationDirectoryProvider;

  @override
  final String assetPath;
  final AssetBundle? _bundle;
  final dynamic _destinationDirectoryProvider;

  String? _initializedFilePath;
  Future<String>? _ongoingInitialization;

  @override
  String? get localFilePath => _initializedFilePath;

  @override
  bool get isReady => _initializedFilePath != null;

  @override
  Future<String> initialize() {
    if (_initializedFilePath != null) {
      return Future.value(_initializedFilePath!);
    }

    if (_ongoingInitialization != null) {
      return _ongoingInitialization!;
    }

    _ongoingInitialization = _performInitialization();
    return _ongoingInitialization!;
  }

  Future<String> _performInitialization() async {
    try {
      final targetDir = await _resolveTargetDirectory();
      final destinationFile = File(
        p.join(targetDir.path, OfflineMapManager.databaseFileName),
      );

      final bundle = _bundle ?? rootBundle;
      final ByteData assetData;
      try {
        assetData = await bundle.load(assetPath);
      } catch (e) {
        throw OfflineMapException(
          'Failed to load bundled MBTiles asset at "$assetPath". '
          'Verify that the asset exists and is registered in pubspec.yaml.',
          e,
        );
      }

      final assetLength = assetData.lengthInBytes;
      if (assetLength == 0) {
        throw OfflineMapException(
          'Bundled MBTiles asset at "$assetPath" is empty (0 bytes).',
        );
      }

      if (await destinationFile.exists()) {
        final existingLength = await destinationFile.length();
        if (existingLength == assetLength) {
          AppLogger.info(
            'Offline campus map already present at: ${destinationFile.path} ($existingLength bytes)',
            tag: 'OfflineMapManager',
          );
          _initializedFilePath = destinationFile.path;
          return _initializedFilePath!;
        }
        AppLogger.info(
          'Offline map size mismatch ($existingLength vs $assetLength). Overwriting...',
          tag: 'OfflineMapManager',
        );
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final tempFile = File('${destinationFile.path}.tmp');
      final buffer = assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      );

      await tempFile.writeAsBytes(buffer, flush: true);
      await tempFile.rename(destinationFile.path);

      AppLogger.info(
        'Offline campus map successfully installed to: ${destinationFile.path} ($assetLength bytes)',
        tag: 'OfflineMapManager',
      );

      _initializedFilePath = destinationFile.path;
      return _initializedFilePath!;
    } catch (e) {
      _initializedFilePath = null;
      if (e is OfflineMapException) {
        AppLogger.error(e.message, error: e.cause, tag: 'OfflineMapManager');
        rethrow;
      }
      final error = OfflineMapException(
        'Unexpected error while initializing offline campus map: $e',
        e,
      );
      AppLogger.error(error.message, error: e, tag: 'OfflineMapManager');
      throw error;
    } finally {
      _ongoingInitialization = null;
    }
  }

  Future<Directory> _resolveTargetDirectory() async {
    final customProvider = _destinationDirectoryProvider;
    if (customProvider != null) {
      if (customProvider is Future<Directory> Function()) {
        return customProvider();
      }
      if (customProvider is Directory Function()) {
        return customProvider();
      }
    }

    // In unit / widget test environments, path_provider's platform channel is
    // not registered unless mocked, and awaiting it hangs FakeAsync timers.
    final isTestEnvironment = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnvironment) {
      return Directory.systemTemp.createTemp('tracklet_offline_map_');
    }

    try {
      return await getApplicationSupportDirectory();
    } catch (_) {
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {
        return Directory.systemTemp.createTemp('tracklet_offline_map_');
      }
    }
  }

  @override
  MbTilesTileProvider createTileProvider() {
    final path = _initializedFilePath;
    if (path == null) {
      throw const OfflineMapException(
        'OfflineMapManager must be initialized before creating a tile provider.',
      );
    }
    return MbTilesTileProvider.fromPath(path: path);
  }

  @override
  @visibleForTesting
  void reset() {
    _initializedFilePath = null;
    _ongoingInitialization = null;
  }
}
