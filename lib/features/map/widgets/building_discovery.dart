import 'package:flutter/material.dart';

import '../../../data/campus/campus_building.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

class BuildingSearchSheet extends StatefulWidget {
  const BuildingSearchSheet({super.key, required this.buildings});

  final List<CampusBuilding> buildings;

  @override
  State<BuildingSearchSheet> createState() => _BuildingSearchSheetState();
}

class _BuildingSearchSheetState extends State<BuildingSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final buildings = widget.buildings
        .where(
          (building) =>
              building.name.toLowerCase().contains(query) ||
              (building.category?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: TrackletSpacing.screenMargin,
          right: TrackletSpacing.screenMargin,
          top: TrackletSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + TrackletSpacing.md,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find a campus building',
                style: TrackletTypography.titleLarge.copyWith(
                  color: TrackletColors.adaptiveTextPrimary(context),
                  fontWeight: TrackletTypography.weightBold,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(TrackletIcons.search, size: 20),
                  hintText: 'Search by name or category',
                  filled: true,
                  fillColor: TrackletColors.adaptiveSurfaceContainer(context),
                  border: const OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedMd,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: TrackletSpacing.sm),
              Expanded(
                child:
                    buildings.isEmpty
                        ? Center(
                          child: Text(
                            'No matching buildings',
                            style: TrackletTypography.bodyMedium.copyWith(
                              color: TrackletColors.adaptiveTextSecondary(
                                context,
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: buildings.length,
                          itemBuilder: (context, index) {
                            final building = buildings[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: TrackletSpacing.sm,
                              ),
                              leading: const Icon(
                                TrackletIcons.building,
                                color: TrackletColors.primary,
                              ),
                              title: Text(
                                building.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TrackletTypography.bodyLarge.copyWith(
                                  color: TrackletColors.adaptiveTextPrimary(
                                    context,
                                  ),
                                  fontWeight: TrackletTypography.weightMedium,
                                ),
                              ),
                              subtitle:
                                  building.category == null
                                      ? null
                                      : Text(
                                        building.category!,
                                        style: TrackletTypography.bodySmall
                                            .copyWith(
                                              color:
                                                  TrackletColors.adaptiveTextSecondary(
                                                    context,
                                                  ),
                                            ),
                                      ),
                              onTap: () => Navigator.pop(context, building),
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

class BuildingDetailSheet extends StatelessWidget {
  const BuildingDetailSheet({
    super.key,
    required this.building,
    required this.onClose,
  });

  final CampusBuilding building;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      elevation: TrackletShadows.elevationLevel4,
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.md),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TrackletColors.primary.withValues(alpha: 0.12),
                borderRadius: TrackletRadii.roundedMd,
              ),
              child: const Icon(
                TrackletIcons.building,
                size: 20,
                color: TrackletColors.primary,
              ),
            ),
            const SizedBox(width: TrackletSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    building.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TrackletTypography.titleMedium.copyWith(
                      color: TrackletColors.adaptiveTextPrimary(context),
                      fontWeight: TrackletTypography.weightBold,
                    ),
                  ),
                  if (building.category != null) ...[
                    const SizedBox(height: TrackletSpacing.xxs),
                    Text(
                      building.category!,
                      style: TrackletTypography.labelMedium.copyWith(
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                  if (building.description != null) ...[
                    const SizedBox(height: TrackletSpacing.xs),
                    Text(
                      building.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TrackletTypography.bodySmall.copyWith(
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              tooltip: 'Close building details',
              icon: const Icon(TrackletIcons.x, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
