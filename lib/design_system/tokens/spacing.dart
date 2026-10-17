import 'package:flutter/widgets.dart';

/// Tracklet spacing and sizing tokens.
abstract final class TrackletSpacing {
  static const double none = 0.0;
  static const double hairline = 1.0;
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double compact = 6.0;
  static const double sm = 8.0;
  static const double compactMd = 10.0;
  static const double md = 12.0;
  static const double compactLg = 14.0;
  static const double lg = 16.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingLg = 18.0;
  static const double section = 20.0;
  static const double xl = 24.0;
  static const double spacious = 28.0;
  static const double xxl = 32.0;
  static const double large = 40.0;
  static const double xxxl = 48.0;

  // Component Dimensions & Heights
  static const double controlHeightSm = 36.0;
  static const double controlHeightMd = 44.0;
  static const double controlHeightLg = 48.0;
  static const double controlHeightXl = 56.0;
  static const double bottomBarHeight = 72.0;
  static const double control = 32.0;

  // Icon Dimensions
  static const double iconXs = 14.0;
  static const double iconSm = 16.0;
  static const double icon = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;
  static const double iconHuge = 48.0;

  static const double smallIcon = 18.0;
  static const double mediumIcon = 36.0;
  static const double largeIcon = 38.0;

  // Avatar Dimensions
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatar = 56.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  /// Standard screen edge horizontal margin.
  static const double screenMargin = 16.0;

  /// Accessible minimum touch target dimension (WCAG 2.1 AA / Material standard).
  static const double minTouchTarget = 48.0;

  // Standard EdgeInsets Helpers
  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAllXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsAllSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsAllMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsAllLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsAllXl = EdgeInsets.all(xl);

  static const EdgeInsets edgeInsetsScreen = EdgeInsets.all(screenMargin);
  static const EdgeInsets edgeInsetsScreenHorizontal = EdgeInsets.symmetric(
    horizontal: screenMargin,
  );
  static const EdgeInsets edgeInsetsScreenVertical = EdgeInsets.symmetric(
    vertical: screenMargin,
  );
  static const EdgeInsets edgeInsetsCard = EdgeInsets.all(cardPadding);
  static const EdgeInsets edgeInsetsCardLg = EdgeInsets.all(cardPaddingLg);

  // Standard SizedBox Spacer Helpers
  static const SizedBox spaceXs = SizedBox(height: xs, width: xs);
  static const SizedBox spaceSm = SizedBox(height: sm, width: sm);
  static const SizedBox spaceMd = SizedBox(height: md, width: md);
  static const SizedBox spaceLg = SizedBox(height: lg, width: lg);
  static const SizedBox spaceXl = SizedBox(height: xl, width: xl);
  static const SizedBox spaceXxl = SizedBox(height: xxl, width: xxl);

  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalCompactMd = SizedBox(height: compactMd);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalCompactLg = SizedBox(height: compactLg);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalSection = SizedBox(height: section);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalSpacious = SizedBox(height: spacious);
  static const SizedBox verticalXxl = SizedBox(height: xxl);
  static const SizedBox verticalLarge = SizedBox(height: large);

  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalCompactMd = SizedBox(width: compactMd);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalCompactLg = SizedBox(width: compactLg);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalSection = SizedBox(width: section);
  static const SizedBox horizontalXl = SizedBox(width: xl);
  static const SizedBox horizontalXxl = SizedBox(width: xxl);
}
