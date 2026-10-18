import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/transit_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Selection dialog for choosing the student's favorite campus bus route.
class FavoriteRoutePickerDialog extends ConsumerWidget {
  const FavoriteRoutePickerDialog({super.key, required this.selectedRouteId});

  final String selectedRouteId;

  static Future<BusRoute?> show(
    BuildContext context, {
    String selectedRouteId = '',
  }) {
    return showDialog<BusRoute>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) =>
              FavoriteRoutePickerDialog(selectedRouteId: selectedRouteId),
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
        constraints: const BoxConstraints(maxWidth: 420.0, maxHeight: 480.0),
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
                      'Select Favorite Route',
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
                'Default route highlighted on initial map load',
                style: TrackletFonts.outfit(
                  fontSize: 12.0,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              Divider(color: TrackletColors.adaptiveDivider(context)),
              const SizedBox(height: TrackletSpacing.sm),
              Expanded(
                child: FutureBuilder<List<BusRoute>>(
                  future: transitRepo.getRoutes(),
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
                              'Could not load campus routes',
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
                    final routes = snapshot.data ?? [];
                    if (routes.isEmpty) {
                      return Center(
                        child: Text(
                          'No campus routes available',
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
                      itemCount: routes.length,
                      separatorBuilder:
                          (_, _) => Divider(
                            color: TrackletColors.adaptiveDivider(context),
                            height: TrackletSpacing.hairline,
                          ),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final isSelected = route.id == selectedRouteId;
                        return InkWell(
                          onTap: () => Navigator.pop(context, route),
                          borderRadius: TrackletRadii.roundedSm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: TrackletSpacing.compactMd,
                              horizontal: TrackletSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: TrackletSpacing.compactMd,
                                    vertical: TrackletSpacing.compact,
                                  ),
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
                                  child: Text(
                                    route.code,
                                    style: TrackletFonts.outfit(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isSelected
                                              ? TrackletColors.textInverse
                                              : (isDark
                                                  ? TrackletColors.primaryDark
                                                  : TrackletColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        route.name,
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
                                      if (route.description != null) ...[
                                        const SizedBox(
                                          height: TrackletSpacing.xxs,
                                        ),
                                        Text(
                                          route.description!,
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
