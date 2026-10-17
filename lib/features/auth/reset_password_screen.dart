import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'auth_field_decoration.dart';
import 'providers/auth_provider.dart';

/// Authentic Attendrix Reset Password Screen layout and styling.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisibility = false;
  bool _confirmPasswordVisibility = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match. Please verify and try again.',
            style: TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Success! Your new password has been updated. Please log in.',
            style: TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.success,
          duration: Duration(seconds: 4),
        ),
      );

      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Failed to update password. Please try again.',
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
    }
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
          top: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TrackletSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 28.0),

                  // Brand Lockup
                  const TrackletBrandLockup(
                    logoSize: 42.0,
                    wordmarkHeight: 24.0,
                  )
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
                          'Reset Your Password!',
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
                            'We’ve got you covered, no stress!\nJust Enter Your Brand New Password!',
                            textAlign: TextAlign.center,
                            style: TrackletTypography.labelLarge,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 50.ms)
                      .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),

                  // New Password Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: TrackletSpacing.sm),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_passwordVisibility,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: TrackletTypography.bodyMedium.copyWith(
                          color: TrackletColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a new password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _confirmPasswordFocusNode.requestFocus();
                        },
                        decoration: authInputDecoration(
                          label: 'New Password',
                          hint: 'abc123*',
                          icon: TrackletIcons.lock,
                          suffixIcon: IconButton(
                            tooltip:
                                _passwordVisibility
                                    ? 'Hide password'
                                    : 'Show password',
                            onPressed: () {
                              setState(() {
                                _passwordVisibility = !_passwordVisibility;
                              });
                            },
                            icon: Icon(
                              _passwordVisibility
                                  ? TrackletIcons.eye
                                  : TrackletIcons.eyeOff,
                              color: TrackletColors.secondaryText,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  // Confirm Password Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: TrackletSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: !_confirmPasswordVisibility,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        style: TrackletTypography.bodyMedium.copyWith(
                          color: TrackletColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your new password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleResetPassword(),
                        decoration: authInputDecoration(
                          label: 'Confirm Password',
                          hint: 'abc123*',
                          icon: TrackletIcons.lock,
                          suffixIcon: IconButton(
                            tooltip:
                                _confirmPasswordVisibility
                                    ? 'Hide password'
                                    : 'Show password',
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisibility =
                                    !_confirmPasswordVisibility;
                              });
                            },
                            icon: Icon(
                              _confirmPasswordVisibility
                                  ? TrackletIcons.eye
                                  : TrackletIcons.eyeOff,
                              color: TrackletColors.secondaryText,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                  // Set New Password Button
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
                              onPressed:
                                  _isLoading ? null : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TrackletColors.primaryText,
                                foregroundColor:
                                    TrackletColors.primaryBackground,
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
                                          color:
                                              TrackletColors.primaryBackground,
                                        ),
                                      )
                                      : Text(
                                        'Set New Password',
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
                      .fadeIn(duration: 400.ms, delay: 200.ms)
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
                        context.go('/login');
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
                  ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
