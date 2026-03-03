import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/history_controller.dart';

class HistoryPage extends GetView<HistoryController> {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surface,
                cs.surfaceContainerLowest.withValues(alpha: 0.95),
                cs.surfaceContainerLow.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, cs),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.loadHistory(),
                  color: cs.primary,
                  child: Obx(() {
                    final events = controller.events;
                    if (events.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 120.h),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 52.r,
                                    color: cs.primary.withValues(alpha: 0.45),
                                  ),
                                  SizedBox(height: 14.h),
                                  Text(
                                    'no_history'.tr,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final item = events[index];
                        final event = item['event']?.toString() ?? 'unknown_event'.tr;
                        final screen = item['screen']?.toString() ?? '-';
                        final route = item['route']?.toString() ?? '-';
                        final at = _formatTime(item['at']);

                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: cs.outline.withValues(alpha: 0.32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  _eventIcon(event),
                                  color: cs.primary,
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'history_subtitle'.trParams({
                                        'screen': screen,
                                        'route': route,
                                      }),
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11.sp,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                at,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 14.w, 10.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'history'.tr,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.clearAll,
                tooltip: 'clear_all'.tr,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20.r,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatTime(dynamic raw) {
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    }
    return '-';
  }

  IconData _eventIcon(String eventName) {
    final target = eventName.toLowerCase();

    if (target.contains('premium')) {
      return Icons.workspace_premium;
    }
    if (target.contains('stats')) {
      return Icons.bar_chart_rounded;
    }
    if (target.contains('draw') || target.contains('stroke') || target.contains('path')) {
      return Icons.brush;
    }
    if (target.contains('open_')) {
      return Icons.arrow_forward;
    }

    return Icons.history;
  }
}
