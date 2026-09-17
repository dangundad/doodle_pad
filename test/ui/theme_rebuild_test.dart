import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/theme/app_theme.dart';

/// `Get.theme` 은 InheritedWidget 구독이 아니라 GetMaterialApp 이 들고 있는
/// 테마를 즉시 읽는다. 따라서 시스템 다크/라이트 전환처럼 "테마만 바뀌는"
/// 상황에서 그 값을 읽은 위젯은 리빌드되지 않고 옛 색을 그대로 유지한다.
///
/// 실기기 QA 에서 이 때문에 화면이 절반만 다크로 바뀌었고, 홈의 "내 그림
/// 보관함" 카드가 검은 배경 + 검은 글씨가 되어 읽을 수 없었다.
/// 페이지 build 안에서는 반드시 `Theme.of(context)` 를 쓴다.
void main() {
  test('페이지 build 안에서 Get.theme 으로 색을 읽지 않는다', () {
    // `build(BuildContext context)` 바디에서 쓰이는 형태만 잡는다.
    // 컨텍스트가 없는 static show() 안(바텀시트 빌더 등)은 예외로 둔다.
    final pattern = RegExp(r'final\s+cs\s*=\s*Get\.theme\b');
    final offenders = <String>[];

    for (final file
        in Directory('lib/app/pages')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final content = file.readAsStringSync();
      for (final match in pattern.allMatches(content)) {
        // static show() 안에서 시트를 만드는 경우는 BuildContext 가 없다.
        // 그 지점은 시트가 열려 있는 동안만 유효하므로 제외한다.
        final before = content.substring(0, match.start);
        final lastBuild = before.lastIndexOf('Widget build(BuildContext');
        final lastStatic = before.lastIndexOf('static ');
        if (lastBuild > lastStatic) {
          final line = '\n'.allMatches(before).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'build() 안에서는 Theme.of(context) 를 쓰세요. '
          '테마 전환 시 리빌드되지 않습니다:\n${offenders.join('\n')}',
    );
  });

  testWidgets('테마가 바뀌면 Theme.of(context) 를 읽은 위젯이 새 색으로 리빌드된다', (
    tester,
  ) async {
    // 회귀 방지의 본질: "테마만 바뀌어도 화면 색이 따라온다".
    Widget app(ThemeMode mode) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.pumpWidget(app(ThemeMode.light));
    final lightColor = tester.widget<ColoredBox>(find.byType(ColoredBox)).color;

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    final darkColor = tester.widget<ColoredBox>(find.byType(ColoredBox)).color;

    expect(lightColor, AppTheme.light.colorScheme.surface);
    expect(darkColor, AppTheme.dark.colorScheme.surface);
    expect(lightColor, isNot(darkColor));
  });
}
