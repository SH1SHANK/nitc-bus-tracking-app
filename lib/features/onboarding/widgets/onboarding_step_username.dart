import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 6: Username setup with live availability check and magic wand randomizer.
class OnboardingStepUsername extends StatefulWidget {
  const OnboardingStepUsername({
    super.key,
    required this.initialUsername,
    required this.isAvailable,
    required this.onUsernameChanged,
    required this.onMagicWandPressed,
    required this.onContinue,
  });

  final String initialUsername;
  final bool? isAvailable;
  final ValueChanged<String> onUsernameChanged;
  final VoidCallback onMagicWandPressed;
  final VoidCallback onContinue;

  @override
  State<OnboardingStepUsername> createState() => _OnboardingStepUsernameState();
}

class _OnboardingStepUsernameState extends State<OnboardingStepUsername> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void didUpdateWidget(covariant OnboardingStepUsername oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUsername != widget.initialUsername &&
        _controller.text != widget.initialUsername) {
      _controller.text = widget.initialUsername;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final isAvailable = widget.isAvailable ?? true;
    final canContinue = hasText && isAvailable;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.sm),

          // Illustration
          Center(
            child: Container(
              height: 180,
              width: 220,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0E7FF), Color(0xFFEDE9FE)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Young_Man_with_Laptop.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_pin_rounded,
                      size: 80,
                      color: TrackletColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Title
          Text(
            'Choose Your Username',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          RichText(
            text: const TextSpan(
              style: TrackletTypography.bodyMedium,
              children: [
                TextSpan(
                  text: "This is how you'll be known across Tracklet. Craft something uniquely yours, or tap the ",
                ),
                TextSpan(
                  text: 'magic wand',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' for a suggestion.'),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Username Field + Magic Wand Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: TrackletColors.surface,
                    borderRadius: TrackletRadii.roundedMd,
                    border: Border.all(
                      color: hasText
                          ? (isAvailable
                                ? TrackletColors.primary
                                : TrackletColors.busDelayed)
                          : TrackletColors.border,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '@',
                        style: TrackletTypography.titleLarge.copyWith(
                          color: TrackletColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: TrackletSpacing.xs),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'username',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TrackletTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: widget.onUsernameChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: TrackletSpacing.sm),

              // Magic Wand Button
              InkWell(
                onTap: widget.onMagicWandPressed,
                borderRadius: TrackletRadii.roundedMd,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary,
                    borderRadius: TrackletRadii.roundedMd,
                    boxShadow: [
                      BoxShadow(
                        color: TrackletColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🪄', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.sm),

          // Live validation status
          if (hasText) ...[
            if (!isAvailable)
              Row(
                children: [
                  const TrackletIcon(
                    TrackletIcons.warning,
                    color: TrackletColors.busDelayed,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'sorry, username already taken ⚠️',
                    style: TrackletTypography.labelSmall.copyWith(
                      color: TrackletColors.busDelayed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const TrackletIcon(
                    TrackletIcons.check,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'username available 🗹',
                    style: TrackletTypography.labelSmall.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
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
            onPressed: canContinue ? widget.onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
