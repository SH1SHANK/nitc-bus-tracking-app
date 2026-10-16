import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Fullscreen About Tracklet screen displaying application metadata,
/// campus transit provenance, and legal links.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version.isNotEmpty ? info.version : '1.0.0';
          _buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : '1';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
          'About Tracklet',
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
          children: [
            const SizedBox(height: TrackletSpacing.md),

            // Hero Brand Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: TrackletSpacing.xl,
                horizontal: TrackletSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: TrackletColors.adaptiveSurface(context),
                borderRadius: BorderRadius.circular(TrackletRadii.card),
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
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
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: TrackletColors.pure,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.md),
                  Text(
                    'Tracklet',
                    style: TrackletFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NITC Campus Public Transit Tracking',
                    style: TrackletFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: TrackletColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TrackletColors.primary.withValues(
                          alpha: isDark ? 0.4 : 0.2,
                        ),
                      ),
                    ),
                    child: Text(
                      _isLoading
                          ? 'Checking version...'
                          : 'Version $_version (Build $_buildNumber)',
                      style: TrackletFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: TrackletColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.lg),

            // Mission / Provenance
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
                  Text(
                    'Campus Transit Utility',
                    style: TrackletFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tracklet is an official campus mobility platform developed specifically for the students, faculty, and residents of the National Institute of Technology Calicut.\n\nFeaturing live GPS vehicle positions, arrival timeline calculations, and interactive transit cartography grounded in OpenStreetMap.',
                    style: TrackletFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.lg),

            // Navigation Links Card
            Container(
              decoration: BoxDecoration(
                color: TrackletColors.adaptiveSurface(context),
                borderRadius: BorderRadius.circular(TrackletRadii.card),
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    context,
                    icon: Icons.gavel_rounded,
                    title: 'Terms of Service',
                    onTap: () => context.push('/terms'),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: TrackletColors.adaptiveBorder(context),
                  ),
                  _buildNavTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => context.push('/privacy'),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: TrackletColors.adaptiveBorder(context),
                  ),
                  _buildNavTile(
                    context,
                    icon: Icons.source_outlined,
                    title: 'Open Source Licenses',
                    onTap: () => context.push('/licenses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TrackletSpacing.xl),

            // Footer
            Text(
              '© 2026 National Institute of Technology Calicut',
              style: TrackletFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crafted for the NITC Commute',
              style: TrackletFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
            const SizedBox(height: TrackletSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: TrackletColors.adaptiveTextSecondary(context),
      ),
      title: Text(
        title,
        style: TrackletFonts.outfit(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: TrackletColors.adaptiveTextPrimary(context),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: TrackletColors.textTertiary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TrackletRadii.card),
      ),
      onTap: onTap,
    );
  }
}
