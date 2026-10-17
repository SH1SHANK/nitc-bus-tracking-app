import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/turnstile_service.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../profile/providers/profile_provider.dart';
import 'auth_field_decoration.dart';
import 'providers/auth_provider.dart';

/// Authentic Attendrix Login Screen layout, styling, and Supabase Auth integration.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _passwordVisibility = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? captchaToken;
    try {
      captchaToken = await TurnstileService.instance.getCaptchaToken(
        action: 'login',
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
        .signIn(email, password, captchaToken: captchaToken);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      final profile = await ref.read(profileStateProvider.future);
      if (!mounted) return;

      if (profile.hasCompletedOnboarding) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Sign in failed. Please check your credentials.',
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
      final currentAuth = ref.read(authNotifierProvider);
      if (currentAuth.isAuthenticated) {
        final profile = await ref.read(profileStateProvider.future);
        if (!mounted) return;

        if (profile.hasCompletedOnboarding) {
          context.go('/');
        } else {
          context.go('/onboarding');
        }
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Google Sign-In failed.',
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
    }
  }

  bool _isGuestSigningIn = false;

  Future<void> _handleGuestSignIn() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _isGuestSigningIn = true;
    });
    String? captchaToken;
    try {
      captchaToken = await TurnstileService.instance.getCaptchaToken(
        action: 'guest_login',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isGuestSigningIn = false;
      });
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
        .signInAnonymously(captchaToken: captchaToken);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isGuestSigningIn = false;
    });

    if (result.isSuccess) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Guest sign-in failed. Please check your internet connection.',
            style: const TextStyle(color: TrackletColors.info),
          ),
          backgroundColor: TrackletColors.errorBorder,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: const TextStyle(color: TrackletColors.info),
            ),
            backgroundColor: TrackletColors.errorBorder,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

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
              // Top 40% height banner with Clean Rectangle and Character
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
                      alignment: const Alignment(0.0, 1.5),
                      child: ClipRRect(
                        borderRadius: TrackletRadii.roundedInput,
                        child: Image.asset(
                          'assets/images/Young_Man_Laptop_Clean_Login_Design.png',
                          width: 250.0,
                          height: 250.0,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Image.asset(
                                'assets/images/Young_Man_with_Laptop.png',
                                width: 250.0,
                                height: 250.0,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16.0,
                      left: 16.0,
                      child: SafeArea(
                        child: TrackletBrandLockup(
                          logoSize: 28.0,
                          wordmarkHeight: 18.0,
                          withContainer: true,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Login Form Area
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
                        // Brand Logo and Wordmark
                        AuthEntrance(
                          delay: 20.ms,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: TrackletBrandLockup(
                              logoSize: 40.0,
                              wordmarkHeight: 22.0,
                              isDark: isDark,
                            ),
                          ),
                        ),

                        // Title
                        AuthEntrance(
                          child: Text(
                            'Welcome Back!',
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
                              "Log in and pick up right where you left off. We've been saving your seat. ",
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
                            10.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 90.ms,
                              child: TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                onFieldSubmitted:
                                    (_) => _passwordFocusNode.requestFocus(),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Enter your email address.';
                                  }
                                  if (!RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(email)) {
                                    return 'Enter a valid email address.';
                                  }
                                  if (!email.toLowerCase().endsWith(
                                    '@nitc.ac.in',
                                  )) {
                                    return 'Use your NITC institute email ending in @nitc.ac.in.';
                                  }
                                  return null;
                                },
                                decoration: authInputDecoration(
                                  label: 'Email address',
                                  hint: 'name@nitc.ac.in',
                                  icon: TrackletIcons.mail,
                                  context: context,
                                ),
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  color:
                                      isDark
                                          ? TrackletColors.darkTextPrimary
                                          : TrackletColors.altPrimaryText,
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
                            10.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 150.ms,
                              child: TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: !_passwordVisibility,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Enter your password.'
                                            : null,
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: authInputDecoration(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: TrackletIcons.lock,
                                  context: context,
                                  suffixIcon: IconButton(
                                    tooltip:
                                        _passwordVisibility
                                            ? 'Hide password'
                                            : 'Show password',
                                    onPressed:
                                        () => setState(() {
                                          _passwordVisibility =
                                              !_passwordVisibility;
                                        }),
                                    icon: Icon(
                                      _passwordVisibility
                                          ? TrackletIcons.eye
                                          : TrackletIcons.eyeOff,
                                      color:
                                          isDark
                                              ? TrackletColors.darkTextSecondary
                                              : TrackletColors.secondaryText,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  color:
                                      isDark
                                          ? TrackletColors.darkTextPrimary
                                          : TrackletColors.altPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: const AlignmentDirectional(1.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0,
                              0.0,
                              0.0,
                              16.0,
                            ),
                            child: InkWell(
                              onTap: () {
                                context.push('/forgot-password');
                              },
                              child: Text(
                                'perhaps, forgot your password?',
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? TrackletColors.velvetSky
                                          : TrackletColors.altPrimaryText,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Login Button
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
                              delay: 240.ms,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
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
                                    _isLoading && !_isGuestSigningIn
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: TrackletColors.pure,
                                          ),
                                        )
                                        : Text(
                                          'Login',
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
                            '-- OR --',
                            style: TrackletTypography.caption.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? TrackletColors.darkTextSecondary
                                      : TrackletColors.secondaryText,
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
                                backgroundColor:
                                    isDark
                                        ? TrackletColors.darkSurfaceElevated
                                        : TrackletColors.altPrimaryText,
                                foregroundColor: TrackletColors.pure,
                                elevation: 0.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: TrackletRadii.roundedInput,
                                  side:
                                      isDark
                                          ? const BorderSide(
                                            color: TrackletColors.darkBorder,
                                          )
                                          : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/favicon.png',
                                    width: 20,
                                    height: 20,
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

                        // Continue as Guest Option
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            12.0,
                            0.0,
                            0.0,
                          ),
                          child: Material(
                            key: const ValueKey('continue_as_guest_button'),
                            color:
                                isDark
                                    ? TrackletColors.darkSurfaceElevated
                                    : TrackletColors.background2,
                            borderRadius: TrackletRadii.roundedInput,
                            child: InkWell(
                              onTap: _isLoading ? null : _handleGuestSignIn,
                              borderRadius: TrackletRadii.roundedInput,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: TrackletRadii.roundedInput,
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? TrackletColors.darkBorder
                                            : TrackletColors.primary.withValues(
                                              alpha: 0.25,
                                            ),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: TrackletColors.primary
                                            .withValues(
                                              alpha: isDark ? 0.2 : 0.1,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        TrackletIcons.user,
                                        size: 20,
                                        color: TrackletColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continue as Guest',
                                            style: TrackletTypography.titleSmall
                                                .copyWith(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      isDark
                                                          ? TrackletColors
                                                              .darkTextPrimary
                                                          : TrackletColors
                                                              .altPrimaryText,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Explore BusTracker live bus tracking without creating an account',
                                            style: TrackletTypography.bodySmall
                                                .copyWith(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      isDark
                                                          ? TrackletColors
                                                              .darkTextSecondary
                                                          : TrackletColors
                                                              .secondaryText,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isGuestSigningIn)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: TrackletColors.primary,
                                        ),
                                      )
                                    else
                                      Icon(
                                        TrackletIcons.arrowRight,
                                        size: 18,
                                        color:
                                            isDark
                                                ? TrackletColors
                                                    .darkTextSecondary
                                                : TrackletColors.secondaryText,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Sign Up / Create Account Link
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
                                    text: "Don't have an account? ",
                                    style: TrackletTypography.bodyMedium
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16.0,
                                          color:
                                              isDark
                                                  ? TrackletColors
                                                      .darkTextSecondary
                                                  : TrackletColors
                                                      .altPrimaryText,
                                        ),
                                  ),
                                  TextSpan(
                                    text: 'Sign Up Here',
                                    style: TrackletTypography.bodyMedium
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.0,
                                          color: TrackletColors.primary,
                                        ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            context.push('/create-account');
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
