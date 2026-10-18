import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Reusable profile avatar rendering a blocky 3D character via DiceBear Voxel Art API.
///
/// Deterministically seeds the voxel avatar based on the user's email address.
/// Gracefully falls back to initials or a guest icon if the image cannot be loaded.
class VoxelAvatar extends StatelessWidget {
  const VoxelAvatar({
    super.key,
    required this.email,
    this.name = '',
    this.avatarSeed,
    this.size = 48.0,
    this.borderRadius,
    this.border,
    this.isGuest = false,
  });

  /// The user's email address used as the fallback deterministic seed.
  final String email;

  /// User's display name for initials fallback.
  final String name;

  /// Optional custom avatar seed from DiceBear generator.
  final String? avatarSeed;

  /// Dimensions (width and height).
  final double size;

  /// Border radius (defaults to circular).
  final BorderRadius? borderRadius;

  /// Optional border around avatar.
  final BoxBorder? border;

  /// Whether the user is an anonymous guest.
  final bool isGuest;

  /// Generates the DiceBear Voxel Art URL.
  String get _avatarUrl {
    final explicit = avatarSeed?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return 'https://api.dicebear.com/10.x/voxel-art/png?seed=${Uri.encodeComponent(explicit)}&size=150&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
    }

    final cleanEmail = email.trim().toLowerCase();
    final seed =
        cleanEmail.isNotEmpty
            ? cleanEmail
            : (name.trim().isNotEmpty
                ? name.trim().toLowerCase()
                : (isGuest ? 'guest' : 'nitc_rider'));

    // DiceBear 10.x Voxel Art endpoint
    return 'https://api.dicebear.com/10.x/voxel-art/png?seed=${Uri.encodeComponent(seed)}&size=150&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
  }

  String get _initials {
    if (isGuest) return 'GR';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'ST';
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: border,
        color: TrackletColors.background2,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Image.network(
          _avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(isPlaceholder: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(isPlaceholder: false);
          },
        ),
      ),
    );
  }

  Widget _buildFallback({required bool isPlaceholder}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: TrackletColors.primary),
      child: Center(
        child:
            isPlaceholder
                ? SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
                : Text(
                  _initials,
                  style: TextStyle(
                    color: TrackletColors.textInverse,
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
