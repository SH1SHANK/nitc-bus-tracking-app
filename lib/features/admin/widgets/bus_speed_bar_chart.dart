import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/admin/admin_models.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Horizontal bar spectrum visualizing fleet bus speeds and operational status.
class BusSpeedBarChart extends StatelessWidget {
  const BusSpeedBarChart({super.key, required this.speedMetrics});

  final List<BusSpeedMetric> speedMetrics;

  @override
  Widget build(BuildContext context) {
    final maxSpeed =
        speedMetrics.isEmpty
            ? 40.0
            : speedMetrics
                .map((s) => s.speed)
                .reduce(math.max)
                .clamp(30.0, 80.0);

    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: const Icon(
                  TrackletIcons.speed,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: TrackletSpacing.sm),
              const Expanded(
                child: Text(
                  'Fleet Velocity Spectrum',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                'Max: ${maxSpeed.toStringAsFixed(0)} km/h',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: TrackletColors.adaptiveTextMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          if (speedMetrics.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'No bus telemetry records available.',
                style: TextStyle(
                  fontSize: 12,
                  color: TrackletColors.adaptiveTextMuted(context),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: speedMetrics.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final metric = speedMetrics[index];
                final factor = (metric.speed / maxSpeed).clamp(0.02, 1.0);
                final color =
                    metric.speed > 15
                        ? TrackletColors.primary
                        : (metric.speed > 0 ? Colors.amber : Colors.grey);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          metric.busNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          metric.deviceId,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: TrackletColors.adaptiveTextMuted(context),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${metric.speed.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: TrackletRadii.roundedFull,
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                          FractionallySizedBox(
                            widthFactor: factor,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: TrackletRadii.roundedFull,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
