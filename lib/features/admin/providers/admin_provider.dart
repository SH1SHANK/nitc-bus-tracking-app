import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/admin/admin_models.dart';
import '../../../data/admin/admin_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider determining whether the current session has admin privileges.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (!authState.isAuthenticated || authState.isGuest) {
    return false;
  }
  final repo = ref.watch(adminRepositoryProvider);
  return repo.checkAdminStatus();
});

/// High-level operational metrics provider.
final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getOverview();
});

/// Detailed health check indicators provider.
final adminHealthProvider = FutureProvider<DetailedHealth>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDetailedHealth();
});

/// Chronological audit logs provider.
final adminAuditLogsProvider = FutureProvider<List<AdminAuditLog>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAuditLogs();
});

/// Aggregated telemetry metrics provider for charts.
final adminTelemetryMetricsProvider = FutureProvider<AdminTelemetryMetrics>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getTelemetryMetrics();
});

/// State notifier managing device inventory with interactive operations.
class AdminDevicesNotifier extends AsyncNotifier<List<AdminDevice>> {
  @override
  Future<List<AdminDevice>> build() async {
    final repo = ref.watch(adminRepositoryProvider);
    return repo.getDevices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).getDevices(),
    );
  }

  Future<DeviceRegistrationResult> registerDevice({
    required String deviceId,
    required String busNumber,
    String? secret,
  }) async {
    final res = await ref
        .read(adminRepositoryProvider)
        .registerDevice(
          deviceId: deviceId,
          busNumber: busNumber,
          secret: secret,
        );
    await refresh();
    ref.invalidate(adminOverviewProvider);
    return res;
  }

  Future<void> toggleDeviceStatus({
    required String deviceId,
    required bool isActive,
  }) async {
    await ref
        .read(adminRepositoryProvider)
        .updateDeviceStatus(deviceId: deviceId, isActive: isActive);
    await refresh();
    ref.invalidate(adminOverviewProvider);
  }

  Future<String> rotateSecret({
    required String deviceId,
    String? newSecret,
  }) async {
    final secret = await ref
        .read(adminRepositoryProvider)
        .rotateSecret(deviceId: deviceId, newSecret: newSecret);
    await refresh();
    return secret;
  }

  Future<Map<String, dynamic>> testPingDevice({
    required String deviceId,
    required String secret,
  }) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .testPingDevice(deviceId: deviceId, secret: secret);
    await refresh();
    ref.invalidate(adminOverviewProvider);
    ref.invalidate(adminHealthProvider);
    return result;
  }
}

final adminDevicesProvider =
    AsyncNotifierProvider<AdminDevicesNotifier, List<AdminDevice>>(
      AdminDevicesNotifier.new,
    );

/// State for Live Debug Console stream with pause/resume support and polling interval.
class DebugConsoleState {
  const DebugConsoleState({
    required this.trackers,
    required this.isPaused,
    required this.lastUpdated,
    this.searchQuery = '',
    this.selectedFreshnessFilter,
    this.pollingIntervalSeconds = 3,
  });

  final List<TrackerDebugItem> trackers;
  final bool isPaused;
  final DateTime lastUpdated;
  final String searchQuery;
  final String? selectedFreshnessFilter;
  final int pollingIntervalSeconds;

  List<TrackerDebugItem> get filteredTrackers {
    return trackers.where((t) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesId = t.deviceId.toLowerCase().contains(query);
        final matchesBus = t.busNumber.toLowerCase().contains(query);
        final matchesRoute =
            t.routeName?.toLowerCase().contains(query) ?? false;
        if (!matchesId && !matchesBus && !matchesRoute) return false;
      }
      if (selectedFreshnessFilter != null &&
          selectedFreshnessFilter!.isNotEmpty &&
          selectedFreshnessFilter != 'all') {
        if (t.freshness != selectedFreshnessFilter) return false;
      }
      return true;
    }).toList();
  }

  DebugConsoleState copyWith({
    List<TrackerDebugItem>? trackers,
    bool? isPaused,
    DateTime? lastUpdated,
    String? searchQuery,
    String? selectedFreshnessFilter,
    int? pollingIntervalSeconds,
  }) {
    return DebugConsoleState(
      trackers: trackers ?? this.trackers,
      isPaused: isPaused ?? this.isPaused,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFreshnessFilter:
          selectedFreshnessFilter ?? this.selectedFreshnessFilter,
      pollingIntervalSeconds:
          pollingIntervalSeconds ?? this.pollingIntervalSeconds,
    );
  }
}

/// Debug console notifier that periodically pulls real-time telemetry if unpaused.
class DebugConsoleNotifier extends Notifier<DebugConsoleState> {
  Timer? _pollingTimer;

  @override
  DebugConsoleState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    Future.microtask(() {
      _startPolling();
    });

    return DebugConsoleState(
      trackers: const [],
      isPaused: false,
      lastUpdated: DateTime.now(),
      pollingIntervalSeconds: 3,
    );
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _fetch();
    _pollingTimer = Timer.periodic(
      Duration(seconds: state.pollingIntervalSeconds),
      (_) {
        if (!state.isPaused) {
          _fetch();
        }
      },
    );
  }

  void setPollingInterval(int seconds) {
    if (state.pollingIntervalSeconds == seconds) return;
    state = state.copyWith(pollingIntervalSeconds: seconds);
    _startPolling();
  }

  Future<void> _fetch() async {
    try {
      final trackers =
          await ref.read(adminRepositoryProvider).getDebugTrackers();
      state = state.copyWith(trackers: trackers, lastUpdated: DateTime.now());
    } catch (_) {
      // Retain existing state on transient poll failure
    }
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    if (!state.isPaused) {
      _fetch();
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(String? freshness) {
    state = state.copyWith(selectedFreshnessFilter: freshness);
  }

  Future<void> forceRefresh() => _fetch();
}

final debugConsoleProvider =
    NotifierProvider<DebugConsoleNotifier, DebugConsoleState>(
      DebugConsoleNotifier.new,
    );

/// State notifier managing administrator allowlist with add/remove actions.
class AdminUsersNotifier extends AsyncNotifier<List<AdminUser>> {
  @override
  Future<List<AdminUser>> build() async {
    return ref.watch(adminRepositoryProvider).getAdminUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).getAdminUsers(),
    );
  }

  Future<AdminUser> addAdmin(String email, {String? notes}) async {
    final added = await ref
        .read(adminRepositoryProvider)
        .addAdminUser(email, notes: notes);
    await refresh();
    return added;
  }

  Future<void> deleteAdmin(String id) async {
    await ref.read(adminRepositoryProvider).deleteAdminUser(id);
    await refresh();
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUser>>(
      AdminUsersNotifier.new,
    );
