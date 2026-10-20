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
    final colorScheme = Theme.of(context).colorScheme;
    final animationDuration = TrackletMotion.adaptiveDuration(
      context,
      TrackletMotion.tabSwitch,
    );
    final selectedModeIndex = _modes.indexWhere(
      (mode) => mode.key == selectedMode,
    );
    final selectedIndex = selectedModeIndex < 0 ? 0 : selectedModeIndex;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: TrackletRadii.roundedLg,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
      ),
      padding: const EdgeInsets.all(TrackletSpacing.xs),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                key: const Key('theme-selection-indicator'),
                alignment: Alignment(selectedIndex * 1.0 - 1.0, 0),
                duration: animationDuration,
                curve: TrackletMotion.standardCurve,
                child: FractionallySizedBox(
                  widthFactor: 1 / _modes.length,
                  heightFactor: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: TrackletColors.primary,
                      borderRadius: TrackletRadii.roundedMd,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children:
                  _modes.map((mode) {
                    final isSelected = mode.key == selectedMode;
                    final foreground =
                        isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '${mode.label} theme mode',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleSelect(mode.key),
                            borderRadius: TrackletRadii.roundedMd,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.08 : 1,
                                    duration: animationDuration,
                                    curve: TrackletMotion.standardCurve,
                                    child: Icon(
                                      mode.icon,
                                      size: 16,
                                      color: foreground,
                                    ),
                                  ),
                                  const SizedBox(width: TrackletSpacing.xs),
                                  Text(
                                    mode.label,
                                    style: TrackletTypography.labelMedium
                                        .copyWith(
                                          fontSize:
                                              TrackletTypography.fontSize13,
                                          fontWeight:
                                              isSelected
                                                  ? TrackletTypography
                                                      .weightSemiBold
                                                  : TrackletTypography
                                                      .weightMedium,
                                          color: foreground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
