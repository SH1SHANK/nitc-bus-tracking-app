import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/components/bottom_sheets/why_do_we_need_your_info_bottom_sheet.dart';
import '../../../design_system/components/tracklet_dropdown.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_entrance.dart';

/// All-in-One Academic Profile Setup Page matching Attendrix Onboarding Layout.
/// Dynamic database-driven selection for Branch, Batch, Hostel, and Agreement.
class OnboardingAcademicProfilePage extends StatefulWidget {
  const OnboardingAcademicProfilePage({
    super.key,
    required this.name,
    required this.branch,
    required this.batch,
    required this.hostel,
    required this.agreedToTerms,
    required this.onNameChanged,
    required this.onBranchChanged,
    required this.onBatchChanged,
    required this.onHostelChanged,
    required this.onAgreementChanged,
    required this.onContinue,
    this.branches = const [],
    this.hostels = const [],
    this.batches = kNitcBatches,
    this.isLoadingDepartments = false,
    this.isLoadingHostels = false,
    this.departmentsError,
    this.hostelsError,
    this.onRetryDepartments,
    this.onRetryHostels,
  });

  final String name;
  final String branch;
  final String batch;
  final String hostel;
  final bool agreedToTerms;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBranchChanged;
  final ValueChanged<String> onBatchChanged;
  final ValueChanged<String> onHostelChanged;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onContinue;

  final List<String> branches;
  final List<String> hostels;
  final List<String> batches;
  final bool isLoadingDepartments;
  final bool isLoadingHostels;
  final String? departmentsError;
  final String? hostelsError;
  final VoidCallback? onRetryDepartments;
  final VoidCallback? onRetryHostels;

  @override
  State<OnboardingAcademicProfilePage> createState() =>
      _OnboardingAcademicProfilePageState();
}

