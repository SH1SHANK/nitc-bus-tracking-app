import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/features/map/widgets/bus_detail_sheet.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'compact and expanded sheet states fit both requested viewports',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-internal-id',
        name: 'Campus Bus 1',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        tripId: 'trip-internal-id',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93),
          speedKmH: 18,
          timestamp: now,
        ),
        lastUpdated: now,
      );
      const route = BusRoute(
        id: 'route-1',
        code: 'R1',
        name: 'East Campus → Mega Boys Hostel',
        geometry: RouteGeometry.missing(),
      );

      for (final size in [const Size(320, 568), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        for (final eta in [
          const BusEtaResult.valid(
            minutes: 3,
            distanceMeters: 450,
            busProgressMeters: 150,
            smoothedSpeedMetersPerSecond: 5,
          ),
          const BusEtaResult.unavailable(BusEtaStatus.stationary),
        ]) {
          await tester.pumpTrackletWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: BusDetailSheet(
                  key: ValueKey('${size.width}-${eta.status}'),
                  bus: bus,
                  route: route,
                  eta: eta,
                  onClose: () {},
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: 'compact $size $eta');
          expect(find.text('Campus Bus 1'), findsOneWidget);
          await tester.ensureVisible(find.text('More detail'));
          await tester.tap(find.text('More detail'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('ETA'));
          expect(tester.takeException(), isNull, reason: 'expanded $size $eta');
          expect(find.text('ETA'), findsOneWidget);
          expect(find.text(eta.displayValue), findsAtLeastNWidgets(1));
          expect(
            tester.getRect(find.byType(BusDetailSheet)).height,
            lessThanOrEqualTo(size.height * 0.56 + 1),
          );
        }
      }
    },
  );
}
