import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_telemetry.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/motion.dart';
import '../../../design_system/tokens/shadows.dart';

import '../../../services/maps/map_config.dart';

/// Directional campus bus marker with explicit moving, stationary, and stale states.
class BusMarkerWidget extends StatefulWidget {
  const BusMarkerWidget({
    super.key,
    required this.bus,
    this.isSelected = false,
    this.routeColor,
    this.onTap,
  });

  final Bus bus;
  final bool isSelected;
  final Color? routeColor;
  final VoidCallback? onTap;

  @override
  State<BusMarkerWidget> createState() => _BusMarkerWidgetState();
}

class _BusMarkerWidgetState extends State<BusMarkerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headingAnimation;
  double _headingFrom = 0;
  double _headingTo = 0;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _headingFrom = _headingTo = widget.bus.position.heading;
    _headingAnimation = AnimationController(
      vsync: this,
      value: 1,
      duration: TrackletMotion.medium,
    );
  }

  @override
  void didUpdateWidget(covariant BusMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bus.position.heading != widget.bus.position.heading) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _headingFrom = _headingTo = widget.bus.position.heading;
        _headingAnimation.value = 1;
        setState(() {});
        return;
      }
      final current =
          _headingFrom + (_headingTo - _headingFrom) * _headingAnimation.value;
      _headingFrom = current;
      _headingTo =
          current +
          BusTelemetry.headingDelta(current % 360, widget.bus.position.heading);
      _headingAnimation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _headingAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.bus;
    final routeColor = widget.routeColor;
    final trackingState = bus.trackingState();
    final stale =
        trackingState == BusTrackingState.stale ||
        trackingState == BusTrackingState.offline ||
        trackingState == BusTrackingState.noLocation;
    final stationary = trackingState == BusTrackingState.liveStationary;
    final color =
        stale
            ? TrackletColors.busOffline
            : stationary
            ? TrackletColors.warningStrong
            : routeColor ?? TrackletColors.routeActive;
    final state =
        stale
            ? 'stale or offline'
            : stationary
            ? 'stationary'
            : 'moving';

    // Direction indicators should only be displayed when reliable:
    // 1. Bus is actively moving (not stale, not stationary)
    // 2. Hardware telemetry provided a genuine heading
    // 3. Speed exceeds stationary jitter threshold
    final isDirectionReliable =
        !stale &&
        !stationary &&
        bus.position.hasHeading &&
        bus.position.speedKmH >= BusTelemetry.stationarySpeedThresholdKmH;

    return Semantics(
      button: widget.onTap != null,
      selected: widget.isSelected,
      enabled: true,
      label: '${bus.name}, $state bus',
      hint: 'Double tap or press enter to view bus details and upcoming stops',
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        onShowFocusHighlight: (show) => setState(() => _isFocused = show),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: MapConfig.busMarkerSize,
            height: MapConfig.busMarkerSize,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: TrackletMotion.adaptiveDuration(
                      context,
                      TrackletMotion.fast,
                    ),
                    curve: TrackletMotion.standardCurve,
                    width:
                        widget.isSelected
                            ? MapConfig.selectedBusMarkerSize
                            : MapConfig.unselectedBusMarkerSize,
                    height:
                        widget.isSelected
                            ? MapConfig.selectedBusMarkerSize
                            : MapConfig.unselectedBusMarkerSize,
                    decoration: BoxDecoration(
                      color:
                          stale
                              ? (TrackletColors.isDark(context)
                                  ? TrackletColors.darkSurfaceContainerHighest
                                  : TrackletColors.busOfflineBg)
                              : TrackletColors.adaptiveSurfaceElevated(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _isFocused
                                ? TrackletColors.primary
                                : (widget.isSelected
                                    ? TrackletColors.adaptiveTextPrimary(
                                      context,
                                    )
                                    : color),
                        width:
                            _isFocused ? 3.0 : (widget.isSelected ? 3.0 : 2.0),
                      ),
                      boxShadow: [
                        if (widget.isSelected)
                          BoxShadow(
                            color: (routeColor ?? TrackletColors.primary)
                                .withValues(alpha: 0.38),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        TrackletShadows.sm,
                      ],
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _headingAnimation,
                        builder: (context, child) {
                          final double displayAngle =
                              isDirectionReliable
                                  ? (_headingFrom +
                                          (_headingTo - _headingFrom) *
                                              _headingAnimation.value) *
                                      math.pi /
                                      180
                                  : 0.0;
                          return Transform.rotate(
                            // Map headings use north=0° and increase clockwise.
                            angle: displayAngle,
                            child: child,
                          );
                        },
                        child: Icon(
                          stationary ? TrackletIcons.pause : TrackletIcons.bus,
                          size: widget.isSelected ? 24 : 20,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  if (stale)
                    Positioned(
                      top: widget.isSelected ? 0 : 2,
                      right: widget.isSelected ? 0 : 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: TrackletColors.busOffline,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TrackletColors.adaptiveSurfaceElevated(
                              context,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          TrackletIcons.cloudOff,
                          size: 7,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
