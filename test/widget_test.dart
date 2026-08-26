import 'package:flutter_test/flutter_test.dart';

import 'package:fsd/main.dart';

void main() {
  testWidgets('FSD home screen shows the fetch button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FsdApp());
    await tester.pump();

    expect(find.text('Fetch Customer Details'), findsOneWidget);
    expect(find.text('FSD'), findsOneWidget);
  });
}
