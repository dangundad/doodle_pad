import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

/// 360dp — 실기기/에뮬레이터 QA 기준 폭. 여기서 잘리면 대부분의 폰에서 잘린다.
const Size _compactPhone = Size(360, 800);

Future<void> _pumpDialog(
  WidgetTester tester, {
  required String cancelLabel,
  required String confirmLabel,
}) async {
  tester.view.physicalSize = _compactPhone * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppConfirmDialog(
            icon: LucideIcons.triangleAlert,
            title: 'Discard drawing?',
            message: 'This drawing will be lost.',
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            destructive: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 두 버튼이 세로로 쌓였는지(true) 한 행에 나란한지(false) 판정한다.
bool _isStacked(WidgetTester tester, String cancelLabel, String confirmLabel) {
  final cancelCenter = tester.getCenter(find.text(cancelLabel));
  final confirmCenter = tester.getCenter(find.text(confirmLabel));
  return (cancelCenter.dy - confirmCenter.dy).abs() > 1.0;
}

/// 라벨이 담긴 버튼이 자기 라벨을 잘리지 않고 담을 만큼 넓은지.
///
/// 주의: flutter_test 는 실제 앱 폰트(google_fonts)를 로드하지 않으므로
/// 글리프 폭이 실기기와 다르다. 따라서 "실제로 잘렸는가"는 단위 테스트로
/// 판정할 수 없고, 여기서는 폰트에 무관한 레이아웃 불변식만 검증한다.
double _labelWidth(WidgetTester tester, String label) =>
    tester.getSize(find.text(label)).width;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AppConfirmDialog 액션 버튼', () {
    // 지원 11개 로케일의 `keep_drawing`/`discard`, `watch_ad`/`cancel` 등
    // 실제로 쓰이는 라벨 조합 중 긴 것들. 예전에는 두 버튼을 항상 반폭으로
    // 나눠, `Keep drawing`(en)조차 `Keep drawi…`로 잘렸다.
    const labelPairs = <(String cancel, String confirm)>[
      ('Cancel', 'Discard'), // en - 짧은 조합
      ('취소', '지우기'), // ko
      ('Keep drawing', 'Discard'), // en
      ('Continuer à dessiner', 'Abandonner'), // fr - 가장 긴 조합
      ('Continuar desenhando', 'Descartar'), // pt
      ('Lanjut menggambar', 'Buang'), // id
      ('Seguir dibujando', 'Descartar'), // es
      ('Weiter zeichnen', 'Verwerfen'), // de
      ('Cancel', 'Watch ad'), // en - 잠금 브러시 해금
      ('Отмена', 'Смотреть рекламу'), // ru - 가장 긴 확인 라벨
    ];

    for (final (cancelLabel, confirmLabel) in labelPairs) {
      testWidgets('"$cancelLabel" / "$confirmLabel" 은 라벨 폭을 담는다', (
        tester,
      ) async {
        await _pumpDialog(
          tester,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
        );

        // 한 행을 고집하지 않는지 확인: 반폭 버튼에 담기지 않는 라벨이라면
        // 세로로 쌓여서 전폭을 써야 한다.
        final stacked = _isStacked(tester, cancelLabel, confirmLabel);
        final dialogWidth = tester.getSize(find.byType(OutlinedButton)).width;
        final widest = [
          _labelWidth(tester, cancelLabel),
          _labelWidth(tester, confirmLabel),
        ].reduce((a, b) => a > b ? a : b);

        if (!stacked) {
          // 한 행으로 배치했다면, 그 폭이 라벨을 담을 수 있어야 한다.
          expect(
            dialogWidth,
            greaterThan(widest),
            reason:
                '"$cancelLabel"/"$confirmLabel" 을 한 행에 두었지만 '
                '버튼 폭($dialogWidth)이 라벨 폭($widest)보다 좁습니다.',
          );
        }
      });
    }

    testWidgets('세로로 쌓을 때는 확인 버튼이 위에 온다', (tester) async {
      await _pumpDialog(
        tester,
        cancelLabel: 'Continuer à dessiner',
        confirmLabel: 'Abandonner',
      );

      expect(_isStacked(tester, 'Continuer à dessiner', 'Abandonner'), isTrue);
      final cancelCenter = tester.getCenter(find.text('Continuer à dessiner'));
      final confirmCenter = tester.getCenter(find.text('Abandonner'));
      expect(confirmCenter.dy, lessThan(cancelCenter.dy));
    });

    testWidgets('세로로 쌓으면 두 버튼 모두 전폭을 쓴다', (tester) async {
      await _pumpDialog(
        tester,
        cancelLabel: 'Continuer à dessiner',
        confirmLabel: 'Abandonner',
      );

      final cancelWidth = tester.getSize(find.byType(OutlinedButton)).width;
      final confirmWidth = tester.getSize(find.byType(FilledButton)).width;
      expect(cancelWidth, closeTo(confirmWidth, 0.5));
      // 반폭(=예전 동작)보다 확실히 넓어야 한다.
      final dialogWidth = tester.getSize(find.byType(Dialog)).width;
      expect(cancelWidth, greaterThan(dialogWidth / 2));
    });

    testWidgets('짧은 라벨은 한 행에 나란히 둔다', (tester) async {
      // 한국어처럼 짧은 라벨까지 세로로 쌓이면 다이얼로그가 불필요하게 길어진다.
      await _pumpDialog(tester, cancelLabel: '취소', confirmLabel: '지우기');

      expect(_isStacked(tester, '취소', '지우기'), isFalse);
      final cancelCenter = tester.getCenter(find.text('취소'));
      final confirmCenter = tester.getCenter(find.text('지우기'));
      expect(cancelCenter.dx, lessThan(confirmCenter.dx));
    });
  });
}
