import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tracklet/data/admin/admin_repository.dart';

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);
  final Future<http.Response> Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();
    final httpRequest =
        http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..bodyBytes = bodyBytes;
    final res = await handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}

void main() {
  group('Supabase-Native AdminRepository Tests', () {
    const supabaseUrl = 'https://mock.supabase.co';
    const anonKey = 'mock-anon-key';

    test('checkAdminStatus returns true when RPC returns true', () async {
      final client = FakeHttpClient((req) async {
        if (req.url.path == '/rest/v1/rpc/is_current_user_admin') {
          return http.Response(
            jsonEncode(true),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(supabaseUrl, anonKey, httpClient: client);
      final repo = HttpAdminRepository(supabase: supabase, httpClient: client);

      final isAdmin = await repo.checkAdminStatus();
      expect(isAdmin, isTrue);
    });

    test(
      'checkAdminStatus returns false when RPC returns false or errors',
      () async {
        final client = FakeHttpClient((req) async {
          if (req.url.path == '/rest/v1/rpc/is_current_user_admin') {
            return http.Response(
              jsonEncode(false),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final supabase = SupabaseClient(
          supabaseUrl,
          anonKey,
          httpClient: client,
        );
        final repo = HttpAdminRepository(
          supabase: supabase,
          httpClient: client,
        );

        final isAdmin = await repo.checkAdminStatus();
        expect(isAdmin, isFalse);
      },
    );

    test('getOverview parses operational metrics correctly', () async {
      final client = FakeHttpClient((req) async {
        if (req.url.path == '/rest/v1/rpc/admin_get_overview') {
          return http.Response(
            jsonEncode({
              'fleet_summary': {
                'total_devices': 5,
                'active_devices': 4,
                'total_buses': 5,
                'active_buses': 4,
                'active_trackers': 3,
                'stale_trackers': 1,
                'offline_trackers': 1,
              },
              'telemetry_health': {
                'recent_packets_24h': 1200,
                'latest_packet_at': '2026-10-17T03:00:00.000Z',
                'is_pipeline_healthy': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/healthz') {
          return http.Response(
            jsonEncode({'status': 'ok', 'uptime': 3600.0}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(supabaseUrl, anonKey, httpClient: client);
      final repo = HttpAdminRepository(supabase: supabase, httpClient: client);

      final overview = await repo.getOverview();
      expect(overview.totalDevices, 5);
      expect(overview.activeDevices, 4);
      expect(overview.onlineDevices, 3);
      expect(overview.staleDevices, 1);
      expect(overview.offlineDevices, 1);
      expect(overview.databaseConnected, isTrue);
      expect(overview.uptimeSeconds, 3600.0);
    });

    test(
      'getDevices retrieves tracker inventory with safe attributes',
      () async {
        final client = FakeHttpClient((req) async {
          if (req.url.path == '/rest/v1/rpc/admin_get_devices') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'd-uuid-1',
                  'device_id': 'NITC-BUS-001',
                  'bus_id': 'bus-uuid-1',
                  'bus_number': 'Bus 1',
                  'registration_number': 'KL-11-AV-0001',
                  'is_active': true,
                  'current_epoch': 2,
                  'created_at': '2026-10-17T00:00:00.000Z',
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final supabase = SupabaseClient(
          supabaseUrl,
          anonKey,
          httpClient: client,
        );
        final repo = HttpAdminRepository(
          supabase: supabase,
          httpClient: client,
        );

        final devices = await repo.getDevices();
        expect(devices.length, 1);
        expect(devices.first.deviceId, 'NITC-BUS-001');
        expect(devices.first.busNumber, 'Bus 1');
        expect(devices.first.busLabel, 'KL-11-AV-0001');
        expect(devices.first.isActive, isTrue);
      },
    );

    test(
      'registerDevice provisions tracker and returns one-time secret',
      () async {
        final client = FakeHttpClient((req) async {
          if (req.url.path == '/rest/v1/rpc/admin_register_device') {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            expect(body['p_device_id'], 'NITC-BUS-009');
            expect(body['p_bus_number'], 'Bus 9');
            expect(
              (body['p_secret'] as String).length,
              greaterThanOrEqualTo(16),
            );

            return http.Response(
              jsonEncode({
                'device_id': 'NITC-BUS-009',
                'bus_id': 'bus-uuid-9',
                'bus_number': 'Bus 9',
                'secret': body['p_secret'],
                'current_epoch': 1,
                'is_active': true,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final supabase = SupabaseClient(
          supabaseUrl,
          anonKey,
          httpClient: client,
        );
        final repo = HttpAdminRepository(
          supabase: supabase,
          httpClient: client,
        );

        final result = await repo.registerDevice(
          deviceId: 'NITC-BUS-009',
          busNumber: 'Bus 9',
        );

        expect(result.device.deviceId, 'NITC-BUS-009');
        expect(result.device.busNumber, 'Bus 9');
        expect(result.generatedSecret.length, 32);
      },
    );

    test('updateDeviceStatus toggles tracker active status', () async {
      final client = FakeHttpClient((req) async {
        if (req.url.path == '/rest/v1/rpc/admin_toggle_device_status') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['p_device_id'], 'NITC-BUS-001');
          expect(body['p_is_active'], false);
          return http.Response(
            jsonEncode(true),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(supabaseUrl, anonKey, httpClient: client);
      final repo = HttpAdminRepository(supabase: supabase, httpClient: client);

      final success = await repo.updateDeviceStatus(
        deviceId: 'NITC-BUS-001',
        isActive: false,
      );
      expect(success, isTrue);
    });

    test('rotateSecret generates and sets a new secret', () async {
      final client = FakeHttpClient((req) async {
        if (req.url.path == '/rest/v1/rpc/admin_rotate_device_secret') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['p_device_id'], 'NITC-BUS-001');
          return http.Response(
            jsonEncode({
              'device_id': 'NITC-BUS-001',
              'new_secret': body['p_new_secret'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(supabaseUrl, anonKey, httpClient: client);
      final repo = HttpAdminRepository(supabase: supabase, httpClient: client);

      final newSecret = await repo.rotateSecret(deviceId: 'NITC-BUS-001');
      expect(newSecret.length, 32);
    });

    test(
      'getDebugTrackers parses telemetry and breadcrumbs correctly',
      () async {
        final client = FakeHttpClient((req) async {
          if (req.url.path == '/rest/v1/rpc/admin_get_debug_trackers') {
            return http.Response(
              jsonEncode([
                {
                  'device_id': 'NITC-BUS-001',
                  'bus_number': 'Bus 1',
                  'route_name': 'Hostel Loop',
                  'latitude': 11.3216,
                  'longitude': 75.9337,
                  'speed': 24.0,
                  'heading': 180.0,
                  'accuracy': 3.5,
                  'seq': 100,
                  'epoch': 1,
                  'is_active': true,
                  'last_seen': '2026-10-17T03:00:00.000Z',
                  'freshness_status': 'LIVE',
                  'recent_positions': [
                    {
                      'latitude': 11.3215,
                      'longitude': 75.9336,
                      'speed': 23.0,
                      'heading': 180.0,
                      'accuracy': 3.5,
                      'seq': 99,
                      'recorded_at': '2026-10-17T02:59:50.000Z',
                    },
                  ],
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final supabase = SupabaseClient(
          supabaseUrl,
          anonKey,
          httpClient: client,
        );
        final repo = HttpAdminRepository(
          supabase: supabase,
          httpClient: client,
        );

        final trackers = await repo.getDebugTrackers();
        expect(trackers.length, 1);
        final t = trackers.first;
        expect(t.deviceId, 'NITC-BUS-001');
        expect(t.freshness, 'live');
        expect(t.currentPosition?['latitude'], 11.3216);
        expect(t.recentBreadcrumbs.length, 1);
        expect(t.recentBreadcrumbs.first.seq, 99);
      },
    );

    test('getDetailedHealth parses system diagnostics', () async {
      final client = FakeHttpClient((req) async {
        if (req.url.path == '/rest/v1/rpc/admin_get_system_health') {
          return http.Response(
            jsonEncode({
              'api': {'status': 'ok', 'uptime_seconds': 0},
              'database': {
                'status': 'connected',
                'latency_ms': 5,
                'connected': true,
              },
              'telemetry_pipeline': {
                'status': 'healthy',
                'latest_record_age_seconds': 12.5,
                'healthy': true,
              },
              'fleet_summary': {
                'online_trackers': 4,
                'stale_trackers': 1,
                'offline_trackers': 0,
                'total_devices': 5,
                'active_devices': 5,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/healthz') {
          return http.Response(
            jsonEncode({'status': 'ok', 'uptime': 7200.0}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(supabaseUrl, anonKey, httpClient: client);
      final repo = HttpAdminRepository(supabase: supabase, httpClient: client);

      final health = await repo.getDetailedHealth();
      expect(health.dbConnected, isTrue);
      expect(health.telemetryHealthy, isTrue);
      expect(health.fleetOnline, 4);
      expect(health.fleetTotal, 5);
      expect(health.uptimeSeconds, 7200.0);
    });

    test(
      'getAdminUsers and addAdminUser manage allowlist via Supabase',
      () async {
        final client = FakeHttpClient((req) async {
          if (req.url.path == '/rest/v1/admin_emails') {
            if (req.method == 'GET') {
              return http.Response(
                jsonEncode([
                  {
                    'id': 'a-1',
                    'email': 'admin1@nitc.ac.in',
                    'created_at': '2026-10-17T00:00:00.000Z',
                  },
                ]),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (req.method == 'POST') {
              return http.Response(
                jsonEncode({
                  'id': 'a-2',
                  'email': 'newadmin@nitc.ac.in',
                  'created_at': '2026-10-17T03:00:00.000Z',
                }),
                201,
                headers: {'content-type': 'application/json'},
              );
            }
            if (req.method == 'DELETE') {
              return http.Response('', 204);
            }
          }
          if (req.url.path == '/rest/v1/rpc/log_admin_action') {
            return http.Response(jsonEncode('log-uuid'), 200);
          }
          return http.Response('Not Found', 404);
        });

        final supabase = SupabaseClient(
          supabaseUrl,
          anonKey,
          httpClient: client,
        );
        final repo = HttpAdminRepository(
          supabase: supabase,
          httpClient: client,
        );

        final users = await repo.getAdminUsers();
        expect(users.length, 1);
        expect(users.first.email, 'admin1@nitc.ac.in');

        final added = await repo.addAdminUser('newadmin@nitc.ac.in');
        expect(added.email, 'newadmin@nitc.ac.in');

        final deleted = await repo.deleteAdminUser('a-1');
        expect(deleted, isTrue);
      },
    );
  });
}
