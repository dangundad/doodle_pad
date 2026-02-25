import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

class ActivityLogService extends GetxService {
  static ActivityLogService get to => Get.find<ActivityLogService>();

  static const String _kLogBox = 'phase1_activity_log';
  static const String _kEventKey = 'events';
  static const int _kMaxEvents = 300;

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_kLogBox)) {
      return Hive.box(_kLogBox);
    }
    return await Hive.openBox(_kLogBox);
  }

  Future<List<Map<String, dynamic>>> getEvents({
    int limit = 200,
    String? appId,
  }) async {
    final box = await _openBox();
    final raw = box.get(_kEventKey, defaultValue: <dynamic>[]);
    final all = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final parsed = <String, dynamic>{};
          for (final entry in item.entries) {
            parsed[entry.key?.toString() ?? 'unknown'] = entry.value;
          }
          final targetApp = parsed['appId']?.toString() ?? '';
          if (appId == null || targetApp == appId) {
            all.add(parsed);
          }
        }
      }
    }

    all.sort((a, b) {
      final aTime = _parseDate(a['at']);
      final bTime = _parseDate(b['at']);
      return bTime.compareTo(aTime);
    });

    if (limit <= 0 || all.length <= limit) {
      return all;
    }
    return all.sublist(0, limit);
  }

  Future<void> logEvent({
    required String appId,
    required String eventName,
    required String screen,
    String? route,
    Map<String, dynamic> metadata = const {},
  }) async {
    final box = await _openBox();
    final raw = box.get(_kEventKey, defaultValue: <dynamic>[]);
    final events = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final parsed = <String, dynamic>{};
          for (final entry in item.entries) {
            parsed[entry.key?.toString() ?? 'unknown'] = entry.value;
          }
          events.add(parsed);
        }
      }
    }

    events.insert(0, {
      'appId': appId,
      'event': eventName,
      'screen': screen,
      'route': route ?? '',
      'at': DateTime.now().toIso8601String(),
      'metadata': metadata,
    });

    if (events.length > _kMaxEvents) {
      events.removeRange(_kMaxEvents, events.length);
    }

    await box.put(_kEventKey, events);
  }

  Future<void> clearEvents({String? appId}) async {
    final box = await _openBox();
    final raw = box.get(_kEventKey, defaultValue: <dynamic>[]);
    if (appId == null || raw is! List || raw.isEmpty) {
      await box.put(_kEventKey, <Map<String, dynamic>>[]);
      return;
    }

    final events = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        final parsed = <String, dynamic>{};
        for (final entry in item.entries) {
          parsed[entry.key?.toString() ?? 'unknown'] = entry.value;
        }
        if (parsed['appId']?.toString() != appId) {
          events.add(parsed);
        }
      }
    }
    await box.put(_kEventKey, events);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
