import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/motion.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Accessible, segmented theme selector for System, Light, and Dark modes.
class SettingsThemeSelector extends StatelessWidget {
  const SettingsThemeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
    this.enableHaptics = true,
  });

  final String selectedMode;
  final ValueChanged<String> onChanged;
  final bool enableHaptics;

  static const List<({String key, String label, IconData icon})> _modes = [
    (key: 'System', label: 'System', icon: Icons.brightness_auto_rounded),
    (key: 'Light', label: 'Light', icon: Icons.light_mode_rounded),
    (key: 'Dark', label: 'Dark', icon: Icons.dark_mode_rounded),
  ];

  void _handleSelect(String mode) {
    if (mode == selectedMode) return;
    if (enableHaptics) {
      HapticFeedback.selectionClick();
    }
    onChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final containerBg =
        isDark
            ? TrackletColors.darkSurfaceElevated
            : TrackletColors.surfaceElevated;
    final borderColor =
        isDark ? TrackletColors.darkBorder : TrackletColors.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: TrackletRadii.roundedLg,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(TrackletSpacing.xs),
      child: Row(
        children:
            _modes.map((mode) {
              final isSelected = mode.key == selectedMode;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${mode.label} theme mode',
                  child: InkWell(
                    onTap: () => _handleSelect(mode.key),
                    borderRadius: TrackletRadii.roundedMd,
                    child: AnimatedContainer(
                      duration:
                          disableAnimations
                              ? Duration.zero
                              : TrackletMotion.adaptiveDuration(
                                context,
                                TrackletMotion.fast,
                              ),
                      curve: TrackletMotion.standardCurve,
                      constraints: const BoxConstraints(minHeight: 44.0),
                      padding: const EdgeInsets.symmetric(
                        vertical: TrackletSpacing.compactMd,
                        horizontal: TrackletSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? TrackletColors.primary
                                : Colors.transparent,
                        borderRadius: TrackletRadii.roundedMd,
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: TrackletColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mode.icon,
                            size: 16.0,
                            color:
                                isSelected
                                    ? TrackletColors.textInverse
                                    : TrackletColors.adaptiveTextSecondary(
                                      context,
                                    ),
                          ),
                          const SizedBox(width: TrackletSpacing.xs),
                          Text(
                            mode.label,
                            style: TrackletTypography.labelMedium.copyWith(
                              fontSize: TrackletTypography.fontSize13,
                              fontWeight:
                                  isSelected
                                      ? TrackletTypography.weightSemiBold
                                      : TrackletTypography.weightMedium,
                              color:
                                  isSelected
                                      ? TrackletColors.textInverse
                                      : TrackletColors.adaptiveTextPrimary(
                                        context,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
