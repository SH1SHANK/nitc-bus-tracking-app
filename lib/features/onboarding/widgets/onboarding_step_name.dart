import 'package:tracklet/design_system/tokens/radii.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 2: Academic profile — Name entry with Attendrix aesthetic.
class OnboardingStepName extends StatefulWidget {
  const OnboardingStepName({
    super.key,
    required this.initialName,
    required this.onContinue,
  });

  final String initialName;
  final ValueChanged<String> onContinue;

  @override
  State<OnboardingStepName> createState() => _OnboardingStepNameState();
}

class _OnboardingStepNameState extends State<OnboardingStepName> {
  late final TextEditingController _controller;
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _currentName = widget.initialName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _currentName.trim().length >= 2;
    final isDark = TrackletColors.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.md),

          // Title
          Text(
            "Let's Set Up Your Academic Profile",
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: TrackletColors.adaptiveTextPrimary(context),
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle with Attendrix "Tap to Learn More." link
          RichText(
            text: TextSpan(
              style: TrackletTypography.bodySmall.copyWith(
                color: TrackletColors.adaptiveTextSecondary(context),
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text:
                      'Tell us your name so we can personalize your bus passes, saved stops, and campus timetable. ',
                ),
                TextSpan(
                  text: 'Tap to Learn More.',
                  style: const TextStyle(
                    color: TrackletColors.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your profile is kept safe locally and used for NITC campus transit personalization.',
                              ),
                              backgroundColor: TrackletColors.primary,
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Input Label
          Text(
            'What is your full name?',
            style: TrackletTypography.titleSmall.copyWith(
              color: TrackletColors.adaptiveTextSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Attendrix Styled Input Container
          Container(
            height: 54,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? TrackletColors.darkSurfaceContainerHighest
                      : TrackletColors.background,
              borderRadius: TrackletRadii.roundedCard,
              border: Border.all(
                color:
                    isValid
                        ? TrackletColors.primary
                        : (isDark
                            ? TrackletColors.darkBorder
                            : TrackletColors.border),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                TrackletIcon(
                  TrackletIcons.profile,
                  color: TrackletColors.adaptiveTextSecondary(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shashank Mergu',
                      hintStyle: TextStyle(
                        color: TrackletColors.adaptiveTextMuted(context),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TrackletTypography.titleMedium.copyWith(
                      color: TrackletColors.adaptiveTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    onChanged: (val) => setState(() => _currentName = val),
                  ),
                ),
                if (_currentName.isNotEmpty)
                  IconButton(
                    icon: TrackletIcon(
                      TrackletIcons.close,
                      size: 16,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _currentName = '');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xxl * 1.5),

          // Continue button
          TrackletButton(
            label: 'Continue',
            icon: const TrackletIcon(
              TrackletIcons.chevronRight,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed:
                isValid ? () => widget.onContinue(_currentName.trim()) : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
