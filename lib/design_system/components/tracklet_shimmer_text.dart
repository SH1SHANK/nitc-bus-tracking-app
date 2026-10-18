import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/motion.dart';

/// A restrained, accessible shimmer effect for loading text and placeholders.
///
/// Automatically respects system reduced-motion accessibility settings.
class TrackletShimmerText extends StatefulWidget {
  const TrackletShimmerText({
    super.key,
    required this.text,
    this.style,
    this.baseColor,
    this.highlightColor,
    this.duration = TrackletMotion.shimmer,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<TrackletShimmerText> createState() => _TrackletShimmerTextState();
}

class _TrackletShimmerTextState extends State<TrackletShimmerText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller?.stop();
    } else {
      _controller ??= AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat();
      if (!_controller!.isAnimating) {
        _controller!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final theme = Theme.of(context);
    final textStyle = widget.style ?? theme.textTheme.bodyMedium;

    if (disableAnimations || _controller == null) {
      return Text(widget.text, style: textStyle, textAlign: widget.textAlign);
    }

    final isDark = theme.brightness == Brightness.dark;
    final base =
        widget.baseColor ??
        (isDark ? TrackletColors.textSecondary : TrackletColors.textTertiary);
    final highlight =
        widget.highlightColor ??
        (isDark ? Colors.white : TrackletColors.textPrimary);

    final textWidget = Text(
      widget.text,
      style: textStyle?.copyWith(color: Colors.white),
      textAlign: widget.textAlign,
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final double value = _controller!.value;
              return LinearGradient(
                begin: const Alignment(-1.0, 0.0),
                end: const Alignment(2.0, 0.0),
                stops: [
                  (value - 0.25).clamp(0.0, 1.0),
                  value.clamp(0.0, 1.0),
                  (value + 0.25).clamp(0.0, 1.0),
                ],
                colors: [base, highlight, base],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: textWidget,
      ),
    );
  }
}
