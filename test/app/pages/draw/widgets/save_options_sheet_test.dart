import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/pages/draw/widgets/save_options_sheet.dart';
import 'package:doodle_pad/app/services/export_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';

Widget _harness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 800),
    builder: (_, _) => GetMaterialApp(
      translations: Languages(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('포맷 옵션과 Save 버튼이 표시된다', (tester) async {
    await tester.pumpWidget(
      _harness(
        SaveOptionsSheet(
          initialResolution: 2,
          initialFormat: ExportImageFormat.png,
          onConfirm: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PNG/JPEG 토글 라벨 존재
    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('JPEG'), findsOneWidget);

    // Save 버튼 존재
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Save 누르면 onConfirm에 현재 포맷과 prefill 해상도가 전달된다', (
    tester,
  ) async {
    int? capturedResolution;
    ExportImageFormat? capturedFormat;

    await tester.pumpWidget(
      _harness(
        SaveOptionsSheet(
          initialResolution: 2,
          initialFormat: ExportImageFormat.png,
          onConfirm: (resolution, format) {
            capturedResolution = resolution;
            capturedFormat = format;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // JPEG로 변경
    await tester.tap(find.text('JPEG'));
    await tester.pumpAndSettle();

    // Save 탭
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // 해상도는 prefill 값을 그대로 콜백에 전달한다 (UI는 제거됨).
    expect(capturedResolution, 2);
    expect(capturedFormat, ExportImageFormat.jpeg);
  });
}
