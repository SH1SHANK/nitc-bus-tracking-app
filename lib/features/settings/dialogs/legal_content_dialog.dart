import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Modal dialog matching Attendrix legal viewer for Terms, Privacy, Licenses, and Open Source.
class LegalContentDialog extends StatelessWidget {
  const LegalContentDialog({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  static void show(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => LegalContentDialog(title: title, content: content),
    );
  }

  static void showTermsOfService(BuildContext context) {
    show(
      context,
      title: 'Terms of Service',
      content: LegalTexts.termsOfService,
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    show(context, title: 'Privacy Policy', content: LegalTexts.privacyPolicy);
  }

  static void showOpenSourceLibraries(BuildContext context) {
    show(
      context,
      title: 'Open Source Libraries',
      content: LegalTexts.openSourceLibraries,
    );
  }

  static void showMitLicense(BuildContext context) {
    show(context, title: 'MIT License', content: LegalTexts.licence);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
        vertical: TrackletSpacing.spacious,
      ),
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 600.0),
        decoration: const BoxDecoration(
          color: TrackletColors.secondaryBackground,
          borderRadius: TrackletRadii.roundedLg,
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: TrackletColors.scrim,
              offset: Offset(0.0, 6.0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TrackletSpacing.section,
                TrackletSpacing.lg,
                TrackletSpacing.md,
                TrackletSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TrackletFonts.outfit(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TrackletColors.secondaryText,
                      size: 24.0,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(
              color: TrackletColors.alternate,
              height: TrackletSpacing.hairline,
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TrackletSpacing.xl),
                child: Text(
                  content,
                  style: TrackletFonts.outfit(
                    fontSize: 13.5,
                    height: 1.5,
                    color: TrackletColors.textPrimary,
                  ),
                ),
              ),
            ),

            const Divider(
              color: TrackletColors.alternate,
              height: TrackletSpacing.hairline,
            ),
            Padding(
              padding: const EdgeInsets.all(TrackletSpacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrackletColors.primary,
                    foregroundColor: TrackletColors.textInverse,
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.section,
                      vertical: TrackletSpacing.compactMd,
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TrackletFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static text contents for Terms of Service, Privacy Policy, Open Source Libraries, and License.
abstract final class LegalTexts {
  static const String termsOfService = '''
# Terms and Conditions for Tracklet

Last Updated: October 2026

## 1. Acceptance of Terms
By accessing or using Tracklet ("the App"), you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not use the application.

## 2. Campus Transit Services
Tracklet is an internal transit utility designed for students, faculty, and staff of the National Institute of Technology Calicut (NITC). The bus timings, schedules, and live telemetry displayed within the app are subject to operational changes, weather conditions, campus roadworks, and driver availability.

## 3. User Accounts & Academic Identity
Users must register using valid institutional NITC credentials. You are responsible for safeguarding your account access credentials and for all activities that occur under your account.

## 4. Location Data & Real-time Services
The App processes device GPS location strictly for the contextual calculation of walking times and nearest bus stop recommendations. Location coordinates are processed locally on-device and are not broadcast to third parties or sold to commercial brokers.

## 5. Community Conduct
Users agree not to disrupt the transit telemetry infrastructure, attempt unauthorized access to API endpoints, or distribute malicious scripts.

## 6. Limitation of Liability
Tracklet and its contributors shall not be liable for missed classes, transit delays, schedule variations, or indirect damages resulting from reliance on the transit tracking data.
''';

  static const String privacyPolicy = '''
# Privacy Policy for Tracklet

Last Updated: October 2026

## 1. Information We Collect
- **Student Profile**: Name, institutional email (@nitc.ac.in), branch, batch year, current semester, and hostel designation.
- **Transit Preferences**: Favorite bus stops, preferred routes, time format (12h/24h), and notification lead times.
- **Device Location**: Contextual device GPS is utilized solely for estimating walking distance to campus bus stops when location permission is explicitly granted.

## 2. How We Use Your Data
- To provide live bus arrival estimates and route schedules.
- To dispatch timely push notifications for upcoming bus arrivals and campus transit disruptions.
- To personalize the commute dashboard based on your preferred stops and semester timetable.

## 3. Data Storage & Security
User preference data is stored with Row Level Security (RLS) policies on secure Supabase infrastructure and locally cached on your device. We do not sell or rent personal data to third parties.

## 4. Your Rights & Account Deletion
You retain complete control over your account. You can update your display name or permanently delete your account and associated transit data at any time from the Settings page.
''';

  static const String openSourceLibraries = '''
# Open Source Libraries Used in Tracklet

Tracklet is built with gratitude to the open-source software community:

- **flutter**: Google's UI toolkit for building natively compiled applications.
- **flutter_riverpod**: A reactive caching and state-management framework for Dart and Flutter.
- **go_router**: A declarative routing package for Flutter.
- **supabase_flutter**: Flutter client for Supabase authentication, database, and realtime updates.
- **flutter_map & latlong2**: Map rendering toolkit for Leaflet/OSM layers.
- **flutter_map_mbtiles**: Offline MBTiles raster map provider.
- **geolocator**: Cross-platform geolocation plugin.
- **onesignal_flutter**: Push notification delivery platform.
- **Outfit / Satoshi**: Open-source typography typefaces bundled with Tracklet.
- **moon_design**: Cohesive UI component kit.
- **shared_preferences**: Persistent key-value storage wrapper.
- **flutter_animate**: Fluid animation and transition primitives.
''';

  static const String licence = '''
MIT License

Copyright (c) 2026 Shashank Mergu & NITC Tracklet Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';
}
