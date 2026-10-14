import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_telemetry.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/shadows.dart';

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

  @override
  void initState() {
    super.initState();
    _headingFrom = _headingTo = widget.bus.position.heading;
    _headingAnimation = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 350),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant BusMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bus.position.heading != widget.bus.position.heading) {
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
    final stale =
        bus.isStale ||
        bus.status == BusStatus.offline ||
        DateTime.now().difference(bus.position.timestamp) >
            BusTelemetry.staleAfter;
    final stationary =
        !stale && bus.position.hasSpeed && bus.position.speedKmH < 2;
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

    return Semantics(
      button: widget.onTap != null,
      selected: widget.isSelected,
      label: '${bus.name}, $state bus',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: widget.isSelected ? 44 : 40,
              height: widget.isSelected ? 44 : 40,
              decoration: BoxDecoration(
                color: stale ? TrackletColors.busOfflineBg : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected ? TrackletColors.textPrimary : color,
                  width: widget.isSelected ? 3 : 2,
                ),
                boxShadow: const [TrackletShadows.sm],
              ),
              child: Center(
                child: Transform.rotate(
                  // Map headings use north=0° and increase clockwise.
                  angle:
                      (_headingFrom +
                          (_headingTo - _headingFrom) *
                              _headingAnimation.value) *
                      math.pi /
                      180,
                  child: Icon(
                    stationary
                        ? Icons.pause_rounded
                        : Icons.directions_bus_filled_rounded,
                    size: 22,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
