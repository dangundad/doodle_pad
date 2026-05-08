import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib Dart files do not use gradients', () {
    final gradientPattern = RegExp(
      r'\b(?:LinearGradient|RadialGradient|SweepGradient)\b',
    );
    final offenders = <String>[];

    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final content = file.readAsStringSync();
      if (gradientPattern.hasMatch(content)) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
