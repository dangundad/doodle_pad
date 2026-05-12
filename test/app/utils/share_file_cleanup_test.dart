import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/utils/share_file_cleanup.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_share_file_cleanup_test_',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('deletes only stale doodle share png files', () async {
    final now = DateTime(2026, 5, 12, 12);
    final staleShare = File(
      '${tempDir.path}${Platform.pathSeparator}doodle_old.png',
    );
    final freshShare = File(
      '${tempDir.path}${Platform.pathSeparator}doodle_new.png',
    );
    final unrelated = File(
      '${tempDir.path}${Platform.pathSeparator}other_old.png',
    );

    await staleShare.writeAsBytes([1]);
    await freshShare.writeAsBytes([2]);
    await unrelated.writeAsBytes([3]);
    await staleShare.setLastModified(now.subtract(const Duration(days: 2)));
    await freshShare.setLastModified(now.subtract(const Duration(hours: 2)));
    await unrelated.setLastModified(now.subtract(const Duration(days: 2)));

    final deleted = await ShareFileCleanup.deleteStaleDoodleShareFiles(
      tempDir,
      now: now,
      maxAge: const Duration(days: 1),
    );

    expect(deleted, 1);
    expect(staleShare.existsSync(), isFalse);
    expect(freshShare.existsSync(), isTrue);
    expect(unrelated.existsSync(), isTrue);
  });
}
