import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tracklet/core/config/app_config.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/home_transit_logic.dart';

void main() {
  group('Full Pipeline End-to-End Integration Test', () {
    const edgeFunctionUrl =
        'https://fnngudikrvelpuhngtlw.supabase.co/functions/v1/telemetry-simulator';
    const anonKey = AppConfig.supabaseAnonKey;
    late SupabaseClient supabaseClient;
    late SupabaseTransitRepository transitRepository;
    final httpClient = HttpClient();

    setUpAll(() {
      supabaseClient = SupabaseClient(AppConfig.supabaseUrl, anonKey);
      transitRepository = SupabaseTransitRepository(supabaseClient);
    });

    tearDownAll(() {
      httpClient.close();
      supabaseClient.dispose();
    });

    test(
      'Pipeline Phase 1: Edge Function Simulator -> Fastify Telemetry API -> Supabase Ingestion',
      () async {
        // Step 1: Trigger the Edge Function to simulate telemetry fixes along Route R2 for Bus 2
        final uri = Uri.parse(
          '$edgeFunctionUrl?mode=simulate&route=R2&deviceId=NITC-SIM-002&busNumber=Bus%202&secret=SimDeviceSecret223456!&points=3&interval=1.0&autoTrip=true',
        );
        final request = await httpClient.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', 'Bearer $anonKey');

        final response = await request.close();
        expect(
          response.statusCode,
          200,
          reason: 'Edge Function must return HTTP 200',
        );

        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        expect(json['ok'], true, reason: 'Simulation run must report ok: true');
        expect(json['mode'], 'simulate');
        expect(json['route'], 'R2');
        expect(json['packetsEmitted'], 3);

        final packets =
            (json['packets'] as List<dynamic>).cast<Map<String, dynamic>>();
        expect(packets.length, 3);

        // Step 2: Verify each packet was accepted by Render Fastify API and persisted in Supabase
        for (final pkt in packets) {
          expect(
            pkt['httpStatus'],
            200,
            reason: 'Fastify Telemetry API must accept packet with 200 OK',
          );
          final apiRes = pkt['apiResponse'] as Map<String, dynamic>;
          expect(
            apiRes['ok'],
            true,
            reason: 'API response must report ok: true',
          );
          expect(
            apiRes['stored'],
            true,
            reason: 'Telemetry position must be stored in bus_positions',
          );
          expect(
            apiRes['state_updated'],
            true,
            reason: 'bus_current_state must be updated',
          );
          expect(pkt['seq'], isNotNull);
          expect(pkt['latitude'], isNotNull);
          expect(pkt['longitude'], isNotNull);
        }
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      'Pipeline Phase 2: Supabase RPCs & Data Model -> Flutter TransitRepository',
      () async {
        // 1. Verify institutional Stops loaded via Flutter TransitRepository
        final stops = await transitRepository.getStops();
        expect(
          stops,
          isNotEmpty,
          reason: 'Stops table must contain active campus stops',
        );

        final mbhStop =
            stops
                .where(
                  (s) =>
                      s.name.toLowerCase().contains('mega') ||
                      s.name.toLowerCase().contains('mbh'),
                )
                .firstOrNull;
        expect(
          mbhStop,
          isNotNull,
          reason: 'Mega Hostel Boys stop must be defined',
        );

        // 2. Verify Routes & Route-Stops loaded via Flutter TransitRepository
        final routes = await transitRepository.getRoutes(knownStops: stops);
        expect(
          routes,
          isNotEmpty,
          reason: 'Routes table must contain active campus routes',
        );

        final routeR1 = routes.where((r) => r.code == 'R1').firstOrNull;
        expect(routeR1, isNotNull, reason: 'Route R1 must exist');
        expect(
          routeR1!.path,
          isNotEmpty,
          reason: 'Route R1 must contain valid PostGIS path coordinates',
        );
        expect(
          routeR1.stopOccurrences,
          isNotEmpty,
          reason: 'Route R1 must have associated stop occurrences',
        );

        // 3. Verify Active Buses via get_active_bus_positions_v2 RPC in Flutter TransitRepository
        final activeBuses = await transitRepository.getActiveBuses();
        expect(
          activeBuses,
          isNotEmpty,
          reason: 'get_active_bus_positions_v2 must return active campus buses',
        );

        // Verify Bus 1 (driven by Cron job) and Bus 2 (driven by pipeline test)
        final liveBus = activeBuses.first;
        expect(
          liveBus.position.point.latitude,
          inInclusiveRange(11.30, 11.35),
          reason: 'Bus latitude must be within NITC campus',
        );
        expect(
          liveBus.position.point.longitude,
          inInclusiveRange(75.90, 75.96),
          reason: 'Bus longitude must be within NITC campus',
        );
        expect(liveBus.lastUpdated, isNotNull);

        // 4. Verify Active Trip & Stop Events via get_active_trip_stop_events RPC
        if (liveBus.tripId != null) {
          final stopEvents = await transitRepository.getBusStopEvents(
            liveBus.tripId!,
          );
          expect(stopEvents, isA<List<dynamic>>());
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Pipeline Phase 3: Flutter HomeTransitLogic & Live Transit UI Projection',
      () async {
        final stops = await transitRepository.getStops();
        final routes = await transitRepository.getRoutes(knownStops: stops);
        final activeBuses = await transitRepository.getActiveBuses();
        final liveBus = activeBuses.first;
        final targetRoute = routes.firstWhere(
          (r) => r.id == liveBus.routeId,
          orElse: () => routes.first,
        );

        // Test nearest campus stop resolution using live bus position
        final nearestStop = nearestCampusStopTo(liveBus.position.point, stops);
        expect(
          nearestStop,
          isNotNull,
          reason:
              'A campus stop must be within walking range of the bus position',
        );

        // Test route progress fraction calculation
        final progressFraction = routeProgressFraction(
          route: targetRoute,
          point: liveBus.position.point,
        );
        expect(progressFraction, isNotNull);
        expect(
          progressFraction,
          inInclusiveRange(0.0, 1.0),
          reason: 'Progress fraction must be between 0.0 and 1.0',
        );

        // Test walking time calculation
        final walkMins = estimateWalkMinutes(160.0);
        expect(walkMins, 2);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Pipeline Phase 4: Dynamic Progression Verification (Monotonic Fix Advancement)',
      () async {
        // Fetch current sequence before emitting next telemetry fix for Bus 2
        final busesBefore = await transitRepository.getActiveBuses();
        final bus2Before = busesBefore.firstWhere(
          (b) => b.numberPlate == 'Bus 2' || b.name.contains('Bus 2'),
        );
        final seqBefore = bus2Before.position.sequenceNumber;

        // Emit another 2 points for Bus 2 via Edge Function
        final uri = Uri.parse(
          '$edgeFunctionUrl?mode=simulate&route=R2&deviceId=NITC-SIM-002&busNumber=Bus%202&secret=SimDeviceSecret223456!&points=2&interval=1.0&autoTrip=true',
        );
        final request = await httpClient.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', 'Bearer $anonKey');
        final response = await request.close();
        expect(response.statusCode, 200);

        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        expect(json['ok'], true);

        // Fetch active buses again and confirm monotonic progression
        final busesAfter = await transitRepository.getActiveBuses();
        final bus2After = busesAfter.firstWhere(
          (b) => b.numberPlate == 'Bus 2' || b.name.contains('Bus 2'),
        );

        // Bus updated timestamp should be equal or newer
        expect(
          bus2After.lastUpdated.isAfter(bus2Before.lastUpdated) ||
              bus2After.lastUpdated.isAtSameMomentAs(bus2Before.lastUpdated),
          true,
        );

        if (seqBefore != null && bus2After.position.sequenceNumber != null) {
          expect(bus2After.position.sequenceNumber! >= seqBefore, true);
        }
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
