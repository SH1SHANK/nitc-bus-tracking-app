import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';

/// Helper to build and launch pre-filled, sanitized GitHub Issues URLs.
class GitHubIssueHelper {
  const GitHubIssueHelper._();

  static const String _repoUrl =
      'https://github.com/SH1SHANK/nitc-bus-tracking-app';

  /// Launches an external browser with a pre-filled Bug Report GitHub issue draft.
  static Future<bool> openBugReportIssue({
    required String title,
    required String description,
    required String stepsToReproduce,
    required String expectedBehavior,
    required String actualBehavior,
    String? category,
    String? severity,
  }) async {
    final body =
        StringBuffer()
          ..writeln('### Description')
          ..writeln(description.trim())
          ..writeln()
          ..writeln('### Steps to Reproduce')
          ..writeln(stepsToReproduce.trim())
          ..writeln()
          ..writeln('### Expected Behavior')
          ..writeln(expectedBehavior.trim())
          ..writeln()
          ..writeln('### Actual Behavior')
          ..writeln(actualBehavior.trim())
          ..writeln()
          ..writeln('### System & Metadata')
          ..writeln('- **Category**: ${category ?? 'General'}')
          ..writeln('- **Severity**: ${severity ?? 'Normal'}')
          ..writeln(
            '- **Platform**: ${kIsWeb ? 'Web Browser' : defaultTargetPlatform.name}',
          )
          ..writeln('- **App Version**: ${AppConfig.appVersion}');

    return _launchIssue(
      title: '[Bug]: ${title.trim()}',
      body: body.toString(),
      labels: 'bug,triage',
    );
  }

  /// Launches an external browser with a pre-filled General Feedback GitHub issue draft.
  static Future<bool> openFeedbackIssue({
    required String feedbackType,
    required int rating,
    required String comments,
  }) async {
    final body =
        StringBuffer()
          ..writeln('### Feedback Type')
          ..writeln(feedbackType.trim())
          ..writeln()
          ..writeln('### Rating')
          ..writeln('$rating / 5 stars')
          ..writeln()
          ..writeln('### Comments & Suggestions')
          ..writeln(comments.trim())
          ..writeln()
          ..writeln('### System & Metadata')
          ..writeln(
            '- **Platform**: ${kIsWeb ? 'Web Browser' : defaultTargetPlatform.name}',
          )
          ..writeln('- **App Version**: ${AppConfig.appVersion}');

    return _launchIssue(
      title: '[Feedback]: $feedbackType ($rating/5)',
      body: body.toString(),
      labels: 'feedback',
    );
  }

  /// Launches an external browser with a pre-filled Feature Suggestion GitHub issue draft.
  static Future<bool> openFeatureSuggestionIssue({
    required String title,
    required String problemSolved,
    required String targetAudience,
    String? priority,
  }) async {
    final body =
        StringBuffer()
          ..writeln('### Proposed Feature')
          ..writeln(title.trim())
          ..writeln()
          ..writeln('### Problem It Solves')
          ..writeln(problemSolved.trim())
          ..writeln()
          ..writeln('### Target Audience & Use Case')
          ..writeln(targetAudience.trim())
          ..writeln()
          ..writeln('### Suggested Priority')
          ..writeln(priority ?? 'Normal')
          ..writeln()
          ..writeln('### System & Metadata')
          ..writeln(
            '- **Platform**: ${kIsWeb ? 'Web Browser' : defaultTargetPlatform.name}',
          )
          ..writeln('- **App Version**: ${AppConfig.appVersion}');

    return _launchIssue(
      title: '[Feature]: ${title.trim()}',
      body: body.toString(),
      labels: 'enhancement',
    );
  }

  static Future<bool> _launchIssue({
    required String title,
    required String body,
    required String labels,
  }) async {
    final queryParams = {'title': title, 'body': body, 'labels': labels};

    final uri = Uri.parse(
      '$_repoUrl/issues/new',
    ).replace(queryParameters: queryParams);

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
