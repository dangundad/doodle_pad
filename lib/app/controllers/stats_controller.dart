import 'package:get/get.dart';

import 'package:doodle_pad/app/services/activity_log_service.dart';

class StatsController extends GetxController {
  static const String appId = 'doodle_pad';

  final ActivityLogService _activityLogService = Get.find<ActivityLogService>();

  final RxInt totalEvents = 0.obs;
  final RxInt todayEvents = 0.obs;
  final RxInt weekEvents = 0.obs;
  final RxInt uniqueRoutes = 0.obs;
  final RxInt uniqueScreens = 0.obs;
  final RxInt openStatsCount = 0.obs;
  final RxList<String> topEventNames = <String>[].obs;
  final RxMap<String, int> eventCountMap = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    final list = await _activityLogService.getEvents(appId: appId, limit: 400);

    totalEvents.value = list.length;

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final weekStart = dayStart.subtract(const Duration(days: 6));

    int todayCount = 0;
    int weekCount = 0;

    final routes = <String>{};
    final screens = <String>{};
    final eventCount = <String, int>{};

    for (final item in list) {
      final eventName = item['event']?.toString() ?? 'unknown';
      final route = item['route']?.toString() ?? '-';
      final screen = item['screen']?.toString() ?? '-';
      final ts = _parseDate(item['at']);

      routes.add(route);
      screens.add(screen);
      eventCount[eventName] = (eventCount[eventName] ?? 0) + 1;

      if (ts.year == today.year && ts.month == today.month && ts.day == today.day) {
        todayCount++;
      }
      if (!ts.isBefore(weekStart)) {
        weekCount++;
      }
    }

    todayEvents.value = todayCount;
    weekEvents.value = weekCount;
    uniqueRoutes.value = routes.length;
    uniqueScreens.value = screens.length;

    final sorted = eventCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    eventCountMap.assignAll(eventCount);
    topEventNames.assignAll(sorted.take(8).map((item) => item.key).toList());
    openStatsCount.value = eventCount['open_stats'] ?? 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
