import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/turnstile_service.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/motion.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../onboarding/providers/onboarding_provider.dart';
import 'auth_field_decoration.dart';
import 'auth_validators.dart';
import 'providers/auth_provider.dart';

/// Authentic Attendrix Create Account Screen layout, styling, and Supabase Auth integration.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisibility = false;
  bool _confirmPasswordVisibility = false;
  bool _isLoading = false;

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match. Please re-enter matching passwords.',
            style: TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? captchaToken;
    try {
      captchaToken = await TurnstileService.instance.getCaptchaToken(
        action: 'signup',
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

    final result = await ref
        .read(authNotifierProvider.notifier)
        .signUp(email, password, captchaToken: captchaToken);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (result.requiresVerification) {
        _showVerificationDialog(email);
      } else {
        ref.read(onboardingProvider.notifier).reset();
        context.go('/onboarding');
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Registration failed. Try again.',
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final result =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      ref.read(onboardingProvider.notifier).reset();
      context.go('/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Google sign-in failed.',
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
    }
  }

  void _showVerificationDialog(String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: TrackletColors.primaryBackground,
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedCard,
            ),
            title: Text(
              'Verification email sent',
              style: TrackletTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: TrackletColors.primaryText,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A verification link has been sent to:\n$email\n\nVerify your email before logging in.',
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/login');
                },
                child: Text(
                  'Back to login',
                  style: TrackletTypography.titleSmall.copyWith(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor:
            isDark
                ? TrackletColors.darkBackground
                : TrackletColors.secondaryBackground,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top 40% height banner
              SizedBox(
                height: screenHeight * 0.40,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ClipRRect(
                        borderRadius: TrackletRadii.roundedInput,
                        child: Image.asset(
                          'assets/images/Clean_Login_Design_Rectangle_10.png',
                          width: double.infinity,
                          height: 320.0,
                          fit: BoxFit.fitWidth,
                          errorBuilder:
                              (_, _, _) => Container(
                                height: 320.0,
                                color: TrackletColors
                                    .permissionHeaderGradientStart
                                    .withValues(alpha: 0.2),
                              ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.0, 1.6),
                      child: ClipRRect(
                        borderRadius: TrackletRadii.roundedInput,
                        child: Image.asset(
                          'assets/images/Young_Man_with_Laptop.png',
                          width: 270.0,
                          height: 270.0,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, _, _) => Image.asset(
                                'assets/images/Young_Man_Laptop_Clean_Login_Design.png',
                                width: 250.0,
                                height: 250.0,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                    // Back navigation button
                    Positioned(
                      top: 14.0,
                      left: TrackletSpacing.screenMargin,
                      child: SafeArea(
                        child: Material(
                          color: (isDark
                                  ? TrackletColors.darkSurfaceElevated
                                  : Colors.white)
                              .withValues(alpha: 0.88),
                          shape: const CircleBorder(),
                          elevation: 2.0,
                          shadowColor: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(TrackletSpacing.sm),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color:
                                    isDark
                                        ? TrackletColors.darkTextPrimary
                                        : TrackletColors.altPrimaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Area
              AuthEntrance(
                delay: 40.ms,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    TrackletSpacing.screenMargin,
                    TrackletSpacing.screenMargin,
                    TrackletSpacing.screenMargin,
                    0.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Authoritative Brand Wordmark (Bigger On Top)
                        AuthEntrance(
                          delay: 20.ms,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: TrackletSpacing.md,
                            ),
                            child: TrackletBrandLockup.wordmarkOnly(
                              wordmarkHeight: 40.0,
                              isDark: isDark,
                            ),
                          ),
                        ),

                        // Title
                        AuthEntrance(
                          child: Text(
                            'Create account',
                            style: TrackletTypography.displaySmall.copyWith(
                              fontSize: 26.0,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? TrackletColors.darkTextPrimary
                                      : TrackletColors.altPrimaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6.0),

                        // Subtitle
                        AuthEntrance(
                          delay: 50.ms,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0,
                              0.0,
                              0.0,
                              18.0,
                            ),
                            child: Text(
                              'Enter your NITC email to register for campus bus tracking.',
                              style: TrackletTypography.labelMedium.copyWith(
                                fontSize: 14.0,
                                color:
                                    isDark
                                        ? TrackletColors.darkTextSecondary
                                        : TrackletColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Email Field
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            8.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 90.ms,
                              child: TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                autofillHints: const [
                                  AutofillHints.newUsername,
                                  AutofillHints.email,
                                ],
                                onFieldSubmitted:
                                    (_) => _passwordFocusNode.requestFocus(),
                                validator: validateNitcEmail,
                                decoration: authInputDecoration(
                                  label: 'Email address',
                                  hint: 'name@nitc.ac.in',
                                  icon: TrackletIcons.mail,
                                ),
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  color: TrackletColors.altPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Password Field
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            8.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 150.ms,
                              child: TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: !_passwordVisibility,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onChanged: (_) => setState(() {}),
                                validator: validatePassword,
                                onFieldSubmitted:
                                    (_) =>
                                        _confirmPasswordFocusNode
                                            .requestFocus(),
                                decoration: authInputDecoration(
                                  label: 'Password',
                                  hint: 'Create a password',
                                  icon: TrackletIcons.lock,
                                  suffixIcon: IconButton(
                                    key: const ValueKey(
                                      'create_account_password_visibility_toggle',
                                    ),
                                    tooltip:
                                        _passwordVisibility
                                            ? 'Hide password'
                                            : 'Show password',
                                    onPressed:
                                        () => setState(() {
                                          _passwordVisibility =
                                              !_passwordVisibility;
                                        }),
                                    icon: IgnorePointer(
                                      child: animated.LucideAnimatedIcon(
                                        key: ValueKey(_passwordVisibility),
                                        icon:
                                            _passwordVisibility
                                                ? animated.eye
                                                : animated.eye_off,
                                        trigger:
                                            animated.AnimationTrigger.manual,
                                        color: TrackletColors.secondaryText,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  color: TrackletColors.altPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Confirm Password Field
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            16.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 200.ms,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: !_confirmPasswordVisibility,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onChanged: (_) => setState(() {}),
                                validator:
                                    (value) => validatePasswordConfirmation(
                                      value,
                                      _passwordController.text,
                                    ),
                                onFieldSubmitted: (_) => _handleCreateAccount(),
                                decoration: authInputDecoration(
                                  label: 'Confirm password',
                                  hint: 'Re-enter your password',
                                  icon: TrackletIcons.lock,
                                  suffixIcon: IconButton(
                                    key: const ValueKey(
                                      'create_account_confirm_password_visibility_toggle',
                                    ),
                                    tooltip:
                                        _confirmPasswordVisibility
                                            ? 'Hide password'
                                            : 'Show password',
                                    onPressed:
                                        () => setState(() {
                                          _confirmPasswordVisibility =
                                              !_confirmPasswordVisibility;
                                        }),
                                    icon: IgnorePointer(
                                      child: animated.LucideAnimatedIcon(
                                        key: ValueKey(
                                          _confirmPasswordVisibility,
                                        ),
                                        icon:
                                            _confirmPasswordVisibility
                                                ? animated.eye
                                                : animated.eye_off,
                                        trigger:
                                            animated.AnimationTrigger.manual,
                                        color: TrackletColors.secondaryText,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  color: TrackletColors.altPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AnimatedSwitcher(
                          duration: TrackletMotion.adaptiveDuration(
                            context,
                            TrackletMotion.fast,
                          ),
                          switchInCurve: TrackletMotion.easeOut,
                          switchOutCurve: TrackletMotion.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              ),
                            );
                          },
                          child:
                              _passwordsMatch
                                  ? const Padding(
                                    key: ValueKey('password-match'),
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          TrackletIcons.checkCircle2,
                                          size: 16,
                                          color: TrackletColors.success,
                                        ),
                                        SizedBox(width: 6),
                                        Text('Passwords match'),
                                      ],
                                    ),
                                  )
                                  : const SizedBox(
                                    key: ValueKey('password-unmatched'),
                                  ),
                        ),

                        // Create Account Button
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            12.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48.0,
                            child: AuthEntrance(
                              delay: 250.ms,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleCreateAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TrackletColors.primary,
                                  foregroundColor: TrackletColors.pure,
                                  elevation: 3.0,
                                  shadowColor: TrackletColors.primary
                                      .withValues(alpha: 0.35),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: TrackletRadii.roundedCard,
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: TrackletColors.pure,
                                          ),
                                        )
                                        : Text(
                                          'Create account',
                                          style: TrackletTypography.titleMedium
                                              .copyWith(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.w600,
                                                color: TrackletColors.pure,
                                              ),
                                        ),
                              ),
                            ),
                          ),
                        ),

                        // -- OR -- Divider
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            'or',
                            style: TrackletTypography.caption.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: TrackletColors.secondaryText,
                            ),
                          ),
                        ),

                        // Continue with Google Button
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            12.0,
                            0.0,
                            0.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 45.0,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TrackletColors.altPrimaryText,
                                foregroundColor: TrackletColors.pure,
                                elevation: 0.0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: TrackletRadii.roundedInput,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google_logo.png',
                                    width: 20,
                                    height: 20,
                                    cacheWidth: 60,
                                    cacheHeight: 60,
                                    errorBuilder:
                                        (_, _, _) => const Icon(
                                          TrackletIcons.globe,
                                          size: 24,
                                          color: TrackletColors.pure,
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continue with Google',
                                    style: TrackletTypography.titleSmall
                                        .copyWith(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w600,
                                          color: TrackletColors.pure,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Already have account link
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0,
                              16.0,
                              0.0,
                              48.0,
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TrackletTypography.bodyMedium
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16.0,
                                          color: TrackletColors.altPrimaryText,
                                        ),
                                  ),
                                  TextSpan(
                                    text: 'Log in',
                                    style: TrackletTypography.bodyMedium
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.0,
                                          color: TrackletColors.primary,
                                        ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            context.push('/login');
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
