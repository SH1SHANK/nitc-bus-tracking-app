import 'package:flutter/material.dart';

import '../../../data/admin/admin_models.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Bottom sheet inspecting live tracker telemetry and sequence breadcrumbs.
class TrackerDetailSheet extends StatelessWidget {
  const TrackerDetailSheet({super.key, required this.tracker});

  final TrackerDebugItem tracker;

  static void show(BuildContext context, TrackerDebugItem tracker) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackerDetailSheet(tracker: tracker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = tracker.currentPosition;
    final lat = pos?['latitude'] as num?;
    final lng = pos?['longitude'] as num?;
    final speed = pos?['speed'] as num?;
    final heading = pos?['heading'] as num?;
    final accuracy = pos?['accuracy'] as num?;

    return Container(
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurface(context),
        borderRadius: TrackletRadii.roundedTopSheet,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TrackletColors.adaptiveDivider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TrackletColors.primary.withValues(alpha: 0.12),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: const Icon(
                  TrackletIcons.bus,
                  color: TrackletColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: TrackletSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracker.busNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tracker ID: ${tracker.deviceId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: TrackletColors.adaptiveTextSecondary(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreshnessPill(context, tracker.freshness),
            ],
          ),
          const SizedBox(height: TrackletSpacing.lg),
          const Text(
            'LATEST TELEMETRY STATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricTile(
                context,
                'Epoch',
                '${tracker.epoch}',
                TrackletIcons.history,
              ),
              _metricTile(
                context,
                'Sequence #',
                '${tracker.seq}',
                TrackletIcons.activity,
              ),
              _metricTile(
                context,
                'Speed',
                speed != null ? '${speed.toStringAsFixed(1)} km/h' : '0.0 km/h',
                TrackletIcons.speed,
              ),
              _metricTile(
                context,
                'Heading',
                heading != null ? '${heading.toStringAsFixed(0)}°' : 'N/A',
                TrackletIcons.compass,
              ),
              _metricTile(
                context,
                'Accuracy',
                accuracy != null ? '${accuracy.toStringAsFixed(1)} m' : 'N/A',
                TrackletIcons.locate,
              ),
              _metricTile(
                context,
                'Coordinates',
                lat != null && lng != null
                    ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                    : 'No GPS Fix',
                TrackletIcons.busStop,
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT BREADCRUMBS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${tracker.recentBreadcrumbs.length} records',
                style: TextStyle(
                  fontSize: 11,
                  color: TrackletColors.adaptiveTextMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.sm),
          if (tracker.recentBreadcrumbs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recorded position history for this tracker yet.',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: 13,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tracker.recentBreadcrumbs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final crumb = tracker.recentBreadcrumbs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '#${crumb.seq}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${crumb.latitude.toStringAsFixed(5)}, ${crumb.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          crumb.speed != null
                              ? '${crumb.speed!.toStringAsFixed(1)} km/h'
                              : '0 km/h',
                          style: TextStyle(
                            fontSize: 11,
                            color: TrackletColors.adaptiveTextSecondary(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: TrackletSpacing.lg),
          TrackletButton(
            label: 'Close Inspector',
            variant: TrackletButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessPill(BuildContext context, String freshness) {
    final (Color color, String label) = switch (freshness) {
      'online' => (TrackletColors.success, 'ONLINE'),
      'stale' => (TrackletColors.warning, 'STALE'),
      _ => (TrackletColors.adaptiveTextMuted(context), 'OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 56) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? TrackletColors.darkSurfaceContainer
                : TrackletColors.surfaceElevated,
        borderRadius: TrackletRadii.roundedSm,
        border: Border.all(color: TrackletColors.adaptiveDivider(context)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: TrackletColors.adaptiveTextMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
