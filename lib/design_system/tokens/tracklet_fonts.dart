import 'package:flutter/material.dart';

import 'typography.dart';

/// Shared styles for fonts provided by Tracklet's bundled font assets.
abstract final class TrackletFonts {
  static TextStyle outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: TrackletTypography.primaryFontFamily,
      fontFamilyFallback: TrackletTypography.fontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle robotoMono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: TrackletTypography.fontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
