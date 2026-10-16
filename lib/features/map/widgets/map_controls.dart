import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Compact, accessible camera actions for the map.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onRecenterCampus,
    this.onRecenterBus,
    this.onFitRoute,
    this.onRecenterUser,
  });

  final VoidCallback onRecenterCampus;
  final VoidCallback? onRecenterBus;
  final VoidCallback? onFitRoute;
  final VoidCallback? onRecenterUser;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 3,
      shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.12),
      borderRadius: TrackletRadii.roundedMd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedMd,
          border: Border.all(color: TrackletColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRecenterUser != null) ...[
              _ControlButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Recenter on your location',
                onPressed: onRecenterUser!,
              ),
              const Divider(
                height: 1,
                indent: 8,
                endIndent: 8,
                color: TrackletColors.border,
              ),
            ],
            if (onRecenterBus != null) ...[
              _ControlButton(
                icon: Icons.directions_bus_filled_rounded,
                tooltip: 'Recenter on selected bus',
                onPressed: onRecenterBus!,
              ),
              const Divider(
                height: 1,
                indent: 8,
                endIndent: 8,
                color: TrackletColors.border,
              ),
            ],
            if (onFitRoute != null) ...[
              _ControlButton(
                icon: Icons.route_rounded,
                tooltip: 'Show all stops on this route',
                onPressed: onFitRoute!,
              ),
              const Divider(
                height: 1,
                indent: 8,
                endIndent: 8,
                color: TrackletColors.border,
              ),
            ],
            _ControlButton(
              icon: Icons.explore_outlined,
              tooltip: 'Recenter on NIT Calicut campus',
              onPressed: onRecenterCampus,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 21),
      color: TrackletColors.textPrimary,
      constraints: const BoxConstraints(
        minWidth: TrackletSpacing.minTouchTarget,
        minHeight: TrackletSpacing.minTouchTarget,
      ),
      padding: const EdgeInsets.all(TrackletSpacing.sm),
      visualDensity: VisualDensity.standard,
    );
  }
}
