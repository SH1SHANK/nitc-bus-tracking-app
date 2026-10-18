import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:go_router/go_router.dart';

import '../design_system/components/icons/tracklet_icons.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/motion.dart';
import '../design_system/tokens/radii.dart';
import '../design_system/tokens/shadows.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';

/// Redesigned navigation shell for Tracklet featuring a floating curved dock
/// with haptic feedback, fluid animated active indicators, and an elevated MAP action button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final surfaceColor = TrackletColors.adaptiveSurface(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              border: Border(
                top: BorderSide(
                  color:
                      isDark
                          ? TrackletColors.darkCardBorder
                          : TrackletColors.cardBorder,
                  width: 1.0,
                ),
              ),
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
                      animatedIcon: animated.home,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),

                    // Placeholder spacing for center elevated button
                    const SizedBox(width: TrackletSpacing.bottomBarHeight),

                    // 3. Profile Item
                    _NavBarItem(
                      animatedIcon: animated.user,
                      label: 'Profile',
                      isSelected: currentIndex == 2,
                      onTap: () => _onTabSelected(2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center Floating Elevated MAP Action Button
          Positioned(
            top: -20,
            child: _ElevatedCenterMapButton(
              isSelected: currentIndex == 1,
              onTap: () => _onTabSelected(1),
              ringColor: surfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatefulWidget {
  const _NavBarItem({
    required this.animatedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final animated.LucideAnimatedIconData animatedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  late final animated.LucideAnimatedIconController _controller;

  @override
  void initState() {
    super.initState();
    _controller = animated.LucideAnimatedIconController();
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.animate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = TrackletColors.primary;
    final inactiveColor =
        isDark
            ? TrackletColors.darkTextSecondary
            : TrackletColors.textSecondary;
    final isSelected = widget.isSelected;
    final label = widget.label;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label navigation tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.animate();
            widget.onTap();
          },
          borderRadius: TrackletRadii.roundedPill,
          splashColor: activeColor.withValues(alpha: 0.12),
          highlightColor: activeColor.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: TrackletMotion.fast,
            curve: TrackletMotion.easeOut,
            constraints: const BoxConstraints(
              minWidth: 72,
              minHeight: TrackletSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.md,
              vertical: TrackletSpacing.xs,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? activeColor.withValues(alpha: isDark ? 0.14 : 0.08)
                      : Colors.transparent,
              borderRadius: TrackletRadii.roundedPill,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.10 : 1.0,
                  duration: TrackletMotion.fast,
                  curve: TrackletMotion.spring,
                  child: animated.LucideAnimatedIcon(
                    icon: widget.animatedIcon,
                    controller: _controller,
                    trigger: animated.AnimationTrigger.manual,
                    color: isSelected ? activeColor : inactiveColor,
                    size: TrackletSpacing.iconLg,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: TrackletMotion.fast,
                  curve: TrackletMotion.easeOut,
                  style: TrackletTypography.caption.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                // Micro-indicator pill
                AnimatedContainer(
                  duration: TrackletMotion.fast,
                  curve: TrackletMotion.easeOut,
                  height: 3,
                  width: isSelected ? 14 : 0,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElevatedCenterMapButton extends StatefulWidget {
  const _ElevatedCenterMapButton({
    required this.isSelected,
    required this.onTap,
    required this.ringColor,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Color ringColor;

  @override
  State<_ElevatedCenterMapButton> createState() =>
      _ElevatedCenterMapButtonState();
}

class _ElevatedCenterMapButtonState extends State<_ElevatedCenterMapButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.isSelected;
    const primaryColor = TrackletColors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Map navigation button',
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Floating Button with spring bounce & halo
            AnimatedScale(
              scale: _isPressed ? 0.90 : (isSelected ? 1.06 : 1.0),
              duration: TrackletMotion.micro,
              curve: TrackletMotion.spring,
              child: AnimatedContainer(
                duration: TrackletMotion.fast,
                curve: TrackletMotion.easeOut,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.ringColor,
                    width: isSelected ? 4.0 : 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(
                        alpha:
                            isSelected
                                ? (isDark ? 0.55 : 0.45)
                                : (isDark ? 0.35 : 0.28),
                      ),
                      blurRadius: isSelected ? 18 : 12,
                      spreadRadius: isSelected ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    TrackletIcons.map,
                    color: TrackletColors.textInverse,
                    size: isSelected ? 28 : TrackletSpacing.iconLg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: TrackletMotion.fast,
              curve: TrackletMotion.easeOut,
              style: TrackletTypography.caption.copyWith(
                color:
                    isSelected
                        ? primaryColor
                        : (isDark
                            ? TrackletColors.darkTextSecondary
                            : TrackletColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.8,
              ),
              child: const Text('MAP'),
            ),
            const SizedBox(height: 2),
            // Micro indicator dot for MAP
            AnimatedContainer(
              duration: TrackletMotion.fast,
              curve: TrackletMotion.easeOut,
              height: 3,
              width: isSelected ? 14 : 0,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
