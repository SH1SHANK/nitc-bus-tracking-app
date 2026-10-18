import 'package:flutter/widgets.dart';

import 'turnstile_service_stub.dart'
    if (dart.library.js_interop) 'turnstile_service_web.dart'
    as impl;

/// Contract for acquiring a Cloudflare Turnstile CAPTCHA response token.
abstract class TurnstileService {
  static final TurnstileService instance = impl.TurnstileServiceImpl();

  /// Obtains a single-use Cloudflare Turnstile token for the given [action].
  /// Optionally passes [context] to render interactive mobile challenge WebView when required.
  /// Returns `null` on platforms where Turnstile is unconfigured or not required.
  Future<String?> getCaptchaToken({
    required String action,
    BuildContext? context,
  });
}
