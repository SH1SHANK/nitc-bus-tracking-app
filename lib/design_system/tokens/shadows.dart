import 'package:flutter/widgets.dart';

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
}
