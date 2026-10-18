import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/voxel_avatar.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/profile_provider.dart';

/// Modal bottom sheet allowing users to customize their 3D voxel avatar
/// by rolling random string seeds or typing custom strings via the DiceBear API.
class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({
    super.key,
    required this.currentSeed,
    required this.userEmail,
    required this.userName,
  });

  final String? currentSeed;
  final String userEmail;
  final String userName;

  static Future<void> show(
    BuildContext context, {
    String? currentSeed,
    required String userEmail,
    required String userName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => AvatarPickerSheet(
            currentSeed: currentSeed,
            userEmail: userEmail,
            userName: userName,
          ),
    );
  }

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet> {
  late String _selectedSeed;
  final List<String> _seedPool = <String>[];
  bool _isSaving = false;

  static const List<String> _adjectives = [
    'Cosmic',
    'Cyber',
    'Quantum',
    'Solar',
    'Neon',
    'Pixel',
    'Voxel',
    'Turbo',
    'Hyper',
    'Astro',
    'Retro',
    'Sonic',
    'Alpha',
    'Shadow',
    'Pulse',
    'Zenith',
  ];

  static const List<String> _nouns = [
    'Rider',
    'Pilot',
    'Voyager',
    'Falcon',
    'Explorer',
    'Ninja',
    'Knight',
    'Ace',
    'Runner',
    'Spark',
    'Phoenix',
    'Captain',
    'Rover',
    'Hero',
    'Tracker',
    'Nomad',
  ];

  @override
  void initState() {
    super.initState();
    final initial =
        widget.currentSeed ??
        (widget.userEmail.trim().isNotEmpty
            ? widget.userEmail.trim().toLowerCase()
            : (widget.userName.trim().isNotEmpty
                ? widget.userName.trim().toLowerCase()
                : 'nitc_rider'));
    _selectedSeed = initial;
    _rollNewBatch();
  }

  void _rollNewBatch() {
    final rand = Random();
    _seedPool.clear();

    // Include the current selection first if not empty
    if (!_seedPool.contains(_selectedSeed)) {
      _seedPool.add(_selectedSeed);
    }

    // Generate 7 additional creative seed strings
    while (_seedPool.length < 8) {
      final adj = _adjectives[rand.nextInt(_adjectives.length)];
      final noun = _nouns[rand.nextInt(_nouns.length)];
      final num = rand.nextInt(90) + 10;
      final generated = '$adj$noun$num';
      if (!_seedPool.contains(generated)) {
        _seedPool.add(generated);
      }
    }
  }

  void _selectSeed(String seed) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _selectedSeed = seed;
    });
  }

  Future<void> _saveAvatar() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      await ref
          .read(profileStateProvider.notifier)
          .updateAvatarSeed(_selectedSeed);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                animated.LucideAnimatedIcon(
                  icon: animated.check,
                  size: 18,
                  color: Colors.white,
                  trigger: animated.AnimationTrigger.onTap,
                ),
                SizedBox(width: 8),
                Text('Avatar updated successfully'),
              ],
            ),
            backgroundColor: TrackletColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = TrackletColors.adaptiveSurface(context);
    final borderColor = TrackletColors.adaptiveBorder(context);

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: TrackletSpacing.lg,
            vertical: TrackletSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: TrackletSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize Avatar',
                        style: TrackletTypography.adaptive(
                          context,
                          TrackletTypography.titleLarge,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Powered by DiceBear 3D Voxel Engine',
                        style: TrackletTypography.adaptiveSecondary(
                          context,
                          TrackletTypography.caption,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.lg),

              // Center Stage: Active Avatar Preview Card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(TrackletSpacing.lg),
                  decoration: BoxDecoration(
                    color: TrackletColors.adaptiveSurfaceElevated(context),
                    borderRadius: TrackletRadii.roundedLg,
                    border: Border.all(
                      color: TrackletColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TrackletColors.primary.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TrackletColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TrackletColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: VoxelAvatar(
                        key: ValueKey(_selectedSeed),
                        email: widget.userEmail,
                        name: widget.userName,
                        avatarSeed: _selectedSeed,
                        size: 96,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),

              // Action Row: Randomize Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pick an Avatar',
                    style: TrackletTypography.adaptive(
                      context,
                      TrackletTypography.titleMedium,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      setState(() => _rollNewBatch());
                    },
                    icon: const Icon(
                      Icons.casino_rounded,
                      size: 18,
                      color: TrackletColors.primary,
                    ),
                    label: const Text(
                      'Roll New',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TrackletColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.xs),

              // Grid of 8 Avatar Options
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    _seedPool.map((seed) {
                      final isSelected = seed == _selectedSeed;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectSeed(seed),
                          borderRadius: TrackletRadii.roundedMd,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? TrackletColors.primary.withValues(
                                        alpha: 0.15,
                                      )
                                      : TrackletColors.adaptiveSurfaceElevated(
                                        context,
                                      ),
                              borderRadius: TrackletRadii.roundedMd,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? TrackletColors.primary
                                        : borderColor,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: TrackletColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: VoxelAvatar(
                                email: widget.userEmail,
                                name: widget.userName,
                                avatarSeed: seed,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: TrackletSpacing.xl),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedMd,
                  ),
                  elevation: 2,
                ),
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const animated.LucideAnimatedIcon(
                          icon: animated.check,
                          size: 20,
                          color: Colors.white,
                          trigger: animated.AnimationTrigger.manual,
                        ),
                label: Text(
                  _isSaving ? 'Applying...' : 'Apply Avatar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
}
