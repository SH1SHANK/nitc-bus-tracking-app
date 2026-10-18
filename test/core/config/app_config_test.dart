import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/config/app_config.dart';

void main() {
  group('AppConfig endpoint selection', () {
    test('provides valid default development endpoints and credentials', () {
      expect(
        AppConfig.supabaseUrl,
        equals('https://fnngudikrvelpuhngtlw.supabase.co'),
      );
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      expect(AppConfig.hasSupabaseCredentials, isTrue);
      expect(AppConfig.isCaptchaConfigured, isTrue);
      expect(AppConfig.captchaSiteKey, equals('0x4AAAAAAFXxHTiFZHgWmlcA'));
      expect(AppConfig.isMapboxConfigured, isA<bool>());
      expect(AppConfig.mapboxPublicToken, isA<String>());
    });

    test('rejects malformed and insecure release endpoints', () {
      expect(AppConfig.isValidServiceUrl('not a url', 'production'), isFalse);
      expect(
        AppConfig.isValidServiceUrl('http://api.example.com', 'staging'),
        isFalse,
      );
      expect(
        AppConfig.isValidServiceUrl(
          'https://user:pass@example.com',
          'production',
        ),
        isFalse,
      );
      expect(
        AppConfig.isValidServiceUrl(
          'https://api.example.com?token=invalid',
          'production',
        ),
        isFalse,
      );
      expect(AppConfig.isSupportedEnvironment('prod'), isFalse);
      expect(
        AppConfig.isValidServiceUrl('https://prod.example.com', 'preview'),
        isFalse,
      );
    });

    test(
      'allows explicitly selected development, staging, and production URLs',
      () {
        expect(
          AppConfig.isValidServiceUrl('http://localhost:54321', 'development'),
          isTrue,
        );
        expect(
          AppConfig.isValidServiceUrl('https://staging.example.com', 'staging'),
          isTrue,
        );
        expect(
          AppConfig.isValidServiceUrl('https://prod.example.com', 'production'),
          isTrue,
        );
        expect(AppConfig.isSupportedEnvironment('production'), isTrue);
      },
    );

    test('requires a non-empty anon key and a valid explicit environment', () {
      expect(
        AppConfig.hasValidSupabaseConfiguration('', '', 'development'),
        isFalse,
      );
      expect(
        AppConfig.hasValidSupabaseConfiguration(
          'https://dev.example.com',
          '',
          'development',
        ),
        isFalse,
      );
      expect(
        AppConfig.hasValidSupabaseConfiguration(
          'https://dev.example.com',
          'public-key',
          'development',
        ),
        isTrue,
      );
      expect(
        AppConfig.hasValidSupabaseConfiguration(
          'https://stage.example.com',
          'public-key',
          'staging',
        ),
        isTrue,
      );
      expect(
        AppConfig.hasValidSupabaseConfiguration(
          'https://prod.example.com',
          'public-key',
          'production',
        ),
        isTrue,
      );
      expect(
        AppConfig.hasValidSupabaseConfiguration(
          'https://prod.example.com',
          'public-key',
          'preview',
        ),
        isFalse,
      );
    });
  });
}
