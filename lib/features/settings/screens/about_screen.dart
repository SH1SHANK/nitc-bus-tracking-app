import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
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
        elevation: TrackletShadows.elevationLevel0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(TrackletIcons.chevronLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'About BusTracker',
          style: TrackletFonts.outfit(
            fontSize: TrackletTypography.fontSize19,
            fontWeight: TrackletTypography.weightBold,
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
                borderRadius: TrackletRadii.roundedCard,
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/branding/bustracker_bus_icon.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: 156,
                  ),
                  const SizedBox(height: TrackletSpacing.md),
                  Image.asset(
                    'assets/branding/bustracker_wordmark.png',
                    height: 28,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    cacheHeight: 84,
                    color: isDark ? TrackletColors.darkTextPrimary : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'BusTracker · NITC campus transit tracking',
                    textAlign: TextAlign.center,
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize13,
                      fontWeight: TrackletTypography.weightSemiBold,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.md,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: TrackletColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.08,
                      ),
                      borderRadius: TrackletRadii.roundedLg,
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
                        fontSize: TrackletTypography.fontSize12_5,
                        fontWeight: TrackletTypography.weightSemiBold,
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
                borderRadius: TrackletRadii.roundedCard,
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus transit',
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize16,
                      fontWeight: TrackletTypography.weightBold,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BusTracker provides campus transit tracking for students, staff, and residents of the National Institute of Technology Calicut. It shows live vehicle locations, estimated arrival times, and campus route maps.',
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize13_5,
                      fontWeight: TrackletTypography.weightRegular,
                      height: TrackletTypography.lineHeightRelaxed,
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
                borderRadius: TrackletRadii.roundedCard,
                border: Border.all(
                  color: TrackletColors.adaptiveBorder(context),
                ),
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    context,
                    icon: TrackletIcons.scale,
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
                    icon: TrackletIcons.shield,
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
                    icon: TrackletIcons.folderGit2,
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
                fontSize: TrackletTypography.fontSize12_5,
                fontWeight: TrackletTypography.weightMedium,
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Built for the NITC campus',
              style: TrackletFonts.outfit(
                fontSize: TrackletTypography.fontSize12,
                fontWeight: TrackletTypography.weightRegular,
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
          fontSize: TrackletTypography.fontSize14_5,
          fontWeight: TrackletTypography.weightSemiBold,
          color: TrackletColors.adaptiveTextPrimary(context),
        ),
      ),
      trailing: Icon(
        TrackletIcons.chevronRight,
        size: 20,
        color: TrackletColors.adaptiveTextMuted(context),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedCard,
      ),
      onTap: onTap,
    );
  }
}
