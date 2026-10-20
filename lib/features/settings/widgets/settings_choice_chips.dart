import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/motion.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Choice chips selector matching Attendrix time format and choice chips.
class SettingsChoiceChips<T> extends StatelessWidget {
  const SettingsChoiceChips({
    super.key,
    required this.options,
    required this.selectedOption,
    this.onChanged,
    this.onSelected,
    this.labelBuilder,
  });

  final List<T> options;
  final T selectedOption;
  final ValueChanged<T>? onChanged;
  final ValueChanged<T>? onSelected;
  final String Function(T option)? labelBuilder;

  void _handleSelect(T option) {
    if (onSelected != null) {
      onSelected!(option);
    } else if (onChanged != null) {
      onChanged!(option);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children:
          options.map((option) {
            final isSelected = option == selectedOption;
            final label =
                labelBuilder != null
                    ? labelBuilder!(option)
                    : option.toString();

            return InkWell(
              onTap: () => _handleSelect(option),
              borderRadius: TrackletRadii.roundedLg,
              child: AnimatedContainer(
                duration: TrackletMotion.adaptiveDuration(
                  context,
                  TrackletMotion.fast,
                ),
                curve: TrackletMotion.standardCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.compactLg,
                  vertical: TrackletSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? TrackletColors.primary
                          : (isDark
                              ? TrackletColors.darkSurfaceElevated
                              : TrackletColors.background),
                  borderRadius: TrackletRadii.roundedLg,
                  border: Border.all(
                    color:
                        isSelected
                            ? TrackletColors.primary
                            : (isDark
                                ? TrackletColors.darkBorder
                                : TrackletColors.cardBorder),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize13,
                    fontWeight:
                        isSelected
                            ? TrackletTypography.weightSemiBold
                            : TrackletTypography.weightMedium,
                    color:
                        isSelected
                            ? TrackletColors.textInverse
                            : (isDark
                                ? TrackletColors.darkTextSecondary
                                : TrackletColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
