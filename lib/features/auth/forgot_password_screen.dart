import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/turnstile_service.dart';
import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/auth_provider.dart';

/// Authentic Attendrix-styled Forgot Password screen with Supabase Auth magic link recovery.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We’ll need your email to help you reset your password.',
            style: TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid email address.',
            style: TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? captchaToken;
    try {
      captchaToken = await TurnstileService.instance.getCaptchaToken(
        action: 'password_reset',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final rawMsg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Error: ', '');
      if (rawMsg.contains('Verification cancelled')) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rawMsg,
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordRecovery(email, captchaToken: captchaToken);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Generic confirmation prevents email enumeration
    unawaited(
      context.push('/reset-password-sent?email=${Uri.encodeComponent(email)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: TrackletColors.primaryBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 36.0),

                // Brand Lockup
                const TrackletBrandLockup(logoSize: 42.0, wordmarkHeight: 24.0)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0),
                    ),

                const SizedBox(height: 18.0),

                // Title
                const Align(
                      alignment: AlignmentDirectional(0.0, -1.0),
                      child: Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: TrackletTypography.displaySmall,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

                // Subtitle
                const Align(
                      alignment: AlignmentDirectional(0.0, -1.0),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: TrackletSpacing.xs,
                          bottom: TrackletSpacing.xl,
                        ),
                        child: Text(
                          'We’ve got you covered, no stress!\nJust drop your email below... ',
                          textAlign: TextAlign.center,
                          style: TrackletTypography.labelLarge,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 50.ms)
                    .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),

                // Email Input Field
                Padding(
                  padding: const EdgeInsets.only(bottom: TrackletSpacing.sm),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _focusNode,
                      autofocus: false,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: TrackletColors.primaryText,
                      style: TrackletTypography.bodyMedium.copyWith(
                        color: TrackletColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: false,
                        labelText: 'Your Email Address:',
                        labelStyle: TrackletTypography.labelMedium.copyWith(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: TrackletColors.secondaryText,
                        ),
                        hintText: 'joedoe@email.com',
                        hintStyle: TrackletTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.normal,
                          color: TrackletColors.secondaryText,
                        ),
                        filled: true,
                        fillColor: TrackletColors.secondaryBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.md,
                          vertical: TrackletSpacing.md,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: TrackletColors.inputBorder,
                            width: 2.0,
                          ),
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: TrackletColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: TrackletColors.errorBorder,
                            width: 2.0,
                          ),
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: TrackletColors.errorBorder,
                            width: 2.0,
                          ),
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                      ),
                      onFieldSubmitted: (_) => _handleSendLink(),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                // Send Magic Link Button
                Align(
                      alignment: const AlignmentDirectional(0.0, -0.8),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: TrackletSpacing.xs,
                          bottom: TrackletSpacing.sm,
                        ),
                        child: SizedBox(
                          width: 257.0,
                          height: 44.0,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TrackletColors.primaryText,
                              foregroundColor: TrackletColors.primaryBackground,
                              elevation: 3.0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: TrackletRadii.roundedButton,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: TrackletColors.primaryBackground,
                                      ),
                                    )
                                    : Text(
                                      'Send Magic Link',
                                      style: TrackletTypography.titleSmall
                                          .copyWith(
                                            color:
                                                TrackletColors
                                                    .primaryBackground,
                                          ),
                                    ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                // Head Back To Login Link
                Padding(
                  padding: const EdgeInsets.only(top: TrackletSpacing.md),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Head Back To Login Page',
                          style: TrackletTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: TrackletColors.secondaryText,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(width: TrackletSpacing.sm),
                        const TrackletIcon(
                          TrackletIcons.chevronLeft,
                          color: TrackletColors.secondaryText,
                          size: 24.0,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
