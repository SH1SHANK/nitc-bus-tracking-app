import 'package:flutter/material.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Interactive row item matching Attendrix list item typography, spacing, and switch / chevron alignment.
class SettingsRowItem extends StatelessWidget {
  const SettingsRowItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leadingIcon,
    this.leadingIconColor,
    this.titleColor,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.showChevron = false,
    this.hasSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.padding = const EdgeInsets.symmetric(
      horizontal: TrackletSpacing.lg,
      vertical: TrackletSpacing.md,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? titleColor;
  final Widget? trailing;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool hasSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget? leftWidget = icon;
    if (leftWidget == null && leadingIcon != null) {
      leftWidget = Container(
        width: TrackletSpacing.icon,
        height: TrackletSpacing.icon,
        decoration: BoxDecoration(
          color: (leadingIconColor ?? TrackletColors.primary).withValues(
            alpha: 0.1,
          ),
          borderRadius: TrackletRadii.roundedSm,
        ),
        alignment: Alignment.center,
        child: Icon(
          leadingIcon,
          color: leadingIconColor ?? TrackletColors.primary,
          size: 20.0,
        ),
      );
    }

    Widget rightWidget;
    if (hasSwitch) {
      rightWidget = Switch.adaptive(
        value: switchValue,
        onChanged: onSwitchChanged,
        activeTrackColor: TrackletColors.primary,
        activeThumbColor: TrackletColors.textInverse,
      );
    } else if (trailing != null) {
      rightWidget = trailing!;
    } else if (trailingText != null) {
      rightWidget = Text(
        trailingText!,
        style: TrackletFonts.outfit(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: TrackletColors.primary,
        ),
      );
    } else if (showChevron) {
      rightWidget = const Icon(
        Icons.chevron_right_rounded,
        color: TrackletColors.textSecondary,
        size: 22.0,
      );
    } else {
      rightWidget = const SizedBox.shrink();
    }

    final rowContent = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (leftWidget != null) ...[
                  leftWidget,
                  const SizedBox(width: TrackletSpacing.md),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TrackletTypography.bodyMedium.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color:
                              titleColor ??
                              TrackletColors.adaptiveTextPrimary(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: TrackletSpacing.xxs),
                        Text(
                          subtitle!,
                          style: TrackletTypography.bodySmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: TrackletColors.adaptiveTextSecondary(
                              context,
                            ),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TrackletSpacing.sm),
          rightWidget,
        ],
      ),
    );

    if (onTap != null && !hasSwitch) {
      return InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: TrackletRadii.roundedSm,
        child: rowContent,
      );
    }

    return rowContent;
  }
}
