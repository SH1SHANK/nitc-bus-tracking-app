import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'live pipeline integration requires a dedicated non-production Supabase project',
    () {},
    skip:
        'The previous test called the deployed simulator with device credentials and wrote production telemetry. Run integration checks only against an isolated project with provisioned SIM buses.',
  );
}
