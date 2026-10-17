import 'package:flutter/foundation.dart';

/// Lightweight in-memory metrics tracking for data caching, request deduplication,
/// and live transit event streaming.
class TransitCacheMetrics {
  TransitCacheMetrics._();
  static final TransitCacheMetrics instance = TransitCacheMetrics._();

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _deduplicatedRequests = 0;
  int _realtimeBroadcasts = 0;
  int _fallbackPolls = 0;

  final Map<String, int> _hitsByCategory = {};
  final Map<String, int> _missesByCategory = {};
  final Map<String, int> _dedupByCategory = {};

  int get totalCacheHits => _cacheHits;
  int get totalCacheMisses => _cacheMisses;
  int get totalDeduplicatedRequests => _deduplicatedRequests;
  int get totalRealtimeBroadcasts => _realtimeBroadcasts;
  int get totalFallbackPolls => _fallbackPolls;

  void recordHit(String category) {
    _cacheHits++;
    _hitsByCategory[category] = (_hitsByCategory[category] ?? 0) + 1;
  }

  void recordMiss(String category) {
    _cacheMisses++;
    _missesByCategory[category] = (_missesByCategory[category] ?? 0) + 1;
  }

  void recordDeduplicated(String category) {
    _deduplicatedRequests++;
    _dedupByCategory[category] = (_dedupByCategory[category] ?? 0) + 1;
  }

  void recordRealtimeBroadcast() {
    _realtimeBroadcasts++;
  }

  void recordFallbackPoll() {
    _fallbackPolls++;
  }

  int getHits(String category) => _hitsByCategory[category] ?? 0;
  int getMisses(String category) => _missesByCategory[category] ?? 0;
  int getDeduplications(String category) => _dedupByCategory[category] ?? 0;

  Map<String, dynamic> snapshot() {
    return {
      'totalCacheHits': _cacheHits,
      'totalCacheMisses': _cacheMisses,
      'totalDeduplicatedRequests': _deduplicatedRequests,
      'totalRealtimeBroadcasts': _realtimeBroadcasts,
      'totalFallbackPolls': _fallbackPolls,
      'hitsByCategory': Map<String, int>.unmodifiable(_hitsByCategory),
      'missesByCategory': Map<String, int>.unmodifiable(_missesByCategory),
      'dedupByCategory': Map<String, int>.unmodifiable(_dedupByCategory),
    };
  }

  @visibleForTesting
  void reset() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _deduplicatedRequests = 0;
    _realtimeBroadcasts = 0;
    _fallbackPolls = 0;
    _hitsByCategory.clear();
    _missesByCategory.clear();
    _dedupByCategory.clear();
  }
}
