import 'dart:io';

/// Finds high-confidence credential material in tracked text files.
///
/// This is intentionally small and complementary to GitHub secret scanning; it
/// is not intended to replace a full secret-management system.
void main() {
  final result = Process.runSync('git', ['ls-files'], runInShell: true);
  if (result.exitCode != 0) {
    stderr.writeln('Unable to list tracked files for secret scanning.');
    exit(1);
  }

  final findings = <String>[];
  final patterns = <RegExp>[
    RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    RegExp(
      r'(?:supabase[_-]?service[_-]?role|onesignal[_-]?rest[_-]?api|mapbox[_-]?secret)[^\n:=]*[:=]',
      caseSensitive: false,
    ),
    RegExp(r'"type"\s*:\s*"service_account"', caseSensitive: false),
    RegExp(
      r'(?:ghp_|github_pat_|sk_live_|AKIA)[A-Za-z0-9_\-]{12,}',
      caseSensitive: false,
    ),
  ];

  for (final path in (result.stdout as String).split('\n')) {
    if (path.isEmpty ||
        path.endsWith('.lock') ||
        <String>[
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.ttf',
          '.ico',
        ].any(path.endsWith)) {
      continue;
    }
    final file = File(path);
    if (!file.existsSync()) continue;

    String contents;
    try {
      contents = file.readAsStringSync();
    } on FormatException {
      continue;
    } on FileSystemException {
      continue;
    }
    final lines = contents.split('\n');
    for (var index = 0; index < lines.length; index++) {
      if (patterns.any((pattern) => pattern.hasMatch(lines[index]))) {
        final isExample =
            path.contains('.example.') ||
            lines[index].contains('your-') ||
            lines[index].contains('replace-me');
        if (!isExample) {
          findings.add('$path:${index + 1}');
        }
      }
    }
  }

  if (findings.isNotEmpty) {
    stderr.writeln('Potential credentials found in tracked files:');
    for (final finding in findings) {
      stderr.writeln('  $finding');
    }
    exit(1);
  }
  stdout.writeln('Secret scan passed: no high-confidence credentials found.');
}
