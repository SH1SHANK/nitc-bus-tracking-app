import 'package:flutter/material.dart';

import 'colors.dart';

/// Tracklet elevation & shadow tokens matching Attendrix design standards.
abstract final class TrackletShadows {
  static const double elevationLevel0 = 0;
  static const double elevationLevel2 = 2;
  static const double elevationLevel3 = 3;
  static const double elevationLevel4 = 4;

  static const BoxShadow sm = BoxShadow(
    blurRadius: 3.0,
    color: TrackletPalette.argb1A000000,
    offset: Offset(0.0, 1.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow md = BoxShadow(
    blurRadius: 6.0,
    color: TrackletPalette.argb1A000000,
    offset: Offset(0.0, 3.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow lg = BoxShadow(
    blurRadius: 15.0,
    color: TrackletPalette.argb1A000000,
    offset: Offset(0.0, 8.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow xl = BoxShadow(
    blurRadius: 25.0,
    color: TrackletPalette.argb1A000000,
    offset: Offset(0.0, 16.0),
    spreadRadius: 0.0,
  );

  // Card and Bottom Bar Specific Shadows
  static const BoxShadow card = BoxShadow(
    blurRadius: 12.0,
    color: TrackletPalette.argb08000000,
    offset: Offset(0.0, 4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow cardDark = BoxShadow(
    blurRadius: 12.0,
    color: TrackletPalette.argb26000000,
    offset: Offset(0.0, 4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow bottomBar = BoxShadow(
    blurRadius: 18.0,
    color: TrackletPalette.argb14000000,
    offset: Offset(0.0, -4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow bottomBarDark = BoxShadow(
    blurRadius: 18.0,
    color: TrackletPalette.argb4D000000,
    offset: Offset(0.0, -4.0),
    spreadRadius: 0.0,
  );

  // List helpers
  static const List<BoxShadow> shadowSm = [sm];
  static const List<BoxShadow> shadowMd = [md];
  static const List<BoxShadow> shadowLg = [lg];
  static const List<BoxShadow> shadowXl = [xl];
  static const List<BoxShadow> shadowCard = [card];
  static const List<BoxShadow> shadowCardDark = [cardDark];
  static const List<BoxShadow> shadowBottomBar = [bottomBar];
  static const List<BoxShadow> shadowBottomBarDark = [bottomBarDark];

  // Adaptive Context Helpers
  static List<BoxShadow> adaptiveCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? shadowCardDark
          : shadowCard;

  static List<BoxShadow> adaptiveBottomBar(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? shadowBottomBarDark
          : shadowBottomBar;
}
