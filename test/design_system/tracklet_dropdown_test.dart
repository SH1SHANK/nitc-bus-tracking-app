import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_dropdown.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrackletDropdown', () {
    testWidgets('renders hint text and items list properly', (tester) async {
      String? selectedValue;

      await tester.pumpTrackletWidget(
        TrackletDropdown(
          items: const ['Option 1', 'Option 2', 'Option 3'],
          hintText: 'Select Option',
          onChanged: (val) => selectedValue = val,
        ),
      );

      expect(find.text('Select Option'), findsOneWidget);

      // Tap to open dropdown
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);

      // Select an option
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'Option 2');
    });

    testWidgets('renders with initialItem when provided', (tester) async {
      await tester.pumpTrackletWidget(
        TrackletDropdown(
          items: const ['Computer Science', 'Mechanical', 'Civil'],
          initialItem: 'Computer Science',
          onChanged: (_) {},
        ),
      );

      expect(find.text('Computer Science'), findsOneWidget);
    });

    testWidgets('renders searchable dropdown correctly', (tester) async {
      await tester.pumpTrackletWidget(
        TrackletDropdown(
          items: const ['Mega Hostel', 'Ladies Hostel', 'PG 1 Hostel'],
          hintText: 'Select Hostel',
          isSearchable: true,
          searchHintText: 'Search hostel...',
          onChanged: (_) {},
        ),
      );

      expect(find.text('Select Hostel'), findsOneWidget);

      await tester.tap(find.text('Select Hostel'));
      await tester.pumpAndSettle();

      expect(find.text('Mega Hostel'), findsOneWidget);
      expect(find.text('Search hostel...'), findsOneWidget);
    });
  });
}
