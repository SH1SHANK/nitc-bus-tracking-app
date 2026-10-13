import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

/// Flat grouped container used to keep related settings visually together.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    this.child,
    this.children,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (child != null) {
      content = child!;
    } else if (children != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: children!,
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: TrackletColors.surface,
          borderRadius: TrackletRadii.roundedCard,
          border: Border.all(color: TrackletColors.cardBorder),
        ),
        child: Padding(padding: padding, child: content),
      ),
    );
  }
}
