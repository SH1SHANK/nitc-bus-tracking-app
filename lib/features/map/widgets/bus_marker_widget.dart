import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/shadows.dart';

/// Bus marker displayed on the campus map with live status indicator.
class BusMarkerWidget extends StatelessWidget {
  const BusMarkerWidget({
    super.key,
    required this.bus,
    this.isSelected = false,
    this.onTap,
  });

  final Bus bus;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bus.status) {
      BusStatus.live => TrackletColors.busLive,
      BusStatus.delayed => TrackletColors.busDelayed,
      BusStatus.due => TrackletColors.busDue,
      BusStatus.offline => TrackletColors.busOffline,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 48.0 : 40.0,
        height: isSelected ? 48.0 : 40.0,
        decoration: BoxDecoration(
          color: TrackletColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? TrackletColors.primary : statusColor,
            width: isSelected ? 3.0 : 2.0,
          ),
          boxShadow: const [TrackletShadows.sm],
        ),
        child: Center(
          child: TrackletIcon(
            TrackletIcons.bus,
            size: isSelected ? 24 : 20,
            color: isSelected ? TrackletColors.primary : statusColor,
          ),
        ),
      ),
    );
  }
}
