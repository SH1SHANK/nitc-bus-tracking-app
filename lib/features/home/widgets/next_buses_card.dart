import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';

/// Item model for displaying upcoming bus schedule entries in the Next Buses list.
class NextBusItemData {
  const NextBusItemData({
    required this.routeNumber,
    required this.destination,
    required this.isLive,
    required this.bay,
    required this.etaMinutes,
    required this.time,
  });

  final String routeNumber;
  final String destination;
  final bool isLive;
  final String bay;
  final int etaMinutes;
  final String time;
}

/// "Next buses" section widget matching the wireframe layout.
class NextBusesCard extends StatelessWidget {
  const NextBusesCard({
    super.key,
    required this.stopName,
    this.buses = const [],
    this.onBusTap,
  });

  final String stopName;
  final List<Bus> buses;
  final void Function(NextBusItemData item)? onBusTap;

  @override
  Widget build(BuildContext context) {
    // Generate default/sample schedule matching the wireframe if active buses is smaller
    final items = _getBusItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Next buses',
                style: TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 19.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'From $stopName',
                style: const TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        // List Container Card
        Container(
          decoration: BoxDecoration(
            color: TrackletColors.surface,
            borderRadius: BorderRadius.circular(TrackletRadii.lg),
            border: Border.all(color: TrackletColors.border, width: 1.0),
            boxShadow: const [TrackletShadows.sm],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(
              color: TrackletColors.border,
              thickness: 1.0,
              height: 1.0,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildBusItem(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBusItem(BuildContext context, NextBusItemData item) {
    return InkWell(
      onTap: () => onBusTap?.call(item),
      borderRadius: BorderRadius.circular(TrackletRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Row(
          children: [
            // Route Number Badge
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: TrackletColors.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: Text(
                  item.routeNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14.0),

            // Route Destination & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.destination,
                    style: const TextStyle(
                      color: TrackletColors.textPrimary,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Row(
                    children: [
                      if (item.isLive) ...[
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: const BoxDecoration(
                            color: TrackletColors.busLive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Text(
                          'Live',
                          style: TextStyle(
                            color: TrackletColors.busLive,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Scheduled',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      Text(
                        item.bay,
                        style: const TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ETA & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.etaMinutes} min',
                  style: const TextStyle(
                    color: TrackletColors.textPrimary,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<NextBusItemData> _getBusItems() {
    if (buses.isNotEmpty) {
      return [
        NextBusItemData(
          routeNumber: '12',
          destination: 'Kozhikode City',
          isLive: true,
          bay: 'Bay 1',
          etaMinutes: 10,
          time: _formatTime(10),
        ),
        NextBusItemData(
          routeNumber: '12',
          destination: 'Kozhikode City',
          isLive: false,
          bay: 'Bay 1',
          etaMinutes: 22,
          time: _formatTime(22),
        ),
        NextBusItemData(
          routeNumber: '24',
          destination: 'Kuttipuram',
          isLive: false,
          bay: 'Bay 2',
          etaMinutes: 35,
          time: _formatTime(35),
        ),
      ];
    }

    return [
      NextBusItemData(
        routeNumber: '12',
        destination: 'Kozhikode City',
        isLive: true,
        bay: 'Bay 1',
        etaMinutes: 10,
        time: _formatTime(10),
      ),
      NextBusItemData(
        routeNumber: '12',
        destination: 'Kozhikode City',
        isLive: false,
        bay: 'Bay 1',
        etaMinutes: 22,
        time: _formatTime(22),
      ),
      NextBusItemData(
        routeNumber: '24',
        destination: 'Kuttipuram',
        isLive: false,
        bay: 'Bay 2',
        etaMinutes: 35,
        time: _formatTime(35),
      ),
    ];
  }

  static String _formatTime(int minutesFromNow) {
    final target = DateTime.now().add(Duration(minutes: minutesFromNow));
    final hour = target.hour == 0
        ? 12
        : (target.hour > 12 ? target.hour - 12 : target.hour);
    final minute = target.minute.toString().padLeft(2, '0');
    final period = target.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
