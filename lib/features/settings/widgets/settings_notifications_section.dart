import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../services/notifications/notification_push_state.dart';
import 'settings_card.dart';
import 'settings_row_item.dart';

class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.pushState,
    required this.onPushChanged,
    this.isBusy = false,
  });

  final PushNotificationState pushState;
  final ValueChanged<bool> onPushChanged;
  final bool isBusy;

  String get _pushDescription => switch (pushState) {
    PushNotificationState.checking =>
      'Checking this device’s permission and subscription.',
    PushNotificationState.enabled => 'Enabled on this device',
    PushNotificationState.permissionRequired =>
      'Allow notifications for live bus and service updates.',
    PushNotificationState.permissionDenied =>
      'Blocked in device settings. Allow notifications there to continue.',
    PushNotificationState.registrationPending =>
      'Permission is on; waiting for OneSignal to register this device.',
    PushNotificationState.registrationFailed =>
      'This device could not register. Tap to retry.',
    PushNotificationState.unavailable =>
      'Push notifications are unavailable on this device.',
    PushNotificationState.disabled => 'Off on this device',
  };

  @override
  Widget build(BuildContext context) {
    final canEnable =
        pushState != PushNotificationState.checking &&
        pushState != PushNotificationState.unavailable &&
        pushState != PushNotificationState.registrationPending &&
        !isBusy;

    return SettingsCard(
      child: Column(
        children: [
          SettingsRowItem(
            key: const Key('push-notifications-toggle-row'),
            title: 'Push notifications',
            subtitle:
                isBusy
                    ? 'Requesting permission and registering…'
                    : _pushDescription,
            leadingIcon: TrackletIcons.notifications,
            leadingIconColor: TrackletColors.primary,
            hasSwitch: true,
            switchValue: pushState == PushNotificationState.enabled,
            onSwitchChanged: canEnable ? onPushChanged : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.lg),
            child: Divider(
              height: 1,
              color: TrackletColors.adaptiveBorder(context),
            ),
          ),
          SettingsRowItem(
            key: const Key('live-notifications-toggle-row'),
            title: 'Live notifications',
            subtitle: 'See nearby bus activity at a glance.',
            leadingIcon: TrackletIcons.activity,
            leadingIconColor: TrackletColors.secondary,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.sm,
                    vertical: TrackletSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.adaptiveSurfaceElevated(context),
                    borderRadius: TrackletRadii.roundedPill,
                  ),
                  child: Text(
                    'Coming soon',
                    style: TrackletTypography.labelSmall.copyWith(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xxs),
                const Switch(value: false, onChanged: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
