import 'package:flutter/widgets.dart';

/// Tracklet corner radius tokens matching Attendrix design standards.
abstract final class TrackletRadii {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double input = 8.0;
  static const double md = 12.0;
  static const double card = 12.0;
  static const double button = 14.0;
  static const double banner = 14.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double dialog = 16.0;
  static const double avatar = 28.0;
  static const double compact = 6.0;
  static const double pill = 20.0;
  static const double full = 9999.0;

  // BorderRadius helpers
  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedInput = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedCard = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius roundedButton = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius roundedBanner = BorderRadius.all(
    Radius.circular(banner),
  );
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(full),
  );
}
