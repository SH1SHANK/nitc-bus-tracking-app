import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistent key-value storage wrapper.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences? _prefs;
  final Map<String, dynamic> _fallbackMemory = <String, dynamic>{};

  bool? getBool(String key) =>
      _prefs?.getBool(key) ?? (_fallbackMemory[key] as bool?);
  Future<bool> setBool(String key, bool value) async {
    _fallbackMemory[key] = value;
    if (_prefs != null) {
      return _prefs.setBool(key, value);
    }
    return true;
  }

  String? getString(String key) =>
      _prefs?.getString(key) ?? (_fallbackMemory[key] as String?);
  Future<bool> setString(String key, String value) async {
    _fallbackMemory[key] = value;
    if (_prefs != null) {
      return _prefs.setString(key, value);
    }
    return true;
  }

  Future<bool> remove(String key) async {
    _fallbackMemory.remove(key);
    if (_prefs != null) {
      return _prefs.remove(key);
    }
    return true;
  }

  Future<bool> clear() async {
    _fallbackMemory.clear();
    if (_prefs != null) {
      return _prefs.clear();
    }
    return true;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return StorageService(prefs);
  } catch (_) {
    return StorageService(null);
  }
});
