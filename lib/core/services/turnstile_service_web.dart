import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'turnstile_service.dart';

@JS('requestTurnstileToken')
external JSPromise<JSString>? _requestTurnstileToken(
  JSString sitekey,
  JSString action,
);

/// Web implementation of [TurnstileService] invoking Cloudflare Turnstile explicitly.
class TurnstileServiceImpl implements TurnstileService {
  @override
  Future<String?> getCaptchaToken({required String action}) async {
    if (!kIsWeb || !AppConfig.isCaptchaConfigured) {
      return null;
    }

    try {
      final promise = _requestTurnstileToken(
        AppConfig.captchaSiteKey.toJS,
        action.toJS,
      );
      if (promise == null) return null;
      final jsString = await promise.toDart;
      return jsString.toDart;
    } catch (e) {
      debugPrint('Turnstile error: $e');
      rethrow;
    }
  }
}
