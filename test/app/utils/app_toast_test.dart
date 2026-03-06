import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

import 'package:doodle_pad/app/utils/app_toast.dart';

void main() {
  testWidgets('AppToast shows a success toast message', (tester) async {
    await tester.pumpWidget(
      const ToastificationWrapper(
        child: MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    AppToast.show(const AppToastMessage.success(title: 'Saved'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });
}
