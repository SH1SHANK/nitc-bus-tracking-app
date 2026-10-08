import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';

/// Authentic Attendrix-style Campus Transit Card (`BusTimeCardWidget`).
/// Shows Next Bus, Walk Time pill, Nearest Stop pill, Available Buses list,
/// and recommendation footer.
class NextBusCard extends StatelessWidget {
  const NextBusCard({
    super.key,
    required this.selectedStop,
    required this.nextBus,
    required this.route,
    required this.etaMinutes,
    this.onTrackPressed,
  });

  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? route;
  final int etaMinutes;
  final VoidCallback? onTrackPressed;

  @override
  Widget build(BuildContext context) {
    if (nextBus != null) {
      final routeName = route?.name ?? nextBus!.name;
      final walkTime = selectedStop.walkingTimeMinutes;

      return Container(
        decoration: BoxDecoration(
          color: TrackletColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: TrackletColors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Next Bus Header + Walk Time & Nearest Stop Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Bus',
                        style: TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$routeName (${nextBus!.name})',
                        style: const TextStyle(
                          color: TrackletColors.primary,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                // Chips Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Walk Time Chip
                    Container(
                      height: 28.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: TrackletColors.background,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: TrackletColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Walk Time',
                            style: TextStyle(
                              color: TrackletColors.tertiary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '$walkTime',
                            style: const TextStyle(
                              color: TrackletColors.textPrimary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          const Text(
                            'mins',
                            style: TextStyle(
                              color: TrackletColors.textSecondary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),

                    // Nearest Stop Chip
                    Container(
                      height: 28.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: TrackletColors.background,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: TrackletColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TrackletIcon(
                            TrackletIcons.location,
                            color: TrackletColors.primary,
                            size: 14.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            selectedStop.name,
                            style: const TextStyle(
                              color: TrackletColors.textPrimary,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Available Buses Section Header
            const Text(
              'Available Departures',
              style: TextStyle(
                color: TrackletColors.textSecondary,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6.0),

            // Mini Departure Item Container (Attendrix style)
            Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: TrackletColors.background,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: TrackletColors.border, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${selectedStop.name} → East Campus Terminal',
                      style: const TextStyle(
                        color: TrackletColors.textPrimary,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Arrival Countdown Pill
                  Container(
                    height: 26.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: TrackletColors.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: TrackletColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'in ',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$etaMinutes',
                          style: const TextStyle(
                            color: TrackletColors.primary,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          ' mins',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),

            // Footer Subtitle with "Tap to learn more."
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 9.0,
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Based on official NITC Bus timings. ',
                      ),
                      TextSpan(
                        text: 'Tap to learn more.',
                        style: const TextStyle(
                          color: TrackletColors.tertiary,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.0,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onTrackPressed,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'updated live',
                  style: TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Empty state when no more buses
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: TrackletColors.background,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: TrackletColors.border, width: 2.0),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrackletIcon(
              TrackletIcons.bus,
              color: TrackletColors.textSecondary,
              size: 40.0,
            ),
            SizedBox(height: 8.0),
            Text(
              'No More Scheduled Buses Today',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TrackletColors.textPrimary,
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              'Campus shuttle service resumes tomorrow morning at 08:00 AM.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TrackletColors.textSecondary,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    }
  }
}
