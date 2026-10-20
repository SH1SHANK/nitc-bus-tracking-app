import 'package:tracklet/design_system/tokens/typography.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/admin/admin_models.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Interactive time-series graph displaying 24-hour telemetry packet ingestion throughput.
class TelemetryThroughputChart extends StatelessWidget {
  const TelemetryThroughputChart({
    super.key,
    required this.buckets,
    required this.totalPackets24h,
    required this.totalPacketsAllTime,
  });

  final List<HourlyPacketBucket> buckets;
  final int totalPackets24h;
  final int totalPacketsAllTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount =
        buckets.isEmpty
            ? 1
            : buckets.map((b) => b.count).reduce(math.max).clamp(1, 100000);

    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TrackletSpacing.iconBadgeInset),
                decoration: BoxDecoration(
                  color: TrackletColors.primary.withValues(alpha: 0.12),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: const Icon(
                  TrackletIcons.activity,
                  color: TrackletColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: TrackletSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telemetry Ingestion Throughput',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: TrackletTypography.fontSize15,
                      ),
                    ),
                    Text(
                      'Hourly packet throughput (Past 24 Hours)',
                      style: TextStyle(
                        fontSize: TrackletTypography.fontSize11_5,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.sm,
                  vertical: TrackletSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TrackletColors.primary.withValues(alpha: 0.1),
                  borderRadius: TrackletRadii.roundedSm,
                  border: Border.all(
                    color: TrackletColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$totalPackets24h pkts / 24h',
                  style: const TextStyle(
                    fontSize: TrackletTypography.fontSize11,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          if (buckets.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Text(
                'No telemetry packets recorded in the last 24 hours.',
                style: TextStyle(
                  fontSize: TrackletTypography.fontSize12,
                  color: TrackletColors.adaptiveTextMuted(context),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: CustomPaint(
                size: Size.infinite,
                painter: _ThroughputChartPainter(
                  buckets: buckets,
                  maxCount: maxCount,
                  lineColor: TrackletColors.primary,
                  gridColor:
                      isDark
                          ? TrackletColors.textInverse.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                  textColor: TrackletColors.adaptiveTextMuted(context),
                ),
              ),
            ),
            const SizedBox(height: TrackletSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatHour(buckets.first.timestamp),
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize10,
                    fontFamily: 'monospace',
                    color: TrackletColors.adaptiveTextMuted(context),
                  ),
                ),
                Text(
                  'Peak: $maxCount pkts/hr',
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize10,
                    fontWeight: TrackletTypography.weightSemiBold,
                    color: TrackletColors.adaptiveTextSecondary(context),
                  ),
                ),
                Text(
                  _formatHour(buckets.last.timestamp),
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize10,
                    fontFamily: 'monospace',
                    color: TrackletColors.adaptiveTextMuted(context),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricPill(
                context,
                label: 'All-Time Total',
                value: '$totalPacketsAllTime',
              ),
              _metricPill(
                context,
                label: '24h Packets',
                value: '$totalPackets24h',
              ),
              _metricPill(context, label: 'Hourly Peak', value: '$maxCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: TrackletTypography.fontSize10_5,
            color: TrackletColors.adaptiveTextMuted(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: TrackletTypography.fontSize13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  String _formatHour(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ThroughputChartPainter extends CustomPainter {
  _ThroughputChartPainter({
    required this.buckets,
    required this.maxCount,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<HourlyPacketBucket> buckets;
  final int maxCount;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    final gridPaint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    final dx = buckets.length > 1 ? size.width / (buckets.length - 1) : 0.0;

    for (int i = 0; i < buckets.length; i++) {
      final normalizedY = (buckets[i].count / maxCount).clamp(0.0, 1.0);
      final y = size.height - (normalizedY * (size.height - 12)) - 6;
      final x = dx * i;
      points.add(Offset(x, y));
    }

    // Draw filled gradient area
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.35),
              lineColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw curve line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.5;

    canvas.drawPath(linePath, linePaint);

    // Draw marker dots
    final dotPaint = Paint()..color = lineColor;
    final dotInnerPaint = Paint()..color = TrackletColors.textInverse;

    for (int i = 0; i < points.length; i++) {
      if (buckets.length > 12 && i % 2 != 0) continue;
      canvas.drawCircle(points[i], 3.5, dotPaint);
      canvas.drawCircle(points[i], 1.8, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThroughputChartPainter oldDelegate) {
    return oldDelegate.buckets != buckets ||
        oldDelegate.maxCount != maxCount ||
        oldDelegate.lineColor != lineColor;
  }
}
