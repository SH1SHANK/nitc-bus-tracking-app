import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Selection dialog for choosing the student's favorite campus bus stop.
class FavoriteStopPickerDialog extends ConsumerWidget {
  const FavoriteStopPickerDialog({super.key, required this.selectedStopId});

  final String selectedStopId;

  static Future<Stop?> show(
    BuildContext context, {
    String selectedStopId = '',
  }) {
    return showDialog<Stop>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => FavoriteStopPickerDialog(selectedStopId: selectedStopId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitRepo = ref.watch(transitRepositoryProvider);
    final isDark = TrackletColors.isDark(context);

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
        vertical: TrackletSpacing.xl,
      ),
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420.0, maxHeight: 520.0),
        decoration: BoxDecoration(
          color: TrackletColors.adaptiveSurfaceElevated(context),
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(
            color: TrackletColors.adaptiveCardBorder(context),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18.0,
              color: TrackletColors.scrim.withValues(
                alpha: isDark ? 0.3 : 0.08,
              ),
              offset: const Offset(0.0, 6.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Favorite Stop',
                      style: TrackletFonts.outfit(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: TrackletColors.adaptiveTextPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      TrackletIcons.x,
                      color: TrackletColors.adaptiveTextSecondary(context),
                      size: 22.0,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.xxs),
              Text(
                'Choose your primary campus stop for quick ETA shortcuts',
                style: TrackletFonts.outfit(
                  fontSize: 12.0,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              Divider(color: TrackletColors.adaptiveDivider(context)),
              const SizedBox(height: TrackletSpacing.sm),
              Expanded(
                child: FutureBuilder<List<Stop>>(
                  future: transitRepo.getStops(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: TrackletColors.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              TrackletIcons.alertCircle,
                              color: TrackletColors.error,
                              size: 36.0,
                            ),
                            const SizedBox(height: TrackletSpacing.sm),
                            Text(
                              'Failed to load campus stops',
                              style: TrackletFonts.outfit(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: TrackletColors.adaptiveTextPrimary(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: TrackletSpacing.xs),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                    final stops = snapshot.data ?? [];
                    if (stops.isEmpty) {
                      return Center(
                        child: Text(
                          'No campus stops available',
                          style: TrackletFonts.outfit(
                            fontSize: 14.0,
                            color: TrackletColors.adaptiveTextSecondary(
                              context,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: stops.length,
                      separatorBuilder:
                          (_, _) => Divider(
                            color: TrackletColors.adaptiveDivider(context),
                            height: TrackletSpacing.hairline,
                          ),
                      itemBuilder: (context, index) {
                        final stop = stops[index];
                        final isSelected = stop.id == selectedStopId;
                        return InkWell(
                          onTap: () => Navigator.pop(context, stop),
                          borderRadius: TrackletRadii.roundedSm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: TrackletSpacing.compactMd,
                              horizontal: TrackletSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: TrackletSpacing.mediumIcon,
                                  height: TrackletSpacing.mediumIcon,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? TrackletColors.primary
                                            : (isDark
                                                ? TrackletColors
                                                    .primaryContainerDark
                                                : TrackletColors
                                                    .primaryBackground),
                                    borderRadius: TrackletRadii.roundedSm,
                                  ),
                                  child: Icon(
                                    TrackletIcons.bus,
                                    color:
                                        isSelected
                                            ? TrackletColors.textInverse
                                            : (isDark
                                                ? TrackletColors.primaryDark
                                                : TrackletColors.primary),
                                    size: 18.0,
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stop.name,
                                        style: TrackletFonts.outfit(
                                          fontSize: 15.0,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                          color:
                                              isSelected
                                                  ? (isDark
                                                      ? TrackletColors
                                                          .primaryDark
                                                      : TrackletColors.primary)
                                                  : TrackletColors.adaptiveTextPrimary(
                                                    context,
                                                  ),
                                        ),
                                      ),
                                      if (stop.description != null) ...[
                                        const SizedBox(
                                          height: TrackletSpacing.xxs,
                                        ),
                                        Text(
                                          stop.description!,
                                          style: TrackletFonts.outfit(
                                            fontSize: 11.0,
                                            color:
                                                TrackletColors.adaptiveTextSecondary(
                                                  context,
                                                ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    TrackletIcons.checkCircle2,
                                    color: TrackletColors.primary,
                                    size: 22.0,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
