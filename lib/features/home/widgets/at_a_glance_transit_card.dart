import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';

/// Hero "At a Glance" Transit Card representing the live bus tracker
/// exactly as designed in the Tracklet wireframe.
class AtAGlanceTransitCard extends StatelessWidget {
  const AtAGlanceTransitCard({
    super.key,
    required this.selectedStop,
    required this.nextBus,
    required this.route,
    required this.etaMinutes,
    this.onTap,
  });

  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? route;
  final int etaMinutes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final walkTime = selectedStop.walkingTimeMinutes;
    final destination = route?.name ?? nextBus?.name ?? 'Kozhikode City';
    final routeCode = route?.code.replaceAll(RegExp(r'[^0-9]'), '') ?? '12';
    final isLive = nextBus?.isLive ?? true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TrackletRadii.lg),
      child: Container(
        decoration: BoxDecoration(
          color: TrackletColors.surface,
          borderRadius: BorderRadius.circular(TrackletRadii.lg),
          border: Border.all(color: TrackletColors.border, width: 1.0),
          boxShadow: const [TrackletShadows.sm],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Stop Selector Pill & Updated Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stop Capsule Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.primaryBackground,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: TrackletColors.primary,
                        size: 15.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        selectedStop.name,
                        style: const TextStyle(
                          color: TrackletColors.textPrimary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.directions_walk_rounded,
                        color: TrackletColors.textSecondary,
                        size: 14.0,
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        '$walkTime min walk',
                        style: const TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Updated just now',
                  style: TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // Row 2: Route Badge, Destination, Live Pill, ETA
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Route Number Badge
                Container(
                  width: 46.0,
                  height: 46.0,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Text(
                      routeCode.isEmpty ? '12' : routeCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Destination & Live Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(
                          color: TrackletColors.textPrimary,
                          fontSize: 17.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isLive
                              ? TrackletColors.busLiveBg
                              : TrackletColors.primaryBackground,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: isLive
                                    ? TrackletColors.busLive
                                    : TrackletColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              isLive ? 'Live · On time' : 'Scheduled',
                              style: TextStyle(
                                color: isLive
                                    ? TrackletColors.busLive
                                    : TrackletColors.textSecondary,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ETA & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$etaMinutes',
                          style: const TextStyle(
                            color: TrackletColors.primary,
                            fontSize: 26.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          ' min',
                          style: TextStyle(
                            color: TrackletColors.textPrimary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatScheduledTime(etaMinutes),
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            const Divider(
              color: TrackletColors.border,
              thickness: 1.0,
              height: 1.0,
            ),
            const SizedBox(height: 12.0),

            // Row 3: Route Tracker Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ROUTE TRACKER',
                  style: TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: TrackletColors.primary,
                        size: 6.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        '1 stop away',
                        style: TextStyle(
                          color: TrackletColors.primary,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Visual Stop Timeline
            _buildTimeline(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: [
        // Track Line with Multi-Node Indicators
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track line (grey/active split)
              Positioned(
                left: 24,
                right: 24,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: TrackletColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: TrackletColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nodes & Icons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stop 1: Hostel Circle
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: TrackletColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // In-transit Bus Icon Badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: TrackletColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x330066FF),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: TrackletIcon(
                        TrackletIcons.bus,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),

                  // Stop 2: Main Gate (Boarding Target Node)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TrackletColors.primary,
                        width: 3.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: TrackletColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Stop 3: Medical College
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: TrackletColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Node Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Hostel Circle',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(
              width: 60,
              child: Text(
                'On route',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TrackletColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  selectedStop.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TrackletColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Board here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TrackletColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 70,
              child: Text(
                'Medical Col.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatScheduledTime(int eta) {
    final now = DateTime.now().add(Duration(minutes: eta));
    final hour = now.hour == 0
        ? 12
        : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
