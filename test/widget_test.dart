import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

import 'package:doodle_pad/main.dart';

void main() {
  testWidgets('doodle_pad smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DoodlePadApp());

    expect(find.byType(DoodlePadApp), findsOneWidget);
    expect(find.byType(ToastificationWrapper), findsOneWidget);
  });
}
