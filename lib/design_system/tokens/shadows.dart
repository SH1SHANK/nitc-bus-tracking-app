import 'package:flutter/material.dart';

/// Tracklet elevation & shadow tokens matching Attendrix design standards.
abstract final class TrackletShadows {
  static const BoxShadow sm = BoxShadow(
    blurRadius: 3.0,
    color: Color(0x1A000000),
    offset: Offset(0.0, 1.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow md = BoxShadow(
    blurRadius: 6.0,
    color: Color(0x1A000000),
    offset: Offset(0.0, 3.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow lg = BoxShadow(
    blurRadius: 15.0,
    color: Color(0x1A000000),
    offset: Offset(0.0, 8.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow xl = BoxShadow(
    blurRadius: 25.0,
    color: Color(0x1A000000),
    offset: Offset(0.0, 16.0),
    spreadRadius: 0.0,
  );

  // Card and Bottom Bar Specific Shadows
  static const BoxShadow card = BoxShadow(
    blurRadius: 12.0,
    color: Color(0x08000000),
    offset: Offset(0.0, 4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow cardDark = BoxShadow(
    blurRadius: 12.0,
    color: Color(0x26000000),
    offset: Offset(0.0, 4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow bottomBar = BoxShadow(
    blurRadius: 18.0,
    color: Color(0x14000000),
    offset: Offset(0.0, -4.0),
    spreadRadius: 0.0,
  );

  static const BoxShadow bottomBarDark = BoxShadow(
    blurRadius: 18.0,
    color: Color(0x4D000000),
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
