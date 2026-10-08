import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../tracklet_button.dart';

/// Authentic Attendrix Bottom Sheet: "Why We Need This Information".
class WhyDoWeNeedYourInfoBottomSheet extends StatelessWidget {
  const WhyDoWeNeedYourInfoBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const WhyDoWeNeedYourInfoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28.0),
        topRight: Radius.circular(28.0),
      ),
      child: Container(
        width: double.infinity,
        color: TrackletColors.surface,
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draggable Handle
              Center(
                child: Container(
                  width: 36.0,
                  height: 5.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: TrackletColors.border,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                ),
              ),

              // Title
              Text(
                'Why We Need This Information',
                style: TrackletTypography.displaySmall.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'We only collect the information required to provide Tracklet’s campus transit and timetable features.',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20.0),

              // Bullet List Title
              Text(
                'We use these details to:',
                style: TrackletTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),

              // Bullet Items
              _buildBulletItem(
                'Prioritize shuttle stops near your hostel and department.',
              ),
              const SizedBox(height: 8.0),
              _buildBulletItem(
                'Calculate precise walk times and hurry recommendations.',
              ),
              const SizedBox(height: 8.0),
              _buildBulletItem(
                'Sync class lecture times with transit departures.',
              ),
              const SizedBox(height: 8.0),
              _buildBulletItem(
                'Personalize your student transit pass on campus.',
              ),
              const SizedBox(height: 20.0),

              // Privacy Notice Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: TrackletColors.background,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: TrackletColors.border, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔒 ', style: TextStyle(fontSize: 16)),
                        Text(
                          'Privacy',
                          style: TrackletTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Your information is stored locally and securely, used solely for campus transit features, and never shared with third parties.',
                      style: TrackletTypography.bodySmall.copyWith(
                        color: TrackletColors.textSecondary,
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Got it Button
              TrackletButton(
                label: 'Got it',
                isFullWidth: true,
                size: TrackletButtonSize.large,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: TrackletColors.primary,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.0,
              color: TrackletColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
