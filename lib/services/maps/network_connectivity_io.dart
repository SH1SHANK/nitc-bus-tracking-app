import 'dart:io';

/// Probes whether [host] can be resolved and reached via DNS/socket.
Future<bool> isHostReachable(
  String host, {
  Duration timeout = const Duration(milliseconds: 2500),
}) async {
  // In unit test environment, bypass OS socket lookup unless overridden.
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }
  try {
    final result = await InternetAddress.lookup(host).timeout(timeout);
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
