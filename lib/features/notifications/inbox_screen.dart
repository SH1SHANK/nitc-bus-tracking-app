import 'package:tracklet/design_system/tokens/spacing.dart';
import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../design_system/tokens/shadows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/notifications/notification_models.dart';
import '../../data/notifications/notification_repository.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_empty_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/tracklet_fonts.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(userInboxNotificationsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? TrackletColors.darkBackground : TrackletColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: TrackletShadows.elevationLevel0,
        leading: IconButton(
          icon: Icon(
            TrackletIcons.arrowLeft,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TrackletFonts.outfit(
            fontSize: TrackletTypography.fontSize20,
            fontWeight: TrackletTypography.weightBold,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reminders & Schedules',
            icon: Icon(
              TrackletIcons.notifications,
              color: TrackletColors.adaptiveTextPrimary(context),
            ),
            onPressed: () => context.push('/reminders'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(userInboxNotificationsProvider);
            },
            child: Text(
              'Read all',
              style: TrackletFonts.outfit(
                color: TrackletColors.primary,
                fontWeight: TrackletTypography.weightSemiBold,
                fontSize: TrackletTypography.fontSize14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.lg,
              vertical: TrackletSpacing.sm,
            ),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', 'unread', isDark),
                const Spacer(),
                Text(
                  'Retained for 7 days',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.adaptiveTextSecondary(context),
                    fontSize: TrackletTypography.fontSize12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, _) => Center(
                    child: TrackletEmptyState(
                      title: 'Unable to load notifications',
                      description: err.toString(),
                    ),
                  ),
              data: (items) {
                final filtered =
                    _selectedFilter == 'unread'
                        ? items.where((i) => !i.isRead).toList()
                        : items;

                if (filtered.isEmpty) {
                  return Center(
                    child: TrackletEmptyState(
                      title:
                          _selectedFilter == 'unread'
                              ? 'No unread notifications'
                              : 'Your inbox is clear',
                      description:
                          'Recent bus updates and announcements will appear here.',
                    ),
                  );
                }

                return RefreshIndicator(
                  color: TrackletColors.primary,
                  onRefresh: () async {
                    ref.invalidate(userInboxNotificationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.lg,
                      vertical: TrackletSpacing.md,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _NotificationCard(
                        item: item,
                        onTap: () async {
                          if (!item.isRead) {
                            await ref
                                .read(notificationRepositoryProvider)
                                .markAsRead(item.id);
                            ref.invalidate(userInboxNotificationsProvider);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.compactLg,
          vertical: TrackletSpacing.compact,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? TrackletColors.primary
                  : (isDark
                      ? TrackletColors.darkSurfaceElevated
                      : TrackletColors.surface),
          borderRadius: TrackletRadii.roundedPill,
        ),
        child: Text(
          label,
          style: TrackletFonts.outfit(
            color:
                isSelected
                    ? TrackletColors.textInverse
                    : TrackletColors.adaptiveTextSecondary(context),
            fontWeight:
                isSelected
                    ? TrackletTypography.weightBold
                    : TrackletTypography.weightMedium,
            fontSize: TrackletTypography.fontSize13,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = _formatTimestamp(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: TrackletRadii.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.compactLg),
        decoration: BoxDecoration(
          color:
              isDark
                  ? TrackletColors.darkSurfaceElevated
                  : TrackletColors.surface,
          borderRadius: TrackletRadii.roundedMd,
          border: Border.all(
            color:
                item.isRead
                    ? Colors.transparent
                    : TrackletColors.primary.withValues(alpha: 0.4),
            width: item.isRead ? 0 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TrackletFonts.outfit(
                            fontSize: TrackletTypography.fontSize15,
                            fontWeight:
                                item.isRead
                                    ? TrackletTypography.weightSemiBold
                                    : TrackletTypography.weightBold,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TrackletFonts.outfit(
                          fontSize: TrackletTypography.fontSize11,
                          color: TrackletColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize13,
                      height: TrackletTypography.lineHeightBodyCompact,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'disruption':
        icon = TrackletIcons.warning;
        color = TrackletColors.error;
        break;
      case 'boarding_reminder':
        icon = TrackletIcons.notifications;
        color = TrackletColors.primary;
        break;
      case 'bus_arrival':
        icon = TrackletIcons.bus;
        color = TrackletColors.busLive;
        break;
      default:
        icon = TrackletIcons.info;
        color = TrackletColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(TrackletSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
