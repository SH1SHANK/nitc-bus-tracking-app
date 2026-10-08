import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Combined permissions step in Onboarding: Location & Notifications.
/// Styled according to Attendrix design principles with checkboxes,
/// card containers, and Attendrix buttons.
class OnboardingStepPermissions extends StatefulWidget {
  const OnboardingStepPermissions({
    super.key,
    required this.locationGranted,
    required this.notificationsGranted,
    required this.onEnablePermissions,
    required this.onSkip,
  });

  final bool locationGranted;
  final bool notificationsGranted;
  final Future<void> Function({
    required bool enableLocation,
    required bool enableNotifications,
  })
  onEnablePermissions;
  final VoidCallback onSkip;

  @override
  State<OnboardingStepPermissions> createState() =>
      _OnboardingStepPermissionsState();
}

class _OnboardingStepPermissionsState extends State<OnboardingStepPermissions> {
  late bool _locationSelected;
  late bool _notificationsSelected;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _locationSelected = !widget.locationGranted;
    _notificationsSelected = !widget.notificationsGranted;
  }

  Future<void> _handleGrant() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onEnablePermissions(
        enableLocation: _locationSelected,
        enableNotifications: _notificationsSelected,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        TrackletColors.permissionHeaderGradientStart,
                        TrackletColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: TrackletColors.primary.withValues(alpha: 0.25),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: TrackletColors.pure.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: TrackletColors.pure,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: TrackletColors.pure.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: TrackletColors.pure,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: TrackletSpacing.xl),

          // Title & Subtitle
          Text(
                'Permissions & Access',
                style: TrackletTypography.displayLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.altPrimaryText,
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms, delay: 50.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 6),
          Text(
                'Tracklet gives you real-time NITC transit updates. Select permissions to optimize your experience.',
                style: TrackletTypography.bodyMedium.copyWith(
                  color: TrackletColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: TrackletSpacing.lg),

          // Location Permission Card
          _buildPermissionCard(
                icon: Icons.location_on_rounded,
                iconBg: TrackletColors.permissionBlueBg,
                iconColor: TrackletColors.permissionBlueIcon,
                title: 'Campus Live Location',
                subtitle: 'Locate nearest bus stops, calculate walking ETA, and track live buses around campus.',
                isSelected: _locationSelected,
                isGranted: widget.locationGranted,
                onChanged: widget.locationGranted
                    ? null
                    : (val) => setState(() => _locationSelected = val ?? false),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),

          // Notifications Permission Card
          _buildPermissionCard(
                icon: Icons.notifications_active_rounded,
                iconBg: TrackletColors.permissionPinkBg,
                iconColor: TrackletColors.permissionPinkIcon,
                title: 'Transit & Arrival Alerts',
                subtitle: 'Get notified when your bus is approaching, departures are near, or schedules change.',
                isSelected: _notificationsSelected,
                isGranted: widget.notificationsGranted,
                onChanged: widget.notificationsGranted
                    ? null
                    : (val) =>
                          setState(() => _notificationsSelected = val ?? false),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: TrackletSpacing.xl),

          // Primary Button: Grant Permissions
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
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: TrackletColors.pure,
                      ),
                    )
                  : Text(
                      'Allow Selected Permissions',
                      style: TrackletTypography.titleMedium.copyWith(
                        color: TrackletColors.pure,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          const SizedBox(height: 10),

          // Secondary Ghost Button: Skip for now
          Center(
            child: TextButton(
              onPressed: _isProcessing ? null : widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: TrackletColors.secondaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Skip for now',
                style: TrackletTypography.bodyMedium.copyWith(
                  color: TrackletColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isGranted,
    required ValueChanged<bool?>? onChanged,
  }) {
    return InkWell(
      onTap: isGranted ? null : () => onChanged?.call(!isSelected),
      borderRadius: BorderRadius.circular(TrackletRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TrackletColors.primaryBackground,
          borderRadius: BorderRadius.circular(TrackletRadii.lg),
          border: Border.all(
            color: isSelected
                ? TrackletColors.primary
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
                            color: TrackletColors.altPrimaryText,
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
                            unselectedWidgetColor: TrackletColors.secondaryText,
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
                      color: TrackletColors.secondaryText,
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
