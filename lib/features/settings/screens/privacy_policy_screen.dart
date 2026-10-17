import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Fullscreen Privacy Policy screen for NITC Tracklet.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

    return Scaffold(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        foregroundColor: TrackletColors.adaptiveTextPrimary(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(TrackletIcons.chevronLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Privacy Policy',
          style: TrackletFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.screenMargin,
          vertical: TrackletSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TrackletSpacing.lg),
              decoration: BoxDecoration(
                color: TrackletColors.adaptiveSurface(context),
                borderRadius: TrackletRadii.roundedCard,
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TrackletColors.secondary.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          TrackletIcons.shield,
                          color: TrackletColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BusTracker Privacy Policy',
                              style: TrackletFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: TrackletColors.adaptiveTextPrimary(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your Privacy Matters • On-Device First',
                              style: TrackletFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TrackletSpacing.md),
                  Text(
                    'BusTracker is designed with privacy-by-design principles for NIT Calicut campus transit. We do not sell personal information, and rider locations are processed exclusively on your device.',
                    style: TrackletFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.lg),

            // Callout: On-Device Location vs Bus Telemetry
            Container(
              width: double.infinity,
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
                    size: 22,
                    color:
                        isDark
                            ? TrackletColors.velvetSky
                            : TrackletColors.permissionBlueIcon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important: Rider Location vs. Bus Telemetry',
                          style: TrackletFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? TrackletColors.darkTextPrimary
                                    : TrackletColors.altPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live tracking on the map represents official NITC transit buses equipped with hardware trackers. Your personal phone coordinates are NEVER uploaded, logged, or visible to drivers, admins, or other students.',
                          style: TrackletFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            color:
                                isDark
                                    ? TrackletColors.darkTextSecondary
                                    : TrackletColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.lg),

            _buildSection(
              context,
              title: '1. Information We Collect',
              content:
                  '• Academic Profile: Display name, username, official NITC institute email (@nitc.ac.in), branch of study, batch year, and assigned campus hostel.\n\n• Commute Preferences: Selected boarding stop, favorite stops, and interface theme choices.\n\n• On-Device Location: When permitted, device coordinates are read temporarily by your phone solely to compute walking distance to nearest stops. Coordinates are immediately discarded and never sent to our servers.',
            ),
            _buildSection(
              context,
              title: '2. How Information is Used',
              content:
                  'We utilize stored profile and preference information strictly to:\n• Personalize your campus transit dashboard and arrival timelines.\n• Validate student enrollment within the NIT Calicut ecosystem.\n• Prevent abusive or unauthorized access to campus transit servers.',
            ),
            _buildSection(
              context,
              title: '3. Data Security & Storage',
              content:
                  'All backend communication utilizes TLS encryption. User records are hosted in Supabase PostgreSQL protected by Row Level Security (RLS) policies, ensuring each student may only read or edit their own authenticated profile.',
            ),
            _buildSection(
              context,
              title: '4. Third Parties & Zero Commercial Tracking',
              content:
                  'BusTracker is a free academic utility for the NIT Calicut community. We do not use third-party behavioral ad trackers, do not sell user data to data brokers, and do not track users outside the campus transit purview.',
            ),
            _buildSection(
              context,
              title: '5. Account Control & Permanent Deletion',
              content:
                  'You possess absolute control over your information. At any point, you may update your profile or permanently delete your account directly inside Settings via "Delete Account". Account deletion instantaneously and irreversibly purges your student profile and preferences from our database.',
            ),
            _buildSection(
              context,
              title: '6. Policy Updates',
              content:
                  'Any updates to this Privacy Policy will be posted here with an updated revision date. Substantial policy changes will be highlighted within the app settings.',
            ),
            const SizedBox(height: TrackletSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TrackletSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TrackletSpacing.lg),
        decoration: BoxDecoration(
          color: TrackletColors.adaptiveSurface(context),
          borderRadius: TrackletRadii.roundedCard,
          border: Border.all(color: TrackletColors.adaptiveBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TrackletFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TrackletColors.adaptiveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TrackletFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
