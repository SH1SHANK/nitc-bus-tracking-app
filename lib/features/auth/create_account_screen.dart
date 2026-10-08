import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Authentic Attendrix Create Account Screen layout and styling.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
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
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields.',
            style: TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: Color(0xFFFA000E),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordMismatch = true);
      return;
    }

    setState(() {
      _passwordMismatch = false;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
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
        backgroundColor: Colors.white,
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
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/Clean_Login_Design_Rectangle_10.png',
                          width: double.infinity,
                          height: 320.0,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, _, _) => Container(
                            height: 320.0,
                            color: const Color(0xFF5AB2F7).withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.0, 1.6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/Young_Man_with_Laptop.png',
                          width: 270.0,
                          height: 270.0,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Image.asset(
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
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14181B),
                        letterSpacing: 0.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // Subtitle
                    const Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Text(
                        "Let's get started by filling out the form below.",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.0,
                          color: Color(0xFF57636C),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),

                    // Email Field
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
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
                            hintText: 'Email',
                            hintStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              color: Color(0xFF57636C),
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF6F61EF),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F4F8),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                              14.0,
                              18.0,
                              14.0,
                              18.0,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.0,
                            color: Color(0xFF14181B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Password Field
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          autofocus: false,
                          obscureText: !_passwordVisibility,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_passwordMismatch) {
                              setState(() => _passwordMismatch = false);
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              color: Color(0xFF57636C),
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF6F61EF),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F4F8),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
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
                                color: const Color(0xFF57636C),
                                size: 22.0,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.0,
                            color: Color(0xFF14181B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Confirm Password Field
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 4.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          autofocus: false,
                          obscureText: !_confirmPasswordVisibility,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (_passwordMismatch) {
                              setState(() => _passwordMismatch = false);
                            }
                          },
                          onFieldSubmitted: (_) => _handleCreateAccount(),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Confirm Password',
                            hintStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              color: Color(0xFF57636C),
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF6F61EF),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFFA000E),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F4F8),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                              14.0,
                              18.0,
                              14.0,
                              18.0,
                            ),
                            suffixIcon: InkWell(
                              onTap: () {
                                setState(() {
                                  _confirmPasswordVisibility =
                                      !_confirmPasswordVisibility;
                                });
                              },
                              child: Icon(
                                _confirmPasswordVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF57636C),
                                size: 22.0,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.0,
                            color: Color(0xFF14181B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Password Mismatch Error Indicator
                    if (_passwordMismatch)
                      const Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 0.0, 6.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFA000E),
                              size: 16.0,
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              'Passwords do not match.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFA000E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12.0),

                    // Create Account Button
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCreateAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6F61EF),
                            foregroundColor: Colors.white,
                            elevation: 3.0,
                            shadowColor: const Color(0xFF6F61EF).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // -- OR -- Divider
                    const Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        '-- OR --',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF57636C),
                        ),
                      ),
                    ),

                    // Continue with Google Button
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45.0,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/onboarding');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14181B),
                            foregroundColor: Colors.white,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 48.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.0,
                                  color: Color(0xFF14181B),
                                ),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                  color: Color(0xFF6F61EF),
                                ),
                                recognizer: TapGestureRecognizer()
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
            ],
          ),
        ),
      ),
    );
  }
}
