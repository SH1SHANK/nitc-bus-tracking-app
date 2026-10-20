import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';

/// Standard animated dropdown component for Tracklet.
/// Wraps `animated_custom_dropdown` with Tracklet design system tokens.
class TrackletDropdown extends StatelessWidget {
  const TrackletDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialItem,
    this.hintText = 'Select option',
    this.validator,
    this.prefixIcon,
    this.isValid,
  });

  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? initialItem;
  final String hintText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool? isValid;

  @override
  Widget build(BuildContext context) {
    final decoration = CustomDropdownDecoration(
      closedFillColor: TrackletColors.primaryBackground,
      expandedFillColor: TrackletColors.primaryBackground,
      closedBorderRadius: TrackletRadii.roundedCard,
      expandedBorderRadius: TrackletRadii.roundedCard,
      closedBorder: Border.all(
        color:
            isValid == true
                ? TrackletColors.primary.withValues(alpha: 0.45)
                : TrackletColors.alternate,
        width: 1.5,
      ),
      expandedBorder: Border.all(color: TrackletColors.primary, width: 2.0),
      closedErrorBorder: Border.all(
        color: TrackletColors.errorBorder,
        width: 2.0,
      ),
      closedShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      prefixIcon: prefixIcon,
      closedSuffixIcon: const Icon(
        TrackletIcons.chevronDown,
        color: TrackletColors.secondaryText,
        size: 22,
      ),
      expandedSuffixIcon: const Icon(
        TrackletIcons.chevronUp,
        color: TrackletColors.primary,
        size: 22,
      ),
      hintStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: TrackletTypography.fontSize15,
        fontWeight: TrackletTypography.weightSemiBold,
        color: TrackletColors.secondaryText,
      ),
      headerStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: TrackletTypography.fontSize15,
        fontWeight: TrackletTypography.weightSemiBold,
        color: TrackletColors.altPrimaryText,
      ),
      listItemStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: TrackletTypography.fontSize14,
        fontWeight: TrackletTypography.weightMedium,
        color: TrackletColors.altPrimaryText,
      ),

      listItemDecoration: ListItemDecoration(
        selectedColor: TrackletColors.primary.withValues(alpha: 0.12),
        highlightColor: TrackletColors.secondaryBackground,
      ),
    );

    final safeInitial =
        (initialItem != null && items.contains(initialItem))
            ? initialItem
            : null;

    return CustomDropdown<String>(
      items: items,
      initialItem: safeInitial,
      hintText: hintText,
      decoration: decoration,
      validator: validator,
      onChanged: onChanged,
      excludeSelected: false,
    );
  }
}
