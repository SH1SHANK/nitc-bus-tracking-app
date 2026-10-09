import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';

/// A focused snapshot of the nearest campus bus and the stop it serves.
class AtAGlanceTransitCard extends StatelessWidget {
  const AtAGlanceTransitCard({
    super.key,
    required this.selectedStop,
    required this.nextBus,
    required this.route,
    this.onTap,
  });

  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bus = nextBus;
    final isLive = bus?.isLive ?? false;
    final statusColor = switch (bus?.status) {
      BusStatus.live => TrackletColors.busLive,
      BusStatus.delayed => TrackletColors.busDelayed,
      BusStatus.due => TrackletColors.busDue,
      _ => TrackletColors.busOffline,
    };
    final statusBackground = switch (bus?.status) {
      BusStatus.live => TrackletColors.busLiveBg,
      BusStatus.delayed => TrackletColors.busDelayedBg,
      BusStatus.due => TrackletColors.busDueBg,
      _ => TrackletColors.busOfflineBg,
    };

    return Material(
      color: TrackletColors.surface,
      borderRadius: BorderRadius.circular(TrackletRadii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TrackletRadii.xl),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TrackletRadii.xl),
            boxShadow: const [TrackletShadows.md],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: TrackletColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedStop.name,
                      style: const TextStyle(
                        color: TrackletColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'Boarding stop',
                    style: TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (bus == null)
                _EmptyBusState(onTap: onTap)
              else ...[
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TrackletColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route?.name ?? bus.name,
                            style: const TextStyle(
                              color: TrackletColors.textPrimary,
                              fontSize: 18,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus.numberPlate,
                            style: const TextStyle(
                              color: TrackletColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bus.status.displayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: TrackletColors.border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      isLive
                          ? Icons.my_location_rounded
                          : Icons.info_outline_rounded,
                      color: isLive
                          ? TrackletColors.busLive
                          : TrackletColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        isLive
                            ? 'Live location is available'
                            : 'Live location is not available',
                        style: const TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: TrackletColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBusState extends StatelessWidget {
  const _EmptyBusState({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No buses to show right now',
          style: TextStyle(
            color: TrackletColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Check the campus map for the latest bus activity.',
          style: TextStyle(
            color: TrackletColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Open campus map'),
          style: TextButton.styleFrom(
            foregroundColor: TrackletColors.primary,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
