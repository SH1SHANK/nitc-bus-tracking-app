import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 2: Academic profile — Name entry with dynamic avatar initial preview.
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
    final initial = _currentName.trim().isNotEmpty
        ? _currentName.trim().substring(0, 1).toUpperCase()
        : 'N';

    final isValid = _currentName.trim().length >= 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.lg),

          // Title & Description
          Text(
            "What's Your Name?",
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'We use this to personalize your student pass, bus notifications, and campus profile.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Live Avatar Initial Badge
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TrackletTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Name Input Field
          Text(
            'Full Name',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: TrackletColors.surface,
              borderRadius: TrackletRadii.roundedMd,
              border: Border.all(
                color: isValid ? TrackletColors.primary : TrackletColors.border,
                width: isValid ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.md,
              vertical: 4,
            ),
            child: Row(
              children: [
                const TrackletIcon(
                  TrackletIcons.profile,
                  color: TrackletColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: TrackletSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Shashank Mergu',
                      border: InputBorder.none,
                    ),
                    style: TrackletTypography.titleLarge,
                    onChanged: (val) => setState(() => _currentName = val),
                  ),
                ),
                if (_currentName.isNotEmpty)
                  IconButton(
                    icon: const TrackletIcon(
                      TrackletIcons.close,
                      size: 16,
                      color: TrackletColors.textSecondary,
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
            onPressed: isValid
                ? () => widget.onContinue(_currentName.trim())
                : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
