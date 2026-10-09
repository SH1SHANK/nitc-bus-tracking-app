import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/tokens/colors.dart';
import 'package:tracklet/features/auth/create_account_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows account fields with the alternate 2px outline', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(const CreateAccountScreen());
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields, hasLength(3));

    final decorators = tester.widgetList<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorators, hasLength(3));

    for (final decorator in decorators) {
      final border = decorator.decoration.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.width, 2.0);
      expect(border.borderSide.color, TrackletColors.alternate);
    }

    expect(find.text('name@nitc.ac.in'), findsOneWidget);
    expect(find.text('Create a password'), findsOneWidget);
    expect(find.text('Re-enter your password'), findsOneWidget);
    for (final field in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(field.style.fontWeight, FontWeight.w600);
    }
    for (final decorator in decorators) {
      expect(decorator.decoration.hintStyle?.fontFamily, 'Outfit');
      expect(decorator.decoration.hintStyle?.fontWeight, FontWeight.w700);
      expect(decorator.decoration.labelStyle?.fontFamily, 'Outfit');
      expect(decorator.decoration.labelStyle?.fontWeight, FontWeight.w600);
      expect(
        decorator.decoration.floatingLabelStyle?.fontWeight,
        FontWeight.w700,
      );
      expect(decorator.decoration.errorStyle?.fontWeight, FontWeight.w600);
    }
  });

  testWidgets('rejects email addresses outside the NITC institute domain', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(const CreateAccountScreen());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'student@gmail.com',
    );
    final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Use your NITC institute email ending in @nitc.ac.in.'),
      findsOneWidget,
    );
  });

  testWidgets('accepts the NITC domain without case sensitivity', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(const CreateAccountScreen());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'student@NITC.AC.IN',
    );
    final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Use your NITC institute email ending in @nitc.ac.in.'),
      findsNothing,
    );
  });
}
