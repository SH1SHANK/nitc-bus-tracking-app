import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import 'providers/home_provider.dart';
import 'widgets/next_bus_card.dart';
import 'widgets/upcoming_buses_list.dart';

/// Authentic Attendrix Dashboard styled Home screen for Tracklet.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeStateProvider);

    return Scaffold(
      backgroundColor: TrackletColors.background,
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
          final firstName = state.userProfile.name.split(' ').first;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Top Gradient App Bar & Greeting Container (Attendrix Style)
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5AB2F7), TrackletColors.primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TrackletColors.primary.withValues(alpha: 0.25),
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
                          16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar: Drawer / Menu Icon + Profile Avatar Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: TrackletIcon(
                                          TrackletIcons.menu,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Tracklet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => context.go('/profile'),
                                  icon: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: TrackletIcon(
                                        TrackletIcons.profile,
                                        color: TrackletColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  tooltip: 'Profile & Settings',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),

                            // Dynamic Greeting
                            Text(
                              '$greeting, $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Next campus shuttle departing in ${state.etaMinutes} mins',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12.0),

                            // Quick Info Pill Banner
                            InkWell(
                              onTap: () => context.go('/map'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const TrackletIcon(
                                          TrackletIcons.navigation,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Campus Shuttle Loop Active',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const TrackletIcon(
                                      TrackletIcons.chevronRight,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Quick Action Buttons Row (Attendrix 18px pills)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 6.0),
                    child: Column(
                      children: [
                        // Button 1: Sync Timetable (Velvet Sky 0xFF7B6FF8)
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Timetable synced with academic schedule.',
                                  ),
                                  backgroundColor: TrackletColors.primary,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Sync Timetable',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TrackletColors.velvetSky,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Button 2: Campus Map (Tertiary 0xFFEE8B60)
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/map'),
                            icon: const Icon(
                              Icons.map_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Campus Transit Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TrackletColors.tertiary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Two Columns: IMS Portal (Success) & Moodle (Primary)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Opening NITC IMS Portal...',
                                        ),
                                        backgroundColor: TrackletColors.success,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.account_balance_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'IMS Portal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TrackletColors.success,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening NITC Moodle...'),
                                        backgroundColor: TrackletColors.primary,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.school_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Moodle',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TrackletColors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero Campus Transit Card (`BusTimeCardWidget` layout)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
                    child: NextBusCard(
                      selectedStop: state.selectedStop,
                      nextBus: state.nextBus,
                      route: state.nextBusRoute,
                      etaMinutes: state.etaMinutes,
                      onTrackPressed: () => context.go('/map'),
                    ),
                  ),
                ),

                // TabBar (Today's Buses / Campus Routes)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: TrackletColors.primary,
                      unselectedLabelColor: TrackletColors.textSecondary,
                      indicatorColor: TrackletColors.primary,
                      indicatorWeight: 2.5,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: "Today's Buses"),
                        Tab(text: 'Campus Routes'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Today's Active Buses
                SingleChildScrollView(
                  padding: const EdgeInsets.all(14.0),
                  child: UpcomingBusesList(
                    buses: state.upcomingBuses,
                    onBusSelected: (bus) => context.go('/map'),
                  ),
                ),

                // Tab 2: Campus Routes
                SingleChildScrollView(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      _buildRouteCard(
                        title: 'East Campus Shuttle (Bus 1)',
                        stops: 'Main Gate → MBH → PG Hostel → East Campus',
                        frequency: 'Every 15 mins',
                        isActive: true,
                        onTap: () => context.go('/map'),
                      ),
                      const SizedBox(height: 10),
                      _buildRouteCard(
                        title: 'Academic Complex Loop (Bus 2)',
                        stops: 'ELHC → Admin Block → Library → Center Circle',
                        frequency: 'Every 10 mins',
                        isActive: true,
                        onTap: () => context.go('/map'),
                      ),
                      const SizedBox(height: 10),
                      _buildRouteCard(
                        title: 'Hostel Ring Connector (Bus 3)',
                        stops: 'Mega Hostel Hub → Ladies Hostel → C-Mess',
                        frequency: 'Every 20 mins',
                        isActive: false,
                        onTap: () => context.go('/map'),
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

  Widget _buildRouteCard({
    required String title,
    required String stops,
    required String frequency,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TrackletColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TrackletColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? TrackletColors.primary.withValues(alpha: 0.1)
                    : TrackletColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TrackletIcon(
                  TrackletIcons.bus,
                  color: isActive
                      ? TrackletColors.primary
                      : TrackletColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TrackletColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stops,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TrackletColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frequency,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            const TrackletIcon(
              TrackletIcons.chevronRight,
              color: TrackletColors.textSecondary,
              size: 18,
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
}
