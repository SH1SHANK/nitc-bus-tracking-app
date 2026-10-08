import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/icons/tracklet_icon.dart';
import '../design_system/components/icons/tracklet_icons.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';

/// Navigation shell for Tracklet with emphasized central Map action.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: TrackletColors.surfaceElevated,
          border: Border(
            top: BorderSide(color: TrackletColors.border, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.lg,
              vertical: TrackletSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _NavBarItem(
                  icon: TrackletIcons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => _onTabSelected(0),
                ),

                // 2. Map (Emphasized Center Action)
                _CenterMapButton(
                  isSelected: currentIndex == 1,
                  onTap: () => _onTabSelected(1),
                ),

                // 3. Profile
                _NavBarItem(
                  icon: TrackletIcons.profile,
                  label: 'Profile',
                  isSelected: currentIndex == 2,
                  onTap: () => _onTabSelected(2),
                ),
              ],
            ),
          ),
        ),
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
    final color = isSelected
        ? TrackletColors.primary
        : TrackletColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrackletIcon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TrackletTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMapButton extends StatelessWidget {
  const _CenterMapButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TrackletColors.primary
              : TrackletColors.textPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? TrackletColors.primary : Colors.black)
                  .withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TrackletIcon(
              TrackletIcons.map,
              color: TrackletColors.textInverse,
              size: 20,
            ),
            const SizedBox(width: TrackletSpacing.xs),
            Text(
              'Map',
              style: TrackletTypography.labelLarge.copyWith(
                color: TrackletColors.textInverse,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
