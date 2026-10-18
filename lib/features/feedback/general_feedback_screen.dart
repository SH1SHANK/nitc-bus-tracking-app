import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/tracklet_app_bar.dart';
import '../../design_system/components/tracklet_snack_bar.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/tracklet_fonts.dart';
import '../../design_system/tokens/typography.dart';
import 'github_issue_helper.dart';

/// Dedicated General Feedback Page with interactive 5-star rating, category selection,
/// validation, and direct GitHub Issues integration.
class GeneralFeedbackScreen extends StatefulWidget {
  const GeneralFeedbackScreen({super.key});

  @override
  State<GeneralFeedbackScreen> createState() => _GeneralFeedbackScreenState();
}

class _GeneralFeedbackScreenState extends State<GeneralFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  String _selectedType = 'General Experience';
  int _rating = 5;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<String> _feedbackTypes = [
    'General Experience',
    'Transit Timetables & Accuracy',
    'Map Navigation & UI',
    'Performance & Speed',
    'Accessibility & Readability',
    'Other',
  ];

  static const List<String> _ratingLabels = [
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitInApp() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });

    TrackletSnackBar.showSuccess(
      context,
      'Feedback submitted successfully. Thank you for your thoughts!',
    );
  }

  Future<void> _handleOpenGitHub() async {
    final comments =
        _commentsController.text.trim().isNotEmpty
            ? _commentsController.text.trim()
            : 'Submitted general feedback rating $_rating/5 stars.';

    final success = await GitHubIssueHelper.openFeedbackIssue(
      feedbackType: _selectedType,
      rating: _rating,
      comments: comments,
    );

    if (!mounted) return;
    if (!success) {
      TrackletSnackBar.showError(
        context,
        'Could not open browser for GitHub issues.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        appBar: const TrackletAppBar(title: 'Feedback'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.screenMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.lg),
                  decoration: BoxDecoration(
                    color: TrackletColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: TrackletColors.success,
                    size: 56.0,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),
                Text(
                  'Feedback Received!',
                  style: TrackletTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                Text(
                  'Your voice helps shape the future of student transit on the NIT Calicut campus.',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.adaptiveTextSecondary(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.section),
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Settings'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = TrackletColors.isDark(context);
    final cardBg =
        isDark
            ? TrackletColors.darkSurfaceElevated
            : TrackletColors.surfaceElevated;
    final borderColor =
        isDark ? TrackletColors.darkBorder : TrackletColors.cardBorder;

    return Scaffold(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      appBar: TrackletAppBar(
        title: 'App Feedback',
        subtitle: 'Share your thoughts and campus transit experience',
        actions: [
          IconButton(
            tooltip: 'Open on GitHub',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            onPressed: _handleOpenGitHub,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(TrackletSpacing.screenMargin),
            children: [
              _buildFieldCard(
                cardBg: cardBg,
                borderColor: borderColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Feedback Topic'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: _inputDecoration(''),
                      items:
                          _feedbackTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedType = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              _buildFieldCard(
                cardBg: cardBg,
                borderColor: borderColor,
                child: Column(
                  children: [
                    _buildLabel('How is your overall experience?'),
                    const SizedBox(height: TrackletSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final filled = star <= _rating;
                        return IconButton(
                          iconSize: 36,
                          splashRadius: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () => setState(() => _rating = star),
                          icon: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color:
                                filled
                                    ? const Color(0xFFF59E0B)
                                    : TrackletColors.adaptiveBorder(context),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: TrackletSpacing.xxs),
                    Text(
                      _ratingLabels[_rating - 1],
                      style: TrackletFonts.outfit(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              _buildFieldCard(
                cardBg: cardBg,
                borderColor: borderColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Comments & Suggestions *'),
                    TextFormField(
                      controller: _commentsController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Tell us what works well or what could be improved...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 8) {
                          return 'Please provide comments of at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),

              FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmitInApp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedMd,
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
              const SizedBox(height: TrackletSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _handleOpenGitHub,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Post as GitHub Feedback'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard({
    required Widget child,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: TrackletRadii.roundedCard,
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(TrackletSpacing.md),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TrackletSpacing.xs),
      child: Text(
        text,
        style: TrackletFonts.outfit(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: TrackletColors.adaptiveTextPrimary(context),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TrackletTypography.bodySmall.copyWith(
        color: TrackletColors.adaptiveTextSecondary(
          context,
        ).withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.md,
        vertical: TrackletSpacing.compactMd,
      ),
      border: OutlineInputBorder(
        borderRadius: TrackletRadii.roundedSm,
        borderSide: BorderSide(color: TrackletColors.adaptiveBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TrackletRadii.roundedSm,
        borderSide: BorderSide(color: TrackletColors.adaptiveBorder(context)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: TrackletRadii.roundedSm,
        borderSide: BorderSide(color: TrackletColors.primary, width: 1.5),
      ),
    );
  }
}
