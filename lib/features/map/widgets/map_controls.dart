import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Compact, accessible camera actions for the map.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onRecenterCampus,
    this.onRecenterBus,
    this.onFitFleet,
    this.onFitRoute,
    this.onRecenterUser,
    this.onOpenLegend,
  });

  final VoidCallback onRecenterCampus;
  final VoidCallback? onRecenterBus;
  final VoidCallback? onFitFleet;
  final VoidCallback? onFitRoute;
  final VoidCallback? onRecenterUser;
  final VoidCallback? onOpenLegend;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final dividerColor = TrackletColors.adaptiveDivider(context);

    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      elevation: TrackletShadows.elevationLevel3,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.12),
      borderRadius: TrackletRadii.roundedMd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedMd,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRecenterUser != null) ...[
              _ControlButton(
                icon: TrackletIcons.locateFixed,
                tooltip: 'Recenter on your location',
                onPressed: onRecenterUser!,
              ),
              Divider(height: 1, indent: 8, endIndent: 8, color: dividerColor),
            ],
            if (onRecenterBus != null) ...[
              _ControlButton(
                icon: TrackletIcons.bus,
                tooltip: 'Recenter on selected bus',
                onPressed: onRecenterBus!,
              ),
              Divider(height: 1, indent: 8, endIndent: 8, color: dividerColor),
            ],
            if (onFitFleet != null) ...[
              _ControlButton(
                icon: TrackletIcons.radar,
                tooltip: 'Fit all active buses in view',
                onPressed: onFitFleet!,
              ),
              Divider(height: 1, indent: 8, endIndent: 8, color: dividerColor),
            ],
            if (onFitRoute != null) ...[
              _ControlButton(
                icon: TrackletIcons.gitCommit,
                tooltip: 'Show all stops on this route',
                onPressed: onFitRoute!,
              ),
              Divider(height: 1, indent: 8, endIndent: 8, color: dividerColor),
            ],
            _ControlButton(
              icon: TrackletIcons.compass,
              animatedIcon: animated.compass,
              tooltip: 'Recenter on NIT Calicut campus',
              onPressed: onRecenterCampus,
            ),
            if (onOpenLegend != null) ...[
              Divider(height: 1, indent: 8, endIndent: 8, color: dividerColor),
              _ControlButton(
                icon: TrackletIcons.layers,
                tooltip: 'Map legend',
                onPressed: onOpenLegend!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    this.animatedIcon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final animated.LucideAnimatedIconData? animatedIcon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: tooltip,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon:
            animatedIcon != null
                ? IgnorePointer(
                  child: animated.LucideAnimatedIcon(
                    icon: animatedIcon!,
                    size: 21,
                    color: TrackletColors.adaptiveTextPrimary(context),
                    trigger: animated.AnimationTrigger.manual,
                  ),
                )
                : Icon(icon, size: 21),
        color: TrackletColors.adaptiveTextPrimary(context),
        focusColor: TrackletColors.primary.withValues(alpha: 0.18),
        hoverColor: TrackletColors.adaptiveBorder(
          context,
        ).withValues(alpha: 0.45),
        highlightColor: TrackletColors.primary.withValues(alpha: 0.12),
        constraints: const BoxConstraints(
          minWidth: TrackletSpacing.minTouchTarget,
          minHeight: TrackletSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.all(TrackletSpacing.sm),
        visualDensity: VisualDensity.standard,
      ),
    );
  }
}
