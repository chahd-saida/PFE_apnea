import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apnea_project/screens/shared/fix_profile_screen.dart';

void main() {
  testWidgets('FixProfileScreen renders support guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FixProfileScreen()));

    expect(find.text('Profil Incomplet'), findsOneWidget);
    expect(
      find.textContaining('profil est incomplet', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Se reconnecter'), findsOneWidget);
  });
}
