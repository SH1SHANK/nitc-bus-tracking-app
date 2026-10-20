import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../services/updates/app_update_service.dart';

/// Modal dialog displaying details about an available GitHub release,
/// release notes, and direct download/update actions.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.updateInfo});

  final AppUpdateInfo updateInfo;

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AppUpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final apkAsset = updateInfo.primaryApkAsset;

    return Dialog(
      backgroundColor: TrackletColors.adaptiveSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedCardLg,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
        vertical: TrackletSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          updateInfo.isUpdateAvailable
                              ? TrackletColors.primary.withValues(alpha: 0.12)
                              : TrackletColors.success.withValues(alpha: 0.12),
                      borderRadius: TrackletRadii.roundedMd,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      updateInfo.isUpdateAvailable
                          ? Icons.system_update_rounded
                          : Icons.check_circle_outline_rounded,
                      color:
                          updateInfo.isUpdateAvailable
                              ? TrackletColors.primary
                              : TrackletColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updateInfo.isUpdateAvailable
                              ? 'Update Available'
                              : 'Up to Date',
                          style: TrackletFonts.outfit(
                            fontSize: TrackletTypography.fontSize18,
                            fontWeight: FontWeight.bold,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          updateInfo.isUpdateAvailable
                              ? 'A newer version of BusTracker is ready'
                              : 'You are running the latest version',
                          style: TrackletTypography.bodySmall.copyWith(
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

              // Version Comparison Card
              Container(
                padding: const EdgeInsets.all(TrackletSpacing.md),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? TrackletColors.darkSurfaceElevated
                          : TrackletColors.surfaceContainer,
                  borderRadius: TrackletRadii.roundedCard,
                  border: Border.all(
                    color: TrackletColors.adaptiveCardBorder(context),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT VERSION',
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize10,
                              fontWeight: TrackletTypography.weightExtraBold,
                              letterSpacing:
                                  TrackletTypography.letterSpacingLabel,
                              color: TrackletColors.adaptiveTextMuted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'v${updateInfo.currentVersion}',
                            style: TrackletFonts.outfit(
                              fontSize: TrackletTypography.fontSize15,
                              fontWeight: TrackletTypography.weightBold,
                              color: TrackletColors.adaptiveTextPrimary(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: TrackletColors.adaptiveTextMuted(context),
                      size: 18,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LATEST RELEASE',
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize10,
                              fontWeight: TrackletTypography.weightExtraBold,
                              letterSpacing:
                                  TrackletTypography.letterSpacingLabel,
                              color:
                                  updateInfo.isUpdateAvailable
                                      ? TrackletColors.primary
                                      : TrackletColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            updateInfo.tagName.startsWith('v')
                                ? updateInfo.tagName
                                : 'v${updateInfo.latestVersion}',
                            style: TrackletFonts.outfit(
                              fontSize: TrackletTypography.fontSize15,
                              fontWeight: TrackletTypography.weightBold,
                              color:
                                  updateInfo.isUpdateAvailable
                                      ? TrackletColors.primary
                                      : TrackletColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              // Release Notes / Body
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'Release Highlights',
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize13,
                    fontWeight: TrackletTypography.weightBold,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xs),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TrackletSpacing.compactMd),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? TrackletColors.darkSurfaceContainer
                              : TrackletColors.background,
                      borderRadius: TrackletRadii.roundedSm,
                      border: Border.all(
                        color: TrackletColors.adaptiveDivider(context),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        updateInfo.releaseNotes,
                        style: TextStyle(
                          fontSize: TrackletTypography.fontSize12,
                          height: TrackletTypography.lineHeightBodyRelaxed,
                          fontFamily: 'monospace',
                          color: TrackletColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.md),
              ],

              // Action Buttons
              if (updateInfo.isUpdateAvailable) ...[
                ElevatedButton.icon(
                  onPressed: () => _handleDownloadAndUpdate(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    apkAsset != null
                        ? 'Download & Install APK (${apkAsset.sizeFormatted})'
                        : 'View Release on GitHub',
                    style: TrackletFonts.outfit(
                      fontWeight: TrackletTypography.weightBold,
                      fontSize: TrackletTypography.fontSize14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrackletColors.primary,
                    foregroundColor: TrackletColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.dialogActionPaddingVertical,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedButton,
                    ),
                    elevation: TrackletShadows.elevationLevel0,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Later',
                    style: TrackletFonts.outfit(
                      color: TrackletColors.adaptiveTextSecondary(context),
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark
                            ? TrackletColors.darkSurfaceElevated
                            : TrackletColors.surfaceContainer,
                    foregroundColor: TrackletColors.adaptiveTextPrimary(
                      context,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.dialogActionPaddingVertical,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedButton,
                    ),
                    elevation: TrackletShadows.elevationLevel0,
                  ),
                  child: Text(
                    'Done',
                    style: TrackletFonts.outfit(
                      fontWeight: TrackletTypography.weightBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadAndUpdate(BuildContext context) async {
    Navigator.of(context).pop();
    final downloadUrl = updateInfo.primaryDownloadUrl ?? updateInfo.htmlUrl;
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
