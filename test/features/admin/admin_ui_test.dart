import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/admin/admin_models.dart';
import 'package:tracklet/data/admin/admin_repository.dart';
import 'package:tracklet/features/admin/admin_dashboard_screen.dart';
import 'package:tracklet/features/admin/providers/admin_provider.dart';

import '../../helpers/pump_app.dart';

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.isAdmin = true});

  final bool isAdmin;
  bool lastStatusUpdate = true;

  @override
  Future<bool> checkAdminStatus() async => isAdmin;

  @override
  Future<AdminOverview> getOverview() async {
    return const AdminOverview(
      totalDevices: 4,
      activeDevices: 3,
      inactiveDevices: 1,
      onlineDevices: 2,
      staleDevices: 1,
      offlineDevices: 1,
      totalBuses: 4,
      activeBuses: 3,
      telemetryLastReceivedAt: null,
      databaseConnected: true,
      uptimeSeconds: 1800.0,
    );
  }

  @override
  Future<List<AdminDevice>> getDevices() async {
    return [
      AdminDevice(
        id: 'dev-1',
        deviceId: 'NITC-BUS-001',
        busNumber: 'Bus 1',
        isActive: true,
        currentEpoch: 1,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<DeviceRegistrationResult> registerDevice({
    required String deviceId,
    required String busNumber,
    String? secret,
  }) async {
    return DeviceRegistrationResult(
      device: AdminDevice(
        id: 'dev-2',
        deviceId: deviceId,
        busNumber: busNumber,
        isActive: true,
        currentEpoch: 1,
        createdAt: DateTime.now(),
      ),
      generatedSecret: 'test_generated_secret_key_123',
      message: 'Success',
    );
  }

  @override
  Future<bool> updateDeviceStatus({
    required String deviceId,
    required bool isActive,
  }) async {
    lastStatusUpdate = isActive;
    return true;
  }

  @override
  Future<String> rotateSecret({
    required String deviceId,
    String? newSecret,
  }) async {
    return 'new_rotated_secret_value_xyz';
  }

  @override
  Future<List<TrackerDebugItem>> getDebugTrackers() async {
    return [
      const TrackerDebugItem(
        deviceId: 'NITC-BUS-001',
        busNumber: 'Bus 1',
        isActive: true,
        epoch: 1,
        seq: 50,
        freshness: 'online',
        recentBreadcrumbs: [],
      ),
    ];
  }

  @override
  Future<DetailedHealth> getDetailedHealth() async {
    return DetailedHealth(
      apiStatus: 'healthy',
      uptimeSeconds: 3600.0,
      heapUsedMb: 40.0,
      heapTotalMb: 70.0,
      rssMb: 95.0,
      nodeVersion: 'v20.10.0',
      dbStatus: 'connected',
      dbLatencyMs: 3.5,
      dbConnected: true,
      totalRecordsRecorded: 500,
      lastPacketAgeSeconds: 1.0,
      telemetryHealthy: true,
      fleetTotal: 4,
      fleetOnline: 2,
      fleetStale: 1,
      fleetOffline: 1,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs({int limit = 50}) async {
    return [
      AdminAuditLog(
        id: 'log-1',
        action: 'REGISTER_DEVICE',
        targetType: 'device',
        targetId: 'NITC-BUS-001',
        details: const {},
        adminEmail: 'admin@nitc.ac.in',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<AdminUser>> getAdminUsers() async {
    return [
      AdminUser(
        id: 'u-1',
        email: 'admin@nitc.ac.in',
        notes: 'Lead',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<AdminUser> addAdminUser(String email, {String? notes}) async {
    return AdminUser(
      id: 'u-2',
      email: email,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> deleteAdminUser(String id) async => true;

  @override
  Future<AdminTelemetryMetrics> getTelemetryMetrics() async {
    return AdminTelemetryMetrics(
      hourlyPackets: [
        HourlyPacketBucket(
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          count: 120,
          avgSpeed: 22.5,
        ),
        HourlyPacketBucket(
          timestamp: DateTime.now(),
          count: 250,
          avgSpeed: 26.0,
        ),
      ],
      speedDistribution: [
        BusSpeedMetric(
          busNumber: 'Bus 1',
          deviceId: 'NITC-BUS-001',
          speed: 28.5,
          heading: 90.0,
          lastSeen: DateTime.now(),
        ),
      ],
      totalPacketsAllTime: 12000,
      totalPackets24h: 370,
    );
  }

  @override
  Future<Map<String, dynamic>> testPingDevice({
    required String deviceId,
    required String secret,
  }) async {
    return {
      'ok': true,
      'epoch': 2,
      'idempotent_retry': false,
      'latency_ms': 42,
      'http_status': 200,
      'message': 'Session reset successfully',
    };
  }

  @override
  Future<Map<String, dynamic>> injectSimulatedTelemetry({
    required String deviceId,
    required String secret,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) async {
    return {'ok': true, 'seq': 51, 'latency_ms': 35, 'http_status': 200};
  }
}

void main() {
  group('Admin Dashboard UI Tests', () {
    testWidgets('Non-admin user receives Access Denied screen', (tester) async {
      await tester.pumpTrackletWidget(
        const AdminDashboardScreen(),
        overrides: [
          isAdminProvider.overrideWith((ref) => Future.value(false)),
          adminRepositoryProvider.overrideWithValue(
            FakeAdminRepository(isAdmin: false),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsNWidgets(2));
      expect(
        find.text('Your account is not on the administrator allowlist.'),
        findsOneWidget,
      );
    });

    testWidgets('Verified admin sees Admin Controls, charts and tabs', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository(isAdmin: true);

      await tester.pumpTrackletWidget(
        const AdminDashboardScreen(),
        overrides: [
          isAdminProvider.overrideWith((ref) => Future.value(true)),
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Controls'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Debug Console'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);
      expect(find.text('Admins'), findsOneWidget);

      // Verify Overview contents & charts
      expect(find.text('Telemetry Core Connected'), findsOneWidget);
      expect(find.text('Total Trackers'), findsOneWidget);
      expect(find.text('Fleet Tracker Distribution'), findsOneWidget);

      // Drag down to reveal throughput and hardware workbench charts
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Telemetry Ingestion Throughput'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Live Hardware & Telemetry Workbench'), findsOneWidget);
    });

    testWidgets(
      'Devices tab shows filters, status pill, and Test Ping button',
      (tester) async {
        final fakeRepo = FakeAdminRepository(isAdmin: true);

        await tester.pumpTrackletWidget(
          const AdminDashboardScreen(initialTabIndex: 1),
          overrides: [
            isAdminProvider.overrideWith((ref) => Future.value(true)),
            adminRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );

        await tester.pumpAndSettle();

        // Check filter chips
        expect(find.text('All (1)'), findsOneWidget);
        expect(find.text('Active (1)'), findsOneWidget);
        expect(find.text('Inactive (0)'), findsOneWidget);
        expect(find.text('Simulated (0)'), findsOneWidget);

        // Check device details
        expect(find.text('NITC-BUS-001'), findsOneWidget);
        expect(find.text('Test Ping'), findsOneWidget);
        expect(find.text('Rotate Secret'), findsOneWidget);
      },
    );

    testWidgets('Live Debug Console displays rate selector and speed chart', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository(isAdmin: true);

      await tester.pumpTrackletWidget(
        const AdminDashboardScreen(initialTabIndex: 2),
        overrides: [
          isAdminProvider.overrideWith((ref) => Future.value(true)),
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      await tester.pumpAndSettle();

      // Debug Console tab is active
      expect(find.text('PAUSE STREAM'), findsOneWidget);
      expect(find.text('Fleet Velocity Spectrum'), findsOneWidget);
      expect(find.text('1s'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
      expect(find.text('5s'), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);

      // Tap pause button
      await tester.tap(find.text('PAUSE STREAM'));
      await tester.pumpAndSettle();

      // State is now paused
      expect(find.text('RESUME STREAM'), findsOneWidget);

      // Tap resume button
      await tester.tap(find.text('RESUME STREAM'));
      await tester.pumpAndSettle();

      expect(find.text('PAUSE STREAM'), findsOneWidget);
    });
  });
}
