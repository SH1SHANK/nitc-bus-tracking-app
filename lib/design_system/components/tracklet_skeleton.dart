import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'tracklet_shimmer_text.dart';

/// A lightweight loading placeholder for content that has a meaningful wait.
class TrackletSkeleton extends StatefulWidget {
  const TrackletSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = TrackletRadii.roundedMd,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<TrackletSkeleton> createState() => _TrackletSkeletonState();
}

class _TrackletSkeletonState extends State<TrackletSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveBorder(context),
        borderRadius: widget.borderRadius,
      ),
      child: SizedBox(width: widget.width, height: widget.height),
    );
    if (reducedMotion) return child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: 0.55 + (_controller.value * 0.3), child: child);
      },
      child: child,
    );
  }
}

class TrackletHomeSkeleton extends StatelessWidget {
  const TrackletHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 20, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TrackletSkeleton(
                  width: 42,
                  height: 42,
                  borderRadius: TrackletRadii.roundedFull,
                ),
                SizedBox(width: TrackletSpacing.md),
                Expanded(
                  child: TrackletSkeleton(width: double.infinity, height: 18),
                ),
                SizedBox(width: TrackletSpacing.md),
                TrackletSkeleton(
                  width: 42,
                  height: 42,
                  borderRadius: TrackletRadii.roundedFull,
                ),
              ],
            ),
            SizedBox(height: TrackletSpacing.xl),
            TrackletSkeleton(width: 190, height: 24),
            SizedBox(height: TrackletSpacing.sm),
            TrackletSkeleton(width: 270, height: 16),
            SizedBox(height: TrackletSpacing.lg),
            TrackletSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: TrackletRadii.roundedCard,
            ),
            SizedBox(height: TrackletSpacing.lg),
            TrackletSkeleton(width: 130, height: 20),
            SizedBox(height: TrackletSpacing.md),
            TrackletSkeleton(
              width: double.infinity,
              height: 190,
              borderRadius: TrackletRadii.roundedCard,
            ),
            SizedBox(height: TrackletSpacing.lg),
            TrackletSkeleton(
              width: double.infinity,
              height: 150,
              borderRadius: TrackletRadii.roundedCard,
            ),
          ],
        ),
      ),
    );
  }
}

class TrackletMapSkeleton extends StatelessWidget {
  const TrackletMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: TrackletSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Positioned(
            left: TrackletSpacing.md,
            right: TrackletSpacing.md,
            bottom: TrackletSpacing.md,
            child: Material(
              color: TrackletColors.adaptiveSurfaceElevated(context),
              borderRadius: TrackletRadii.roundedXl,
              child: const Padding(
                padding: EdgeInsets.all(TrackletSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TrackletShimmerText(
                      text: 'Loading transit map...',
                      style: TrackletTypography.caption,
                    ),
                    SizedBox(height: TrackletSpacing.md),
                    TrackletSkeleton(width: 150, height: 20),
                    SizedBox(height: TrackletSpacing.md),
                    TrackletSkeleton(width: double.infinity, height: 16),
                    SizedBox(height: TrackletSpacing.sm),
                    TrackletSkeleton(width: 220, height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
