import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../config/app_config.dart';
import 'turnstile_service.dart';

/// Mobile WebView implementation for Cloudflare Turnstile CAPTCHA.
class TurnstileServiceImpl implements TurnstileService {
  @override
  Future<String?> getCaptchaToken({
    required String action,
    BuildContext? context,
  }) async {
    if (kIsWeb || !AppConfig.isCaptchaConfigured) {
      return null;
    }

    if (context == null || !context.mounted) {
      return null;
    }

    // Only invoke interactive WebView dialog on mobile surfaces (Android / iOS) with active WebView platform
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile || WebViewPlatform.instance == null) {
      return null;
    }

    return _showTurnstileDialog(context: context, action: action);
  }

  Future<String?> _showTurnstileDialog({
    required BuildContext context,
    required String action,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TurnstileModalSheet(
          siteKey: AppConfig.captchaSiteKey,
          action: action,
        );
      },
    );

    if (result == null) {
      throw Exception('Verification cancelled by user');
    }

    if (result == '__ERROR_DOMAIN_UNSUPPORTED__') {
      debugPrint(
        'Turnstile domain/key not permitted on this mobile host. Proceeding without captcha token.',
      );
      return null;
    }

    return result;
  }
}

class _TurnstileModalSheet extends StatefulWidget {
  const _TurnstileModalSheet({required this.siteKey, required this.action});

  final String siteKey;
  final String action;

  @override
  State<_TurnstileModalSheet> createState() => _TurnstileModalSheetState();
}

class _TurnstileModalSheetState extends State<_TurnstileModalSheet> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  void _setupController() {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final theme = isDark ? 'dark' : 'light';
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      background: transparent;
      overflow: hidden;
    }
    #cf-turnstile {
      display: flex;
      justify-content: center;
      align-items: center;
    }
  </style>
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
</head>
<body>
  <div id="cf-turnstile"></div>
  <script>
    function onTurnstileSuccess(token) {
      if (window.TurnstileBridge) {
        window.TurnstileBridge.postMessage(JSON.stringify({ type: 'success', token: token }));
      }
    }
    function onTurnstileError(errorCode) {
      if (window.TurnstileBridge) {
        window.TurnstileBridge.postMessage(JSON.stringify({ type: 'error', code: errorCode }));
      }
    }
    function renderTurnstile() {
      if (window.turnstile && typeof window.turnstile.render === 'function') {
        window.turnstile.render('#cf-turnstile', {
          sitekey: '${widget.siteKey}',
          action: '${widget.action}',
          callback: onTurnstileSuccess,
          'error-callback': onTurnstileError,
          theme: '$theme'
        });
      } else {
        setTimeout(renderTurnstile, 100);
      }
    }
    window.onload = renderTurnstile;
  </script>
</body>
</html>
''';

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                if (mounted) setState(() => _isLoading = false);
              },
              onWebResourceError: (err) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = err.description;
                  });
                }
              },
            ),
          )
          ..addJavaScriptChannel(
            'TurnstileBridge',
            onMessageReceived: (JavaScriptMessage msg) {
              try {
                final data = jsonDecode(msg.message) as Map<String, dynamic>;
                final type = data['type'] as String?;
                if (type == 'success') {
                  final token = data['token'] as String?;
                  Navigator.of(context).pop(token);
                } else if (type == 'error') {
                  final code = data['code']?.toString() ?? '';
                  if (code.contains('110200') ||
                      code.contains('110600') ||
                      code.contains('domain')) {
                    Navigator.of(context).pop('__ERROR_DOMAIN_UNSUPPORTED__');
                  } else {
                    setState(() {
                      _errorMessage =
                          'Verification error ($code). Please retry.';
                    });
                  }
                }
              } catch (_) {
                Navigator.of(context).pop();
              }
            },
          )
          ..loadHtmlString(html, baseUrl: 'https://localhost');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TrackletRadii.lg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        TrackletSpacing.screenMargin,
        TrackletSpacing.lg,
        TrackletSpacing.screenMargin,
        TrackletSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TrackletSpacing.xs),
                    decoration: BoxDecoration(
                      color: TrackletColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: TrackletColors.primary,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Text(
                    'Security Verification',
                    style: TrackletTypography.titleMedium.copyWith(
                      fontWeight: TrackletTypography.weightSemiBold,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cancel',
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.xs),
          Text(
            'Complete verification to protect campus transit services.',
            style: TrackletTypography.bodySmall.copyWith(
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(TrackletSpacing.md),
              decoration: BoxDecoration(
                color: TrackletColors.error.withValues(alpha: 0.1),
                borderRadius: TrackletRadii.roundedMd,
                border: Border.all(
                  color: TrackletColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: TrackletColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TrackletTypography.bodySmall.copyWith(
                        color: TrackletColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.md),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _setupController();
              },
              child: const Text('Retry Verification'),
            ),
          ] else ...[
            SizedBox(
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
