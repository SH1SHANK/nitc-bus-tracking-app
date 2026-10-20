import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications/notification_repository.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/transit_repository.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/tracklet_fonts.dart';

final _routesListProvider = FutureProvider.autoDispose<List<BusRoute>>((
  ref,
) async {
  final repo = ref.watch(transitRepositoryProvider);
  return repo.getRoutes();
});

class SendAnnouncementDialog extends ConsumerStatefulWidget {
  const SendAnnouncementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const SendAnnouncementDialog(),
    );
  }

  @override
  ConsumerState<SendAnnouncementDialog> createState() =>
      _SendAnnouncementDialogState();
}

class _SendAnnouncementDialogState
    extends ConsumerState<SendAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _type = 'general'; // 'general' or 'disruption'
  String? _selectedRouteId;
  int _expiryDays = 3;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routesAsync = ref.watch(_routesListProvider);

    return AlertDialog(
      backgroundColor:
          isDark ? TrackletColors.darkBackground : TrackletColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedLg,
      ),
      title: Text(
        'Broadcast Notification',
        style: TrackletFonts.outfit(
          fontSize: TrackletTypography.fontSize18,
          fontWeight: TrackletTypography.weightBold,
          color: TrackletColors.adaptiveTextPrimary(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('General'),
                      selected: _type == 'general',
                      onSelected: (val) => setState(() => _type = 'general'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Route Alert'),
                      selected: _type == 'disruption',
                      onSelected: (val) => setState(() => _type = 'disruption'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_type == 'disruption') ...[
                routesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (List<BusRoute> routes) {
                    if (_selectedRouteId == null && routes.isNotEmpty) {
                      _selectedRouteId = routes.first.id;
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedRouteId,
                      decoration: const InputDecoration(
                        labelText: 'Target Route',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          routes.map((BusRoute r) {
                            return DropdownMenuItem<String>(
                              value: r.id,
                              child: Text('${r.code} - ${r.name}'),
                            );
                          }).toList(),
                      onChanged:
                          (val) => setState(() => _selectedRouteId = val),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Campus Route Diversion',
                ),
                validator:
                    (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Title is required'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  border: OutlineInputBorder(),
                  hintText: 'Enter announcement details...',
                ),
                validator:
                    (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Body is required'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _expiryDays,
                decoration: const InputDecoration(
                  labelText: 'Expiration',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Day')),
                  DropdownMenuItem(value: 3, child: Text('3 Days')),
                  DropdownMenuItem(value: 7, child: Text('7 Days (Max)')),
                ],
                onChanged: (val) => setState(() => _expiryDays = val ?? 3),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TrackletColors.primary,
            foregroundColor: TrackletColors.textInverse,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TrackletColors.textInverse,
                    ),
                  )
                  : const Text('Broadcast'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final expiry = DateTime.now().add(Duration(days: _expiryDays));
    final repo = ref.read(notificationRepositoryProvider);

    final result = await repo.sendAdminAnnouncement(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      type: _type,
      targetRouteId: _type == 'disruption' ? _selectedRouteId : null,
      expiresAt: expiry,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement broadcasted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error'] ?? 'Broadcast failed'}'),
        ),
      );
    }
  }
}
