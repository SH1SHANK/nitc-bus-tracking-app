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

/// Dedicated Feature Suggestion Page with structured problem/audience breakdown,
/// validation, and direct GitHub Issues integration.
class FeatureSuggestionScreen extends StatefulWidget {
  const FeatureSuggestionScreen({super.key});

  @override
  State<FeatureSuggestionScreen> createState() =>
      _FeatureSuggestionScreenState();
}

class _FeatureSuggestionScreenState extends State<FeatureSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _problemController = TextEditingController();
  final _audienceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<String> _priorities = [
    'Low (Nice-to-have)',
    'Medium (Helpful improvement)',
    'High (Important workflow)',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _problemController.dispose();
    _audienceController.dispose();
    _notesController.dispose();
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
      'Feature idea submitted successfully! Thanks for helping improve BusTracker.',
    );
  }

  Future<void> _handleOpenGitHub() async {
    final title =
        _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'New Feature Idea';
    final problem =
        _problemController.text.trim().isNotEmpty
            ? _problemController.text.trim()
            : 'N/A';
    final audience =
        _audienceController.text.trim().isNotEmpty
            ? _audienceController.text.trim()
            : 'All NITC campus students';

    final success = await GitHubIssueHelper.openFeatureSuggestionIssue(
      title: title,
      problemSolved: problem,
      targetAudience: audience,
      priority: _selectedPriority,
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
        appBar: const TrackletAppBar(title: 'Suggest a Feature'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.screenMargin),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.lg),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: TrackletColors.primary,
                    size: 56.0,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),
                Text(
                  'Idea Submitted!',
                  style: TrackletTypography.headlineMedium.copyWith(
                    fontWeight: TrackletTypography.weightBold,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                Text(
                  'Great campus transit starts with great student ideas. We will review this feature during upcoming sprint planning.',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.adaptiveTextSecondary(context),
                    height: TrackletTypography.lineHeightBodyRelaxed,
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
                const SizedBox(height: TrackletSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _handleOpenGitHub,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Also Track on GitHub'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 44),
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
        title: 'Suggest a Feature',
        subtitle: 'Propose ideas to improve campus transit',
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
              Container(
                padding: const EdgeInsets.all(TrackletSpacing.md),
                decoration: BoxDecoration(
                  color: TrackletColors.primary.withValues(alpha: 0.08),
                  borderRadius: TrackletRadii.roundedMd,
                  border: Border.all(
                    color: TrackletColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: TrackletColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: TrackletSpacing.sm),
                    Expanded(
                      child: Text(
                        'Have an idea for a new transit route indicator, notification, or campus feature? Let us know!',
                        style: TrackletTypography.bodySmall.copyWith(
                          color: TrackletColors.adaptiveTextPrimary(context),
                          height: TrackletTypography.lineHeightBodyCompact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),

              _buildFieldCard(
                cardBg: cardBg,
                borderColor: borderColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Feature Title *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        'e.g. Push notification 5 minutes before bus arrives',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Please enter a feature title of at least 5 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TrackletSpacing.md),

                    _buildLabel('Target Audience / Use Case *'),
                    TextFormField(
                      controller: _audienceController,
                      decoration: _inputDecoration(
                        'e.g. Mega Hostel residents during morning rush hour',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 4) {
                          return 'Please describe the intended audience.';
                        }
                        return null;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Problem It Solves *'),
                    TextFormField(
                      controller: _problemController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'What challenge or inconvenience does this feature address?',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Please describe the problem solved (min 10 chars).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TrackletSpacing.md),

                    _buildLabel('Suggested Priority'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      decoration: _inputDecoration(''),
                      items:
                          _priorities.map((p) {
                            return DropdownMenuItem(
                              value: p.split(' ').first,
                              child: Text(
                                p,
                                style: const TextStyle(
                                  fontSize: TrackletTypography.fontSize13_5,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPriority = val);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Additional Details (Optional)'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Any mockups, alternative ideas, or edge cases to consider.',
                      ),
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
                            color: TrackletColors.textInverse,
                          ),
                        )
                        : const Text(
                          'Submit Feature Idea',
                          style: TextStyle(
                            fontSize: TrackletTypography.fontSize15,
                            fontWeight: TrackletTypography.weightSemiBold,
                          ),
                        ),
              ),
              const SizedBox(height: TrackletSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _handleOpenGitHub,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Post as GitHub Issue'),
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
          fontSize: TrackletTypography.fontSize13,
          fontWeight: TrackletTypography.weightSemiBold,
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
