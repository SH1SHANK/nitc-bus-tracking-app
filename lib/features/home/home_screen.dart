import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/home_provider.dart';
import 'widgets/next_bus_card.dart';
import 'widgets/upcoming_buses_list.dart';

/// Minimal, transit-focused Home screen for Tracklet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeStateProvider);

    return Scaffold(
      backgroundColor: TrackletColors.background,
      body: SafeArea(
        child: homeStateAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TrackletColors.primary),
          ),
          error: (error, stack) => TrackletErrorState(
            message: 'Unable to load transit schedule',
            onRetry: () => ref.invalidate(homeStateProvider),
          ),
          data: (state) {
            final greeting = _getGreeting();
            final firstName = state.userProfile.name.split(' ').first;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.screenMargin,
                vertical: TrackletSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Area: Greeting + Top-right Profile Entry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, $firstName',
                              style: TrackletTypography.displayMedium,
                            ),
                            const SizedBox(height: TrackletSpacing.xs),
                            const Text(
                              'Catch your next ride.',
                              style: TrackletTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // Top-right Profile / Settings entry
                      IconButton(
                        onPressed: () => context.go('/profile'),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: TrackletColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: TrackletColors.border),
                          ),
                          child: const TrackletIcon(
                            TrackletIcons.profile,
                            size: 20,
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                        tooltip: 'Profile & Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: TrackletSpacing.xl),

                  // Hero Next Bus Card
                  NextBusCard(
                    selectedStop: state.selectedStop,
                    nextBus: state.nextBus,
                    route: state.nextBusRoute,
                    etaMinutes: state.etaMinutes,
                    onTrackPressed: () => context.go('/map'),
                  ),
                  const SizedBox(height: TrackletSpacing.xl),

                  // Upcoming Buses
                  UpcomingBusesList(
                    buses: state.upcomingBuses,
                    onBusSelected: (bus) => context.go('/map'),
                  ),
                ],
              ),
            );
          },
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
}
