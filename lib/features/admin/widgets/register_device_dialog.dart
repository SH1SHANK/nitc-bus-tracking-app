import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../providers/admin_provider.dart';

/// Modal dialog to register a new bus tracking device.
class RegisterDeviceDialog extends ConsumerStatefulWidget {
  const RegisterDeviceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RegisterDeviceDialog(),
    );
  }

  @override
  ConsumerState<RegisterDeviceDialog> createState() =>
      _RegisterDeviceDialogState();
}

class _RegisterDeviceDialogState extends ConsumerState<RegisterDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _secretController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _busNumberController.dispose();
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
      final res = await ref
          .read(adminDevicesProvider.notifier)
          .registerDevice(
            deviceId: _deviceIdController.text.trim(),
            busNumber: _busNumberController.text.trim(),
            secret:
                _secretController.text.trim().isNotEmpty
                    ? _secretController.text.trim()
                    : null,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      // Show one-time revealed secret dialog
      _showOneTimeSecretModal(
        context,
        res.generatedSecret,
        res.device.deviceId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static void _showOneTimeSecretModal(
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
                    'Tracker Provisioned',
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
                  'Device $deviceId has been provisioned successfully.',
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
                          'IMPORTANT: Copy this secret now. It is hashed with Bcrypt and will never be shown again.',
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
                  'DEVICE SECRET:',
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
                        tooltip: 'Copy secret',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: secret));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Device secret copied to clipboard!',
                              ),
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
                label: 'I Have Saved This Secret',
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
              color: TrackletColors.primary.withValues(alpha: 0.15),
              borderRadius: TrackletRadii.roundedSm,
            ),
            child: const Icon(
              TrackletIcons.plus,
              color: TrackletColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TrackletSpacing.md),
          const Expanded(
            child: Text(
              'Register New Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Hardware Device ID *',
                  hintText: 'e.g. NITC-BUS-001',
                  prefixIcon: Icon(TrackletIcons.smartphone, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Device ID is required';
                  }
                  if (val.trim().length < 3) {
                    return 'Device ID must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TrackletSpacing.md),
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Bus Number *',
                  hintText: 'e.g. Bus 1 or NITC-B01',
                  prefixIcon: Icon(TrackletIcons.bus, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Bus number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TrackletSpacing.md),
              TextFormField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'Tracker Secret (Optional)',
                  hintText: 'Leave empty to auto-generate (recommended)',
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
          label: _isSubmitting ? 'Provisioning...' : 'Provision Tracker',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          size: TrackletButtonSize.medium,
        ),
      ],
    );
  }
}
