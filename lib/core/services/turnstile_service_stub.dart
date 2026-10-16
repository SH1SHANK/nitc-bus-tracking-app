import 'turnstile_service.dart';

/// Non-web fallback implementation for [TurnstileService].
class TurnstileServiceImpl implements TurnstileService {
  @override
  Future<String?> getCaptchaToken({required String action}) async => null;
}
