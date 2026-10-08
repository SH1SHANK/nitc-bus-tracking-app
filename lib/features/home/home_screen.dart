import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/profile/profile.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import 'providers/home_provider.dart';
import 'widgets/at_a_glance_transit_card.dart';
import 'widgets/next_buses_card.dart';

/// Authentic Attendrix-inspired Home screen for Tracklet, featuring the
/// gradient header, user greeting, drawer menu, and the At a Glance transit card.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: TrackletColors.background,
      drawer: homeStateAsync.maybeWhen(
        data: (state) => _buildDrawer(context, state.userProfile),
        orElse: () => null,
      ),
      body: homeStateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TrackletColors.primary),
        ),
        error: (error, stack) => SafeArea(
          child: TrackletErrorState(
            message: 'Unable to load transit schedule',
            onRetry: () => ref.invalidate(homeStateProvider),
          ),
        ),
        data: (state) {
          final greeting = _getGreeting();
          final firstName = state.userProfile.name.isNotEmpty
              ? state.userProfile.name.split(' ').first
              : 'Student';
          final userInitials = _getInitials(state.userProfile.name);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Gradient App Bar & Greeting Container (Attendrix Style)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        TrackletColors.permissionHeaderGradientStart,
                        TrackletColors.info,
                      ],
                      stops: [0.0, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        12.0,
                        16.0,
                        20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Bar: Hamburger Menu Button & Avatar Initials
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: TrackletColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_rounded,
                                      color: TrackletColors.textPrimary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => context.go('/profile'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: TrackletColors.primaryBackground,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: TrackletColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userInitials,
                                      style: const TextStyle(
                                        color: TrackletColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),

                          // Greeting Title & Subtitle matching the wireframe
                          Text(
                            '$greeting, $firstName',
                            style: const TextStyle(
                              color: TrackletColors.textPrimary,
                              fontSize: 24.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          const Text(
                            'Catch your next ride.',
                            style: TextStyle(
                              color: TrackletColors.textSecondary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content Body: At a Glance Hero Card & Next Buses List
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero "At a Glance" Transit Card
                      AtAGlanceTransitCard(
                        selectedStop: state.selectedStop,
                        nextBus: state.nextBus,
                        route: state.nextBusRoute,
                        etaMinutes: state.etaMinutes,
                        onTap: () => context.go('/map'),
                      ),
                      const SizedBox(height: 22.0),

                      // Next buses list (Single scroll without TabBar)
                      NextBusesCard(
                        stopName: state.selectedStop.name,
                        buses: state.upcomingBuses,
                        onBusTap: (item) => context.go('/map'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Attendrix-styled Drawer (Account Options)
  Widget _buildDrawer(BuildContext context, Profile profile) {
    return Drawer(
      elevation: 16.0,
      child: Container(
        color: TrackletColors.surface,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Group
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 16, 0, 8),
                      child: Text(
                        'Account Options',
                        style: TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Profile Header in Drawer
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: TrackletColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: TrackletColors.primary,
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(profile.name),
                                style: const TextStyle(
                                  color: TrackletColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name.isNotEmpty
                                      ? profile.name
                                      : 'Student User',
                                  style: const TextStyle(
                                    color: TrackletColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email.isNotEmpty
                                      ? profile.email
                                      : 'student@nitc.ac.in',
                                  style: const TextStyle(
                                    color: TrackletColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: TrackletColors.border, height: 24),

                    // Menu Items
                    _buildDrawerItem(
                      icon: Icons.tune_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.error_outline_rounded,
                      title: 'Report Errors/Bugs',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening bug report form...'),
                            backgroundColor: TrackletColors.primary,
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.directions_bus_rounded,
                      title: 'Live Campus Map',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/map');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/auth/login');
                      },
                    ),
                  ],
                ),

                // Bottom Footer: Clean App Version
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Tracklet v1.0.0 · NITC Bus Tracking',
                    style: TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: TrackletColors.textPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return 'SC';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
