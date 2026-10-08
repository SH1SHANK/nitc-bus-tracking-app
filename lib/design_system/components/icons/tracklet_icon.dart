import 'package:flutter/widgets.dart';

/// Standard Tracklet icon widget.
///
/// Wraps icon rendering with design-system defaults, sizing,
/// and accessibility support.
class TrackletIcon extends StatelessWidget {
  const TrackletIcon(
    this.icon, {
    super.key,
    this.size = 20.0,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  /// The icon glyph to display, sourced from [TrackletIcons].
  final IconData icon;

  /// The size of the icon in logical pixels. Defaults to 20.0.
  final double? size;

  /// The color to use when drawing the icon.
  final Color? color;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  /// The text direction to use for rendering the icon.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
