import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

import '../../../data/preferences/user_preferences.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../services/notifications/notification_service.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_row_item.dart';
import '../widgets/settings_stepper.dart';

/// Screen for fine-grained transit notification and alert preferences.
/// Modeled after Attendrix's ManageNotificationsWidget.
class ManageNotificationsScreen extends ConsumerWidget {
  const ManageNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: TrackletColors.background,
      appBar: AppBar(
        backgroundColor: TrackletColors.textInverse,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TrackletColors.textPrimary,
            size: 24.0,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Notifications',
          style: TrackletFonts.outfit(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
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
              Text(
                'Transit Notifications & Alerts',
                style: TrackletFonts.outfit(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: TrackletColors.textSecondary,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              // Master Opt-In Card
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Push Notifications',
                      subtitle:
                          'Allow Tracklet to send transit updates to this device',
                      leadingIcon: Icons.notifications_active_rounded,
                      leadingIconColor: TrackletColors.primary,
                      hasSwitch: true,
                      switchValue: prefs.notificationsEnabled,
                      onSwitchChanged: (bool val) async {
                        await prefsNotifier.toggleNotifications(val);
                        if (val) {
                          await ref.read(notificationServiceProvider).optIn();
                        } else {
                          await ref.read(notificationServiceProvider).optOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),

              if (!prefs.notificationsEnabled) ...[
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.md),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.08),
                    borderRadius: TrackletRadii.roundedCard,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: TrackletColors.primary,
                        size: 20.0,
                      ),
                      SizedBox(width: TrackletSpacing.compactMd),
                      Expanded(
                        child: Text(
                          'Push notifications are disabled. Enable the master toggle above to customize individual alert categories.',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13.0,
                            color: TrackletColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (prefs.notificationsEnabled) ...[
                Text(
                  'Live Bus & Arrival Alerts',
                  style: TrackletFonts.outfit(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: TrackletColors.textSecondary,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                SettingsCard(
                  child: Column(
                    children: [
                      SettingsRowItem(
                        title: 'Bus Arrival Alerts',
                        subtitle:
                            'Alert me when a bus is nearing my favorite stop',
                        leadingIcon: Icons.directions_bus_rounded,
                        leadingIconColor: TrackletColors.primary,
                        hasSwitch: true,
                        switchValue: prefs.busArrivalAlerts,
                        onSwitchChanged:
                            (bool val) =>
                                prefsNotifier.toggleBusArrivalAlerts(val),
                      ),
                      if (prefs.busArrivalAlerts) ...[
                        const Divider(
                          height: 1,
                          color: TrackletColors.background,
                        ),
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
                                    'Alert Lead Time',
                                    style: TrackletFonts.outfit(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500,
                                      color: TrackletColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: TrackletSpacing.xxs),
                                  const Text(
                                    'Minutes before bus arrival at stop',
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
                                onChanged:
                                    (int val) =>
                                        prefsNotifier.setAlertLeadTime(val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),

                Text(
                  'Service Disruptions & Schedules',
                  style: TrackletFonts.outfit(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: TrackletColors.textSecondary,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                SettingsCard(
                  child: Column(
                    children: [
                      SettingsRowItem(
                        title: 'Service Disruptions',
                        subtitle:
                            'Breakdowns, weather delays, and traffic notices',
                        leadingIcon: Icons.warning_amber_rounded,
                        leadingIconColor: TrackletColors.warningStrong,
                        hasSwitch: true,
                        switchValue: prefs.disruptionAlerts,
                        onSwitchChanged:
                            (bool val) =>
                                prefsNotifier.toggleDisruptionAlerts(val),
                      ),
                      const Divider(
                        height: 1,
                        color: TrackletColors.background,
                      ),
                      SettingsRowItem(
                        title: 'Schedule Revisions',
                        subtitle:
                            'Holiday timetables and exam period schedules',
                        leadingIcon: Icons.calendar_month_rounded,
                        leadingIconColor: TrackletColors.primary,
                        hasSwitch: true,
                        switchValue: prefs.scheduleChangeAlerts,
                        onSwitchChanged:
                            (bool val) =>
                                prefsNotifier.toggleScheduleChangeAlerts(val),
                      ),
                      const Divider(
                        height: 1,
                        color: TrackletColors.background,
                      ),
                      SettingsRowItem(
                        title: 'Campus Transit Notices',
                        subtitle: 'TKM / Ragam festival shuttle announcements',
                        leadingIcon: Icons.campaign_rounded,
                        leadingIconColor: TrackletColors.primary,
                        hasSwitch: true,
                        switchValue: prefs.campusTransportationNotices,
                        onSwitchChanged:
                            (bool val) => prefsNotifier
                                .setCampusTransportationNotices(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),

                Text(
                  'Do Not Disturb',
                  style: TrackletFonts.outfit(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: TrackletColors.textSecondary,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                SettingsCard(
                  child: Column(
                    children: [
                      SettingsRowItem(
                        title: 'Quiet Hours (10 PM – 6 AM)',
                        subtitle:
                            'Silence non-emergency transit notifications at night',
                        leadingIcon: Icons.bedtime_rounded,
                        leadingIconColor: TrackletColors.primary,
                        hasSwitch: true,
                        switchValue: prefs.quietHoursEnabled,
                        onSwitchChanged:
                            (bool val) => prefsNotifier.toggleQuietHours(val),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TrackletSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
