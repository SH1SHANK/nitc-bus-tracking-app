import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
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

    return Container(
      width: width,
      height: TrackletSpacing.icon,
      padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.xxs),
      decoration: BoxDecoration(
        color: TrackletColors.background,
        borderRadius: TrackletRadii.roundedSm,
        border: Border.all(
          color: TrackletColors.cardBorder,
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
                Icons.remove_rounded,
                color:
                    canDecrement
                        ? TrackletColors.textSecondary
                        : TrackletColors.disabled,
                size: 16.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.xs),
            child: Text(
              '$value $displayUnit',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: TrackletColors.textPrimary,
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
                Icons.add_rounded,
                color:
                    canIncrement
                        ? TrackletColors.primary
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