class _OnboardingAcademicProfilePageState
    extends State<OnboardingAcademicProfilePage> {
  late final TextEditingController _nameController;
  late final TapGestureRecognizer _learnMoreRecognizer;
  late final TapGestureRecognizer _requestRecognizer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _learnMoreRecognizer =
        TapGestureRecognizer()..onTap = _showInformationSheet;
    _requestRecognizer =
        TapGestureRecognizer()..onTap = _showRequestInstructions;
  }

  void _showInformationSheet() {
    WhyDoWeNeedYourInfoBottomSheet.show(context);
  }

  void _showRequestInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'To request custom departments or hostels, contact transit-support@nitc.ac.in',
          style: TextStyle(fontFamily: TrackletTypography.primaryFontFamily),
        ),
        backgroundColor: TrackletColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _learnMoreRecognizer.dispose();
    _requestRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNameValid = widget.name.trim().length >= 2;
    final isBranchValid = widget.branch.isNotEmpty;
    final isBatchValid = widget.batch.isNotEmpty;
    final isHostelValid = widget.hostel.isNotEmpty;
    final isFormValid =
        isNameValid &&
        isBranchValid &&
        isBatchValid &&
        isHostelValid &&
        widget.agreedToTerms;

    final hasError =
        widget.departmentsError != null || widget.hostelsError != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.sm),

          // Header Title
          Text(
            "Let's Set Up Your Academic Profile",
            style: TrackletTypography.displaySmall.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TrackletColors.altPrimaryText,
            ),
          ).enterOnboarding(context),
          const SizedBox(height: 6),

          // RichText Subtitle with "Tap to Learn More." modal trigger
          RichText(
            text: TextSpan(
              style: TrackletTypography.labelSmall.copyWith(
                color: TrackletColors.secondaryText,
                fontSize: 11.5,
                height: 1.45,
              ),
              children: [
                const TextSpan(
                  text:
                      'Add your details to customize campus bus routes and arrival times. Why we ask: ',
                ),
                TextSpan(
                  text: 'Learn more.',
                  style: const TextStyle(
                    color: TrackletColors.tertiaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: _learnMoreRecognizer,
                ),
                const TextSpan(text: " Can't find yours? "),
                TextSpan(
                  text: 'Request here',
                  style: const TextStyle(
                    color: TrackletColors.tertiaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: _requestRecognizer,
                ),
              ],
            ),
          ).enterOnboarding(context, delay: 50.ms),
          const SizedBox(height: 18),

          if (hasError)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TrackletColors.error.withValues(alpha: 0.08),
                borderRadius: TrackletRadii.roundedCard,
                border: Border.all(
                  color: TrackletColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    TrackletIcons.alertCircle,
                    color: TrackletColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.departmentsError ??
                          widget.hostelsError ??
                          'Could not load campus options.',
                      style: const TextStyle(
                        fontFamily: TrackletTypography.primaryFontFamily,
                        fontSize: 12,
                        color: TrackletColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onRetryDepartments?.call();
                      widget.onRetryHostels?.call();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TrackletColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Field 1: Full Name
          _buildFieldLabel('What is your full name?'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            onChanged: (val) {
              widget.onNameChanged(val);
              setState(() {});
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Full Name',
              hintStyle: TrackletTypography.labelLarge.copyWith(
                color: TrackletColors.secondaryText,
                fontWeight: FontWeight.w700,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: TrackletColors.alternate,
                  width: 2.0,
                ),
                borderRadius: TrackletRadii.roundedCard,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: TrackletColors.primary,
                  width: 2.0,
                ),
                borderRadius: TrackletRadii.roundedCard,
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: TrackletColors.errorBorder,
                  width: 2.0,
                ),
                borderRadius: TrackletRadii.roundedCard,
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: TrackletColors.errorBorder,
                  width: 2.0,
                ),
                borderRadius: TrackletRadii.roundedCard,
              ),
              filled: true,
              fillColor: TrackletColors.primaryBackground,
              contentPadding: const EdgeInsetsDirectional.fromSTEB(
                14.0,
                16.0,
                14.0,
                16.0,
              ),
              prefixIcon: const Icon(
                TrackletIcons.user,
                color: TrackletColors.secondaryText,
                size: 20,
              ),
              suffixIcon:
                  _nameController.text.isNotEmpty
                      ? IconButton(
                        tooltip: 'Clear name',
                        onPressed: () {
                          _nameController.clear();
                          widget.onNameChanged('');
                          setState(() {});
                        },
                        icon: const Icon(
                          TrackletIcons.x,
                          size: 18,
                          color: TrackletColors.secondaryText,
                        ),
                      )
                      : null,
            ),
            style: TrackletTypography.bodyMedium.copyWith(
              fontSize: 15.0,
              color: TrackletColors.altPrimaryText,
              fontWeight: FontWeight.w600,
            ),
          ).enterOnboarding(context, delay: 90.ms),
          const SizedBox(height: 14),

          // Field 2: Branch Animated Dropdown
          _buildFieldLabel('Which branch do you belong to?'),
          const SizedBox(height: 6),
          TrackletDropdown(
            items: widget.branches,
            initialItem: widget.branch.isNotEmpty ? widget.branch : null,
            hintText:
                widget.isLoadingDepartments
                    ? 'Loading departments...'
                    : widget.departmentsError != null
                    ? 'Could not load departments'
                    : widget.branches.isEmpty
                    ? 'No departments found'
                    : 'Select Branch',
            prefixIcon: const Icon(
              TrackletIcons.gitBranch,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: isBranchValid,
            onChanged: (val) {
              widget.onBranchChanged(val ?? '');
              setState(() {});
            },
          ).enterOnboarding(context, delay: 130.ms),
          const SizedBox(height: 14),

          // Field 3: Batch Animated Dropdown
          _buildFieldLabel('Which batch do you belong to?'),
          const SizedBox(height: 6),
          TrackletDropdown(
            items: widget.batches,
            initialItem: widget.batch.isNotEmpty ? widget.batch : null,
            hintText: 'Select Batch',
            prefixIcon: const Icon(
              TrackletIcons.users,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: isBatchValid,
            onChanged: (val) {
              widget.onBatchChanged(val ?? '');
              setState(() {});
            },
          ).enterOnboarding(context, delay: 170.ms),
          const SizedBox(height: 14),

          // Field 4: Hostel
          _buildFieldLabel('Which hostel do you belong to?'),
          const SizedBox(height: 6),
          TrackletDropdown(
            items: widget.hostels,
            initialItem: widget.hostel.isNotEmpty ? widget.hostel : null,
            hintText:
                widget.isLoadingHostels
                    ? 'Loading hostels...'
                    : widget.hostelsError != null
                    ? 'Could not load hostels'
                    : widget.hostels.isEmpty
                    ? 'No hostels found'
                    : 'Select Hostel',
            prefixIcon: const Icon(
              TrackletIcons.building2,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: isHostelValid,
            onChanged: (val) {
              widget.onHostelChanged(val ?? '');
              setState(() {});
            },
          ).enterOnboarding(context, delay: 250.ms),
          const SizedBox(height: 14),

          // Information acknowledgement checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Theme(
                data: ThemeData(
                  checkboxTheme: const CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedXs,
                    ),
                  ),
                  unselectedWidgetColor: TrackletColors.secondaryText,
                ),
                child: Checkbox(
                  value: widget.agreedToTerms,
                  activeColor: TrackletColors.primary,
                  checkColor: TrackletColors.pure,
                  onChanged:
                      (value) => widget.onAgreementChanged(value ?? false),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy.',
                  style: TextStyle(
                    fontFamily: TrackletTypography.primaryFontFamily,
                    fontSize: 12,
                    color: TrackletColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ).enterOnboarding(context, delay: 250.ms),
          if (!isFormValid)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    TrackletIcons.info,
                    size: 16,
                    color: TrackletColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete all fields and accept the terms to continue.',
                      style: TrackletTypography.labelSmall.copyWith(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ).enterOnboarding(context, delay: 270.ms),
          const SizedBox(height: 8),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isFormValid ? widget.onContinue : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                TrackletIcons.arrowRight,
                size: 18,
                color: TrackletColors.pure,
              ),
              label: const Text(
                'Continue',
                style: TextStyle(
                  fontFamily: TrackletTypography.primaryFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.pure,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TrackletColors.primary,
                disabledBackgroundColor: TrackletColors.primary.withValues(
                  alpha: 0.4,
                ),
                elevation: 3,
                shadowColor: TrackletColors.primary.withValues(alpha: 0.3),
                shape: const RoundedRectangleBorder(
                  borderRadius: TrackletRadii.roundedCard,
                ),
              ),
            ),
          ).enterOnboarding(context, delay: 290.ms),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: TrackletTypography.primaryFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: TrackletColors.secondaryText,
      ),
    );
  }
}
