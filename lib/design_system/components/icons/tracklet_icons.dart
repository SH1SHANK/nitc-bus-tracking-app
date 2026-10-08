import 'package:flutter/widgets.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Semantic icon repository for Tracklet.
///
/// Policy:
/// - Tabler Icons is the primary/default icon provider.
/// - Phosphor Icons is used where Tabler lacks coverage or Phosphor
///   offers superior semantic/visual precision.
/// - Feature code MUST NOT import icon packages directly; consume [TrackletIcons]
///   via [TrackletIcon].
abstract final class TrackletIcons {
  // Navigation & Shell
  static const IconData home = TablerIcons.home;
  static const IconData map = TablerIcons.map_2;
  static const IconData profile = TablerIcons.user;
  static const IconData settings = TablerIcons.settings;
  static const IconData notifications = TablerIcons.bell;
  static const IconData search = TablerIcons.search;
  static const IconData filter = TablerIcons.adjustments_horizontal;
  static const IconData menu = TablerIcons.menu_2;

  // Transit & Geo
  static const IconData bus = TablerIcons.bus;
  static const IconData busStop = TablerIcons.map_pin;
  static const IconData location = TablerIcons.current_location;
  static const IconData navigation = TablerIcons.navigation;
  static const IconData route = TablerIcons.route;
  static const IconData speed = TablerIcons.gauge;
  static const IconData compass = TablerIcons.compass;
  static const IconData layers = TablerIcons.layers_intersect;

  // Temporal & Numeric
  static const IconData time = TablerIcons.clock;
  static const IconData calendar = TablerIcons.calendar;
  static const IconData refresh = TablerIcons.refresh;

  // Capacity & Amenities
  static const IconData seat = TablerIcons.armchair;
  static const IconData wheelchair = TablerIcons.accessible;
  static const IconData wifi = TablerIcons.wifi;

  // Status & Feedback
  static const IconData info = TablerIcons.info_circle;
  static const IconData warning = TablerIcons.alert_triangle;
  static const IconData error = TablerIcons.alert_circle;
  static const IconData check = TablerIcons.check;
  static const IconData help = TablerIcons.help_circle;

  // Chevrons & Controls
  static const IconData chevronLeft = TablerIcons.chevron_left;
  static const IconData chevronRight = TablerIcons.chevron_right;
  static const IconData chevronDown = TablerIcons.chevron_down;
  static const IconData chevronUp = TablerIcons.chevron_up;
  static const IconData close = TablerIcons.x;
  static const IconData plus = TablerIcons.plus;
  static const IconData minus = TablerIcons.minus;
  static const IconData share = TablerIcons.share;
  static const IconData logout = TablerIcons.logout;
  static const IconData externalLink = TablerIcons.external_link;
  static const IconData copy = TablerIcons.copy;
}
