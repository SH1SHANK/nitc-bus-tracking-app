import 'package:flutter/material.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/typography.dart';

/// Modal dialog displaying campus transit FAQs for NIT Calicut students.
class TransitFaqDialog extends StatelessWidget {
  const TransitFaqDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const TransitFaqDialog(),
    );
  }

  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'How frequently do campus shuttle buses run?',
      'answer':
          'Campus buses operate on a 15-minute headway during peak hours (08:00–10:00 AM, 12:30–02:00 PM, 05:00–07:00 PM) on weekdays. Off-peak headway is 20–30 minutes across East and Main Campus routes.',
    },
    {
      'question': 'How accurate is the live bus tracking GPS?',
      'answer':
          'Bus locations update approximately every 5 seconds via onboard GPS transponders and telemetry. Live ETA predictions account for campus speed limits and stop dwell times.',
    },
    {
      'question': 'Are there buses available on weekends and holidays?',
      'answer':
          'Yes, weekend shuttle service operates with reduced frequency connecting Main Gate, Mega Hostel, LHC, and East Campus between 07:30 AM and 09:30 PM.',
    },
    {
      'question': 'How do I check live arrivals for my stop?',
      'answer':
          'Select your boarding stop from the dropdown on the Home screen to see real-time approaching buses, live route progression, and scheduled departures for that stop.',
    },
    {
      'question': 'Who should I contact for lost items left on campus buses?',
      'answer':
          'Report lost items immediately to the Transport Committee office near the Main Gate Security Cabin or email transport@nitc.ac.in with route, bus number, and time of commute.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedLg,
      ),
      backgroundColor: TrackletColors.textInverse,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
        vertical: TrackletSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: TrackletSpacing.largeIcon,
                        height: TrackletSpacing.largeIcon,
                        decoration: BoxDecoration(
                          color: TrackletColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: TrackletColors.primary,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: TrackletSpacing.md),
                      Text(
                        'Transit FAQ',
                        style: TrackletFonts.outfit(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: TrackletColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TrackletColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.md),
              Text(
                'Frequently asked questions about NIT Calicut campus transit, schedules, and live tracking.',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textSecondary,
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),
              const Divider(height: 1, color: TrackletColors.cardBorder),
              const SizedBox(height: TrackletSpacing.sm),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _faqItems.length,
                  separatorBuilder:
                      (context, index) => const Divider(
                        height: 1,
                        color: TrackletColors.background,
                      ),
                  itemBuilder: (context, index) {
                    final item = _faqItems[index];
                    return Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.xs,
                          vertical: TrackletSpacing.xxs,
                        ),
                        leading: Container(
                          width: TrackletSpacing.spacious,
                          height: TrackletSpacing.spacious,
                          decoration: const BoxDecoration(
                            color: TrackletColors.background,
                            borderRadius: TrackletRadii.roundedSm,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TrackletFonts.outfit(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: TrackletColors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          item['question']!,
                          style: TrackletFonts.outfit(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              40.0,
                              0.0,
                              12.0,
                              12.0,
                            ),
                            child: Text(
                              item['answer']!,
                              style: TrackletTypography.bodySmall.copyWith(
                                fontSize: 13.0,
                                height: 1.45,
                                color: TrackletColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrackletColors.primary,
                    foregroundColor: TrackletColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.md,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedMd,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: TrackletFonts.outfit(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
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
