import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transit/bus_route.dart';
import '../../data/transit/scheduled_departure.dart';
import '../../data/transit/stop.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/radii.dart';
import '../home/providers/home_provider.dart';

/// Full institute timetable screen displaying scheduled departures for campus routes.
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key, this.initialStopId});

  final String? initialStopId;

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String? _selectedRouteId;
  late String? _filteredStopId;

  @override
  void initState() {
    super.initState();
    _filteredStopId = widget.initialStopId;
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeStateProvider);

    return Scaffold(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: TrackletColors.adaptiveSurfaceElevated(context),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            TrackletIcons.arrowLeft,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Campus Timetable',
          style: TextStyle(
            color: TrackletColors.adaptiveTextPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: homeStateAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: TrackletColors.primary),
            ),
        error:
            (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      TrackletIcons.alertCircle,
                      color: TrackletColors.busDelayed,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load timetable',
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(homeStateProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TrackletColors.primary,
                        foregroundColor: TrackletColors.pure,
                        shape: const RoundedRectangleBorder(
                          borderRadius: TrackletRadii.roundedCard,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        data: (data) {
          final isDark = TrackletColors.isDark(context);
          final stops = data.stops;
          final routes = data.routes;
          final allDepartures = data.scheduledDepartures;

          Stop? filteredStop;
          if (_filteredStopId != null) {
            filteredStop =
                stops.where((s) => s.id == _filteredStopId).firstOrNull;
          }

          // Filter by stop if active
          final departuresForStop =
              filteredStop != null
                  ? allDepartures.where((dep) {
                    final route =
                        routes.where((r) => r.id == dep.routeId).firstOrNull;
                    return route != null &&
                        route.stopIds.contains(filteredStop!.id);
                  }).toList()
                  : allDepartures;

          // Filter by selected route if any
          final filteredDepartures =
              _selectedRouteId != null
                  ? departuresForStop
                      .where((dep) => dep.routeId == _selectedRouteId)
                      .toList()
                  : departuresForStop;

          // Sort chronologically
          filteredDepartures.sort((a, b) {
            final cmp = a.secondsAfterMidnight.compareTo(
              b.secondsAfterMidnight,
            );
            if (cmp != 0) return cmp;
            return a.sortOrder.compareTo(b.sortOrder);
          });

          return CustomScrollView(
            slivers: [
              // Disclaimer Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? TrackletColors.warningContainerDark
                              : TrackletColors.warningContainer,
                      borderRadius: TrackletRadii.roundedCard,
                      border: Border.all(
                        color:
                            isDark
                                ? TrackletColors.warningContainerDark
                                    .withValues(alpha: 0.4)
                                : TrackletColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              TrackletIcons.info,
                              size: 16,
                              color:
                                  isDark
                                      ? TrackletColors.onWarningContainerDark
                                      : TrackletColors.onWarningContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Institute timetable · Reference only',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? TrackletColors.onWarningContainerDark
                                        : TrackletColors.onWarningContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Actual bus timings may vary depending on traffic and driver availability. These times are scheduled departures published by NIT Calicut and do not represent live tracking.',
                          style: TextStyle(
                            color:
                                isDark
                                    ? TrackletColors.onWarningContainerDark
                                    : TrackletColors.onWarningContainer,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stop Dropdown Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TrackletColors.adaptiveSurfaceElevated(context),
                      borderRadius: TrackletRadii.roundedCard,
                      border: Border.all(
                        color: TrackletColors.adaptiveCardBorder(context),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              TrackletIcons.mapPin,
                              size: 15,
                              color:
                                  isDark
                                      ? TrackletColors.primaryDark
                                      : TrackletColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'VIEW TIMINGS FOR STOP',
                              style: TextStyle(
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value:
                                stops.any((s) => s.id == _filteredStopId)
                                    ? _filteredStopId
                                    : null,
                            isExpanded: true,
                            icon: Icon(
                              TrackletIcons.chevronDown,
                              color: TrackletColors.adaptiveTextPrimary(
                                context,
                              ),
                            ),
                            style: TextStyle(
                              color: TrackletColors.adaptiveTextPrimary(
                                context,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            dropdownColor:
                                TrackletColors.adaptiveSurfaceElevated(context),
                            borderRadius: TrackletRadii.roundedCard,
                            onChanged: (value) {
                              setState(() {
                                _filteredStopId = value;
                                if (value != null && _selectedRouteId != null) {
                                  final selectedRoute =
                                      routes
                                          .where(
                                            (r) => r.id == _selectedRouteId,
                                          )
                                          .firstOrNull;
                                  if (selectedRoute != null &&
                                      !selectedRoute.stopIds.contains(value)) {
                                    _selectedRouteId = null;
                                  }
                                }
                              });
                            },
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'All campus stops (Full timetable)',
                                  style: TextStyle(
                                    color: TrackletColors.adaptiveTextPrimary(
                                      context,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...stops.map((stop) {
                                return DropdownMenuItem<String?>(
                                  value: stop.id,
                                  child: Text(
                                    stop.name,
                                    style: TextStyle(
                                      color: TrackletColors.adaptiveTextPrimary(
                                        context,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Route Filter Tabs
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: routes.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedRouteId == null;
                        return ChoiceChip(
                          label: Text(
                            'All routes (${departuresForStop.length})',
                          ),
                          selected: isSelected,
                          onSelected:
                              (_) => setState(() => _selectedRouteId = null),
                          selectedColor:
                              isDark
                                  ? TrackletColors.primaryContainerDark
                                  : TrackletColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                          backgroundColor:
                              isDark
                                  ? TrackletColors.darkSurfaceContainerHighest
                                  : TrackletColors.surface,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? (isDark
                                        ? TrackletColors.primaryDark
                                        : TrackletColors.primary)
                                    : TrackletColors.adaptiveTextSecondary(
                                      context,
                                    ),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? (isDark
                                        ? TrackletColors.primaryDark
                                        : TrackletColors.primary)
                                    : TrackletColors.adaptiveBorder(context),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: TrackletRadii.roundedInput,
                          ),
                        );
                      }

                      final route = routes[index - 1];
                      final isSelected = _selectedRouteId == route.id;
                      final routeColor = route.color;
                      final routeDepCount =
                          departuresForStop
                              .where((d) => d.routeId == route.id)
                              .length;

                      return ChoiceChip(
                        avatar: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: routeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text('${route.name} ($routeDepCount)'),
                        selected: isSelected,
                        onSelected:
                            (_) => setState(
                              () =>
                                  _selectedRouteId =
                                      isSelected ? null : route.id,
                            ),
                        selectedColor: routeColor.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        backgroundColor:
                            isDark
                                ? TrackletColors.darkSurfaceContainerHighest
                                : TrackletColors.surface,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? (routeColor == TrackletColors.routeDefault
                                      ? TrackletColors.adaptiveTextPrimary(
                                        context,
                                      )
                                      : routeColor)
                                  : TrackletColors.adaptiveTextSecondary(
                                    context,
                                  ),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? routeColor
                                  : TrackletColors.adaptiveBorder(context),
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Departure Count & Timetable List
              if (filteredDepartures.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            TrackletIcons.bus,
                            size: 40,
                            color: TrackletColors.adaptiveTextMuted(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No scheduled departures found for this filter.',
                            style: TextStyle(
                              color: TrackletColors.adaptiveTextSecondary(
                                context,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: TrackletColors.adaptiveSurfaceElevated(context),
                        borderRadius: TrackletRadii.roundedLg,
                        border: Border.all(
                          color: TrackletColors.adaptiveCardBorder(context),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredDepartures.length,
                        separatorBuilder:
                            (_, _) => Divider(
                              color: TrackletColors.adaptiveDivider(context),
                              height: 1,
                              indent: 68,
                            ),
                        itemBuilder: (context, index) {
                          final dep = filteredDepartures[index];
                          final route =
                              routes
                                  .where((r) => r.id == dep.routeId)
                                  .firstOrNull;
                          final routeColor =
                              route?.color ?? TrackletColors.routeDefault;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: routeColor.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: TrackletRadii.roundedInput,
                                  ),
                                  child: Icon(
                                    TrackletIcons.bus,
                                    color: routeColor,
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
                                        route?.name ?? 'Campus route',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              TrackletColors.adaptiveTextPrimary(
                                                context,
                                              ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _buildDepartureSubtitle(dep, route),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              TrackletColors.adaptiveTextSecondary(
                                                context,
                                              ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dep.formattedTime,
                                      style: TextStyle(
                                        color:
                                            TrackletColors.adaptiveTextPrimary(
                                              context,
                                            ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    if (dep.isSpecial)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? TrackletColors
                                                      .busDelayedBgDark
                                                  : TrackletColors.busDelayedBg,
                                          borderRadius:
                                              TrackletRadii.roundedCompact,
                                        ),
                                        child: Text(
                                          'Special',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? TrackletColors
                                                        .busDelayedTextDark
                                                    : TrackletColors.busDelayed,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _buildDepartureSubtitle(
    ScheduledDeparture dep,
    BusRoute? route,
  ) {
    final busLabel = dep.busNumber;
    final stopJourney = _formatRouteStops(route);
    if (busLabel != null && busLabel.isNotEmpty) {
      return '$busLabel · $stopJourney';
    }
    return stopJourney;
  }

  static String _formatRouteStops(BusRoute? route) {
    if (route == null) return 'Campus route';
    final desc = route.description;
    if (desc != null && desc.contains('→')) {
      final parts =
          desc
              .split('→')
              .map((s) => s.trim())
              .where((s) => !s.toLowerCase().startsWith('return'))
              .toList();
      if (parts.length >= 2) {
        return '${parts.first} ↔ ${parts.last}';
      }
    }
    if (desc != null && desc.isNotEmpty) {
      return desc;
    }
    return 'Campus service';
  }
}
