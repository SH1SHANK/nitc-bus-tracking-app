import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';

import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import 'onboarding_entrance.dart';
import 'onboarding_username_illustration.dart';

/// Username setup with availability feedback and a generated-name action.
class OnboardingStepUsername extends StatefulWidget {
  const OnboardingStepUsername({
    super.key,
    required this.initialUsername,
    required this.isAvailable,
    this.isCheckingUsername = false,
    required this.onUsernameChanged,
    required this.onMagicWandPressed,
    required this.onContinue,
  });

  final String initialUsername;
  final bool? isAvailable;
  final bool isCheckingUsername;
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
      _controller.value = TextEditingValue(
        text: widget.initialUsername,
        selection: TextSelection.collapsed(
          offset: widget.initialUsername.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildValidationFeedback({
    required String text,
    required bool isLengthValid,
  }) {
    final String message;
    final Color color;
    final IconData icon;
    final Widget? trailing;

    if (text.isEmpty) {
      message = '3–16 characters · letters, numbers, and underscores';
      color = TrackletColors.textSecondary;
      icon = Icons.info_outline_rounded;
      trailing = null;
    } else if (!isLengthValid) {
      message = 'Choose 3–16 characters for your username';
      color = TrackletColors.errorBorder;
      icon = Icons.info_outline_rounded;
      trailing = null;
    } else if (widget.isCheckingUsername) {
      message = 'Checking username availability';
      color = TrackletColors.textSecondary;
      icon = Icons.circle;
      trailing = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: TrackletColors.primary,
        ),
      );
    } else if (widget.isAvailable == true) {
      message = 'Username available';
      color = TrackletColors.primary;
      icon = Icons.verified_outlined;
      trailing = null;
    } else if (widget.isAvailable == false) {
      message = 'Sorry, username already taken';
      color = TrackletColors.errorBorder;
      icon = Icons.warning_amber_rounded;
      trailing = null;
    } else {
      message = 'Availability has not been checked yet';
      color = TrackletColors.textSecondary;
      icon = Icons.info_outline_rounded;
      trailing = null;
    }

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : 180.ms;

    return SizedBox(
      height: 24,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Row(
          key: ValueKey(message),
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TrackletTypography.bodyMedium.copyWith(
                  fontFamily: TrackletTypography.secondaryFontFamily,
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final isLengthValid = text.length >= 3 && text.length <= 16;
    final canContinue =
        isLengthValid &&
        widget.isAvailable == true &&
        !widget.isCheckingUsername;
    final topSpace = (MediaQuery.sizeOf(context).height * 0.11)
        .clamp(56.0, 108.0)
        .toDouble();
    final illustrationWidth = (MediaQuery.sizeOf(context).width * 0.56)
        .clamp(196.0, 320.0)
        .toDouble();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSpace),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: illustrationWidth,
              child: const OnboardingUsernameIllustration(),
            ).enterOnboarding(context),
          ),
          const SizedBox(height: 28),
          Text(
            'Choose Your Username',
            style: TrackletTypography.headlineLarge.copyWith(
              fontFamily: TrackletTypography.secondaryFontFamily,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
              color: TrackletColors.textPrimary,
            ),
          ).enterOnboarding(context, delay: 40.ms),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              style: TrackletTypography.bodyMedium.copyWith(
                fontFamily: TrackletTypography.secondaryFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TrackletColors.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: "This is how you'll be known across Tracklet. Craft something uniquely yours, or tap the ",
                ),
                TextSpan(
                  text: 'magic wand',
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color: TrackletColors.tertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const TextSpan(text: ' for a suggestion.'),
              ],
            ),
          ).enterOnboarding(context, delay: 70.ms),
          const SizedBox(height: TrackletSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.nickname],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TrackletTypography.bodyMedium.copyWith(
                      fontFamily: TrackletTypography.secondaryFontFamily,
                      color: TrackletColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: TrackletColors.alternate,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: TrackletColors.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.82),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                  ),
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color: TrackletColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (value) {
                    widget.onUsernameChanged(value);
                    setState(() {});
                  },
                  onFieldSubmitted: (_) {
                    if (canContinue) widget.onContinue();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Generate a username',
                child: Material(
                  color: TrackletColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: widget.onMagicWandPressed,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).enterOnboarding(context, delay: 100.ms),
          const SizedBox(height: 8),
          _buildValidationFeedback(text: text, isLengthValid: isLengthValid),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 130,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canContinue ? widget.onContinue : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: Colors.white,
                ),
                label: Text(
                  'Continue',
                  style: TrackletTypography.titleSmall.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  disabledBackgroundColor: TrackletColors.primary.withValues(
                    alpha: 0.42,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ).enterOnboarding(context, delay: 140.ms),
          const SizedBox(height: TrackletSpacing.xl),
        ],
      ),
    );
  }
}
