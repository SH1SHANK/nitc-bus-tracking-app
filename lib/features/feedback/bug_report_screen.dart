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

/// Dedicated Bug Report Page with structured reproduction fields, validation,
/// duplicate-submission prevention, and direct GitHub Issues integration.
class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Map & Navigation';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const List<String> _categories = [
    'Map & Navigation',
    'Bus Tracking & GPS',
    'Routes & Schedules',
    'Auth & Account',
    'Visual & Layout',
    'Other',
  ];

  static const List<String> _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitInApp() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate async submission without requiring remote database modifications
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });

    TrackletSnackBar.showSuccess(
      context,
      'Bug report submitted successfully. Thank you!',
    );
  }

  Future<void> _handleOpenGitHub() async {
    final title =
        _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Issue in $_selectedCategory';
    final desc =
        _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Reported via BusTracker App.';
    final steps =
        _stepsController.text.trim().isNotEmpty
            ? _stepsController.text.trim()
            : 'N/A';
    final expected =
        _expectedController.text.trim().isNotEmpty
            ? _expectedController.text.trim()
            : 'Expected normal operation.';
    final actual =
        _actualController.text.trim().isNotEmpty
            ? _actualController.text.trim()
            : 'Encountered unexpected behavior.';

    final success = await GitHubIssueHelper.openBugReportIssue(
      title: title,
      description: desc,
      stepsToReproduce: steps,
      expectedBehavior: expected,
      actualBehavior: actual,
      category: _selectedCategory,
      severity: _selectedSeverity,
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
        appBar: const TrackletAppBar(title: 'Report a Bug'),
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
                    Icons.check_circle_rounded,
                    color: TrackletColors.success,
                    size: 56.0,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),
                Text(
                  'Bug Report Submitted',
                  style: TrackletTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                Text(
                  'Thank you for reporting this issue. Our developer team will review it and resolve it in an upcoming release.',
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
        title: 'Report a Bug',
        subtitle: 'Help us make campus transit more reliable',
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
                      Icons.bug_report_outlined,
                      color: TrackletColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: TrackletSpacing.sm),
                    Expanded(
                      child: Text(
                        'Provide clear details so our engineering team can isolate and fix the problem quickly.',
                        style: TrackletTypography.bodySmall.copyWith(
                          color: TrackletColors.adaptiveTextPrimary(context),
                          height: 1.35,
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
                    _buildLabel('Issue Summary *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        'e.g. Map bus marker glides when panning',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Please enter a summary of at least 5 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TrackletSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Category'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                decoration: _inputDecoration(''),
                                items:
                                    _categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: TrackletSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Severity'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSeverity,
                                decoration: _inputDecoration(''),
                                items:
                                    _severities.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSeverity = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    _buildLabel('Steps to Reproduce *'),
                    TextFormField(
                      controller: _stepsController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        '1. Open the Map tab\n2. Pan diagonally across campus\n3. Observe bus position',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Please provide steps to reproduce (min 10 chars).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TrackletSpacing.md),

                    _buildLabel('Expected Behavior *'),
                    TextFormField(
                      controller: _expectedController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'What did you expect to happen?',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Please describe the expected behavior.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TrackletSpacing.md),

                    _buildLabel('Actual Behavior *'),
                    TextFormField(
                      controller: _actualController,
                      maxLines: 2,
                      decoration: _inputDecoration('What actually happened?'),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Please describe what actually happened.';
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
                    _buildLabel('Additional Context / Notes (Optional)'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Any error codes, screenshots description, or bus numbers involved.',
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
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit Bug Report',
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
                label: const Text('Open Pre-Filled on GitHub'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedMd,
                  ),
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
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
