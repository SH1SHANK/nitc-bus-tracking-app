import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../services/location/location_service.dart';
import 'onboarding_entrance.dart';

/// Location permission step in Onboarding.
///
/// Designed to request device location permissions transparently while guaranteeing
/// on-device privacy. Features full dark mode adaptation, OS state awareness,
/// and clear fallbacks for manual stop selection.
class OnboardingStepPermissions extends StatefulWidget {
  const OnboardingStepPermissions({
    super.key,
    required this.locationGranted,
    required this.onEnableLocation,
    required this.onSkip,
    this.permissionState,
    this.onOpenSettings,
  });

  final bool locationGranted;
  final Future<void> Function({required bool enableLocation}) onEnableLocation;
  final VoidCallback onSkip;
  final LocationPermissionState? permissionState;
  final VoidCallback? onOpenSettings;

  @override
  State<OnboardingStepPermissions> createState() =>
      _OnboardingStepPermissionsState();
}

class _OnboardingStepPermissionsState extends State<OnboardingStepPermissions> {
  late bool _locationSelected;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _locationSelected = widget.locationGranted;
  }

  @override
  void didUpdateWidget(covariant OnboardingStepPermissions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locationGranted != oldWidget.locationGranted) {
      _locationSelected = widget.locationGranted;
    }
  }

  Future<void> _handleGrant() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onEnableLocation(enableLocation: _locationSelected);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final isGranted = widget.locationGranted;
    final permState = widget.permissionState;
    final isDeniedForever = permState?.isDeniedForever ?? false;
    final isServiceDisabled = permState?.isServiceDisabled ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.sm),

          // Header Hero Banner
          Center(
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? TrackletColors.darkSurfaceElevated
                        : TrackletColors.primary,
                borderRadius: TrackletRadii.roundedPill,
                boxShadow: [
                  BoxShadow(
                    color: TrackletColors.primary.withValues(
                      alpha: isDark ? 0.35 : 0.25,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TrackletColors.pure.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(
                      TrackletSpacing.cardPaddingLg,
                    ),
                    decoration: BoxDecoration(
                      color: TrackletColors.pure.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      TrackletIcons.mapPin,
                      color: TrackletColors.pure,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
          ).enterOnboarding(context),
          const SizedBox(height: TrackletSpacing.lg),

          // Title & Subtitle
          Text(
            'Permissions & Access',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: TrackletTypography.fontSize24,
              fontWeight: TrackletTypography.weightBold,
              color:
                  isDark
                      ? TrackletColors.darkTextPrimary
                      : TrackletColors.altPrimaryText,
            ),
          ).enterOnboarding(context, delay: 50.ms),
          const SizedBox(height: 6),
          Text(
            'BusTracker uses your location on campus to identify nearby stops and calculate walking times.',
            style: TrackletTypography.bodyMedium.copyWith(
              color:
                  isDark
                      ? TrackletColors.darkTextSecondary
                      : TrackletColors.secondaryText,
              fontSize: TrackletTypography.fontSize14,
              fontWeight: TrackletTypography.weightMedium,
              height: TrackletTypography.lineHeightBody,
            ),
          ).enterOnboarding(context, delay: 90.ms),
          const SizedBox(height: TrackletSpacing.md),

          // Privacy Guarantee Callout Box
          Container(
            padding: const EdgeInsets.all(TrackletSpacing.md),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? TrackletColors.primary.withValues(alpha: 0.12)
                      : TrackletColors.permissionBlueBg,
              borderRadius: TrackletRadii.roundedCard,
              border: Border.all(
                color:
                    isDark
                        ? TrackletColors.primary.withValues(alpha: 0.3)
                        : TrackletColors.permissionBlueIcon.withValues(
                          alpha: 0.2,
                        ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  TrackletIcons.shield,
                  size: 20,
                  color:
                      isDark
                          ? TrackletColors.velvetSky
                          : TrackletColors.permissionBlueIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On-device privacy',
                        style: TrackletTypography.labelMedium.copyWith(
                          color:
                              isDark
                                  ? TrackletColors.darkTextPrimary
                                  : TrackletColors.altPrimaryText,
                          fontWeight: TrackletTypography.weightBold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Location data stays on your device and is never stored or sent to remote servers.',
                        style: TrackletTypography.bodySmall.copyWith(
                          color:
                              isDark
                                  ? TrackletColors.darkTextSecondary
                                  : TrackletColors.secondaryText,
                          fontSize: TrackletTypography.fontSize12,
                          height: TrackletTypography.lineHeightBodyCompact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).enterOnboarding(context, delay: 110.ms),
          const SizedBox(height: TrackletSpacing.md),

          // Location Permission Interactive Card
          _buildPermissionCard(
            context: context,
            icon: TrackletIcons.mapPin,
            iconBg:
                isDark
                    ? TrackletColors.darkSurfaceElevated
                    : TrackletColors.permissionBlueBg,
            iconColor:
                isDark
                    ? TrackletColors.velvetSky
                    : TrackletColors.permissionBlueIcon,
            title: 'Campus Live Location',
            subtitle:
                'Find nearest stops, calculate walking distance, and view buses around campus.',
            isSelected: _locationSelected,
            isGranted: isGranted,
            isDeniedForever: isDeniedForever,
            isServiceDisabled: isServiceDisabled,
            onChanged:
                isGranted
                    ? null
                    : (val) => setState(() => _locationSelected = val ?? false),
          ).enterOnboarding(context, delay: 140.ms),

          // Actionable settings button if blocked
          if (isDeniedForever && widget.onOpenSettings != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onOpenSettings,
                icon: const Icon(TrackletIcons.settings, size: 16),
                label: const Text('Open app settings'),
                style: TextButton.styleFrom(
                  foregroundColor: TrackletColors.primary,
                  textStyle: TrackletTypography.bodySmall.copyWith(
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: TrackletSpacing.xl),

          // Primary Button: Grant Permissions / Continue
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleGrant,
              style: ElevatedButton.styleFrom(
                backgroundColor: TrackletColors.primary,
                foregroundColor: TrackletColors.pure,
                elevation: TrackletShadows.elevationLevel3,
                shadowColor: TrackletColors.primary.withValues(alpha: 0.3),
                shape: const RoundedRectangleBorder(
                  borderRadius: TrackletRadii.roundedCard,
                ),
              ),
              child:
                  _isProcessing
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: TrackletColors.pure,
                        ),
                      )
                      : Text(
                        isGranted
                            ? 'Continue'
                            : _locationSelected
                            ? 'Continue with selected'
                            : 'Continue without permissions',
                        style: TrackletTypography.titleMedium.copyWith(
                          color: TrackletColors.pure,
                          fontWeight: TrackletTypography.weightBold,
                          fontSize: TrackletTypography.fontSize15,
                        ),
                      ),
            ),
          ).enterOnboarding(context, delay: 170.ms),
          const SizedBox(height: 10),

          // Secondary Ghost Button: Skip for now / Manual selection
          Center(
            child: TextButton(
              onPressed: _isProcessing ? null : widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark
                        ? TrackletColors.darkTextSecondary
                        : TrackletColors.secondaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.section,
                  vertical: TrackletSpacing.sm,
                ),
              ),
              child: Text(
                'Skip for now',
                style: TrackletTypography.bodyMedium.copyWith(
                  color:
                      isDark
                          ? TrackletColors.darkTextSecondary
                          : TrackletColors.secondaryText,
                  fontWeight: TrackletTypography.weightSemiBold,
                  fontSize: TrackletTypography.fontSize14,
                ),
              ),
            ),
          ).enterOnboarding(context, delay: 210.ms),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isGranted,
    required bool isDeniedForever,
    required bool isServiceDisabled,
    required ValueChanged<bool?>? onChanged,
  }) {
    final isDark = TrackletColors.isDark(context);

    return InkWell(
      onTap: isGranted ? null : () => onChanged?.call(!isSelected),
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.compactLg),
        decoration: BoxDecoration(
          color:
              isDark
                  ? TrackletColors.darkSurface
                  : TrackletColors.primaryBackground,
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(
            color:
                isSelected
                    ? TrackletColors.primary
                    : isDark
                    ? TrackletColors.darkBorder
                    : TrackletColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: TrackletRadii.roundedCard,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TrackletTypography.titleSmall.copyWith(
                            color:
                                isDark
                                    ? TrackletColors.darkTextPrimary
                                    : TrackletColors.altPrimaryText,
                            fontWeight: TrackletTypography.weightBold,
                            fontSize: TrackletTypography.fontSize15,
                          ),
                        ),
                      ),
                      if (isGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: TrackletColors.permissionGreenBg,
                            borderRadius: TrackletRadii.roundedCompact,
                          ),
                          child: const Text(
                            'Granted',
                            style: TextStyle(
                              color: TrackletColors.permissionGreenText,
                              fontSize: TrackletTypography.fontSize11,
                              fontWeight: TrackletTypography.weightBold,
                            ),
                          ),
                        )
                      else if (isDeniedForever)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: TrackletColors.notificationYellowBg,
                            borderRadius: TrackletRadii.roundedCompact,
                          ),
                          child: const Text(
                            'Blocked',
                            style: TextStyle(
                              color: TrackletColors.notificationAmber,
                              fontSize: TrackletTypography.fontSize11,
                              fontWeight: TrackletTypography.weightBold,
                            ),
                          ),
                        )
                      else if (isServiceDisabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: TrackletColors.notificationYellowBg,
                            borderRadius: TrackletRadii.roundedCompact,
                          ),
                          child: const Text(
                            'GPS Off',
                            style: TextStyle(
                              color: TrackletColors.notificationAmber,
                              fontSize: TrackletTypography.fontSize11,
                              fontWeight: TrackletTypography.weightBold,
                            ),
                          ),
                        )
                      else
                        Theme(
                          data: ThemeData(
                            checkboxTheme: const CheckboxThemeData(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: TrackletRadii.roundedXs,
                              ),
                            ),
                            unselectedWidgetColor:
                                isDark
                                    ? TrackletColors.darkTextSecondary
                                    : TrackletColors.secondaryText,
                          ),
                          child: Checkbox(
                            value: isSelected,
                            activeColor: TrackletColors.primary,
                            checkColor: TrackletColors.pure,
                            onChanged: onChanged,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TrackletTypography.bodySmall.copyWith(
                      color:
                          isDark
                              ? TrackletColors.darkTextSecondary
                              : TrackletColors.secondaryText,
                      fontSize: TrackletTypography.fontSize12_5,
                      fontWeight: TrackletTypography.weightMedium,
                      height: TrackletTypography.lineHeightBodyCompact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
