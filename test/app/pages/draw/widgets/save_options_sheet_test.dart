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
  testWidgets('해상도(1x/2x/3x)와 포맷(PNG/JPEG) 옵션, Save 버튼이 표시된다', (
    tester,
  ) async {
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

    // 해상도 라벨 — 11개 언어에 키 존재, en 값은 1x/2x/3x prefix.
    expect(find.textContaining('1x'), findsOneWidget);
    expect(find.textContaining('2x'), findsOneWidget);
    expect(find.textContaining('3x'), findsOneWidget);

    // 포맷 옵션
    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('JPEG'), findsOneWidget);

    // Save 버튼
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets(
    'Save 누르면 선택된 해상도/포맷이 그대로 onConfirm 에 전달된다',
    (tester) async {
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

      // 3x 해상도 선택
      await tester.tap(find.textContaining('3x'));
      await tester.pumpAndSettle();

      // JPEG 포맷 선택
      await tester.tap(find.text('JPEG'));
      await tester.pumpAndSettle();

      // Save 탭
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        capturedResolution,
        3,
        reason: '해상도 UI 가 복구되었으므로 사용자가 선택한 값이 전달돼야 한다.',
      );
      expect(capturedFormat, ExportImageFormat.jpeg);
    },
  );

  testWidgets(
    '아무 옵션도 누르지 않고 Save 하면 initial 값이 그대로 onConfirm 으로 전달된다',
    (tester) async {
      int? capturedResolution;
      ExportImageFormat? capturedFormat;

      await tester.pumpWidget(
        _harness(
          SaveOptionsSheet(
            initialResolution: 1,
            initialFormat: ExportImageFormat.jpeg,
            onConfirm: (resolution, format) {
              capturedResolution = resolution;
              capturedFormat = format;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(capturedResolution, 1);
      expect(capturedFormat, ExportImageFormat.jpeg);
    },
  );
}
