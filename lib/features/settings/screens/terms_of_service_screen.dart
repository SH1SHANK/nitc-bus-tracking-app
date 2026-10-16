import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Fullscreen Terms of Service screen for NITC Tracklet.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Terms of Service',
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
                borderRadius: BorderRadius.circular(TrackletRadii.card),
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
                          color: TrackletColors.primary.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: TrackletColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracklet Terms of Service',
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
                              'Effective: October 2026 • NIT Calicut Transit',
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
                    'Please review these terms governing the use of Tracklet, the dedicated campus bus tracking system for the National Institute of Technology Calicut community.',
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

            _buildSection(
              context,
              number: '1',
              title: 'Acceptance of Terms',
              content:
                  'By accessing or using Tracklet ("the App"), you agree to be bound by these Terms of Service. If you do not agree to all terms, you may not access or use the application.',
            ),
            _buildSection(
              context,
              number: '2',
              title: 'Campus Transit Services & Realtime Data',
              content:
                  'Tracklet is an internal transit utility designed for students, faculty, staff, and visitors of NIT Calicut. Bus timings, live GPS positions, route progression, and arrival estimates are generated via onboard tracking hardware and predictive models. Transit data is subject to operational changes, weather conditions, campus roadworks, and driver schedules.',
            ),
            _buildSection(
              context,
              number: '3',
              title: 'User Accounts & Academic Identity',
              content:
                  'Registered student accounts require authentication with an official @nitc.ac.in email address. You are responsible for maintaining the confidentiality of your credentials and for all actions taken under your account.',
            ),
            _buildSection(
              context,
              number: '4',
              title: 'On-Device Location & Privacy',
              content:
                  'Your personal GPS location is processed strictly on-device to determine nearby bus stops and walking times. Rider coordinates are never transmitted to, recorded by, or stored on our servers. Live tracking refers strictly to transit buses, not riders.',
            ),
            _buildSection(
              context,
              number: '5',
              title: 'Acceptable Use & Network Integrity',
              content:
                  'Users agree not to disrupt telemetry endpoints, reverse-engineer proprietary APIs, flood system resources, or submit fraudulent transit reports. Violation of network integrity rules may result in immediate account revocation.',
            ),
            _buildSection(
              context,
              number: '6',
              title: 'Limitation of Liability',
              content:
                  'Tracklet is provided on an "as-is" and "as-available" basis without warranties of any kind. Tracklet, NIT Calicut, and project contributors shall not be liable for missed classes, transit delays, or schedule discrepancies resulting from reliance on the application.',
            ),
            _buildSection(
              context,
              number: '7',
              title: 'Modifications & Inquiries',
              content:
                  'We reserve the right to revise these terms to reflect campus transit operational updates. For questions regarding these terms, reach out via the official campus transit administration.',
            ),
            const SizedBox(height: TrackletSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
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
          borderRadius: BorderRadius.circular(TrackletRadii.card),
          border: Border.all(color: TrackletColors.adaptiveBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    number,
                    style: TrackletFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TrackletFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                ),
              ],
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
