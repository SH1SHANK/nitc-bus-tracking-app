import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/theme/tracklet_theme.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpTrackletWidget(
    Widget widget, {
    List<dynamic> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        // ignore: avoid_dynamic_calls
        overrides: overrides.cast(),
        child: MaterialApp(theme: TrackletTheme.lightTheme, home: widget),
      ),
    );
    await pump();
  }
}
