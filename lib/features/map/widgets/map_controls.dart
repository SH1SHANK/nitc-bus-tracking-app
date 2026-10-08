import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Floating control buttons on the map for campus recenter and user location.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onRecenterCampus,
    required this.onLocateUser,
    this.isLocating = false,
  });

  final VoidCallback onRecenterCampus;
  final VoidCallback onLocateUser;
  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.school_rounded,
          tooltip: 'Recenter NITC Campus',
          onPressed: onRecenterCampus,
        ),
        const SizedBox(height: TrackletSpacing.sm),
        _ControlButton(
          icon: isLocating
              ? Icons.hourglass_top_rounded
              : Icons.my_location_rounded,
          tooltip: 'Locate Me',
          onPressed: onLocateUser,
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
      shadowColor: const Color(0x20000000),
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
          child: Icon(icon, size: 20, color: TrackletColors.textPrimary),
        ),
      ),
    );
  }
}
