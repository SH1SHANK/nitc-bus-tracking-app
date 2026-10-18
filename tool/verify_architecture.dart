import 'dart:io';

/// Verifies the small set of import boundaries that keep Tracklet web-safe and
/// prevent feature modules from coupling to infrastructure.
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib/ directory not found.');
    exit(1);
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final path = entity.path.replaceAll('\\', '/');
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (!line.startsWith('import ') && !line.startsWith('export ')) continue;
      final location = '$path:${index + 1}';

      if (_isIn(path, 'features')) {
        final feature = _featureName(path);
        final importedFeature = _importedFeature(line);
        if (feature != null &&
            importedFeature != null &&
            importedFeature != feature) {
          violations.add(
            '$location Feature "$feature" cannot import feature '
            '"$importedFeature": $line',
          );
        }
        if (_containsAny(line, <String>[
          'package:supabase_flutter',
          'package:geolocator',
          'package:flutter_map',
        ])) {
          violations.add(
            '$location Features cannot directly import vendor SDKs; use '
            'data/services boundaries: $line',
          );
        }
      }

      if (_isIn(path, 'core') &&
          _containsAnyLayer(line, <String>['features', 'data', 'services'])) {
        violations.add(
          '$location Core cannot depend on application layers: $line',
        );
      }

      if (_isIn(path, 'design_system') &&
          _containsAnyLayer(line, <String>['features', 'data', 'services'])) {
        violations.add(
          '$location Design system cannot depend on features, data, or services: $line',
        );
      }

      if (_isIn(path, 'core') ||
          _isIn(path, 'data') ||
          _isIn(path, 'services') ||
          _isIn(path, 'design_system')) {
        if (_containsLayer(line, 'features')) {
          violations.add('$location Shared code cannot import features: $line');
        }
      }

      if (!_isIn(path, 'design_system') &&
          _containsAny(line, <String>[
            'package:lucide_icons',
            'package:phosphor_flutter',
            'package:google_fonts',
          ])) {
        violations.add(
          '$location Icon/font packages are only allowed in design_system: $line',
        );
      }

      if (line.contains("import 'dart:io'") ||
          line.contains('import "dart:io"')) {
        // Platform-specific IO implementation isolated behind conditional import
        if (!path.endsWith('offline_map_manager_io.dart') &&
            !path.endsWith('network_connectivity_io.dart')) {
          violations.add('$location dart:io is not allowed in app code: $line');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('=== ARCHITECTURE VIOLATIONS (${violations.length}) ===');
    for (final violation in violations) {
      stderr.writeln('  • $violation');
    }
    exit(1);
  }
  stdout.writeln('✓ Architecture verification passed.');
}

bool _isIn(String path, String layer) =>
    path.startsWith('lib/$layer/') || path.contains('/lib/$layer/');

bool _containsAny(String value, List<String> needles) =>
    needles.any(value.contains);

bool _containsAnyLayer(String importLine, List<String> layers) =>
    layers.any((layer) => _containsLayer(importLine, layer));

bool _containsLayer(String importLine, String layer) =>
    importLine.contains('/$layer/') ||
    importLine.contains("'$layer/") ||
    importLine.contains('"$layer/');

String? _featureName(String path) =>
    RegExp(r'/lib/features/([^/]+)/').firstMatch(path)?.group(1);

String? _importedFeature(String importLine) =>
    RegExp(r'features/([^/]+)/').firstMatch(importLine)?.group(1);
