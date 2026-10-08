import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

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
    this.isSearchable = false,
    this.searchHintText = 'Search...',
    this.validator,
    this.prefixIcon,
    this.isValid,
  });

  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? initialItem;
  final String hintText;
  final bool isSearchable;
  final String searchHintText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool? isValid;

  @override
  Widget build(BuildContext context) {
    final decoration = CustomDropdownDecoration(
      closedFillColor: TrackletColors.primaryBackground,
      expandedFillColor: TrackletColors.primaryBackground,
      closedBorderRadius: BorderRadius.circular(TrackletRadii.card),
      expandedBorderRadius: BorderRadius.circular(TrackletRadii.card),
      closedBorder: Border.all(color: Colors.transparent, width: 2.0),
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
        Icons.keyboard_arrow_down_rounded,
        color: TrackletColors.secondaryText,
        size: 22,
      ),
      expandedSuffixIcon: const Icon(
        Icons.keyboard_arrow_up_rounded,
        color: TrackletColors.primary,
        size: 22,
      ),
      hintStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: TrackletColors.secondaryText,
      ),
      headerStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: TrackletColors.altPrimaryText,
      ),
      listItemStyle: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: TrackletColors.altPrimaryText,
      ),
      searchFieldDecoration: SearchFieldDecoration(
        fillColor: TrackletColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TrackletRadii.xs),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TrackletRadii.xs),
          borderSide: const BorderSide(
            color: TrackletColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          fontFamily: TrackletTypography.primaryFontFamily,
          color: TrackletColors.secondaryText,
          fontSize: 14,
        ),
        textStyle: const TextStyle(
          fontFamily: TrackletTypography.primaryFontFamily,
          color: TrackletColors.altPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      listItemDecoration: ListItemDecoration(
        selectedColor: TrackletColors.primary.withValues(alpha: 0.08),
        highlightColor: TrackletColors.secondaryBackground,
      ),
    );

    final safeInitial = (initialItem != null && items.contains(initialItem))
        ? initialItem
        : null;

    if (isSearchable) {
      return CustomDropdown<String>.search(
        items: items,
        initialItem: safeInitial,
        hintText: hintText,
        searchHintText: searchHintText,
        decoration: decoration,
        validator: validator,
        onChanged: onChanged,
        excludeSelected: false,
      );
    }

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
