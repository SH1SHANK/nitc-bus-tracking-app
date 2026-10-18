import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Donut chart showing fleet tracker status distribution (Online, Stale, Offline).
class FleetStatusDonutChart extends StatelessWidget {
  const FleetStatusDonutChart({
    super.key,
    required this.onlineCount,
    required this.staleCount,
    required this.offlineCount,
    required this.totalDevices,
  });

  final int onlineCount;
  final int staleCount;
  final int offlineCount;
  final int totalDevices;

  @override
  Widget build(BuildContext context) {
    final total =
        totalDevices > 0
            ? totalDevices
            : (onlineCount + staleCount + offlineCount);
    final activePct = total > 0 ? ((onlineCount / total) * 100).round() : 0;

    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: TrackletColors.success.withValues(alpha: 0.12),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: const Icon(
                  TrackletIcons.activity,
                  color: TrackletColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: TrackletSpacing.sm),
              const Expanded(
                child: Text(
                  'Fleet Tracker Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (activePct > 50
                          ? TrackletColors.success
                          : TrackletColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: TrackletRadii.roundedSm,
                  border: Border.all(
                    color: (activePct > 50
                            ? TrackletColors.success
                            : TrackletColors.warning)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$activePct% Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        activePct > 50
                            ? TrackletColors.success
                            : TrackletColors.warning,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          Row(
            children: [
              // Donut Chart Canvas
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    onlineCount: onlineCount,
                    staleCount: staleCount,
                    offlineCount: offlineCount,
                    total: total,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Units',
                          style: TextStyle(
                            fontSize: 10,
                            color: TrackletColors.adaptiveTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TrackletSpacing.lg),
              // Legends
              Expanded(
                child: Column(
                  children: [
                    _legendItem(
                      context,
                      label: 'Online (Live)',
                      count: onlineCount,
                      color: TrackletColors.success,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _legendItem(
                      context,
                      label: 'Stale (Inactive)',
                      count: staleCount,
                      color: TrackletColors.warning,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _legendItem(
                      context,
                      label: 'Offline (No Fix)',
                      count: offlineCount,
                      color: TrackletColors.error,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required int total,
  }) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.onlineCount,
    required this.staleCount,
    required this.offlineCount,
    required this.total,
  });

  final int onlineCount;
  final int staleCount;
  final int offlineCount;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    final basePaint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    if (total == 0) return;

    double startAngle = -math.pi / 2;

    void drawSegment(int count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * math.pi;
      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05,
        (sweepAngle - 0.1).clamp(0.02, 2 * math.pi),
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(onlineCount, TrackletColors.success);
    drawSegment(staleCount, TrackletColors.warning);
    drawSegment(offlineCount, TrackletColors.error);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.onlineCount != onlineCount ||
        oldDelegate.staleCount != staleCount ||
        oldDelegate.offlineCount != offlineCount ||
        oldDelegate.total != total;
  }
}
