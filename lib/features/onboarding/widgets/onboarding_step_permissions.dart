import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';
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
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? const [Color(0xFF2C3258), TrackletColors.primary]
                          : const [
                            TrackletColors.permissionHeaderGradientStart,
                            TrackletColors.primary,
                          ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: TrackletColors.pure.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
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
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color:
                  isDark
                      ? TrackletColors.darkTextPrimary
                      : TrackletColors.altPrimaryText,
            ),
          ).enterOnboarding(context, delay: 50.ms),
          const SizedBox(height: 6),
          Text(
            'Tracklet uses your location exclusively on campus to identify nearby stops and calculate walking times.',
            style: TrackletTypography.bodyMedium.copyWith(
              color:
                  isDark
                      ? TrackletColors.darkTextSecondary
                      : TrackletColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ).enterOnboarding(context, delay: 90.ms),
          const SizedBox(height: TrackletSpacing.md),

          // Privacy Guarantee Callout Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? TrackletColors.primary.withValues(alpha: 0.12)
                      : TrackletColors.permissionBlueBg,
              borderRadius: BorderRadius.circular(TrackletRadii.md),
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
                  Icons.shield_outlined,
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
                        '100% On-Device Privacy',
                        style: TrackletTypography.labelMedium.copyWith(
                          color:
                              isDark
                                  ? TrackletColors.darkTextPrimary
                                  : TrackletColors.altPrimaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your coordinates are never sent to our servers or stored. Location data stays strictly on your device.',
                        style: TrackletTypography.bodySmall.copyWith(
                          color:
                              isDark
                                  ? TrackletColors.darkTextSecondary
                                  : TrackletColors.secondaryText,
                          fontSize: 12,
                          height: 1.35,
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
            icon: Icons.location_on_rounded,
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
                'Locate nearest bus stops, calculate walking distance, and track live buses around campus.',
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
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Open App Settings'),
                style: TextButton.styleFrom(
                  foregroundColor: TrackletColors.primary,
                  textStyle: TrackletTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
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
                elevation: 3,
                shadowColor: TrackletColors.primary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TrackletRadii.card),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Skip for now',
                style: TrackletTypography.bodyMedium.copyWith(
                  color:
                      isDark
                          ? TrackletColors.darkTextSecondary
                          : TrackletColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
      borderRadius: BorderRadius.circular(TrackletRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isDark
                  ? TrackletColors.darkSurface
                  : TrackletColors.primaryBackground,
          borderRadius: BorderRadius.circular(TrackletRadii.lg),
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
                borderRadius: BorderRadius.circular(TrackletRadii.card),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.permissionGreenBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Granted',
                            style: TextStyle(
                              color: TrackletColors.permissionGreenText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (isDeniedForever)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.notificationYellowBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Blocked',
                            style: TextStyle(
                              color: TrackletColors.notificationAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (isServiceDisabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.notificationYellowBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GPS Off',
                            style: TextStyle(
                              color: TrackletColors.notificationAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Theme(
                          data: ThemeData(
                            checkboxTheme: CheckboxThemeData(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  TrackletRadii.xs,
                                ),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
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
