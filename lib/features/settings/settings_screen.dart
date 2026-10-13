import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/tokens/tracklet_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/preferences/user_preferences.dart';
import '../../data/profile/profile.dart';
import '../../data/transit/transit_repository.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/location/location_service.dart';
import '../../services/notifications/notification_service.dart';
import '../auth/providers/auth_provider.dart';
import '../profile/providers/profile_provider.dart';
import 'dialogs/change_display_name_dialog.dart';
import 'dialogs/change_password_dialog.dart';
import 'dialogs/delete_account_dialog.dart';
import 'dialogs/favorite_route_picker_dialog.dart';
import 'dialogs/favorite_stop_picker_dialog.dart';
import 'dialogs/legal_content_dialog.dart';
import 'dialogs/transit_faq_dialog.dart';
import 'screens/manage_notifications_screen.dart';
import 'widgets/settings_card.dart';
import 'widgets/settings_choice_chips.dart';
import 'widgets/settings_row_item.dart';
import 'widgets/settings_stepper.dart';

/// Complete, production-ready Settings Screen for Tracklet.
/// Adheres strictly to Attendrix design language, spacing, tokens, typography, and card hierarchy.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh location permission status when settings page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationStateProvider.notifier).refreshLocationIfPermitted();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationStateProvider.notifier).refreshPermission();
      ref.read(locationStateProvider.notifier).refreshLocationIfPermitted();
    }
  }

  void _showWebLocationHelpDialog() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: TrackletColors.textInverse,
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.sm),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.1),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: TrackletColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Browser Location Access',
                  style: TrackletFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'To grant location permission in your browser:\n\n'
              '1. Click the lock or settings icon next to the URL in your browser address bar.\n'
              '2. Set "Location" to "Allow".\n'
              '3. Refresh the page or tap "Refresh GPS Status".',
              style: TrackletFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: TrackletColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Got It',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TrackletColors.success,
        content: Text(
          message,
          style: TrackletFonts.outfit(
            color: TrackletColors.textInverse,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TrackletColors.primary,
        content: Text(
          message,
          style: TrackletFonts.outfit(
            color: TrackletColors.textInverse,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchEmail(String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'transport@nitc.ac.in',
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showInfoSnackBar('Contact: transport@nitc.ac.in');
      }
    } catch (_) {
      _showInfoSnackBar('Contact: transport@nitc.ac.in');
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.textInverse,
            title: Row(
              children: [
                Container(
                  width: TrackletSpacing.icon,
                  height: TrackletSpacing.icon,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: TrackletColors.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                Text(
                  'Log Out',
                  style: TrackletFonts.outfit(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to log out of Tracklet on this device?',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14.0,
                color: TrackletColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: TrackletColors.textInverse,
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Log Out',
                  style: TrackletFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
      } catch (_) {}
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showExportPreferencesDialog(UserPreferences prefs) {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(prefs.toJson());
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.textInverse,
            title: Text(
              'Exported Preferences',
              style: TrackletFonts.outfit(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: TrackletColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(TrackletSpacing.md),
                  decoration: const BoxDecoration(
                    color: TrackletColors.background,
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: SelectableText(
                    jsonString,
                    style: TrackletFonts.robotoMono(
                      fontSize: 12.0,
                      color: TrackletColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Preferences copied to clipboard');
                },
                child: Text(
                  'Copy to Clipboard',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: TrackletColors.textInverse,
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: TrackletFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStateProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);
    final locationState = ref.watch(locationStateProvider);

    final profile =
        profileAsync.value ??
        const Profile(
          id: 'user-nitc-student',
          name: 'Shashank Mergu',
          email: 'shashank@nitc.ac.in',
          rollNumber: 'B210000CS',
          semester: 'Semester 6',
          branch: 'Computer Science & Engineering',
          batch: '2026',
          hostel: 'MBH II',
        );

    return Scaffold(
      backgroundColor: TrackletColors.background,
      appBar: AppBar(
        backgroundColor: TrackletColors.textInverse,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: Text(
          'App Settings',
          style: TrackletFonts.outfit(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: TrackletColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: TrackletSpacing.lg,
            vertical: TrackletSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // SECTION 1: STUDENT PROFILE & ACADEMIC CARD
              // ==========================================
              _buildSectionHeader('Student Profile'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                padding: const EdgeInsets.all(TrackletSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: TrackletSpacing.avatar,
                          height: TrackletSpacing.avatar,
                          decoration: const BoxDecoration(
                            color: TrackletColors.primary,
                            borderRadius: TrackletRadii.roundedFull,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name
                                    .trim()
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : 'ST',
                            style: TrackletFonts.outfit(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: TrackletColors.textInverse,
                            ),
                          ),
                        ),
                        const SizedBox(width: TrackletSpacing.compactLg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      profile.name,
                                      style: TrackletFonts.outfit(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: TrackletColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap:
                                        () => ChangeDisplayNameDialog.show(
                                          context,
                                        ),
                                    borderRadius: TrackletRadii.roundedFull,
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        TrackletSpacing.compact,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: TrackletColors.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 16.0,
                                        color: TrackletColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: TrackletSpacing.xxs),
                              Text(
                                profile.email,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 13.0,
                                  color: TrackletColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (profile.rollNumber != null) ...[
                                const SizedBox(height: TrackletSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: TrackletSpacing.sm,
                                    vertical: TrackletSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6F61EF,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: TrackletRadii.roundedXs,
                                  ),
                                  child: Text(
                                    profile.rollNumber!,
                                    style: TrackletFonts.robotoMono(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: TrackletColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TrackletSpacing.compactLg),
                    const Divider(height: 1, color: TrackletColors.background),
                    const SizedBox(height: TrackletSpacing.md),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildAcademicPill(
                          icon: Icons.school_rounded,
                          label: profile.semester,
                        ),
                        _buildAcademicPill(
                          icon: Icons.account_tree_rounded,
                          label: profile.branch,
                        ),
                        _buildAcademicPill(
                          icon: Icons.calendar_today_rounded,
                          label: 'Batch ${profile.batch}',
                        ),
                        _buildAcademicPill(
                          icon: Icons.apartment_rounded,
                          label: profile.hostel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 2: ACCOUNT & SECURITY
              // ==========================================
              _buildSectionHeader('Account & Security'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Edit Display Name',
                      subtitle: profile.name,
                      leadingIcon: Icons.badge_outlined,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => ChangeDisplayNameDialog.show(context),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Change Password',
                      subtitle:
                          'Update your student account security credentials',
                      leadingIcon: Icons.lock_outline_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => ChangePasswordDialog.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 3: COMMUTE PREFERENCES
              // ==========================================
              _buildSectionHeader('Commute Preferences'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Favorite Bus Stop',
                      subtitle:
                          prefs.preferredStopName.isNotEmpty
                              ? prefs.preferredStopName
                              : 'Select primary campus stop',
                      leadingIcon: Icons.location_on_outlined,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.compactMd,
                          vertical: TrackletSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6F61EF,
                          ).withValues(alpha: 0.08),
                          borderRadius: TrackletRadii.roundedSm,
                        ),
                        child: Text(
                          prefs.preferredStopName.isNotEmpty
                              ? prefs.preferredStopName
                              : 'Not Set',
                          style: TrackletFonts.outfit(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.primary,
                          ),
                        ),
                      ),
                      onTap: () async {
                        final selectedStop =
                            await FavoriteStopPickerDialog.show(
                              context,
                              selectedStopId: prefs.preferredStopId,
                            );
                        if (selectedStop != null) {
                          await prefsNotifier.setPreferredStop(
                            selectedStop.id,
                            selectedStop.name,
                          );
                          if (prefs.hapticFeedbackEnabled) {
                            unawaited(HapticFeedback.selectionClick());
                          }
                          _showSuccessSnackBar(
                            'Favorite stop set to ${selectedStop.name}',
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Favorite Route',
                      subtitle:
                          prefs.preferredRouteName.isNotEmpty
                              ? prefs.preferredRouteName
                              : 'Select preferred campus route',
                      leadingIcon: Icons.alt_route_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.compactMd,
                          vertical: TrackletSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF39D2C0,
                          ).withValues(alpha: 0.12),
                          borderRadius: TrackletRadii.roundedSm,
                        ),
                        child: Text(
                          prefs.preferredRouteName.isNotEmpty
                              ? prefs.preferredRouteName
                              : 'Not Set',
                          style: TrackletFonts.outfit(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.success,
                          ),
                        ),
                      ),
                      onTap: () async {
                        final selectedRoute =
                            await FavoriteRoutePickerDialog.show(
                              context,
                              selectedRouteId: prefs.preferredRouteId,
                            );
                        if (selectedRoute != null) {
                          await prefsNotifier.setPreferredRoute(
                            selectedRoute.id,
                            selectedRoute.name,
                          );
                          if (prefs.hapticFeedbackEnabled) {
                            unawaited(HapticFeedback.selectionClick());
                          }
                          _showSuccessSnackBar(
                            'Favorite route set to ${selectedRoute.name}',
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    Padding(
                      padding: const EdgeInsets.all(TrackletSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transit Time Format',
                                    style: TrackletFonts.outfit(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                      color: TrackletColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: TrackletSpacing.xxs),
                                  const Text(
                                    'Display timetable & arrival predictions',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13.0,
                                      color: TrackletColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TrackletSpacing.sm,
                                  vertical: TrackletSpacing.xs,
                                ),
                                decoration: const BoxDecoration(
                                  color: TrackletColors.background,
                                  borderRadius: TrackletRadii.roundedXs,
                                ),
                                child: Text(
                                  prefs.timeFormat ==
                                          TransitTimeFormat.twelveHour
                                      ? '05:30 PM'
                                      : '17:30',
                                  style: TrackletFonts.robotoMono(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: TrackletColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TrackletSpacing.compactMd),
                          SettingsChoiceChips<String>(
                            options: const [
                              '12-Hour (05:30 PM)',
                              '24-Hour (17:30)',
                            ],
                            selectedOption:
                                prefs.timeFormat == TransitTimeFormat.twelveHour
                                    ? '12-Hour (05:30 PM)'
                                    : '24-Hour (17:30)',
                            onSelected: (String val) {
                              final is12 = val.startsWith('12-Hour');
                              prefsNotifier.setTimeFormat(
                                is12
                                    ? TransitTimeFormat.twelveHour
                                    : TransitTimeFormat.twentyFourHour,
                              );
                              if (prefs.hapticFeedbackEnabled) {
                                unawaited(HapticFeedback.selectionClick());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.lg,
                        vertical: TrackletSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arrival Alert Lead Time',
                                style: TrackletFonts.outfit(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500,
                                  color: TrackletColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: TrackletSpacing.xxs),
                              const Text(
                                'Minutes before bus reaches your stop',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 13.0,
                                  color: TrackletColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SettingsStepper(
                            value: prefs.alertLeadTimeMinutes,
                            min: 2,
                            max: 20,
                            step: 1,
                            unit: 'min',
                            onChanged: (int val) {
                              prefsNotifier.setAlertLeadTime(val);
                              if (prefs.hapticFeedbackEnabled) {
                                unawaited(HapticFeedback.selectionClick());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 4: NOTIFICATIONS
              // ==========================================
              _buildSectionHeader('Notifications'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Push Notifications',
                      subtitle: 'Receive live transit alerts on this device',
                      leadingIcon: Icons.notifications_none_rounded,
                      leadingIconColor: TrackletColors.primary,
                      hasSwitch: true,
                      switchValue: prefs.notificationsEnabled,
                      onSwitchChanged: (bool val) async {
                        await prefsNotifier.toggleNotifications(val);
                        if (prefs.hapticFeedbackEnabled) {
                          unawaited(HapticFeedback.selectionClick());
                        }
                        if (val) {
                          await ref.read(notificationServiceProvider).optIn();
                        } else {
                          await ref.read(notificationServiceProvider).optOut();
                        }
                      },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Manage Transit Notifications',
                      subtitle: 'Arrival alerts, disruptions, and timetables',
                      leadingIcon: Icons.tune_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (context) => const ManageNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 5: LOCATION & PERMISSIONS
              // ==========================================
              _buildSectionHeader('Location & Permissions'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                padding: const EdgeInsets.all(TrackletSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: TrackletSpacing.large,
                              height: TrackletSpacing.large,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6F61EF,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: TrackletColors.primary,
                                size: 22.0,
                              ),
                            ),
                            const SizedBox(width: TrackletSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location Access',
                                  style: TrackletFonts.outfit(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: TrackletColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: TrackletSpacing.xxs),
                                const Text(
                                  'For nearest bus stop detection',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 13.0,
                                    color: TrackletColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildLocationStatusBadge(
                          locationState.permissionState,
                        ),
                      ],
                    ),
                    const SizedBox(height: TrackletSpacing.md),
                    const Text(
                      'Tracklet uses your approximate location exclusively while viewing the campus map to calculate walking distance to nearest stops and show your blue locator dot. Location data never leaves your device.',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12.5,
                        height: 1.45,
                        color: TrackletColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: TrackletSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final service = ref.read(locationServiceProvider);
                          if (locationState.permissionState ==
                              LocationPermissionState.deniedForever) {
                            if (kIsWeb) {
                              _showWebLocationHelpDialog();
                            } else {
                              await service.openAppSettings();
                            }
                            return;
                          }
                          if (locationState.permissionState ==
                              LocationPermissionState.serviceDisabled) {
                            if (kIsWeb) {
                              _showWebLocationHelpDialog();
                            } else {
                              await service.openLocationSettings();
                            }
                            return;
                          }
                          if (locationState.permissionState ==
                              LocationPermissionState.unsupported) {
                            if (kIsWeb) {
                              _showWebLocationHelpDialog();
                            } else {
                              _showInfoSnackBar(
                                'Location is not supported on this platform.',
                              );
                            }
                            return;
                          }

                          await ref
                              .read(locationStateProvider.notifier)
                              .requestAndFetchLocation();
                          final newState = ref.read(locationStateProvider);
                          if (newState.hasPermission) {
                            _showSuccessSnackBar('Location permission granted');
                          } else if (newState.errorMessage != null) {
                            _showInfoSnackBar(newState.errorMessage!);
                          }
                        },
                        icon:
                            locationState.isLoading
                                ? const SizedBox(
                                  width: TrackletSpacing.lg,
                                  height: TrackletSpacing.lg,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: TrackletColors.primary,
                                  ),
                                )
                                : const Icon(
                                  Icons.gps_fixed_rounded,
                                  size: 16.0,
                                ),
                        label: Text(
                          locationState.permissionState ==
                                  LocationPermissionState.deniedForever
                              ? (kIsWeb
                                  ? 'Browser Permission Help'
                                  : 'Open Device Settings')
                              : locationState.permissionState ==
                                  LocationPermissionState.serviceDisabled
                              ? 'Turn On Location (GPS)'
                              : locationState.hasPermission
                              ? 'Refresh GPS Status'
                              : 'Enable Location Access',
                          style: TrackletFonts.outfit(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TrackletColors.primary,
                          side: const BorderSide(color: TrackletColors.primary),
                          shape: const RoundedRectangleBorder(
                            borderRadius: TrackletRadii.roundedSm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: TrackletSpacing.compactMd,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 6: APPEARANCE & MAP DISPLAY
              // ==========================================
              _buildSectionHeader('Appearance & Map Display'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(TrackletSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Preference',
                            style: TrackletFonts.outfit(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                              color: TrackletColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.xxs),
                          const Text(
                            'Choose interface appearance',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 13.0,
                              color: TrackletColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.compactMd),
                          SettingsChoiceChips<String>(
                            options: const ['System', 'Light', 'Dark'],
                            selectedOption: prefs.themeMode,
                            onSelected: (String val) {
                              prefsNotifier.setThemeMode(val);
                              if (prefs.hapticFeedbackEnabled) {
                                unawaited(HapticFeedback.selectionClick());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Haptic Feedback',
                      subtitle:
                          'Tactile vibrations when selecting stops & routes',
                      leadingIcon: Icons.vibration_rounded,
                      leadingIconColor: TrackletColors.primary,
                      hasSwitch: true,
                      switchValue: prefs.hapticFeedbackEnabled,
                      onSwitchChanged: (bool val) {
                        prefsNotifier.toggleHapticFeedback(val);
                        if (val) {
                          HapticFeedback.lightImpact();
                        }
                      },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: '3D Campus Buildings',
                      subtitle:
                          'Render realistic extruded NITC campus structures',
                      leadingIcon: Icons.domain_rounded,
                      leadingIconColor: TrackletColors.primary,
                      hasSwitch: true,
                      switchValue: prefs.map3DBuildingsEnabled,
                      onSwitchChanged: (bool val) {
                        prefsNotifier.toggleMap3DBuildings(val);
                        if (prefs.hapticFeedbackEnabled) {
                          HapticFeedback.selectionClick();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 7: DATA MANAGEMENT & CACHE
              // ==========================================
              _buildSectionHeader('Data Management & Cache'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Sync Transit Schedules',
                      subtitle:
                          _isSyncing
                              ? 'Synchronizing campus routes & timetables...'
                              : 'Fetch latest campus bus routes & timetables',
                      leadingIcon: Icons.sync_rounded,
                      leadingIconColor: TrackletColors.primary,
                      trailing:
                          _isSyncing
                              ? const SizedBox(
                                width: TrackletSpacing.lg,
                                height: TrackletSpacing.lg,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: TrackletColors.primary,
                                ),
                              )
                              : null,
                      onTap:
                          _isSyncing
                              ? null
                              : () async {
                                setState(() => _isSyncing = true);
                                try {
                                  await ref
                                      .read(transitRepositoryProvider)
                                      .getRoutes();
                                  await ref
                                      .read(transitRepositoryProvider)
                                      .getStops();
                                  if (mounted) {
                                    _showSuccessSnackBar(
                                      'Transit schedules synced successfully',
                                    );
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    _showInfoSnackBar(
                                      'Could not sync schedules. Using cached data.',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSyncing = false);
                                  }
                                }
                              },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Clear Cache',
                      subtitle: 'Free local storage and reset map tile buffers',
                      leadingIcon: Icons.cleaning_services_rounded,
                      leadingIconColor: TrackletColors.textSecondary,
                      onTap: () {
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();
                        _showSuccessSnackBar(
                          'Cached map tiles and temporary data cleared',
                        );
                      },
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Export Preferences',
                      subtitle: 'View and export commute configuration JSON',
                      leadingIcon: Icons.file_download_outlined,
                      leadingIconColor: TrackletColors.textSecondary,
                      showChevron: true,
                      onTap: () => _showExportPreferencesDialog(prefs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 8: SUPPORT & FEEDBACK
              // ==========================================
              _buildSectionHeader('Support & Feedback'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Transit FAQ',
                      subtitle:
                          'Common questions about campus buses & tracking',
                      leadingIcon: Icons.help_outline_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => TransitFaqDialog.show(context),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Report Bus / Route Issue',
                      subtitle:
                          'Report delays, incorrect stops, or schedule mismatch',
                      leadingIcon: Icons.report_problem_outlined,
                      leadingIconColor: TrackletColors.warningStrong,
                      showChevron: true,
                      onTap:
                          () => _launchEmail(
                            'Tracklet Issue Report - [Bus / Route]',
                            'Hi Transport Committee,\n\nI noticed an issue with campus transit:\n- Route / Bus: \n- Stop Location: \n- Description:\n\nStudent: ${profile.name} (${profile.rollNumber ?? "N/A"})',
                          ),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Contact Transport Committee',
                      subtitle: 'Email transport@nitc.ac.in',
                      leadingIcon: Icons.mail_outline_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap:
                          () => _launchEmail(
                            'Tracklet Inquiry / Suggestion',
                            'Hi NITC Transport Committee,\n\n',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 9: ABOUT TRACKLET & LEGAL
              // ==========================================
              _buildSectionHeader('About Tracklet & Legal'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'App Version',
                      subtitle: 'v1.0.0 (Build 42)',
                      leadingIcon: Icons.info_outline_rounded,
                      leadingIconColor: TrackletColors.primary,
                      trailing: TextButton(
                        onPressed: () {
                          _showSuccessSnackBar(
                            'Tracklet is up to date (v1.0.0)',
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.compactMd,
                            vertical: TrackletSpacing.xs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Check for updates',
                          style: TrackletFonts.outfit(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Terms of Service',
                      subtitle: 'Guidelines for campus transit tracking usage',
                      leadingIcon: Icons.description_outlined,
                      leadingIconColor: TrackletColors.textSecondary,
                      showChevron: true,
                      onTap:
                          () => LegalContentDialog.showTermsOfService(context),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Privacy Policy',
                      subtitle: 'How student data and location are handled',
                      leadingIcon: Icons.privacy_tip_outlined,
                      leadingIconColor: TrackletColors.textSecondary,
                      showChevron: true,
                      onTap:
                          () => LegalContentDialog.showPrivacyPolicy(context),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Open Source Licenses',
                      subtitle: 'Third-party packages and dependencies',
                      leadingIcon: Icons.code_rounded,
                      leadingIconColor: TrackletColors.textSecondary,
                      showChevron: true,
                      onTap:
                          () => LegalContentDialog.showOpenSourceLibraries(
                            context,
                          ),
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'License',
                      subtitle: 'MIT Open Source License',
                      leadingIcon: Icons.workspace_premium_outlined,
                      leadingIconColor: TrackletColors.textSecondary,
                      showChevron: true,
                      onTap: () => LegalContentDialog.showMitLicense(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 10: ACCOUNT ACTIONS (DESTRUCTIVE)
              // ==========================================
              _buildSectionHeader('Account Actions'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Log Out',
                      subtitle:
                          'Sign out of your student account on this device',
                      leadingIcon: Icons.logout_rounded,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: _showLogoutDialog,
                    ),
                    const Divider(height: 1, color: TrackletColors.background),
                    SettingsRowItem(
                      title: 'Delete My Account',
                      subtitle:
                          'Permanently remove your profile and commute data',
                      leadingIcon: Icons.delete_forever_rounded,
                      leadingIconColor: TrackletColors.absentRed,
                      titleColor: TrackletColors.absentRed,
                      showChevron: true,
                      onTap:
                          () => DeleteAccountDialog.show(
                            context,
                            username: profile.username ?? '',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: TrackletSpacing.xs,
        bottom: TrackletSpacing.xs,
      ),
      child: Text(
        title,
        style: TrackletFonts.outfit(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: TrackletColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildAcademicPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compactMd,
        vertical: TrackletSpacing.compact,
      ),
      decoration: const BoxDecoration(
        color: TrackletColors.background,
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: TrackletColors.primary),
          const SizedBox(width: TrackletSpacing.compact),
          Text(
            label,
            style: TrackletFonts.outfit(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: TrackletColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatusBadge(LocationPermissionState state) {
    final (label, bgColor, fgColor) = switch (state) {
      LocationPermissionState.granted => (
        'Granted',
        TrackletColors.success.withValues(alpha: 0.12),
        TrackletColors.success,
      ),
      LocationPermissionState.denied => (
        'Denied',
        TrackletColors.error.withValues(alpha: 0.12),
        TrackletColors.error,
      ),
      LocationPermissionState.deniedForever => (
        'Blocked',
        TrackletColors.error.withValues(alpha: 0.12),
        TrackletColors.error,
      ),
      LocationPermissionState.serviceDisabled => (
        'Disabled',
        TrackletColors.warningStrong.withValues(alpha: 0.12),
        TrackletColors.warningStrong,
      ),
      LocationPermissionState.unsupported => (
        'Unsupported',
        TrackletColors.textSecondary.withValues(alpha: 0.12),
        TrackletColors.textSecondary,
      ),
      LocationPermissionState.unavailable => (
        'No Fix',
        TrackletColors.warningStrong.withValues(alpha: 0.12),
        TrackletColors.warningStrong,
      ),
      LocationPermissionState.checking => (
        'Checking...',
        TrackletColors.primary.withValues(alpha: 0.12),
        TrackletColors.primary,
      ),
      LocationPermissionState.error => (
        'Error',
        TrackletColors.error.withValues(alpha: 0.12),
        TrackletColors.error,
      ),
      LocationPermissionState.notRequested ||
      LocationPermissionState.unknown => (
        'Not Checked',
        TrackletColors.textSecondary.withValues(alpha: 0.12),
        TrackletColors.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compactMd,
        vertical: TrackletSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Text(
        label,
        style: TrackletFonts.outfit(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}
