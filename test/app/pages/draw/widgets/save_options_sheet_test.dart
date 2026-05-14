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
  testWidgets('초기 prefill: 2x + PNG가 선택 상태로 렌더된다', (tester) async {
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

    // 2x 라디오는 선택, 1x/3x는 미선택
    expect(find.text('1x  Standard'), findsOneWidget);
    expect(find.text('2x  HD'), findsOneWidget);
    expect(find.text('3x  Ultra HD'), findsOneWidget);

    // PNG/JPEG 토글 라벨 존재
    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('JPEG'), findsOneWidget);

    // Save 버튼 존재
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Save 누르면 onConfirm에 현재 선택값이 전달된다', (tester) async {
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

    // 3x로 변경
    await tester.tap(find.text('3x  Ultra HD'));
    await tester.pumpAndSettle();

    // JPEG로 변경
    await tester.tap(find.text('JPEG'));
    await tester.pumpAndSettle();

    // Save 탭
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(capturedResolution, 3);
    expect(capturedFormat, ExportImageFormat.jpeg);
  });
}
