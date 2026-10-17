import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../providers/admin_provider.dart';

/// Modal dialog to rotate credentials for an existing device.
class RotateSecretDialog extends ConsumerStatefulWidget {
  const RotateSecretDialog({super.key, required this.deviceId});

  final String deviceId;

  static Future<void> show(BuildContext context, String deviceId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RotateSecretDialog(deviceId: deviceId),
    );
  }

  @override
  ConsumerState<RotateSecretDialog> createState() => _RotateSecretDialogState();
}

class _RotateSecretDialogState extends ConsumerState<RotateSecretDialog> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final newSecret = await ref
          .read(adminDevicesProvider.notifier)
          .rotateSecret(
            deviceId: widget.deviceId,
            newSecret:
                _secretController.text.trim().isNotEmpty
                    ? _secretController.text.trim()
                    : null,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      _showRotatedSecretModal(context, newSecret, widget.deviceId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static void _showRotatedSecretModal(
    BuildContext context,
    String secret,
    String deviceId,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.adaptiveSurface(ctx),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TrackletColors.success.withValues(alpha: 0.15),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: const Icon(
                    TrackletIcons.key,
                    color: TrackletColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                const Expanded(
                  child: Text(
                    'Secret Rotated',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New credentials for device $deviceId have been generated.',
                  style: TextStyle(
                    color: TrackletColors.adaptiveTextPrimary(ctx),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TrackletColors.warning.withValues(alpha: 0.12),
                    borderRadius: TrackletRadii.roundedSm,
                    border: Border.all(
                      color: TrackletColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        TrackletIcons.warning,
                        color: TrackletColors.warning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IMPORTANT: Copy this secret now. The previous secret has been invalidated.',
                          style: TextStyle(
                            color: TrackletColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.md),
                const Text(
                  'NEW DEVICE SECRET:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(ctx).brightness == Brightness.dark
                            ? TrackletColors.darkSurfaceContainer
                            : TrackletColors.surfaceElevated,
                    borderRadius: TrackletRadii.roundedSm,
                    border: Border.all(
                      color: TrackletColors.adaptiveDivider(ctx),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          secret,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(TrackletIcons.copy, size: 18),
                        tooltip: 'Copy new secret',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: secret));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('New secret copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TrackletButton(
                label: 'Done',
                onPressed: () => Navigator.of(ctx).pop(),
                size: TrackletButtonSize.medium,
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedLg,
      ),
      backgroundColor: TrackletColors.adaptiveSurface(context),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TrackletColors.warning.withValues(alpha: 0.15),
              borderRadius: TrackletRadii.roundedSm,
            ),
            child: const Icon(
              TrackletIcons.refresh,
              color: TrackletColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: TrackletSpacing.md),
          Expanded(
            child: Text(
              'Rotate Secret: ${widget.deviceId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rotating credentials invalidates existing tracker tokens. '
                'The hardware device will need to be configured with the new secret.',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TrackletColors.error.withValues(alpha: 0.12),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        TrackletIcons.error,
                        color: TrackletColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: TrackletColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.md),
              ],
              TextFormField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'New Secret (Optional)',
                  hintText: 'Leave empty to auto-generate',
                  helperText: 'Must be >= 16 characters if specified',
                  prefixIcon: Icon(TrackletIcons.key, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                ),
                validator: (val) {
                  if (val != null &&
                      val.trim().isNotEmpty &&
                      val.trim().length < 16) {
                    return 'Secret must be at least 16 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TrackletButton(
          label: _isSubmitting ? 'Rotating...' : 'Rotate Secret',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          variant: TrackletButtonVariant.primary,
          size: TrackletButtonSize.medium,
        ),
      ],
    );
  }
}
