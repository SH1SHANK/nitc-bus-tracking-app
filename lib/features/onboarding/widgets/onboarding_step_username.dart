import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step: Username setup with live availability check and magic wand randomizer.
/// Exact Attendrix layout, gradient container, and styling.
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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _focusNode = FocusNode();
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
    _focusNode.dispose();
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

          // Top Illustration Banner with Gradient Background
          Center(
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    TrackletColors.permissionHeaderGradientStart,
                    TrackletColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TrackletColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Abstract_Gradient_Background_4K.jpg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    Container(
                      color: TrackletColors.primary.withValues(alpha: 0.35),
                    ),
                    Image.asset(
                      'assets/images/Research_New_Pin_Crop.gif',
                      width: 180,
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/Young_Man_with_Laptop.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Title
          Text(
            'Choose Your Username',
            style: TrackletTypography.headlineLarge.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TrackletColors.altPrimaryText,
            ),
          ),
          const SizedBox(height: 6),

          // Attendrix Subtitle RichText
          RichText(
            text: TextSpan(
              style: TrackletTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TrackletColors.secondaryText,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: "This is how you'll be known across Tracklet. Craft something uniquely yours, or tap the ",
                ),
                TextSpan(
                  text: 'magic wand ',
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const TextSpan(text: 'for a suggestion.'),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.lg),

          // Text Field & Magic Wand Button Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: TrackletColors.primaryBackground,
                    borderRadius: BorderRadius.circular(TrackletRadii.card),
                    border: Border.all(
                      color: hasText
                          ? (isAvailable
                                ? TrackletColors.primary
                                : TrackletColors.errorBorder)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Text(
                          '@',
                          style: TextStyle(
                            fontFamily: TrackletTypography.primaryFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: false,
                          textInputAction: TextInputAction.done,
                          obscureText: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_]'),
                            ),
                          ],
                          maxLength: 16,
                          buildCounter: (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(
                              fontFamily: TrackletTypography.primaryFontFamily,
                              color: TrackletColors.secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 0,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: TrackletTypography.primaryFontFamily,
                            color: TrackletColors.altPrimaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: widget.onUsernameChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Attendrix Magic Wand Icon Button
              InkWell(
                onTap: widget.onMagicWandPressed,
                borderRadius: BorderRadius.circular(TrackletRadii.card),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary,
                    borderRadius: BorderRadius.circular(TrackletRadii.card),
                    boxShadow: [
                      BoxShadow(
                        color: TrackletColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Magic_Icon_Pack.png',
                      width: 26,
                      height: 26,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.auto_awesome_rounded,
                        color: TrackletColors.pure,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Live Validation Feedback
          if (hasText) ...[
            if (!isAvailable)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    Text(
                      'sorry, username already taken',
                      style: TrackletTypography.caption.copyWith(
                        color: TrackletColors.errorBorder,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: TrackletColors.errorBorder,
                      size: 16,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    Text(
                      'username available',
                      style: TrackletTypography.caption.copyWith(
                        color: TrackletColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/images/Check_icon.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.check_circle_rounded,
                        color: TrackletColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: TrackletSpacing.xxl),

          // Continue Button
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canContinue ? widget.onContinue : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: TrackletColors.pure,
                ),
                label: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: TrackletTypography.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TrackletColors.pure,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  disabledBackgroundColor: TrackletColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  elevation: 3,
                  shadowColor: TrackletColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TrackletRadii.card),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
