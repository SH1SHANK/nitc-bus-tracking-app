import 'package:flutter/widgets.dart';

/// Tracklet corner radius tokens matching Attendrix design standards.
abstract final class TrackletRadii {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double compact = 6.0;
  static const double sm = 8.0;
  static const double input = 8.0;
  static const double md = 12.0;
  static const double card = 12.0;
  static const double button = 14.0;
  static const double banner = 14.0;
  static const double lg = 16.0;
  static const double cardLg = 18.0;
  static const double cardXl = 22.0;
  static const double sheet = 20.0;
  static const double pill = 20.0;
  static const double xl = 24.0;
  static const double dialog = 16.0;
  static const double dialogLg = 20.0;
  static const double avatar = 28.0;
  static const double curvedBar = 32.0;
  static const double full = 9999.0;

  // BorderRadius helpers
  static const BorderRadius roundedNone = BorderRadius.zero;
  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedCompact = BorderRadius.all(
    Radius.circular(compact),
  );
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
  static const BorderRadius roundedCardLg = BorderRadius.all(
    Radius.circular(cardLg),
  );
  static const BorderRadius roundedCardXl = BorderRadius.all(
    Radius.circular(cardXl),
  );
  static const BorderRadius roundedSheet = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedDialog = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius roundedDialogLg = BorderRadius.all(
    Radius.circular(dialogLg),
  );
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(full),
  );

  // Directional Corner Helpers
  static const BorderRadius roundedTopLg = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius roundedTopSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius roundedTopCurvedBar = BorderRadius.vertical(
    top: Radius.circular(curvedBar),
  );
  static const BorderRadius roundedBottomSheet = BorderRadius.vertical(
    bottom: Radius.circular(sheet),
  );
  static const BorderRadius roundedBottomXl = BorderRadius.vertical(
    bottom: Radius.circular(xl),
  );
  static const BorderRadius roundedBottomCurvedBar = BorderRadius.vertical(
    bottom: Radius.circular(curvedBar),
  );
}
