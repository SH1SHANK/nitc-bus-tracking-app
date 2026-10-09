import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../onboarding/providers/onboarding_provider.dart';
import 'auth_field_decoration.dart';

/// Authentic Attendrix Create Account Screen layout and styling.
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
  bool _passwordMismatch = false;
  bool _isLoading = false;

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

  void _handleCreateAccount() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordMismatch = true);
      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _passwordMismatch = false;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ref.read(onboardingProvider.notifier).reset();
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: TrackletColors.secondaryBackground,
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
                        borderRadius: BorderRadius.circular(
                          TrackletRadii.input,
                        ),
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
                        borderRadius: BorderRadius.circular(
                          TrackletRadii.input,
                        ),
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
                        // Title
                        AuthEntrance(
                          child: Text(
                            'Create Your Account',
                            style: TrackletTypography.displaySmall.copyWith(
                              fontSize: 26.0,
                              fontWeight: FontWeight.bold,
                              color: TrackletColors.altPrimaryText,
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
                              "Let's get started by filling out the form below.",
                              style: TrackletTypography.labelMedium.copyWith(
                                fontSize: 14.0,
                                color: TrackletColors.secondaryText,
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
                                  icon: Icons.mail_outline_rounded,
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
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Create a password.'
                                            : null,
                                onChanged: (_) {
                                  if (_passwordMismatch) {
                                    setState(() => _passwordMismatch = false);
                                  }
                                },
                                onFieldSubmitted:
                                    (_) =>
                                        _confirmPasswordFocusNode
                                            .requestFocus(),
                                decoration: authInputDecoration(
                                  label: 'Password',
                                  hint: 'Create a password',
                                  icon: Icons.lock_outline_rounded,
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
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: TrackletColors.secondaryText,
                                      size: 22,
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
                            4.0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthEntrance(
                              delay: 210.ms,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: !_confirmPasswordVisibility,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Confirm your password.'
                                            : null,
                                onChanged: (_) {
                                  if (_passwordMismatch) {
                                    setState(() => _passwordMismatch = false);
                                  }
                                },
                                onFieldSubmitted: (_) => _handleCreateAccount(),
                                decoration: authInputDecoration(
                                  label: 'Confirm password',
                                  hint: 'Re-enter your password',
                                  icon: Icons.lock_reset_rounded,
                                  suffixIcon: IconButton(
                                    tooltip:
                                        _confirmPasswordVisibility
                                            ? 'Hide password'
                                            : 'Show password',
                                    onPressed:
                                        () => setState(() {
                                          _confirmPasswordVisibility =
                                              !_confirmPasswordVisibility;
                                        }),
                                    icon: Icon(
                                      _confirmPasswordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: TrackletColors.secondaryText,
                                      size: 22,
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

                        // Password Mismatch Error Indicator
                        if (_passwordMismatch)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              4.0,
                              4.0,
                              0.0,
                              6.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: TrackletColors.errorBorder,
                                  size: 16.0,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  'Passwords do not match.',
                                  style: TrackletTypography.caption.copyWith(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: TrackletColors.errorBorder,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12.0),

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
                              delay: 260.ms,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleCreateAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TrackletColors.primary,
                                  foregroundColor: TrackletColors.pure,
                                  elevation: 3.0,
                                  shadowColor: TrackletColors.primary
                                      .withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      TrackletRadii.card,
                                    ),
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
                                          'Create Account',
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
                              onPressed: () {
                                context.go('/onboarding');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TrackletColors.altPrimaryText,
                                foregroundColor: TrackletColors.pure,
                                elevation: 0.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    TrackletRadii.input,
                                  ),
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
                                          Icons.g_mobiledata_rounded,
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

                        // Already have an account? Sign In Link
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
                                    text: 'Sign In',
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
