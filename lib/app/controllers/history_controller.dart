import 'package:get/get.dart';

import 'package:doodle_pad/app/services/activity_log_service.dart';

class HistoryController extends GetxController {
  static const String appId = 'doodle_pad';

  final ActivityLogService _activityLogService = Get.find<ActivityLogService>();

  final RxList<Map<String, dynamic>> events = <Map<String, dynamic>>[].obs;
  final RxString filterRoute = ''.obs;
  final RxString filterEvent = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final list = await _activityLogService.getEvents(appId: appId, limit: 400);

    final routeFilter = filterRoute.value.trim();
    final eventFilter = filterEvent.value.trim();

    final filtered = list.where((event) {
      final routeValue = event['route']?.toString() ?? '';
      final eventValue = event['event']?.toString() ?? '';

      if (routeFilter.isNotEmpty && routeValue != routeFilter) {
        return false;
      }
      if (eventFilter.isNotEmpty && eventValue != eventFilter) {
        return false;
      }
      return true;
    }).toList();

    events.assignAll(filtered);
  }

  Future<void> applyFilter({
    String? route,
    String? event,
  }) async {
    filterRoute.value = route ?? '';
    filterEvent.value = event ?? '';
    await loadHistory();
  }

  Future<void> clearFilter() async {
    filterRoute.value = '';
    filterEvent.value = '';
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _activityLogService.clearEvents(appId: appId);
    await loadHistory();
  }
}
