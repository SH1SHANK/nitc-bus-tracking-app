import 'package:tracklet/design_system/tokens/spacing.dart';
import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../design_system/tokens/shadows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_models.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_button.dart';
import '../../design_system/components/tracklet_card.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import 'providers/admin_provider.dart';
import 'widgets/add_admin_dialog.dart';
import 'widgets/bus_speed_bar_chart.dart';
import 'widgets/fleet_status_donut_chart.dart';
import 'widgets/register_device_dialog.dart';
import 'widgets/rotate_secret_dialog.dart';
import 'widgets/telemetry_throughput_chart.dart';
import 'widgets/test_ping_dialog.dart';
import 'widgets/tracker_detail_sheet.dart';
import '../notifications/send_announcement_dialog.dart';

/// Comprehensive Administrative Control Panel for Tracklet.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _deviceSearchController = TextEditingController();
  String _selectedDeviceFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deviceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading:
          () => Scaffold(
            backgroundColor: TrackletColors.adaptiveSurface(context),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: TrackletColors.adaptiveSurface(context),
            appBar: AppBar(title: const Text('Admin Access Denied')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TrackletIcons.shield,
                    color: TrackletColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrator Privileges Required',
                    style: TextStyle(
                      fontSize: TrackletTypography.fontSize18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: TextStyle(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TrackletButton(
                    label: 'Return to Home',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            backgroundColor: TrackletColors.adaptiveSurface(context),
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TrackletIcons.lock,
                    color: TrackletColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: TrackletTypography.fontSize18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account is not on the administrator allowlist.',
                    style: TextStyle(fontSize: TrackletTypography.fontSize14),
                  ),
                  const SizedBox(height: 24),
                  TrackletButton(
                    label: 'Return to Home',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: TrackletColors.adaptiveSurface(context),
          appBar: AppBar(
            backgroundColor: TrackletColors.adaptiveSurfaceElevated(context),
            elevation: TrackletShadows.elevationLevel0,
            leading: IconButton(
              icon: const Icon(TrackletIcons.chevronLeft),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.compact),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.15),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: const Icon(
                    TrackletIcons.shield,
                    color: TrackletColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Admin Controls',
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(TrackletIcons.notifications, size: 20),
                tooltip: 'Broadcast Announcement',
                onPressed: () => SendAnnouncementDialog.show(context),
              ),
              IconButton(
                icon: const Icon(TrackletIcons.refresh, size: 20),
                tooltip: 'Refresh metrics',
                onPressed: () {
                  ref.invalidate(adminOverviewProvider);
                  ref.invalidate(adminDevicesProvider);
                  ref.invalidate(adminHealthProvider);
                  ref.invalidate(adminAuditLogsProvider);
                  ref.invalidate(adminUsersProvider);
                  ref.invalidate(adminTelemetryMetricsProvider);
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: TrackletColors.primary,
              unselectedLabelColor: TrackletColors.adaptiveTextMuted(context),
              indicatorColor: TrackletColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(TrackletIcons.activity, size: 18),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(TrackletIcons.smartphone, size: 18),
                  text: 'Devices',
                ),
                Tab(
                  icon: Icon(TrackletIcons.speed, size: 18),
                  text: 'Debug Console',
                ),
                Tab(
                  icon: Icon(TrackletIcons.checkCircle, size: 18),
                  text: 'Health',
                ),
                Tab(
                  icon: Icon(TrackletIcons.history, size: 18),
                  text: 'Audit Logs',
                ),
                Tab(icon: Icon(TrackletIcons.users, size: 18), text: 'Admins'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context),
              _buildDevicesTab(context),
              _buildDebugConsoleTab(context),
              _buildHealthTab(context),
              _buildAuditLogsTab(context),
              _buildAdminsTab(context),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 1: OVERVIEW
  // -------------------------------------------------------------
  Widget _buildOverviewTab(BuildContext context) {
    final overviewAsync = ref.watch(adminOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(TrackletSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TrackletIcons.error,
                    color: TrackletColors.error,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load operational metrics: $e',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TrackletButton(
                    label: 'Retry',
                    onPressed: () => ref.invalidate(adminOverviewProvider),
                  ),
                ],
              ),
            ),
          ),
      data: (overview) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminOverviewProvider);
            ref.invalidate(adminTelemetryMetricsProvider);
            await ref.read(adminOverviewProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(TrackletSpacing.lg),
            children: [
              // System banner
              Container(
                padding: const EdgeInsets.all(TrackletSpacing.compactLg),
                decoration: BoxDecoration(
                  color:
                      overview.databaseConnected
                          ? TrackletColors.success.withValues(alpha: 0.1)
                          : TrackletColors.error.withValues(alpha: 0.1),
                  borderRadius: TrackletRadii.roundedMd,
                  border: Border.all(
                    color:
                        overview.databaseConnected
                            ? TrackletColors.success.withValues(alpha: 0.3)
                            : TrackletColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      overview.databaseConnected
                          ? TrackletIcons.checkCircle
                          : TrackletIcons.alertCircle,
                      color:
                          overview.databaseConnected
                              ? TrackletColors.success
                              : TrackletColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overview.databaseConnected
                                ? 'Telemetry Core Connected'
                                : 'Database Connection Issue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  overview.databaseConnected
                                      ? TrackletColors.success
                                      : TrackletColors.error,
                            ),
                          ),
                          Text(
                            'API Uptime: ${(overview.uptimeSeconds / 60).toStringAsFixed(1)} min · NITC Transit Fleet',
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize12,
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
              ),
              const SizedBox(height: 16),

              const Text(
                'TRACKER INVENTORY & TELEMETRY',
                style: TextStyle(
                  fontSize: TrackletTypography.fontSize11,
                  fontWeight: TrackletTypography.weightExtraBold,
                  letterSpacing: TrackletTypography.letterSpacingExpanded,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Total Trackers',
                      value: '${overview.totalDevices}',
                      subtitle: '${overview.activeDevices} Active',
                      icon: TrackletIcons.smartphone,
                      color: TrackletColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Online (Live)',
                      value: '${overview.onlineDevices}',
                      subtitle:
                          '${overview.staleDevices} Stale · ${overview.offlineDevices} Off',
                      icon: TrackletIcons.activity,
                      color: TrackletColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Total Buses',
                      value: '${overview.totalBuses}',
                      subtitle: '${overview.activeBuses} Active in fleet',
                      icon: TrackletIcons.bus,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Last Telemetry',
                      value:
                          overview.telemetryLastReceivedAt != null
                              ? _formatRelativeTime(
                                overview.telemetryLastReceivedAt!,
                              )
                              : 'Never',
                      subtitle:
                          overview.telemetryLastReceivedAt != null
                              ? 'Real-time sync'
                              : 'No packets yet',
                      icon: TrackletIcons.refresh,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fleet Distribution Donut Chart
              FleetStatusDonutChart(
                onlineCount: overview.onlineDevices,
                staleCount: overview.staleDevices,
                offlineCount: overview.offlineDevices,
                totalDevices: overview.totalDevices,
              ),
              const SizedBox(height: 16),

              // Telemetry Throughput Chart
              Consumer(
                builder: (context, ref, _) {
                  final metricsAsync = ref.watch(adminTelemetryMetricsProvider);
                  return metricsAsync.when(
                    data:
                        (metrics) => TelemetryThroughputChart(
                          buckets: metrics.hourlyPackets,
                          totalPackets24h: metrics.totalPackets24h,
                          totalPacketsAllTime: metrics.totalPacketsAllTime,
                        ),
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: TrackletSpacing.xl,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    error: (e, _) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: TrackletTypography.fontSize11,
                  fontWeight: TrackletTypography.weightExtraBold,
                  letterSpacing: TrackletTypography.letterSpacingExpanded,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  TrackletButton(
                    label: 'Register New Tracker',
                    icon: const Icon(TrackletIcons.plus, size: 16),
                    onPressed: () => RegisterDeviceDialog.show(context),
                  ),
                  TrackletButton(
                    label: 'Open Debug Stream',
                    variant: TrackletButtonVariant.secondary,
                    icon: const Icon(TrackletIcons.speed, size: 16),
                    onPressed: () => _tabController.animateTo(2),
                  ),
                  TrackletButton(
                    label: 'Manage Admins',
                    variant: TrackletButtonVariant.outline,
                    icon: const Icon(TrackletIcons.users, size: 16),
                    onPressed: () => _tabController.animateTo(5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: DEVICE MANAGEMENT
  // -------------------------------------------------------------
  Widget _buildDevicesTab(BuildContext context) {
    final devicesAsync = ref.watch(adminDevicesProvider);

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(TrackletSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TrackletIcons.error,
                    color: TrackletColors.error,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load devices: $e',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TrackletButton(
                    label: 'Retry',
                    onPressed:
                        () => ref.read(adminDevicesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
      data: (devices) {
        final totalActive = devices.where((d) => d.isActive).length;
        final totalInactive = devices.where((d) => !d.isActive).length;
        final query = _deviceSearchController.text.trim().toLowerCase();
        final filtered =
            devices.where((d) {
              if (_selectedDeviceFilter == 'active' && !d.isActive) {
                return false;
              }
              if (_selectedDeviceFilter == 'inactive' && d.isActive) {
                return false;
              }
              if (query.isEmpty) return true;
              return d.deviceId.toLowerCase().contains(query) ||
                  (d.busNumber?.toLowerCase().contains(query) ?? false) ||
                  (d.busLabel?.toLowerCase().contains(query) ?? false);
            }).toList();

        return Column(
          children: [
            // Search and Register Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _deviceSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search trackers or buses...',
                        prefixIcon: const Icon(TrackletIcons.search, size: 18),
                        suffixIcon:
                            query.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    TrackletIcons.close,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _deviceSearchController.clear();
                                    setState(() {});
                                  },
                                )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.md,
                          vertical: TrackletSpacing.compactMd,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: TrackletRadii.roundedSm,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TrackletButton(
                    label: 'Register',
                    icon: const Icon(TrackletIcons.plus, size: 16),
                    onPressed: () => RegisterDeviceDialog.show(context),
                  ),
                ],
              ),
            ),
            // Device filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.lg,
                vertical: TrackletSpacing.xs,
              ),
              child: Row(
                children: [
                  _buildDeviceFilterChip('All', 'all', devices.length),
                  const SizedBox(width: 8),
                  _buildDeviceFilterChip('Active', 'active', totalActive),
                  const SizedBox(width: 8),
                  _buildDeviceFilterChip('Inactive', 'inactive', totalInactive),
                ],
              ),
            ),
            // Device count indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.lg,
                vertical: TrackletSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} of ${devices.length} Trackers',
                    style: TextStyle(
                      fontSize: TrackletTypography.fontSize12,
                      color: TrackletColors.adaptiveTextMuted(context),
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Device list
            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              TrackletIcons.smartphone,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty
                                  ? 'No tracking devices provisioned yet.'
                                  : 'No devices match "$query".',
                              style: TextStyle(
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                              ),
                            ),
                            if (query.isEmpty) ...[
                              const SizedBox(height: 16),
                              TrackletButton(
                                label: 'Register First Tracker',
                                onPressed:
                                    () => RegisterDeviceDialog.show(context),
                              ),
                            ],
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh:
                            () =>
                                ref
                                    .read(adminDevicesProvider.notifier)
                                    .refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(TrackletSpacing.lg),
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final device = filtered[index];
                            return _buildDeviceCard(context, device);
                          },
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceFilterChip(String label, String value, int count) {
    final isSelected = _selectedDeviceFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: TrackletColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: TrackletTypography.fontSize12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color:
            isSelected
                ? TrackletColors.primary
                : TrackletColors.adaptiveTextPrimary(context),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDeviceFilter = value;
          });
        }
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, AdminDevice device) {
    final isOnline =
        device.isActive &&
        device.lastSeenAt != null &&
        DateTime.now().difference(device.lastSeenAt!).inMinutes < 2;
    final isStale =
        device.isActive &&
        device.lastSeenAt != null &&
        DateTime.now().difference(device.lastSeenAt!).inMinutes >= 2 &&
        DateTime.now().difference(device.lastSeenAt!).inMinutes < 10;

    final statusColor =
        !device.isActive
            ? Colors.grey
            : isOnline
            ? TrackletColors.success
            : isStale
            ? TrackletColors.warning
            : TrackletColors.error;

    final statusText =
        !device.isActive
            ? 'INACTIVE'
            : isOnline
            ? 'ONLINE'
            : isStale
            ? 'STALE'
            : 'OFFLINE';

    final busDisplayName =
        device.busNumber != null
            ? '${device.busNumber}${device.busLabel != null && device.busLabel!.isNotEmpty ? ' · ${device.busLabel}' : ''}'
            : 'Unassigned Bus';

    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TrackletSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: Icon(
                  TrackletIcons.smartphone,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.deviceId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: TrackletTypography.fontSize15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.compact,
                            vertical: TrackletSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: TrackletRadii.roundedSm,
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing:
                                  TrackletTypography.letterSpacingLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      busDisplayName,
                      style: TextStyle(
                        fontSize: TrackletTypography.fontSize12,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Active switch
              Switch(
                value: device.isActive,
                activeThumbColor: TrackletColors.primary,
                onChanged: (val) {
                  ref
                      .read(adminDevicesProvider.notifier)
                      .toggleDeviceStatus(
                        deviceId: device.deviceId,
                        isActive: val,
                      );
                },
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _subInfo('Epoch', '${device.currentEpoch}'),
              const Spacer(),
              _subInfo(
                'Last Seen',
                device.lastSeenAt != null
                    ? _formatRelativeTime(device.lastSeenAt!)
                    : 'Never',
              ),
              if (device.lastPosition != null) ...[
                const Spacer(),
                _subInfo('Seq #', '${device.lastPosition!.seq}'),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(TrackletIcons.activity, size: 14),
                  label: const Text(
                    'Test Ping',
                    style: TextStyle(fontSize: TrackletTypography.fontSize12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.sm,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed:
                      () => TestPingDialog.show(context, device.deviceId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(TrackletIcons.key, size: 14),
                  label: const Text(
                    'Rotate Secret',
                    style: TextStyle(fontSize: TrackletTypography.fontSize12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.sm,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed:
                      () => RotateSecretDialog.show(context, device.deviceId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: LIVE DEBUG CONSOLE
  // -------------------------------------------------------------
  Widget _buildDebugConsoleTab(BuildContext context) {
    final consoleState = ref.watch(debugConsoleProvider);
    final notifier = ref.read(debugConsoleProvider.notifier);

    return Column(
      children: [
        // Control Bar
        Container(
          padding: const EdgeInsets.all(TrackletSpacing.md),
          decoration: BoxDecoration(
            color: TrackletColors.adaptiveSurfaceElevated(context),
            border: Border(
              bottom: BorderSide(
                color: TrackletColors.adaptiveDivider(context),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Pause / Resume toggle button
                  InkWell(
                    onTap: () => notifier.togglePause(),
                    borderRadius: TrackletRadii.roundedSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.md,
                        vertical: TrackletSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            consoleState.isPaused
                                ? TrackletColors.warning.withValues(alpha: 0.15)
                                : TrackletColors.success.withValues(
                                  alpha: 0.15,
                                ),
                        borderRadius: TrackletRadii.roundedSm,
                        border: Border.all(
                          color:
                              consoleState.isPaused
                                  ? TrackletColors.warning
                                  : TrackletColors.success,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            consoleState.isPaused
                                ? TrackletIcons.pause
                                : TrackletIcons.activity,
                            size: 16,
                            color:
                                consoleState.isPaused
                                    ? TrackletColors.warning
                                    : TrackletColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            consoleState.isPaused
                                ? 'RESUME STREAM'
                                : 'PAUSE STREAM',
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize12,
                              fontWeight: FontWeight.bold,
                              color:
                                  consoleState.isPaused
                                      ? TrackletColors.warning
                                      : TrackletColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Updated: ${_formatTime(consoleState.lastUpdated)}',
                    style: TextStyle(
                      fontSize: TrackletTypography.fontSize11,
                      color: TrackletColors.adaptiveTextMuted(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(TrackletIcons.refresh, size: 18),
                    tooltip: 'Pull immediate snapshot',
                    onPressed: () => notifier.forceRefresh(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Polling Interval Selector
              Row(
                children: [
                  Text(
                    'Polling Rate: ',
                    style: TextStyle(
                      fontSize: TrackletTypography.fontSize11,
                      fontWeight: TrackletTypography.weightSemiBold,
                      color: TrackletColors.adaptiveTextMuted(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (final sec in [1, 3, 5, 10]) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TrackletSpacing.compact,
                      ),
                      child: InkWell(
                        onTap: () => notifier.setPollingInterval(sec),
                        borderRadius: TrackletRadii.roundedSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                consoleState.pollingIntervalSeconds == sec
                                    ? TrackletColors.primary.withValues(
                                      alpha: 0.15,
                                    )
                                    : TrackletColors.adaptiveSurface(context),
                            borderRadius: TrackletRadii.roundedSm,
                            border: Border.all(
                              color:
                                  consoleState.pollingIntervalSeconds == sec
                                      ? TrackletColors.primary
                                      : TrackletColors.adaptiveDivider(context),
                            ),
                          ),
                          child: Text(
                            '${sec}s',
                            style: TextStyle(
                              fontSize: TrackletTypography.fontSize11,
                              fontWeight:
                                  consoleState.pollingIntervalSeconds == sec
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  consoleState.pollingIntervalSeconds == sec
                                      ? TrackletColors.primary
                                      : TrackletColors.adaptiveTextPrimary(
                                        context,
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Search & Freshness filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Filter debug trackers...',
                        prefixIcon: Icon(TrackletIcons.search, size: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.sm,
                          vertical: TrackletSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: TrackletRadii.roundedSm,
                        ),
                      ),
                      onChanged: (val) => notifier.updateSearch(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: consoleState.selectedFreshnessFilter ?? 'all',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                      DropdownMenuItem(value: 'stale', child: Text('Stale')),
                      DropdownMenuItem(
                        value: 'offline',
                        child: Text('Offline'),
                      ),
                    ],
                    onChanged: (val) => notifier.setFilter(val),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bus Speed Spectrum
        Consumer(
          builder: (context, ref, _) {
            final metricsAsync = ref.watch(adminTelemetryMetricsProvider);
            return metricsAsync.when(
              data: (metrics) {
                if (metrics.speedDistribution.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: BusSpeedBarChart(
                    speedMetrics: metrics.speedDistribution,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),

        // Live Tracker list
        Expanded(
          child:
              consoleState.filteredTrackers.isEmpty
                  ? Center(
                    child: Text(
                      'No tracker records available.',
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(TrackletSpacing.lg),
                    itemCount: consoleState.filteredTrackers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tracker = consoleState.filteredTrackers[index];
                      return _buildDebugTrackerCard(context, tracker);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDebugTrackerCard(
    BuildContext context,
    TrackerDebugItem tracker,
  ) {
    final pos = tracker.currentPosition;
    final lat = pos?['latitude'] as num?;
    final lng = pos?['longitude'] as num?;
    final speed = pos?['speed'] as num?;

    return TrackletCard(
      onTap: () => TrackerDetailSheet.show(context, tracker),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tracker.busNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: TrackletTypography.fontSize15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.compact,
                  vertical: TrackletSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: TrackletColors.adaptiveSurfaceElevated(context),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: Text(
                  tracker.deviceId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: TrackletTypography.fontSize11,
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                ),
              ),
              const Spacer(),
              _buildFreshnessBadge(context, tracker.freshness),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Epoch: ${tracker.epoch} · Seq: #${tracker.seq}',
                style: TextStyle(
                  fontSize: TrackletTypography.fontSize12,
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                speed != null ? '${speed.toStringAsFixed(1)} km/h' : '0 km/h',
                style: const TextStyle(
                  fontSize: TrackletTypography.fontSize12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                TrackletIcons.busStop,
                size: 14,
                color: TrackletColors.adaptiveTextMuted(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lat != null && lng != null
                      ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                      : 'No GPS Fix Recorded',
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize11,
                    color: TrackletColors.adaptiveTextSecondary(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                '${tracker.recentBreadcrumbs.length} breadcrumbs',
                style: const TextStyle(
                  fontSize: TrackletTypography.fontSize10,
                  color: TrackletColors.primary,
                  fontWeight: TrackletTypography.weightSemiBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: SYSTEM HEALTH
  // -------------------------------------------------------------
  Widget _buildHealthTab(BuildContext context) {
    final healthAsync = ref.watch(adminHealthProvider);

    return healthAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load health: $e')),
      data: (health) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminHealthProvider);
            await ref.read(adminHealthProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(TrackletSpacing.lg),
            children: [
              // Fastify API Health
              TrackletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          TrackletIcons.activity,
                          color: TrackletColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fastify Telemetry API',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TrackletTypography.fontSize16,
                          ),
                        ),
                        const Spacer(),
                        _statusPill(context, health.apiStatus == 'healthy'),
                      ],
                    ),
                    const Divider(height: 16),
                    _healthMetricRow(
                      'Uptime',
                      '${(health.uptimeSeconds / 60).toStringAsFixed(1)} minutes',
                    ),
                    _healthMetricRow('Node.js Runtime', health.nodeVersion),
                    _healthMetricRow(
                      'Memory Heap Used',
                      '${health.heapUsedMb.toStringAsFixed(1)} MB',
                    ),
                    _healthMetricRow(
                      'Memory Heap Total',
                      '${health.heapTotalMb.toStringAsFixed(1)} MB',
                    ),
                    _healthMetricRow(
                      'Process RSS',
                      '${health.rssMb.toStringAsFixed(1)} MB',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Database Health
              TrackletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          TrackletIcons.shield,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Supabase PostgreSQL Database',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TrackletTypography.fontSize16,
                          ),
                        ),
                        const Spacer(),
                        _statusPill(context, health.dbConnected),
                      ],
                    ),
                    const Divider(height: 16),
                    _healthMetricRow(
                      'Connection Status',
                      health.dbStatus.toUpperCase(),
                    ),
                    _healthMetricRow(
                      'Query Ping Latency',
                      '${health.dbLatencyMs.toStringAsFixed(1)} ms',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Telemetry Ingestion Health
              TrackletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(TrackletIcons.refresh, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text(
                          'Telemetry Ingestion Pipeline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TrackletTypography.fontSize16,
                          ),
                        ),
                        const Spacer(),
                        _statusPill(context, health.telemetryHealthy),
                      ],
                    ),
                    const Divider(height: 16),
                    _healthMetricRow(
                      'Total Packets Recorded',
                      '${health.totalRecordsRecorded}',
                    ),
                    _healthMetricRow(
                      'Last Packet Age',
                      health.lastPacketAgeSeconds != null
                          ? '${health.lastPacketAgeSeconds!.toStringAsFixed(0)} seconds ago'
                          : 'No packets ingested',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fleet Counts
              TrackletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Fleet Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: TrackletTypography.fontSize16,
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _fleetPill(
                          'Total',
                          '${health.fleetTotal}',
                          Colors.grey,
                        ),
                        _fleetPill(
                          'Online',
                          '${health.fleetOnline}',
                          TrackletColors.success,
                        ),
                        _fleetPill(
                          'Stale',
                          '${health.fleetStale}',
                          TrackletColors.warning,
                        ),
                        _fleetPill(
                          'Offline',
                          '${health.fleetOffline}',
                          Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 5: AUDIT LOGS
  // -------------------------------------------------------------
  Widget _buildAuditLogsTab(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load audit logs: $e')),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No administrative actions recorded yet.',
              style: TextStyle(
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminAuditLogsProvider);
            await ref.read(adminAuditLogsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(TrackletSpacing.lg),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              return TrackletCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: TrackletRadii.roundedSm,
                          ),
                          child: Text(
                            log.action,
                            style: const TextStyle(
                              color: TrackletColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: TrackletTypography.fontSize11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatRelativeTime(log.createdAt),
                          style: TextStyle(
                            fontSize: TrackletTypography.fontSize11,
                            color: TrackletColors.adaptiveTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin: ${log.adminEmail}',
                      style: const TextStyle(
                        fontSize: TrackletTypography.fontSize13,
                        fontWeight: TrackletTypography.weightSemiBold,
                      ),
                    ),
                    if (log.targetType.isNotEmpty)
                      Text(
                        'Target: ${log.targetType}${log.targetId != null ? ' (${log.targetId})' : ''}',
                        style: TextStyle(
                          fontSize: TrackletTypography.fontSize12,
                          color: TrackletColors.adaptiveTextSecondary(context),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 6: ADMIN ALLOWLIST
  // -------------------------------------------------------------
  Widget _buildAdminsTab(BuildContext context) {
    final adminsAsync = ref.watch(adminUsersProvider);

    return adminsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load administrators: $e')),
      data: (admins) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(TrackletSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${admins.length} Configured Administrators',
                      style: TextStyle(
                        fontSize: TrackletTypography.fontSize13,
                        color: TrackletColors.adaptiveTextSecondary(context),
                        fontWeight: TrackletTypography.weightSemiBold,
                      ),
                    ),
                  ),
                  TrackletButton(
                    label: 'Add Admin',
                    icon: const Icon(TrackletIcons.plus, size: 16),
                    onPressed: () => AddAdminDialog.show(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(TrackletSpacing.lg),
                itemCount: admins.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  return TrackletCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(TrackletSpacing.sm),
                          decoration: BoxDecoration(
                            color: TrackletColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: TrackletRadii.roundedSm,
                          ),
                          child: const Icon(
                            TrackletIcons.shield,
                            color: TrackletColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admin.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: TrackletTypography.fontSize14,
                                ),
                              ),
                              if (admin.notes != null)
                                Text(
                                  admin.notes!,
                                  style: TextStyle(
                                    fontSize: TrackletTypography.fontSize12,
                                    color: TrackletColors.adaptiveTextSecondary(
                                      context,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(TrackletIcons.trash, size: 18),
                          tooltip: 'Remove Administrator',
                          onPressed: () => _confirmDeleteAdmin(context, admin),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAdmin(
    BuildContext context,
    AdminUser admin,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.adaptiveSurface(ctx),
            title: const Text('Remove Administrator?'),
            content: Text(
              'Are you sure you want to remove ${admin.email} from the administrator allowlist? '
              'They will immediately lose access to all admin tools.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: TrackletColors.textInverse),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminUsersProvider.notifier).deleteAdmin(admin.id);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Removed ${admin.email} from administrators')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: TrackletColors.error,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS & FORMATTERS
  // -------------------------------------------------------------
  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return TrackletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize12,
                    color: TrackletColors.adaptiveTextMuted(context),
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: TrackletTypography.fontSize22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: TrackletTypography.fontSize11,
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: TrackletTypography.fontSize10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: TrackletTypography.fontSize12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(BuildContext context, bool ok) {
    final color = ok ? TrackletColors.success : TrackletColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: TrackletRadii.roundedMd,
      ),
      child: Text(
        ok ? 'ONLINE' : 'DEGRADED',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: TrackletTypography.fontSize10,
        ),
      ),
    );
  }

  Widget _fleetPill(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: TrackletTypography.fontSize20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: TrackletTypography.fontSize11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFreshnessBadge(BuildContext context, String freshness) {
    final (Color color, String label) = switch (freshness) {
      'online' => (TrackletColors.success, 'ONLINE'),
      'stale' => (TrackletColors.warning, 'STALE'),
      _ => (Colors.grey, 'OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compact,
        vertical: TrackletSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: TrackletTypography.fontSize9,
        ),
      ),
    );
  }

  Widget _healthMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TrackletSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: TrackletTypography.fontSize13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: TrackletTypography.fontSize13,
              fontWeight: TrackletTypography.weightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
