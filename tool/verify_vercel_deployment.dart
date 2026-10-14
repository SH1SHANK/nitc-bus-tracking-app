import 'dart:convert';
import 'dart:io';

/// Deterministic Post-Deployment Smoke Verification & Security Assertion Tool
/// Usage: dart run tool/verify_vercel_deployment.dart --url=https://your-deployment.vercel.app [--expected-commit=abcdef123...]
void main(List<String> args) async {
  String? url;
  String? expectedCommit;

  for (final arg in args) {
    if (arg.startsWith('--url=')) {
      url = arg.substring('--url='.length).trim();
    } else if (arg.startsWith('--expected-commit=')) {
      expectedCommit = arg.substring('--expected-commit='.length).trim();
    } else if (!arg.startsWith('--') && url == null) {
      url = arg.trim();
    }
  }

  if (url == null || url.isEmpty) {
    stderr.writeln('Error: Missing required --url argument.');
    stderr.writeln(
      'Usage: dart run tool/verify_vercel_deployment.dart --url=https://<DEPLOYMENT_URL> [--expected-commit=<SHA>]',
    );
    exit(1);
  }

  // Normalize base URL (strip trailing slash)
  if (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }

  stdout.writeln(
    '================================================================',
  );
  stdout.writeln(
    '🚀 Vercel Deployment Smoke Verification & Security Assertions',
  );
  stdout.writeln('Target URL: $url');
  if (expectedCommit != null) {
    stdout.writeln('Expected Commit SHA: $expectedCommit');
  }
  stdout.writeln(
    '================================================================\n',
  );

  final client =
      HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..badCertificateCallback = (cert, host, port) => false;

  var hasFailure = false;

  try {
    // -------------------------------------------------------------
    // Assertion 1: Verify BUILD_METADATA.json
    // -------------------------------------------------------------
    stdout.writeln('[1/4] Verifying $url/BUILD_METADATA.json ...');
    final metaUri = Uri.parse('$url/BUILD_METADATA.json');
    final metaReq = await client.getUrl(metaUri);
    final metaRes = await metaReq.close();

    if (metaRes.statusCode != 200) {
      stderr.writeln(
        '  ✗ Expected HTTP 200 for BUILD_METADATA.json, received: ${metaRes.statusCode}',
      );
      hasFailure = true;
    } else {
      final metaBody = await utf8.decodeStream(metaRes);
      try {
        final Map<String, dynamic> metadata =
            jsonDecode(metaBody) as Map<String, dynamic>;
        final String? actualCommit = metadata['commit_sha'] as String?;
        final String? integrity = metadata['integrity_status'] as String?;

        stdout.writeln('  ✓ HTTP 200 OK');
        stdout.writeln('  • Detected version: ${metadata['version']}');
        stdout.writeln(
          '  • Target platform:  ${metadata['target_platform'] ?? metadata['target']}',
        );
        stdout.writeln('  • Commit SHA:       $actualCommit');

        if (expectedCommit != null && expectedCommit.isNotEmpty) {
          if (actualCommit != null &&
              actualCommit.startsWith(expectedCommit.substring(0, 7))) {
            stdout.writeln('  ✓ Commit SHA matches expected GITHUB_SHA');
          } else {
            stderr.writeln(
              '  ✗ Commit SHA mismatch! Expected $expectedCommit, found $actualCommit',
            );
            hasFailure = true;
          }
        }

        if (integrity == 'VERIFIED_PRODUCTION') {
          stdout.writeln('  ✓ Integrity status verified: $integrity');
        } else {
          stderr.writeln('  ✗ Invalid integrity status: $integrity');
          hasFailure = true;
        }
      } catch (e) {
        stderr.writeln('  ✗ Failed to parse BUILD_METADATA.json response: $e');
        hasFailure = true;
      }

      final cacheControl = metaRes.headers.value('cache-control') ?? '';
      if (cacheControl.contains('no-cache') ||
          cacheControl.contains('no-store')) {
        stdout.writeln('  ✓ Metadata Cache-Control: $cacheControl');
      } else {
        stderr.writeln(
          '  ⚠ Warning: Expected no-cache for BUILD_METADATA.json, received: $cacheControl',
        );
      }
    }

    // -------------------------------------------------------------
    // Assertion 2: Verify Root (/) and HTTP Security Headers
    // -------------------------------------------------------------
    stdout.writeln('\n[2/4] Verifying $url/ and HTTP Security Headers ...');
    final rootUri = Uri.parse('$url/');
    final rootReq = await client.getUrl(rootUri);
    final rootRes = await rootReq.close();
    await rootRes.drain<void>();

    if (rootRes.statusCode != 200) {
      stderr.writeln(
        '  ✗ Expected HTTP 200 for root, received: ${rootRes.statusCode}',
      );
      hasFailure = true;
    } else {
      stdout.writeln('  ✓ HTTP 200 OK');
    }

    final headers = rootRes.headers;

    // Strict-Transport-Security
    final hsts = headers.value('strict-transport-security');
    if (hsts != null && hsts.contains('max-age=63072000')) {
      stdout.writeln('  ✓ Strict-Transport-Security: $hsts');
    } else {
      stderr.writeln(
        '  ✗ Missing or invalid Strict-Transport-Security header: $hsts',
      );
      hasFailure = true;
    }

    // X-Content-Type-Options
    final xcto = headers.value('x-content-type-options');
    if (xcto == 'nosniff') {
      stdout.writeln('  ✓ X-Content-Type-Options: nosniff');
    } else {
      stderr.writeln(
        '  ✗ Missing or invalid X-Content-Type-Options header: $xcto',
      );
      hasFailure = true;
    }

    // X-Frame-Options
    final xfo = headers.value('x-frame-options');
    if (xfo == 'DENY') {
      stdout.writeln('  ✓ X-Frame-Options: DENY');
    } else {
      stderr.writeln('  ✗ Missing or invalid X-Frame-Options header: $xfo');
      hasFailure = true;
    }

    // Referrer-Policy
    final refPol = headers.value('referrer-policy');
    if (refPol == 'strict-origin-when-cross-origin') {
      stdout.writeln('  ✓ Referrer-Policy: $refPol');
    } else {
      stderr.writeln('  ✗ Missing or invalid Referrer-Policy header: $refPol');
      hasFailure = true;
    }

    // Permissions-Policy
    final permPol = headers.value('permissions-policy');
    if (permPol != null && permPol.contains('geolocation')) {
      stdout.writeln('  ✓ Permissions-Policy: $permPol');
    } else {
      stderr.writeln(
        '  ✗ Missing or invalid Permissions-Policy header: $permPol',
      );
      hasFailure = true;
    }

    // Content-Security-Policy
    final csp = headers.value('content-security-policy');
    if (csp != null) {
      final hasWasm = csp.contains('wasm-unsafe-eval');
      final hasSupabase = csp.contains('fnngudikrvelpuhngtlw.supabase.co');
      final hasAncestors = csp.contains("frame-ancestors 'none'");

      if (hasWasm && hasSupabase && hasAncestors) {
        stdout.writeln(
          '  ✓ Content-Security-Policy validated (Wasm, Supabase, and frame-ancestors present)',
        );
      } else {
        stderr.writeln(
          '  ✗ Content-Security-Policy missing required directives (Wasm=$hasWasm, Supabase=$hasSupabase, FrameAncestors=$hasAncestors)',
        );
        hasFailure = true;
      }
    } else {
      stderr.writeln('  ✗ Missing Content-Security-Policy header!');
      hasFailure = true;
    }

    // Cache-Control on root
    final rootCache = headers.value('cache-control') ?? '';
    if (rootCache.contains('no-cache') || rootCache.contains('no-store')) {
      stdout.writeln('  ✓ Root Cache-Control: $rootCache');
    } else {
      stderr.writeln(
        '  ⚠ Warning: Root index.html should have no-cache, received: $rootCache',
      );
    }

    // -------------------------------------------------------------
    // Assertion 3: Verify SPA Rewrite for /auth/callback
    // -------------------------------------------------------------
    stdout.writeln('\n[3/4] Verifying SPA rewrite on $url/auth/callback ...');
    final authUri = Uri.parse('$url/auth/callback');
    final authReq = await client.getUrl(authUri);
    final authRes = await authReq.close();
    final authBody = await utf8.decodeStream(authRes);

    if (authRes.statusCode != 200) {
      stderr.writeln(
        '  ✗ Expected HTTP 200 for SPA route /auth/callback, received: ${authRes.statusCode}',
      );
      hasFailure = true;
    } else if (!authBody.contains('flutter_bootstrap.js') &&
        !authBody.contains('Tracklet')) {
      stderr.writeln(
        '  ✗ /auth/callback did not serve the Flutter SPA HTML entrypoint!',
      );
      hasFailure = true;
    } else {
      stdout.writeln(
        '  ✓ HTTP 200 OK: /auth/callback successfully rewrites to SPA shell',
      );
    }

    // -------------------------------------------------------------
    // Assertion 4: Verify Service Worker Cache-Control
    // -------------------------------------------------------------
    stdout.writeln('\n[4/4] Verifying $url/flutter_service_worker.js ...');
    final swUri = Uri.parse('$url/flutter_service_worker.js');
    final swReq = await client.getUrl(swUri);
    final swRes = await swReq.close();
    await swRes.drain<void>();

    if (swRes.statusCode == 200) {
      final swCache = swRes.headers.value('cache-control') ?? '';
      if (swCache.contains('no-cache') || swCache.contains('no-store')) {
        stdout.writeln('  ✓ Service Worker Cache-Control: $swCache');
      } else {
        stderr.writeln(
          '  ⚠ Warning: Service worker should have no-cache, received: $swCache',
        );
      }
    } else {
      stdout.writeln(
        '  • Service worker endpoint status: ${swRes.statusCode} (skipped)',
      );
    }
  } catch (e, stack) {
    stderr.writeln('\n✗ Fatal error during deployment verification: $e');
    stderr.writeln(stack);
    hasFailure = true;
  } finally {
    client.close();
  }

  stdout.writeln(
    '\n================================================================',
  );
  if (hasFailure) {
    stderr.writeln('🚨 SMOKE VERIFICATION FAILED!');
    stderr.writeln('To rollback this deployment immediately, run:');
    stderr.writeln('  vercel rollback --yes --token=\$VERCEL_TOKEN');
    stderr.writeln(
      '================================================================',
    );
    exit(1);
  } else {
    stdout.writeln('🎉 ALL POST-DEPLOYMENT SMOKE ASSERTIONS PASSED!');
    stdout.writeln(
      'The Vercel deployment is verified, secure, and ready for production.',
    );
    stdout.writeln(
      '================================================================',
    );
    exit(0);
  }
}
