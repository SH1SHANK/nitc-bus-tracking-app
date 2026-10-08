import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Authentic Attendrix Login Screen layout and styling.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  void _handleLogin() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email and password.',
            style: TextStyle(fontFamily: TrackletTypography.primaryFontFamily),
          ),
          backgroundColor: TrackletColors.errorBorder,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/');
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
                        borderRadius: BorderRadius.circular(
                          TrackletRadii.input,
                        ),
                        child: Image.asset(
                          'assets/images/Clean_Login_Design_Rectangle_10.png',
                          width: double.infinity,
                          height: 320.0,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, _, _) => Container(
                            height: 320.0,
                            color: TrackletColors.permissionHeaderGradientStart
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.0, 1.5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          TrackletRadii.input,
                        ),
                        child: Image.asset(
                          'assets/images/Young_Man_Laptop_Clean_Login_Design.png',
                          width: 250.0,
                          height: 250.0,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/images/Young_Man_with_Laptop.png',
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

              // Login Form Area
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  TrackletSpacing.screenMargin,
                  TrackletSpacing.screenMargin,
                  TrackletSpacing.screenMargin,
                  0.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Welcome Back!',
                      style: TrackletTypography.displaySmall.copyWith(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                        color: TrackletColors.altPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // Subtitle
                    Padding(
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
                          color: TrackletColors.secondaryText,
                          fontWeight: FontWeight.w500,
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
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          autofocus: false,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Email ',
                            hintStyle: TrackletTypography.labelLarge.copyWith(
                              color: TrackletColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.errorBorder,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.errorBorder,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            filled: true,
                            fillColor: TrackletColors.primaryBackground,
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                  14.0,
                                  18.0,
                                  14.0,
                                  18.0,
                                ),
                          ),
                          style: TrackletTypography.bodyMedium.copyWith(
                            fontSize: 15.0,
                            color: TrackletColors.altPrimaryText,
                            fontWeight: FontWeight.w500,
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
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          autofocus: false,
                          obscureText: !_passwordVisibility,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Password',
                            hintStyle: TrackletTypography.labelLarge.copyWith(
                              color: TrackletColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.errorBorder,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: TrackletColors.errorBorder,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.input,
                              ),
                            ),
                            filled: true,
                            fillColor: TrackletColors.primaryBackground,
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                  14.0,
                                  18.0,
                                  14.0,
                                  18.0,
                                ),
                            suffixIcon: InkWell(
                              onTap: () {
                                setState(() {
                                  _passwordVisibility = !_passwordVisibility;
                                });
                              },
                              child: Icon(
                                _passwordVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: TrackletColors.secondaryText,
                                size: 22.0,
                              ),
                            ),
                          ),
                          style: TrackletTypography.bodyMedium.copyWith(
                            fontSize: 15.0,
                            color: TrackletColors.altPrimaryText,
                            fontWeight: FontWeight.w500,
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
                              color: TrackletColors.altPrimaryText,
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
                        height: 44.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TrackletColors.primary,
                            foregroundColor: TrackletColors.pure,
                            elevation: 3.0,
                            shadowColor: TrackletColors.primary.withValues(
                              alpha: 0.35,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TrackletRadii.card,
                              ),
                            ),
                          ),
                          child: _isLoading
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
                            context.go('/');
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
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 24,
                                  color: TrackletColors.pure,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: TrackletTypography.titleSmall.copyWith(
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
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.0,
                                  color: TrackletColors.altPrimaryText,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign Up Here',
                                style: TrackletTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                  color: TrackletColors.primary,
                                ),
                                recognizer: TapGestureRecognizer()
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
            ],
          ),
        ),
      ),
    );
  }
}
