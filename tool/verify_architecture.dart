import 'dart:io';

/// Script to verify architectural layer import boundaries.
///
/// Rules:
/// 1. Features cannot import other features.
/// 2. Feature code cannot directly import `package:onesignal_flutter`, `package:supabase_flutter`, or `package:geolocator`.
/// 3. Shared code (core, data, services, design_system) cannot import feature code.
/// 4. Design system cannot import data, services, or features.
/// 5. Shared application code must not import `dart:io` directly (to ensure web compatibility).
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib/ directory not found.');
    exit(1);
  }

  final violations = <String>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final relativePath = entity.path.replaceAll('\\', '/');
    final lines = entity.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ') && !line.startsWith('export ')) continue;

      // Check 1: Feature isolation (a feature cannot import another feature)
      if (relativePath.contains('lib/features/')) {
        final featureName = _extractFeatureName(relativePath);
        if (featureName != null) {
          final importedFeature = _extractImportedFeature(line);
          if (importedFeature != null && importedFeature != featureName) {
            violations.add(
              '$relativePath:${i + 1} Feature "$featureName" cannot import feature "$importedFeature": $line',
            );
          }
        }

        // Check 2: Direct 3rd-party vendor imports inside features
        if (line.contains('package:onesignal_flutter') ||
            line.contains('package:supabase_flutter') ||
            line.contains('package:geolocator/')) {
          violations.add(
            '$relativePath:${i + 1} Features cannot directly import external SDKs (use services/data layer): $line',
          );
        }
      }

      // Check 3: Shared layers importing features
      final isSharedLayer =
          relativePath.contains('lib/core/') ||
          relativePath.contains('lib/data/') ||
          relativePath.contains('lib/services/') ||
          relativePath.contains('lib/design_system/');

      if (isSharedLayer && line.contains('/features/')) {
        violations.add(
          '$relativePath:${i + 1} Shared layers cannot import features: $line',
        );
      }

      // Check 4: Design system importing data, services, or features
      if (relativePath.contains('lib/design_system/')) {
        if (line.contains('/data/') ||
            line.contains('/services/') ||
            line.contains('/features/')) {
          violations.add(
            '$relativePath:${i + 1} Design system cannot depend on data/services/features: $line',
          );
        }
      }

      // Check 5: Web compatibility (no dart:io in general app code)
      if (line.contains("import 'dart:io'") ||
          line.contains('import "dart:io"')) {
        violations.add(
          '$relativePath:${i + 1} Disallowed dart:io import (breaks Web build): $line',
        );
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      '=== ARCHITECTURE VIOLATIONS DETECTED (${violations.length}) ===',
    );
    for (final v in violations) {
      stderr.writeln('  • $v');
    }
    exit(1);
  } else {
    stdout.writeln(
      '✓ Architecture verification passed: All layer boundaries respected.',
    );
  }
}

String? _extractFeatureName(String path) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

String? _extractImportedFeature(String importLine) {
  final match = RegExp(r'features/([^/]+)/').firstMatch(importLine);
  return match?.group(1);
}
