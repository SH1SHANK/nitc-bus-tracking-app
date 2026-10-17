import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';

/// Stepper count controller matching Attendrix's count selector.
class SettingsStepper extends StatelessWidget {
  const SettingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 60,
    this.step = 1,
    this.suffix = 'min',
    this.unit,
    this.width = 140.0,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final String? unit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final displayUnit = unit ?? suffix;
    final canDecrement = value - step >= min;
    final canIncrement = value + step <= max;

    final isDark = TrackletColors.isDark(context);

    return Container(
      width: width,
      height: TrackletSpacing.icon,
      padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.xxs),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveBackground(context),
        borderRadius: TrackletRadii.roundedSm,
        border: Border.all(
          color: TrackletColors.adaptiveCardBorder(context),
          width: TrackletSpacing.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: canDecrement ? () => onChanged(value - step) : null,
            borderRadius: TrackletRadii.roundedXs,
            child: SizedBox(
              width: TrackletSpacing.spacious,
              height: TrackletSpacing.control,
              child: Icon(
                TrackletIcons.minus,
                color:
                    canDecrement
                        ? TrackletColors.adaptiveTextSecondary(context)
                        : TrackletColors.disabled,
                size: 16.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.xs),
            child: Text(
              '$value $displayUnit',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: TrackletColors.adaptiveTextPrimary(context),
              ),
            ),
          ),
          InkWell(
            onTap: canIncrement ? () => onChanged(value + step) : null,
            borderRadius: TrackletRadii.roundedXs,
            child: SizedBox(
              width: TrackletSpacing.spacious,
              height: TrackletSpacing.control,
              child: Icon(
                TrackletIcons.plus,
                color:
                    canIncrement
                        ? (isDark
                            ? TrackletColors.primaryDark
                            : TrackletColors.primary)
                        : TrackletColors.disabled,
                size: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
