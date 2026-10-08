import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step: Username setup with live availability check, magic wand randomizer,
/// quick-suggestion chips, and authentic Attendrix layout styling.
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

  final List<String> _quickSuggestions = [
    'nitc_rider',
    'campus_surfer',
    'mega_commuter',
    'calicut_transit',
  ];

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

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    widget.onUsernameChanged(suggestion);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;
    final isLengthValid = text.length >= 3;
    final isAvailable = widget.isAvailable ?? true;
    final canContinue = hasText && isLengthValid && isAvailable;

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
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutBack,
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
              )
              .animate()
              .fadeIn(duration: 350.ms, delay: 50.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
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
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: TrackletSpacing.lg),

          // Text Field & Magic Wand Button Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  obscureText: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  maxLength: 16,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'username',
                    hintStyle: TrackletTypography.labelLarge.copyWith(
                      color: TrackletColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '@',
                        style: TextStyle(
                          fontFamily: TrackletTypography.primaryFontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: TrackletColors.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 0,
                    ),
                    suffixIcon: hasText
                        ? InkWell(
                            onTap: () {
                              _controller.clear();
                              widget.onUsernameChanged('');
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: TrackletColors.secondaryText,
                            ),
                          )
                        : null,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(TrackletRadii.card),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: TrackletColors.primary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(TrackletRadii.card),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: TrackletColors.errorBorder,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(TrackletRadii.card),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: TrackletColors.errorBorder,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(TrackletRadii.card),
                    ),
                    filled: true,
                    fillColor: TrackletColors.primaryBackground,
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      14.0,
                      16.0,
                      14.0,
                      16.0,
                    ),
                  ),
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontFamily: TrackletTypography.primaryFontFamily,
                    color: TrackletColors.altPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) {
                    widget.onUsernameChanged(val);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Attendrix Magic Wand Icon Button
              Material(
                color: Colors.transparent,
                child: InkWell(
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
                          color: TrackletColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/Magic_Icon_Pack.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: TrackletColors.pure,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 10),

          // Live Validation Feedback
          if (hasText) ...[
            if (!isLengthValid)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: TrackletColors.secondaryText,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Username must be at least 3 characters',
                      style: TrackletTypography.caption.copyWith(
                        color: TrackletColors.secondaryText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (!isAvailable)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: TrackletColors.errorBorder,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'sorry, username already taken',
                      style: TrackletTypography.caption.copyWith(
                        color: TrackletColors.errorBorder,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: TrackletColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'username available',
                      style: TrackletTypography.caption.copyWith(
                        color: TrackletColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),

          // Quick Suggestion Chips (UX Enhancement)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK SUGGESTIONS',
                style: TrackletTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: TrackletColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSuggestions.map((suggestion) {
                  final isSelected = text == suggestion;
                  return InkWell(
                    onTap: () => _applySuggestion(suggestion),
                    borderRadius: BorderRadius.circular(TrackletRadii.full),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TrackletColors.primary.withValues(alpha: 0.12)
                            : TrackletColors.primaryBackground,
                        borderRadius: BorderRadius.circular(TrackletRadii.full),
                        border: Border.all(
                          color: isSelected
                              ? TrackletColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '@$suggestion',
                        style: TextStyle(
                          fontFamily: TrackletTypography.primaryFontFamily,
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? TrackletColors.primary
                              : TrackletColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
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
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
