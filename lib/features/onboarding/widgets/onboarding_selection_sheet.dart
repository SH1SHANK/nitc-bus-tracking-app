import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Reusable modal selection sheet for academic choices (Branch, Batch, Hostel).
class OnboardingSelectionSheet extends StatefulWidget {
  const OnboardingSelectionSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.showSearch = false,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String> onSelected;
  final bool showSearch;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
    bool showSearch = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => OnboardingSelectionSheet(
            title: title,
            subtitle: subtitle,
            items: items,
            selectedItem: selectedItem,
            onSelected: onSelected,
            showSearch: showSearch,
          ),
    );
  }

  @override
  State<OnboardingSelectionSheet> createState() =>
      _OnboardingSelectionSheetState();
}

class _OnboardingSelectionSheetState extends State<OnboardingSelectionSheet> {
  late String _query;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _query = '';
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.items
            .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final isDark = TrackletColors.isDark(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: TrackletSpacing.lg,
        left: TrackletSpacing.screenMargin,
        right: TrackletSpacing.screenMargin,
        bottom: MediaQuery.paddingOf(context).bottom + TrackletSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TrackletColors.adaptiveBorder(context),
                borderRadius: TrackletRadii.roundedFull,
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TrackletTypography.adaptive(
                        context,
                        TrackletTypography.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TrackletTypography.adaptiveSecondary(
                        context,
                        TrackletTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: TrackletIcon(
                  TrackletIcons.close,
                  size: 20,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),

          // Search Field if enabled
          if (widget.showSearch) ...[
            Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? TrackletColors.darkSurfaceContainerHighest
                        : TrackletColors.surface,
                borderRadius: TrackletRadii.roundedMd,
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.md,
              ),
              child: Row(
                children: [
                  TrackletIcon(
                    TrackletIcons.search,
                    size: 18,
                    color: TrackletColors.adaptiveTextSecondary(context),
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: TrackletColors.adaptiveTextMuted(context),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
                      ),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.md),
          ],

          // List of Options
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder:
                  (_, _) => const SizedBox(height: TrackletSpacing.xs),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isSelected = item == widget.selectedItem;

                return InkWell(
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                  borderRadius: TrackletRadii.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.md,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? TrackletColors.primary.withValues(
                                alpha: isDark ? 0.2 : 0.08,
                              )
                              : Colors.transparent,
                      borderRadius: TrackletRadii.roundedMd,
                      border:
                          isSelected
                              ? Border.all(
                                color: TrackletColors.primary,
                                width: 1.5,
                              )
                              : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: TrackletTypography.adaptive(
                              context,
                              TrackletTypography.titleMedium,
                            ).copyWith(
                              color:
                                  isSelected
                                      ? TrackletColors.primary
                                      : TrackletColors.adaptiveTextPrimary(
                                        context,
                                      ),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const TrackletIcon(
                            TrackletIcons.check,
                            size: 18,
                            color: TrackletColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
