import 'package:flutter/foundation.dart';

import 'network_connectivity_io.dart'
    if (dart.library.js_interop) 'network_connectivity_web.dart'
    as impl;

/// Cross-platform network reachability probe.
abstract final class NetworkConnectivity {
  @visibleForTesting
  static Future<bool> Function(String host, {Duration timeout})? testOverride;

  /// Returns `true` if [host] resolves and is reachable.
  static Future<bool> isHostReachable(
    String host, {
    Duration timeout = const Duration(milliseconds: 2500),
  }) {
    if (testOverride != null) {
      return testOverride!(host, timeout: timeout);
    }
    return impl.isHostReachable(host, timeout: timeout);
  }
}
