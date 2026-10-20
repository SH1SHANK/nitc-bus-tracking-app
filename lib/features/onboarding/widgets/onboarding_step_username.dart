import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/validation/username_validator.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/motion.dart';
import '../../../design_system/tokens/radii.dart';
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
    this.validationError,
    required this.onUsernameChanged,
    required this.onMagicWandPressed,
    required this.onContinue,
  });

  final String initialUsername;
  final bool? isAvailable;
  final bool isCheckingUsername;
  final String? validationError;
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
    required BuildContext context,
    required String text,
    required UsernameValidationResult localValidation,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String message;
    final Color color;
    final IconData icon;
    final Widget? trailing;

    if (text.isEmpty) {
      message = '3–20 characters · letters, numbers, and underscores';
      color =
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.textSecondary;
      icon = TrackletIcons.info;
      trailing = null;
    } else if (!localValidation.isValid) {
      message = localValidation.errorMessage ?? 'Invalid username format';
      color = TrackletColors.errorBorder;
      icon = TrackletIcons.info;
      trailing = null;
    } else if (widget.isCheckingUsername) {
      message = 'Checking username availability...';
      color =
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.textSecondary;
      icon = TrackletIcons.circle;
      trailing = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: TrackletColors.primary,
        ),
      );
    } else if (widget.validationError != null) {
      message = widget.validationError!;
      color = TrackletColors.errorBorder;
      icon = TrackletIcons.alertTriangle;
      trailing = null;
    } else if (widget.isAvailable == true) {
      message = 'Username available';
      color = TrackletColors.success;
      icon = TrackletIcons.checkCircle2;
      trailing = null;
    } else if (widget.isAvailable == false) {
      message = 'Username is already taken';
      color = TrackletColors.errorBorder;
      icon = TrackletIcons.alertTriangle;
      trailing = null;
    } else {
      message = 'Availability has not been checked yet';
      color =
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.textSecondary;
      icon = TrackletIcons.info;
      trailing = null;
    }

    final duration = TrackletMotion.adaptiveDuration(
      context,
      TrackletMotion.fast,
    );

    return SizedBox(
      height: 24,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: TrackletMotion.easeOut,
        switchOutCurve: TrackletMotion.easeIn,
        transitionBuilder:
            (child, animation) => FadeTransition(
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
                  fontSize: TrackletTypography.fontSize13,
                  fontWeight: TrackletTypography.weightBold,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _controller.text.trim();
    final localValidation = UsernameValidator.validate(text);
    final canContinue =
        localValidation.isValid &&
        widget.isAvailable == true &&
        !widget.isCheckingUsername &&
        widget.validationError == null;
    final topSpace =
        (MediaQuery.sizeOf(context).height * 0.11)
            .clamp(56.0, 108.0)
            .toDouble();
    final illustrationWidth =
        (MediaQuery.sizeOf(context).width * 0.56)
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
              fontSize: TrackletTypography.fontSize22,
              height: TrackletTypography.lineHeightTight,
              fontWeight: TrackletTypography.weightExtraBold,
              letterSpacing: TrackletTypography.letterSpacingHeading,
              color:
                  isDark
                      ? TrackletColors.darkTextPrimary
                      : TrackletColors.textPrimary,
            ),
          ).enterOnboarding(context, delay: 40.ms),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              style: TrackletTypography.bodyMedium.copyWith(
                fontFamily: TrackletTypography.secondaryFontFamily,
                fontSize: TrackletTypography.fontSize14,
                fontWeight: TrackletTypography.weightSemiBold,
                color:
                    isDark
                        ? TrackletColors.darkTextSecondary
                        : TrackletColors.textSecondary,
                height: TrackletTypography.lineHeightBody,
              ),
              children: [
                const TextSpan(
                  text:
                      "This is how you'll be known across BusTracker. Enter a username, or tap the ",
                ),
                TextSpan(
                  text: 'suggestion button',
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color: TrackletColors.tertiary,
                    fontWeight: TrackletTypography.weightExtraBold,
                    fontSize: TrackletTypography.fontSize14,
                  ),
                ),
                const TextSpan(text: ' to generate one.'),
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
                    LengthLimitingTextInputFormatter(
                      UsernameValidator.maxLength,
                    ),
                  ],
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TrackletTypography.bodyMedium.copyWith(
                      fontFamily: TrackletTypography.secondaryFontFamily,
                      color:
                          isDark
                              ? TrackletColors.darkTextSecondary
                              : TrackletColors.textSecondary,
                      fontSize: TrackletTypography.fontSize16,
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? TrackletColors.darkBorder
                                : TrackletColors.alternate,
                        width: 2,
                      ),
                      borderRadius: TrackletRadii.roundedBanner,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: TrackletColors.primary,
                        width: 2,
                      ),
                      borderRadius: TrackletRadii.roundedBanner,
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? TrackletColors.darkSurfaceElevated
                            : TrackletColors.textInverse.withValues(
                              alpha: 0.82,
                            ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.lg,
                      vertical: 15,
                    ),
                  ),
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color:
                        isDark
                            ? TrackletColors.darkTextPrimary
                            : TrackletColors.textPrimary,
                    fontSize: TrackletTypography.fontSize16,
                    fontWeight: TrackletTypography.weightBold,
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
                  borderRadius: TrackletRadii.roundedBanner,
                  child: InkWell(
                    onTap: widget.onMagicWandPressed,
                    borderRadius: TrackletRadii.roundedBanner,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        TrackletIcons.sparkles,
                        color: TrackletColors.textInverse,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).enterOnboarding(context, delay: 100.ms),
          const SizedBox(height: 8),
          _buildValidationFeedback(
            context: context,
            text: text,
            localValidation: localValidation,
          ),
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
                  TrackletIcons.arrowRight,
                  size: 19,
                  color: TrackletColors.textInverse,
                ),
                label: Text(
                  'Continue',
                  style: TrackletTypography.titleSmall.copyWith(
                    fontFamily: TrackletTypography.secondaryFontFamily,
                    color: TrackletColors.textInverse,
                    fontSize: TrackletTypography.fontSize15,
                    fontWeight: TrackletTypography.weightExtraBold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  disabledBackgroundColor: TrackletColors.primary.withValues(
                    alpha: 0.42,
                  ),
                  elevation: TrackletShadows.elevationLevel0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedCard,
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
