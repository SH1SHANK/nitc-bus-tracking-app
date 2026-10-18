import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_snack_bar.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../providers/admin_provider.dart';

/// Interactive hardware simulation & gateway control workbench card.
/// Allows administrators to execute connection probes, cold boot negotiations,
/// and live telemetry packet injections using the verified hardware credentials.
class HardwareWorkbenchCard extends ConsumerStatefulWidget {
  const HardwareWorkbenchCard({super.key});

  @override
  ConsumerState<HardwareWorkbenchCard> createState() =>
      _HardwareWorkbenchCardState();
}

class _HardwareWorkbenchCardState extends ConsumerState<HardwareWorkbenchCard> {
  // Canonical NITC Route R1 Waypoints (from Flutter Android App Simulator)
  static const List<List<double>> _r1Waypoints = [
    [11.317139, 75.937622], // East Campus Terminal
    [11.317949, 75.937769],
    [11.318822, 75.936663],
    [11.318518, 75.936197],
    [11.318776, 75.934940],
    [11.320400, 75.934506], // Main Gate
    [11.321574, 75.934949],
    [11.322844, 75.936270],
    [11.323345, 75.937166], // Mega Boys Hostel
  ];

  int _waypointIndex = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hardwareWorkbenchProvider);
    final notifier = ref.read(hardwareWorkbenchProvider.notifier);

    final currentPoint = _r1Waypoints[_waypointIndex % _r1Waypoints.length];

    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: const Icon(
                  TrackletIcons.smartphone,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: TrackletSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Hardware & Telemetry Workbench',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      'Fastify API Gateway · Device ${AppConfig.defaultSimulatorDeviceId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded
                      ? TrackletIcons.chevronDown
                      : TrackletIcons.chevronRight,
                  size: 18,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TrackletColors.adaptiveSurfaceElevated(context),
              borderRadius: TrackletRadii.roundedSm,
              border: Border.all(
                color: TrackletColors.adaptiveDivider(context),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  TrackletIcons.checkCircle,
                  color: TrackletColors.success,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target: ${AppConfig.backendUrl}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.15),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: const Text(
                    'BUS-SIM-001',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: TrackletColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),
          // Workbench Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TrackletButton(
                label:
                    state.isLoading && state.lastAction == 'Health Probe'
                        ? 'Probing...'
                        : 'Probe Gateway',
                variant: TrackletButtonVariant.secondary,
                icon: const Icon(TrackletIcons.activity, size: 14),
                onPressed:
                    state.isLoading
                        ? null
                        : () async {
                          try {
                            final res = await notifier.probeHealth();
                            if (!context.mounted) return;
                            final ms = res['latency_ms'] ?? 0;
                            TrackletSnackBar.showSuccess(
                              context,
                              'Gateway Healthy · Ping ${ms}ms · Status: ${res['code'] ?? '200 OK'}',
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            TrackletSnackBar.showError(
                              context,
                              'Gateway Probe Failed: $e',
                            );
                          }
                        },
              ),
              TrackletButton(
                label:
                    state.isLoading &&
                            state.lastAction == 'Inject Telemetry Fix'
                        ? 'Injecting...'
                        : 'Inject Live GNSS Fix',
                variant: TrackletButtonVariant.primary,
                icon: const Icon(TrackletIcons.speed, size: 14),
                onPressed:
                    state.isLoading
                        ? null
                        : () async {
                          try {
                            final res = await notifier.injectLiveWaypoint(
                              lat: currentPoint[0],
                              lon: currentPoint[1],
                              speed: 22.0,
                              heading: 90.0,
                            );
                            if (!context.mounted) return;
                            final ok = res['ok'] == true;
                            final seq = res['seq'] ?? 0;
                            final epoch = res['epoch'] ?? 1;
                            final ms = res['latency_ms'] ?? 0;

                            if (ok) {
                              setState(() => _waypointIndex++);
                              TrackletSnackBar.showSuccess(
                                context,
                                'Fix Ingested! Epoch $epoch • Seq #$seq • ${ms}ms latency',
                              );
                            } else {
                              TrackletSnackBar.showWarning(
                                context,
                                'Ingestion Result: ${res['code'] ?? 'REJECTED'} (${res['message'] ?? ''})',
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            TrackletSnackBar.showError(
                              context,
                              'Telemetry Injection Error: $e',
                            );
                          }
                        },
              ),
            ],
          ),
          if (_isExpanded || state.lastResult != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Text(
                  'LATEST TELEMETRY WORKBENCH PACKET',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (state.lastSuccessTimestamp != null)
                  Text(
                    '${state.lastSuccessTimestamp!.hour.toString().padLeft(2, '0')}:${state.lastSuccessTimestamp!.minute.toString().padLeft(2, '0')}:${state.lastSuccessTimestamp!.second.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: TrackletColors.adaptiveTextMuted(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: TrackletRadii.roundedSm,
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                state.lastResult != null
                    ? state.lastResult.toString()
                    : 'Waypoints Ready (Next: ${currentPoint[0].toStringAsFixed(6)}, ${currentPoint[1].toStringAsFixed(6)})\n'
                        'Device: ${AppConfig.defaultSimulatorDeviceId} • Secret: ***MASKED***',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
