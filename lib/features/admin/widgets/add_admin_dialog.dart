import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/nitc_email_validator.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../providers/admin_provider.dart';

/// Modal dialog to add a new administrator to the allowlist.
class AddAdminDialog extends ConsumerStatefulWidget {
  const AddAdminDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddAdminDialog(),
    );
  }

  @override
  ConsumerState<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(adminUsersProvider.notifier)
          .addAdmin(
            _emailController.text.trim(),
            notes:
                _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin ${_emailController.text.trim()} added successfully',
          ),
          backgroundColor: TrackletColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedLg,
      ),
      backgroundColor: TrackletColors.adaptiveSurface(context),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TrackletSpacing.sm),
            decoration: BoxDecoration(
              color: TrackletColors.primary.withValues(alpha: 0.15),
              borderRadius: TrackletRadii.roundedSm,
            ),
            child: const Icon(
              TrackletIcons.shield,
              color: TrackletColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TrackletSpacing.md),
          const Expanded(
            child: Text(
              'Add Administrator',
              style: TextStyle(
                fontSize: TrackletTypography.fontSize18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admins have full access to device management, telemetry inspection, and audit logs.',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: TrackletTypography.fontSize13,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(TrackletSpacing.compactMd),
                  decoration: BoxDecoration(
                    color: TrackletColors.error.withValues(alpha: 0.12),
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        TrackletIcons.error,
                        color: TrackletColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: TrackletColors.error,
                            fontSize: TrackletTypography.fontSize12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.md),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email *',
                  hintText: 'e.g. admin@nitc.ac.in',
                  prefixIcon: Icon(TrackletIcons.mail, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!isNitcEmail(val) && !val.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TrackletSpacing.md),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Lead Transit Coordinator',
                  prefixIcon: Icon(TrackletIcons.fileText, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TrackletButton(
          label: _isSubmitting ? 'Adding...' : 'Add Admin',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          size: TrackletButtonSize.medium,
        ),
      ],
    );
  }
}
