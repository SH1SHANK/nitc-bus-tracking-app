import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/transit_repository.dart';
import '../../../design_system/tokens/colors.dart';
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
        decoration: const BoxDecoration(
          color: TrackletColors.secondaryBackground,
          borderRadius: TrackletRadii.roundedLg,
          boxShadow: [
            BoxShadow(
              blurRadius: 18.0,
              color: TrackletColors.scrim,
              offset: Offset(0.0, 6.0),
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
                        color: TrackletColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TrackletColors.secondaryText,
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
                  color: TrackletColors.secondaryText,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              const Divider(color: TrackletColors.alternate),
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
                              Icons.error_outline_rounded,
                              color: TrackletColors.error,
                              size: 36.0,
                            ),
                            const SizedBox(height: TrackletSpacing.sm),
                            Text(
                              'Failed to load campus routes',
                              style: TrackletFonts.outfit(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: TrackletColors.textPrimary,
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
                            color: TrackletColors.secondaryText,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: routes.length,
                      separatorBuilder:
                          (_, _) => const Divider(
                            color: TrackletColors.alternate,
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
                                            : TrackletColors.primaryBackground,
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
                                              : TrackletColors.primary,
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
                                                  ? TrackletColors.primary
                                                  : TrackletColors.textPrimary,
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
                                            color: TrackletColors.secondaryText,
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
                                    Icons.check_circle_rounded,
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
