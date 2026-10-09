import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Floating control buttons on the map for campus recenter and route bounds fitting.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onRecenterCampus,
    this.onFitRoute,
  });

  final VoidCallback onRecenterCampus;
  final VoidCallback? onFitRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onFitRoute != null) ...[
          _ControlButton(
            icon: TrackletIcons.route,
            tooltip: 'Fit Selected Route Stops',
            onPressed: onFitRoute!,
          ),
          const SizedBox(height: TrackletSpacing.sm),
        ],
        _ControlButton(
          icon: TrackletIcons.compass,
          tooltip: 'Recenter NITC Campus',
          onPressed: onRecenterCampus,
        ),
      ],
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
    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 2,
      shadowColor: TrackletColors.primaryText.withValues(alpha: 0.15),
      borderRadius: TrackletRadii.roundedMd,
      child: InkWell(
        onTap: onPressed,
        borderRadius: TrackletRadii.roundedMd,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: TrackletRadii.roundedMd,
            border: Border.all(color: TrackletColors.border),
          ),
          child: Center(
            child: TrackletIcon(
              icon,
              size: 20,
              color: TrackletColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
