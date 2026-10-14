import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';

import 'offline_map_manager_io.dart'
    if (dart.library.js_interop) 'offline_map_manager_web.dart'
    as impl;

/// Exception thrown when offline map assets or local SQLite files cannot be initialized.
class OfflineMapException implements Exception {
  const OfflineMapException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'OfflineMapException: $message (Caused by: $cause)';
    }
    return 'OfflineMapException: $message';
  }
}

/// Abstract contract for offline map file extraction and tile provider provisioning.
abstract class OfflineMapManager {
  factory OfflineMapManager({
    String assetPath,
    AssetBundle? bundle,
    dynamic destinationDirectoryProvider,
  }) = impl.OfflineMapManagerImpl;

  static const String defaultAssetPath = 'assets/maps/nitc_campus.mbtiles';
  static const String databaseFileName = 'nitc_campus.mbtiles';

  String get assetPath;
  String? get localFilePath;
  bool get isReady;

  Future<String> initialize();
  MbTilesTileProvider createTileProvider();

  @visibleForTesting
  void reset();
}
