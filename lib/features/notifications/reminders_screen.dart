import 'package:tracklet/design_system/tokens/spacing.dart';
import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../design_system/tokens/shadows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/notifications/notification_models.dart';
import '../../data/notifications/notification_repository.dart';
import '../../data/transit/stop.dart';
import '../../data/transit/transit_repository.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_empty_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/tracklet_fonts.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remindersAsync = ref.watch(userBoardingRemindersProvider);

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
          'Boarding Reminders',
          style: TrackletFonts.outfit(
            fontSize: TrackletTypography.fontSize20,
            fontWeight: TrackletTypography.weightBold,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TrackletColors.primary,
        foregroundColor: TrackletColors.textInverse,
        icon: const Icon(TrackletIcons.plus),
        label: Text(
          'New Reminder',
          style: TrackletFonts.outfit(
            fontWeight: TrackletTypography.weightSemiBold,
          ),
        ),
        onPressed: () => _openAddReminderSheet(context),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.lg,
              vertical: TrackletSpacing.sm,
            ),
            padding: const EdgeInsets.all(TrackletSpacing.md),
            decoration: BoxDecoration(
              color: TrackletColors.primary.withValues(alpha: 0.08),
              borderRadius: TrackletRadii.roundedMd,
              border: Border.all(
                color: TrackletColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  TrackletIcons.info,
                  color: TrackletColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reminders trigger 30 mins before your intended leave time (Mon–Fri). Notifications are verified against active bus telemetry before delivery.',
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize12,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: remindersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, _) => const Center(
                    child: TrackletEmptyState(
                      title: 'Unable to load reminders',
                      description: 'Failed to retrieve boarding reminders.',
                    ),
                  ),
              data: (reminders) {
                if (reminders.isEmpty) {
                  return const Center(
                    child: TrackletEmptyState(
                      title: 'No reminders set',
                      description:
                          'Set a reminder for your daily campus transit stops.',
                    ),
                  );
                }

                return RefreshIndicator(
                  color: TrackletColors.primary,
                  onRefresh: () async {
                    ref.invalidate(userBoardingRemindersProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: reminders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = reminders[index];
                      return _ReminderCard(
                        reminder: item,
                        onToggle: (val) async {
                          await ref
                              .read(notificationRepositoryProvider)
                              .toggleReminder(item.id, val);
                          ref.invalidate(userBoardingRemindersProvider);
                        },
                        onDelete: () async {
                          await ref
                              .read(notificationRepositoryProvider)
                              .deleteReminder(item.id);
                          ref.invalidate(userBoardingRemindersProvider);
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

  Future<void> _openAddReminderSheet(BuildContext context) async {
    final stops = await ref.read(transitRepositoryProvider).getStops();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _AddReminderBottomSheet(
            stops: stops,
            onCreated: () {
              ref.invalidate(userBoardingRemindersProvider);
            },
          ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final BoardingReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark
                ? TrackletColors.darkSurfaceElevated
                : TrackletColors.surface,
        borderRadius: TrackletRadii.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.stopName ?? 'Selected Stop',
                      style: TrackletFonts.outfit(
                        fontSize: TrackletTypography.fontSize16,
                        fontWeight: TrackletTypography.weightBold,
                        color: TrackletColors.adaptiveTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mon–Fri • Leave at ${reminder.intendedLeaveTime.substring(0, 5)}',
                      style: TrackletFonts.outfit(
                        fontSize: TrackletTypography.fontSize13,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isActive,
                activeTrackColor: TrackletColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Icon(
                TrackletIcons.clock,
                size: 14,
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Reminder triggers at: ${reminder.reminderNoticeTimeFormatted} (30m lead)',
                style: TrackletFonts.outfit(
                  fontSize: TrackletTypography.fontSize12,
                  fontWeight: TrackletTypography.weightMedium,
                  color: TrackletColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  TrackletIcons.trash2,
                  size: 18,
                  color: TrackletColors.error,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddReminderBottomSheet extends StatefulWidget {
  final List<Stop> stops;
  final VoidCallback onCreated;

  const _AddReminderBottomSheet({required this.stops, required this.onCreated});

  @override
  State<_AddReminderBottomSheet> createState() =>
      _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends State<_AddReminderBottomSheet> {
  String? _selectedStopId;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.stops.isNotEmpty) {
      _selectedStopId = widget.stops.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? TrackletColors.darkBackground : TrackletColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Boarding Reminder',
            style: TrackletFonts.outfit(
              fontSize: TrackletTypography.fontSize18,
              fontWeight: TrackletTypography.weightBold,
              color: TrackletColors.adaptiveTextPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Boarding Stop',
            style: TrackletFonts.outfit(
              fontSize: TrackletTypography.fontSize14,
              fontWeight: TrackletTypography.weightSemiBold,
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedStopId,
            items:
                widget.stops.map<DropdownMenuItem<String>>((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Text(s.name),
                  );
                }).toList(),
            onChanged: (val) => setState(() => _selectedStopId = val),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark
                      ? TrackletColors.darkSurfaceElevated
                      : TrackletColors.surface,
              border: const OutlineInputBorder(
                borderRadius: TrackletRadii.roundedMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Intended Leave Time (Mon–Fri)',
            style: TrackletFonts.outfit(
              fontSize: TrackletTypography.fontSize14,
              fontWeight: TrackletTypography.weightSemiBold,
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) {
                setState(() => _selectedTime = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.lg,
                vertical: TrackletSpacing.compactLg,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? TrackletColors.darkSurfaceElevated
                        : TrackletColors.surface,
                borderRadius: TrackletRadii.roundedMd,
              ),
              child: Row(
                children: [
                  const Icon(TrackletIcons.clock, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize16,
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Notice at ${_getNoticeTime(_selectedTime)}',
                    style: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize13,
                      color: TrackletColors.primary,
                      fontWeight: TrackletTypography.weightMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TrackletColors.primary,
              foregroundColor: TrackletColors.textInverse,
              padding: const EdgeInsets.symmetric(
                vertical: TrackletSpacing.compactLg,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: TrackletRadii.roundedMd,
              ),
            ),
            onPressed:
                _isSubmitting || _selectedStopId == null
                    ? null
                    : () async {
                      setState(() => _isSubmitting = true);
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      final timeStr =
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
                      await container
                          .read(notificationRepositoryProvider)
                          .createBoardingReminder(
                            stopId: _selectedStopId!,
                            intendedLeaveTime: timeStr,
                          );
                      widget.onCreated();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TrackletColors.textInverse,
                      ),
                    )
                    : Text(
                      'Create Reminder',
                      style: TrackletFonts.outfit(
                        fontWeight: TrackletTypography.weightBold,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  String _getNoticeTime(TimeOfDay t) {
    final total = t.hour * 60 + t.minute - 30;
    final notice = total < 0 ? total + 1440 : total;
    final h = (notice ~/ 60).toString().padLeft(2, '0');
    final m = (notice % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
