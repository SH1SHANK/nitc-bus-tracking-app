import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_button.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/typography.dart';

/// Authentic Attendrix Forgot Password screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendLink() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: TrackletColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/reset-password-sent');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrackletColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const TrackletIcon(
            TrackletIcons.chevronLeft,
            color: TrackletColors.textPrimary,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Title
              Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: TrackletTypography.displayMedium.copyWith(
                  fontSize: 30.0,
                  fontWeight: FontWeight.w800,
                  color: TrackletColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              const Text(
                'We’ve got you covered, no stress!\nJust drop your email below...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  color: TrackletColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Email Input Card
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: TrackletColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TrackletColors.border, width: 2.0),
                ),
                child: Row(
                  children: [
                    const TrackletIcon(
                      TrackletIcons.profile,
                      color: TrackletColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Your Email Address (e.g. user@nitc.ac.in)',
                          hintStyle: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TrackletColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Send Magic Link Button
              TrackletButton(
                label: _isLoading ? 'Sending Link...' : 'Send Magic Link',
                isFullWidth: true,
                size: TrackletButtonSize.large,
                onPressed: _isLoading ? null : _handleSendLink,
              ),
              const SizedBox(height: 20),

              // Back to Sign In
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Remember your password? Sign In',
                  style: TextStyle(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
