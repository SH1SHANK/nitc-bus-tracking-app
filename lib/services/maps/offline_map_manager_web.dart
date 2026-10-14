import 'package:flutter/foundation.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';

import 'offline_map_manager.dart';

/// Web stub implementation of [OfflineMapManager].
class OfflineMapManagerImpl implements OfflineMapManager {
  OfflineMapManagerImpl({
    this.assetPath = OfflineMapManager.defaultAssetPath,
    // ignore: avoid_unused_constructor_parameters
    dynamic bundle,
    // ignore: avoid_unused_constructor_parameters
    dynamic destinationDirectoryProvider,
  });

  @override
  final String assetPath;

  @override
  String? get localFilePath => null;

  @override
  bool get isReady => false;

  @override
  Future<String> initialize() async {
    throw const OfflineMapException(
      'Offline MBTiles databases are not supported on Flutter Web platforms.',
    );
  }

  @override
  MbTilesTileProvider createTileProvider() {
    throw const OfflineMapException(
      'Offline MBTiles tile rendering is not supported on Flutter Web platforms.',
    );
  }

  @override
  @visibleForTesting
  void reset() {}
}
