import 'package:flutter/material.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;

import '../../../core/formatting/transit_formatter.dart';
import '../../../core/geo/geo_point.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import 'package:tracklet/design_system/tokens/radii.dart';
import '../home_transit_logic.dart';

/// Searchable bottom sheet allowing students to pick any campus stop as boarding point.
class StopSelectorSheet extends StatefulWidget {
  const StopSelectorSheet({
    super.key,
    required this.stops,
    required this.currentStop,
    this.userLocation,
    required this.onStopSelected,
  });

  final List<Stop> stops;
  final Stop currentStop;
  final GeoPoint? userLocation;
  final ValueChanged<Stop> onStopSelected;

  static Future<void> show({
    required BuildContext context,
    required List<Stop> stops,
    required Stop currentStop,
    GeoPoint? userLocation,
    required ValueChanged<Stop> onStopSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StopSelectorSheet(
            stops: stops,
            currentStop: currentStop,
            userLocation: userLocation,
            onStopSelected: onStopSelected,
          ),
    );
  }

  @override
  State<StopSelectorSheet> createState() => _StopSelectorSheetState();
}

class _StopSelectorSheetState extends State<StopSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredStops =
        widget.stops.where((stop) {
          if (query.isEmpty) return true;
          return stop.name.toLowerCase().contains(query) ||
              stop.code.toLowerCase().contains(query);
        }).toList();

    // Sort by distance if user location is available, otherwise alphabetical
    filteredStops.sort((a, b) {
      if (widget.userLocation != null) {
        final distA = widget.userLocation!.distanceToMeters(a.location);
        final distB = widget.userLocation!.distanceToMeters(b.location);
        return distA.compareTo(distB);
      }
      return a.name.compareTo(b.name);
    });

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final isDark = TrackletColors.isDark(context);
    final sheetBg = TrackletColors.adaptiveSurfaceElevated(context);
    final border = TrackletColors.adaptiveBorder(context);
    final textPrimary = TrackletColors.adaptiveTextPrimary(context);
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);
    final textMuted = TrackletColors.adaptiveTextMuted(context);
    final searchBg =
        isDark
            ? TrackletColors.darkSurfaceContainerHighest
            : TrackletColors.background;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: EdgeInsets.only(bottom: keyboardInset),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: TrackletRadii.roundedXs,
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Boarding Stop',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(TrackletIcons.x, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: TrackletRadii.roundedBanner,
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    animated.LucideAnimatedIcon(
                      icon: animated.search,
                      color: textSecondary,
                      size: 20,
                      trigger: animated.AnimationTrigger.manual,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _query = val),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search campus stops…',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          TrackletIcons.x,
                          color: textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: border),

            // Stop List
            Flexible(
              child:
                  filteredStops.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No stops match "$_query"',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredStops.length,
                        separatorBuilder:
                            (_, _) =>
                                Divider(height: 1, indent: 56, color: border),
                        itemBuilder: (context, index) {
                          final stop = filteredStops[index];
                          final isSelected = stop.id == widget.currentStop.id;
                          final distanceMeters = widget.userLocation
                              ?.distanceToMeters(stop.location);
                          final walkMinutes =
                              distanceMeters != null
                                  ? estimateWalkMinutes(distanceMeters)
                                  : null;

                          final selectedTileBg =
                              isDark
                                  ? TrackletColors.primary.withValues(
                                    alpha: 0.15,
                                  )
                                  : TrackletColors.background2;
                          final unselectedBoxBg =
                              isDark
                                  ? TrackletColors.darkSurfaceContainerHighest
                                  : TrackletColors.background;

                          return Material(
                            color:
                                isSelected
                                    ? selectedTileBg
                                    : Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.onStopSelected(stop);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? TrackletColors.primary
                                                    .withValues(alpha: 0.12)
                                                : unselectedBoxBg,
                                        borderRadius:
                                            TrackletRadii.roundedInput,
                                      ),
                                      child: Icon(
                                        TrackletIcons.mapPin,
                                        color:
                                            isSelected
                                                ? TrackletColors.primary
                                                : textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.name,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? TrackletColors.primary
                                                      : textPrimary,
                                              fontSize: 15,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                            ),
                                          ),
                                          if (distanceMeters != null &&
                                              walkMinutes != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '~${TransitFormatter.formatDistance(distanceMeters)} · ~$walkMinutes min walk',
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (isSelected)
                                      const Icon(
                                        TrackletIcons.checkCircle2,
                                        color: TrackletColors.primary,
                                        size: 20,
                                      )
                                    else
                                      Text(
                                        stop.code,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
