import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/campus/campus_building.dart';
import 'package:tracklet/services/maps/map_cartography.dart';

void main() {
  group('CampusBuilding metadata', () {
    test('parses named points with longitude-first database aliases', () {
      final building = CampusBuilding.tryFromJson({
        'id': 'main-building',
        'name': 'Main Building',
        'category': 'Academic',
        'lat': 11.32165,
        'lng': 75.934246,
        'lon': 75.93425,
        'building_type': 'college',
      });

      expect(building, isNotNull);
      expect(building!.name, 'Main Building');
      expect(
        building.location,
        const GeoPoint(latitude: 11.32165, longitude: 75.93425),
      );
      expect(building.category, 'Academic');
      expect(building.buildingType, 'college');
    });

    test('rejects missing names and invalid or non-finite coordinates', () {
      for (final row in [
        {'id': 'x', 'name': ' ', 'lat': 11, 'lng': 75},
        {'id': 'x', 'name': 'Building', 'lat': 91, 'lng': 75},
        {'id': 'x', 'name': 'Building', 'lat': 11, 'lng': double.nan},
        {'id': 'x', 'name': 'Building', 'lat': 11},
      ]) {
        expect(CampusBuilding.tryFromJson(row), isNull);
      }
    });
  });

  group('Campus map cartography', () {
    test('serializes point features in GeoJSON longitude-latitude order', () {
      final geoJson =
          jsonDecode(
                TrackletMapCartography.toGeoJson([
                  const MapLabelFeature(
                    id: 'building-main',
                    name: 'Main Building',
                    point: GeoPoint(latitude: 11.32165, longitude: 75.934246),
                    kind: MapLabelKind.building,
                  ),
                ]),
              )
              as Map<String, dynamic>;
      final feature =
          (geoJson['features'] as List).single as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;

      expect(geoJson['type'], 'FeatureCollection');
      expect(geometry['type'], 'Point');
      expect(geometry['coordinates'], [75.934246, 11.32165]);
      expect(properties['name'], 'Main Building');
    });

    test(
      'empty building metadata produces no fabricated footprint features',
      () {
        final collection =
            jsonDecode(TrackletMapCartography.toGeoJson(const []))
                as Map<String, dynamic>;
        expect(collection['features'], isEmpty);
      },
    );

    test(
      'suppresses base symbols and restyles discovered footprint and road layers',
      () {
        expect(
          TrackletMapCartography.treatmentFor(
            type: 'symbol',
            sourceLayer: 'poi_label',
          ),
          MapBaseLayerTreatment.hideSymbols,
        );
        expect(
          TrackletMapCartography.treatmentFor(
            type: 'fill',
            sourceLayer: 'building',
          ),
          MapBaseLayerTreatment.campusBuildingFootprint,
        );
        expect(
          TrackletMapCartography.treatmentFor(
            type: 'line',
            sourceLayer: 'transportation',
          ),
          MapBaseLayerTreatment.subtleRoad,
        );
        expect(
          TrackletMapCartography.layerOverrides(
            MapBaseLayerTreatment.warmBackground,
          )['background-color'],
          '#F7F5F0',
        );
        expect(
          TrackletMapCartography.treatmentFor(
            type: 'fill',
            sourceLayer: 'land',
          ),
          MapBaseLayerTreatment.warmLand,
        );
        expect(
          TrackletMapCartography.treatmentFor(
            type: 'fill-extrusion',
            sourceLayer: 'building',
          ),
          MapBaseLayerTreatment.hideBuildingExtrusions,
        );
      },
    );

    test(
      'symbol layers yield to collisions except for the selected stop label',
      () {
        final layers = TrackletMapCartography.labelLayerDefinitions();
        final normalStopLayout =
            layers.singleWhere(
                  (layer) =>
                      layer['id'] ==
                      TrackletMapCartography.otherStopLabelsLayerId,
                )['layout']
                as Map;
        final selectedStopLayout =
            layers.singleWhere(
                  (layer) =>
                      layer['id'] ==
                      TrackletMapCartography.selectedStopLabelLayerId,
                )['layout']
                as Map;

        expect(normalStopLayout['text-field'], ['get', 'name']);
        expect(normalStopLayout['text-allow-overlap'], isFalse);
        expect(normalStopLayout['text-ignore-placement'], isFalse);
        expect(selectedStopLayout['text-allow-overlap'], isTrue);
        expect(selectedStopLayout['text-ignore-placement'], isTrue);
      },
    );
  });
}
