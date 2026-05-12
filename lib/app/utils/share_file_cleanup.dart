import 'dart:io';

class ShareFileCleanup {
  ShareFileCleanup._();

  static const String _doodleSharePrefix = 'doodle_';
  static const String _pngExtension = '.png';

  static Future<int> deleteStaleDoodleShareFiles(
    Directory directory, {
    DateTime? now,
    Duration maxAge = const Duration(days: 1),
  }) async {
    if (!directory.existsSync()) return 0;

    final resolvedNow = now ?? DateTime.now();
    var deleted = 0;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;

      final name = Uri.decodeComponent(entity.uri.pathSegments.last);
      if (!name.startsWith(_doodleSharePrefix) ||
          !name.endsWith(_pngExtension)) {
        continue;
      }

      try {
        final stat = await entity.stat();
        if (resolvedNow.difference(stat.modified) < maxAge) continue;
        await entity.delete();
        deleted += 1;
      } catch (_) {
        // Temp cleanup must never block sharing.
      }
    }

    return deleted;
  }
}
