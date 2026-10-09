import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/colors.dart';

/// Redesigned navigation shell for Tracklet featuring a sleek curved floating bottom bar
/// with an elevated central MAP action button exactly matching the wireframe design.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Curved Bar Container
          Container(
            height: 72 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: TrackletColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Home Item
                    _NavBarItem(
                      icon: Icons.directions_bus_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),

                    // Placeholder spacing for center elevated button
                    const SizedBox(width: 72),

                    // 3. Profile Item
                    _NavBarItem(
                      icon: Icons.person_outline_rounded,
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
              isSelected: currentIndex == 1,
              onTap: () => _onTabSelected(1),
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
    final color = isSelected
        ? TrackletColors.primary
        : TrackletColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
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
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

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
              border: Border.all(color: TrackletColors.surface, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: TrackletColors.primary.withValues(alpha: 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.map_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'MAP',
            style: TextStyle(
              color: isSelected
                  ? TrackletColors.primary
                  : TrackletColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
