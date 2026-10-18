import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../providers/admin_provider.dart';

/// Modal dialog to test connection and session negotiation for a tracking device.
class TestPingDialog extends ConsumerStatefulWidget {
  const TestPingDialog({super.key, required this.deviceId});

  final String deviceId;

  static Future<void> show(BuildContext context, String deviceId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => TestPingDialog(deviceId: deviceId),
    );
  }

  @override
  ConsumerState<TestPingDialog> createState() => _TestPingDialogState();
}

class _TestPingDialogState extends ConsumerState<TestPingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _secretController;

  bool _obscureSecret = true;
  bool _isPinging = false;
  Map<String, dynamic>? _pingResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final isSimulator =
        widget.deviceId == AppConfig.defaultSimulatorDeviceId ||
        widget.deviceId.toUpperCase().contains('SIM');
    _secretController = TextEditingController(
      text: isSimulator ? AppConfig.defaultSimulatorSecret : '',
    );
  }

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _handlePing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPinging = true;
      _errorMessage = null;
      _pingResult = null;
    });

    try {
      final res = await ref
          .read(adminDevicesProvider.notifier)
          .testPingDevice(
            deviceId: widget.deviceId,
            secret: _secretController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _isPinging = false;
        _pingResult = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPinging = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSimulator =
        widget.deviceId == AppConfig.defaultSimulatorDeviceId ||
        widget.deviceId.toUpperCase().contains('SIM');

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
              color: TrackletColors.primary.withValues(alpha: 0.12),
              borderRadius: TrackletRadii.roundedSm,
            ),
            child: const Icon(
              TrackletIcons.activity,
              color: TrackletColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TrackletSpacing.md),
          const Expanded(
            child: Text(
              'Test Device Gateway',
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
              Text(
                'Execute live reboot-session handshake for tracker ${widget.deviceId} against the telemetry ingest gateway.',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              if (isSimulator)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: TrackletSpacing.md),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.08),
                    borderRadius: TrackletRadii.roundedSm,
                    border: Border.all(
                      color: TrackletColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        TrackletIcons.checkCircle,
                        size: 16,
                        color: TrackletColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pre-filled with verified hardware test credentials from simulator workbench.',
                          style: TextStyle(
                            fontSize: 12,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _secretController,
                obscureText: _obscureSecret,
                decoration: InputDecoration(
                  labelText: 'Hardware Secret (min 16 chars)',
                  hintText: 'Enter tracker secret key...',
                  border: const OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  prefixIcon: const Icon(TrackletIcons.key, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSecret ? TrackletIcons.eye : TrackletIcons.eyeOff,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSecret = !_obscureSecret;
                      });
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Secret is required';
                  }
                  if (val.trim().length < 16) {
                    return 'Must be at least 16 characters';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: TrackletSpacing.md),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TrackletColors.error.withValues(alpha: 0.1),
                    borderRadius: TrackletRadii.roundedSm,
                    border: Border.all(
                      color: TrackletColors.error.withValues(alpha: 0.3),
                    ),
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
              ],
              if (_pingResult != null) ...[
                const SizedBox(height: TrackletSpacing.md),
                _buildResultCard(context, _pingResult!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPinging ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TrackletButton(
          label: _isPinging ? 'Pinging Gateway...' : 'Probe Gateway',
          icon:
              _isPinging
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(TrackletIcons.activity, size: 16),
          onPressed: _isPinging ? null : _handlePing,
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> result) {
    final ok = result['ok'] == true || result['epoch'] != null;
    final latency = result['latency_ms'] as int? ?? 0;
    final epoch = result['epoch'];
    final idempotent = result['idempotent_retry'] == true;
    final httpStatus = result['http_status'];

    final latencyColor =
        latency < 150
            ? TrackletColors.success
            : latency < 350
            ? TrackletColors.warning
            : TrackletColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            ok
                ? TrackletColors.success.withValues(alpha: 0.08)
                : TrackletColors.error.withValues(alpha: 0.08),
        borderRadius: TrackletRadii.roundedMd,
        border: Border.all(
          color:
              ok
                  ? TrackletColors.success.withValues(alpha: 0.3)
                  : TrackletColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? TrackletIcons.checkCircle : TrackletIcons.error,
                color: ok ? TrackletColors.success : TrackletColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                      ? 'Gateway Handshake Succeeded'
                      : 'Gateway Handshake Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ok ? TrackletColors.success : TrackletColors.error,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: latencyColor.withValues(alpha: 0.15),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: Text(
                  '$latency ms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: latencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (epoch != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Negotiated Epoch: $epoch ${idempotent ? '(Idempotent Retry)' : '(Fresh Epoch)'}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          if (httpStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'HTTP Status: $httpStatus',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          if (result['message'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                result['message'].toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
