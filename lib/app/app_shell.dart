import 'package:flutter/material.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radii.dart';
import '../design_system/tokens/shadows.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';

/// Redesigned navigation shell for Tracklet featuring a sleek curved floating bottom bar
/// with an elevated central MAP action button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final surfaceColor = TrackletColors.adaptiveSurface(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Curved Bar Container
          Container(
            height:
                TrackletSpacing.bottomBarHeight +
                MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: TrackletRadii.roundedTopCurvedBar,
              boxShadow: TrackletShadows.adaptiveBottomBar(context),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Home Item
                    _NavBarItem(
                      icon: TrackletIcons.bus,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),

                    // Placeholder spacing for center elevated button
                    const SizedBox(width: TrackletSpacing.bottomBarHeight),

                    // 3. Profile Item
                    _NavBarItem(
                      icon: TrackletIcons.user,
                      label: 'Profile',
                      isSelected: currentIndex == 2,
                      onTap: () => _onTabSelected(2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center Floating Elevated MAP Button
          Positioned(
            top: -18,
            child: _ElevatedCenterMapButton(
              onTap: () => _onTabSelected(1),
              ringColor: surfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isSelected
            ? TrackletColors.primary
            : (isDark
                ? TrackletColors.darkTextSecondary
                : TrackletColors.textSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 64,
          minHeight: TrackletSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.compact,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: TrackletSpacing.iconLg),
            const SizedBox(height: 3),
            Text(
              label,
              style: TrackletTypography.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElevatedCenterMapButton extends StatelessWidget {
  const _ElevatedCenterMapButton({
    required this.onTap,
    required this.ringColor,
  });

  final VoidCallback onTap;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Floating Button
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: TrackletColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: TrackletColors.primary.withValues(alpha: 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                TrackletIcons.map,
                color: TrackletColors.textInverse,
                size: TrackletSpacing.iconLg,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'MAP',
            style: TrackletTypography.caption.copyWith(
              color: TrackletColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
