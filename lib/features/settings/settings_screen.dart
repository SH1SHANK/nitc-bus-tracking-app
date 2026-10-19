import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/tokens/tracklet_fonts.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:url_launcher/url_launcher.dart';

import '../../data/preferences/user_preferences.dart';
import '../../data/profile/profile.dart';
import '../../design_system/components/voxel_avatar.dart';
import '../../design_system/components/tracklet_snack_bar.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../services/location/location_service.dart';
import '../auth/providers/auth_provider.dart';
import '../profile/dialogs/avatar_picker_sheet.dart';
import '../profile/providers/profile_provider.dart';
import 'dialogs/change_display_name_dialog.dart';
import 'dialogs/change_password_dialog.dart';
import 'dialogs/change_username_dialog.dart';
import 'dialogs/delete_account_dialog.dart';
import 'dialogs/transit_faq_dialog.dart';
import 'widgets/settings_card.dart';
import 'widgets/settings_row_item.dart';
import 'widgets/settings_theme_selector.dart';

/// Complete, production-ready Settings Screen for Tracklet.
/// Adheres strictly to Attendrix design language, spacing, tokens, typography, and card hierarchy.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
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
            backgroundColor: TrackletColors.adaptiveSurface(ctx),
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
                    TrackletIcons.globe,
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
                    color: TrackletColors.adaptiveTextPrimary(ctx),
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
                color: TrackletColors.adaptiveTextSecondary(ctx),
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
    TrackletSnackBar.showSuccess(context, message);
  }

  void _showInfoSnackBar(String message) {
    TrackletSnackBar.showInfo(context, message);
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
    final isGuest = ref.read(authNotifierProvider).isGuest;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.adaptiveSurface(ctx),
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
                    TrackletIcons.logOut,
                    color: TrackletColors.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                Text(
                  isGuest ? 'Exit Guest Session' : 'Log Out',
                  style: TrackletFonts.outfit(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.adaptiveTextPrimary(ctx),
                  ),
                ),
              ],
            ),
            content: Text(
              isGuest
                  ? 'Are you sure you want to exit your guest session? You can return to guest mode or sign in with your student account anytime.'
                  : 'Are you sure you want to log out of BusTracker on this device?',
              style: TrackletTypography.bodyMedium.copyWith(
                color: TrackletColors.adaptiveTextSecondary(ctx),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.adaptiveTextSecondary(ctx),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: TrackletColors.textInverse,
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isGuest ? 'Exit Guest Mode' : 'Log Out',
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileAsync = ref.watch(profileStateProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);
    final locationState = ref.watch(locationStateProvider);

    final bool isGuest =
        authState.isGuest || profileAsync.value?.role == 'Guest';

    final profile =
        profileAsync.value ??
        (isGuest
            ? const Profile(
              id: 'guest',
              name: 'Guest Rider',
              email: '',
              role: 'Guest',
              hasCompletedOnboarding: true,
            )
            : const Profile(
              id: 'user-nitc-student',
              name: 'Shashank Mergu',
              email: 'shashank@nitc.ac.in',
              rollNumber: 'B210000CS',
              semester: 'Semester 6',
              branch: 'Computer Science & Engineering',
              batch: '2026',
              hostel: 'MBH II',
            ));

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        appBar: AppBar(
          backgroundColor: TrackletColors.adaptiveBackground(context),
          foregroundColor: TrackletColors.adaptiveTextPrimary(context),
          elevation: 0.0,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            icon: const Icon(TrackletIcons.chevronLeft, size: 22),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            'App Settings',
            style: TrackletFonts.outfit(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: TrackletColors.adaptiveTextPrimary(context),
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
              // SECTION 1: STUDENT / GUEST PROFILE CARD
              // ==========================================
              _buildSectionHeader(
                isGuest ? 'Guest Profile' : 'Student Profile',
              ),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                padding: const EdgeInsets.all(TrackletSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap:
                              () => AvatarPickerSheet.show(
                                context,
                                currentSeed: profile.avatarSeed,
                                userEmail: profile.email,
                                userName: profile.name,
                              ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              VoxelAvatar(
                                email: profile.email,
                                name: profile.name,
                                avatarSeed: profile.avatarSeed,
                                size: TrackletSpacing.avatar,
                                isGuest: isGuest,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: TrackletColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: TrackletColors.adaptiveSurface(
                                        context,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const animated.LucideAnimatedIcon(
                                    icon: animated.sparkles,
                                    size: 12,
                                    color: Colors.white,
                                    trigger: animated.AnimationTrigger.manual,
                                  ),
                                ),
                              ),
                            ],
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
                                      isGuest ? 'Guest Rider' : profile.name,
                                      style: TrackletFonts.outfit(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            TrackletColors.adaptiveTextPrimary(
                                              context,
                                            ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isGuest)
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
                                        decoration: BoxDecoration(
                                          color:
                                              TrackletColors.isDark(context)
                                                  ? TrackletColors
                                                      .darkSurfaceElevated
                                                  : TrackletColors.background,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          TrackletIcons.pencil,
                                          size: 16.0,
                                          color: TrackletColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: TrackletSpacing.xxs),
                              Text(
                                isGuest
                                    ? 'Guest Session (Device Only)'
                                    : profile.email,
                                style: TrackletTypography.bodySmall.copyWith(
                                  color: TrackletColors.adaptiveTextSecondary(
                                    context,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: TrackletSpacing.xs),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: TrackletSpacing.sm,
                                      vertical: TrackletSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TrackletColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: TrackletRadii.roundedXs,
                                    ),
                                    child: Text(
                                      isGuest
                                          ? 'Guest Account'
                                          : (profile.rollNumber ??
                                              'Student Account'),
                                      style: TrackletFonts.robotoMono(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w600,
                                        color: TrackletColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap:
                                        () => AvatarPickerSheet.show(
                                          context,
                                          currentSeed: profile.avatarSeed,
                                          userEmail: profile.email,
                                          userName: profile.name,
                                        ),
                                    borderRadius: TrackletRadii.roundedXs,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: TrackletSpacing.sm,
                                        vertical: TrackletSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            TrackletColors.isDark(context)
                                                ? TrackletColors
                                                    .darkSurfaceElevated
                                                : TrackletColors.background,
                                        borderRadius: TrackletRadii.roundedXs,
                                        border: Border.all(
                                          color: TrackletColors.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          animated.LucideAnimatedIcon(
                                            icon: animated.sparkles,
                                            size: 12,
                                            color: TrackletColors.primary,
                                            trigger:
                                                animated
                                                    .AnimationTrigger
                                                    .manual,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change Avatar',
                                            style: TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w600,
                                              color: TrackletColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TrackletSpacing.compactLg),
                    _buildDivider(context),
                    const SizedBox(height: TrackletSpacing.md),
                    if (isGuest)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            TrackletIcons.info,
                            size: 18.0,
                            color: TrackletColors.primary,
                          ),
                          const SizedBox(width: TrackletSpacing.compactMd),
                          Expanded(
                            child: Text(
                              'You are using BusTracker in guest mode. Live tracking, routes, and timetables are available on this device. Sign in with your @nitc.ac.in email to sync bookmarks and preferences.',
                              style: TrackletTypography.bodySmall.copyWith(
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _buildAcademicPill(
                            icon: TrackletIcons.graduationCap,
                            label: profile.semester,
                          ),
                          _buildAcademicPill(
                            icon: TrackletIcons.gitBranch,
                            label: profile.branch,
                          ),
                          _buildAcademicPill(
                            icon: TrackletIcons.calendar,
                            label: 'Batch ${profile.batch}',
                          ),
                          _buildAcademicPill(
                            icon: TrackletIcons.building,
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
                    if (isGuest)
                      SettingsRowItem(
                        title: 'Sign In with NITC Account',
                        subtitle:
                            'Upgrade to a permanent verified student account',
                        leadingIcon: TrackletIcons.logIn,
                        leadingIconColor: TrackletColors.primary,
                        showChevron: true,
                        onTap: () {
                          ref.read(authNotifierProvider.notifier).signOut();
                          context.go('/login');
                        },
                      )
                    else ...[
                      SettingsRowItem(
                        title: 'Edit Display Name',
                        subtitle: profile.name,
                        leadingIcon: TrackletIcons.award,
                        leadingIconColor: TrackletColors.primary,
                        showChevron: true,
                        onTap: () => ChangeDisplayNameDialog.show(context),
                      ),
                      _buildDivider(context),
                      SettingsRowItem(
                        title: 'Change Username',
                        subtitle:
                            profile.username != null &&
                                    profile.username!.isNotEmpty
                                ? '@${profile.username}'
                                : 'Set your unique campus username',
                        leadingIcon: TrackletIcons.atSign,
                        leadingIconColor: TrackletColors.primary,
                        showChevron: true,
                        onTap:
                            () => ChangeUsernameDialog.show(
                              context,
                              currentUsername: profile.username ?? '',
                            ),
                      ),
                      _buildDivider(context),
                      SettingsRowItem(
                        title: 'Change Password',
                        subtitle:
                            'Update your student account security credentials',
                        leadingIcon: TrackletIcons.lock,
                        leadingIconColor: TrackletColors.primary,
                        showChevron: true,
                        onTap: () => ChangePasswordDialog.show(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 3: LOCATION & PERMISSIONS
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
                                TrackletIcons.locateFixed,
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
                                  style: TrackletTypography.bodyMedium.copyWith(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: TrackletColors.adaptiveTextPrimary(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TrackletSpacing.xxs),
                                Text(
                                  'For nearest bus stop detection',
                                  style: TrackletTypography.bodySmall.copyWith(
                                    color: TrackletColors.adaptiveTextSecondary(
                                      context,
                                    ),
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
                    Text(
                      'BusTracker uses your location while viewing the map to calculate walking distances to nearby stops and show your position. Location data stays on your device.',
                      style: TrackletTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        height: 1.45,
                        color: TrackletColors.adaptiveTextSecondary(context),
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
                                  TrackletIcons.locateFixed,
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
              // SECTION 4: APPEARANCE & DISPLAY
              // ==========================================
              _buildSectionHeader('Appearance & Display'),
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
                            style: TrackletTypography.bodyMedium.copyWith(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: TrackletColors.adaptiveTextPrimary(
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.xxs),
                          Text(
                            'Choose interface appearance',
                            style: TrackletTypography.bodySmall.copyWith(
                              color: TrackletColors.adaptiveTextSecondary(
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.compactMd),
                          SettingsThemeSelector(
                            selectedMode: prefs.themeMode,
                            enableHaptics: prefs.hapticFeedbackEnabled,
                            onChanged: (String val) {
                              prefsNotifier.setThemeMode(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Haptic Feedback',
                      subtitle:
                          'Tactile vibrations when selecting stops & routes',
                      leadingIcon: TrackletIcons.smartphone,
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
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 5: SUPPORT & FEEDBACK
              // ==========================================
              _buildSectionHeader('Support & Feedback'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'Report an App Bug',
                      subtitle: 'Submit reproduction steps or track on GitHub',
                      leadingIcon: TrackletIcons.alertCircle,
                      leadingIconColor: TrackletColors.error,
                      showChevron: true,
                      onTap: () => context.push('/bug-report'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'General App Feedback',
                      subtitle: 'Rate your experience and share improvements',
                      leadingIcon: TrackletIcons.star,
                      leadingIconColor: const Color(0xFFF59E0B),
                      showChevron: true,
                      onTap: () => context.push('/feedback'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Suggest a Feature',
                      subtitle: 'Propose ideas for campus transit tracking',
                      leadingIcon: TrackletIcons.sparkles,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => context.push('/feature-suggestion'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Transit FAQ',
                      subtitle:
                          'Common questions about campus buses & tracking',
                      leadingIcon: TrackletIcons.helpCircle,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => TransitFaqDialog.show(context),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Report Bus / Route Issue',
                      subtitle:
                          'Report delays, incorrect stops, or schedule mismatch',
                      leadingIcon: TrackletIcons.alertTriangle,
                      leadingIconColor: TrackletColors.warningStrong,
                      showChevron: true,
                      onTap:
                          () => _launchEmail(
                            'BusTracker Issue Report - [Bus / Route]',
                            'Hi Transport Committee,\n\nI noticed an issue with campus transit:\n- Route / Bus: \n- Stop Location: \n- Description:\n\nStudent: ${profile.name} (${profile.rollNumber ?? "N/A"})',
                          ),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Contact Transport Committee',
                      subtitle: 'Email transport@nitc.ac.in',
                      leadingIcon: TrackletIcons.mail,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap:
                          () => _launchEmail(
                            'BusTracker Inquiry / Suggestion',
                            'Hi NITC Transport Committee,\n\n',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 6: ABOUT TRACKLET & LEGAL
              // ==========================================
              _buildSectionHeader('About BusTracker & Legal'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: 'About BusTracker',
                      subtitle: 'Mission, team, build info, and architecture',
                      leadingIcon: TrackletIcons.info,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => context.push('/about'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Terms of Service',
                      subtitle: 'Guidelines for campus transit tracking usage',
                      leadingIcon: TrackletIcons.fileText,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => context.push('/terms'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Privacy Policy',
                      subtitle: 'How student data and location are handled',
                      leadingIcon: TrackletIcons.shield,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => context.push('/privacy'),
                    ),
                    _buildDivider(context),
                    SettingsRowItem(
                      title: 'Open Source Licenses',
                      subtitle: 'Third-party packages and dependencies',
                      leadingIcon: TrackletIcons.code,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: () => context.push('/licenses'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.section),

              // ==========================================
              // SECTION 7: ACCOUNT ACTIONS (DESTRUCTIVE)
              // ==========================================
              _buildSectionHeader('Account Actions'),
              const SizedBox(height: TrackletSpacing.sm),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsRowItem(
                      title: isGuest ? 'Exit Guest Mode' : 'Log Out',
                      subtitle:
                          isGuest
                              ? 'End your current guest session on this device'
                              : 'Sign out of your student account on this device',
                      leadingIcon: TrackletIcons.logOut,
                      leadingIconColor: TrackletColors.primary,
                      showChevron: true,
                      onTap: _showLogoutDialog,
                    ),
                    if (!isGuest) ...[
                      _buildDivider(context),
                      SettingsRowItem(
                        title: 'Delete My Account',
                        subtitle:
                            'Permanently remove your profile and commute data',
                        leadingIcon: TrackletIcons.trash2,
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
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.large),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, color: TrackletColors.adaptiveBorder(context));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: TrackletSpacing.xs,
        bottom: TrackletSpacing.xs,
      ),
      child: Text(
        title,
        style: TrackletTypography.labelLarge.copyWith(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: TrackletColors.adaptiveTextSecondary(context),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildAcademicPill({required IconData icon, required String label}) {
    final isDark = TrackletColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compactMd,
        vertical: TrackletSpacing.compact,
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? TrackletColors.darkSurfaceElevated
                : TrackletColors.background,
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: TrackletColors.primary),
          const SizedBox(width: TrackletSpacing.compact),
          Text(
            label,
            style: TrackletTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: TrackletColors.adaptiveTextPrimary(context),
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
        style: TrackletTypography.labelSmall.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}
