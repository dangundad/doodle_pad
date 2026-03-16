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
                cs.primary.withValues(alpha: 0.10),
                cs.surface,
                cs.secondaryContainer.withValues(alpha: 0.15),
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                        final rawEvent =
                            item['event']?.toString() ?? 'unknown_event';
                        final event = _localizeEvent(rawEvent);
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
                                  color: _eventColor(rawEvent, cs),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  _eventIcon(rawEvent),
                                  color: _eventIconColor(rawEvent, cs),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 18.r,
                  color: cs.onPrimary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'history'.tr,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: controller.clearAll,
                tooltip: 'clear_all'.tr,
                icon: Icon(Icons.delete_outline, size: 20.r, color: cs.error),
              ),
            ],
          ),
        ),
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
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

  String _localizeEvent(String raw) {
    if (raw == 'unknown_event') return 'unknown_event'.tr;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  IconData _eventIcon(String eventName) {
    final target = eventName.toLowerCase();

    if (target.contains('premium')) {
      return Icons.workspace_premium;
    }
    if (target.contains('stats')) {
      return Icons.bar_chart_rounded;
    }
    if (target.contains('draw') ||
        target.contains('stroke') ||
        target.contains('path')) {
      return Icons.brush;
    }
    if (target.contains('open_')) {
      return Icons.arrow_forward;
    }

    return Icons.history;
  }

  Color _eventColor(String eventName, ColorScheme cs) {
    final t = eventName.toLowerCase();
    if (t.contains('premium')) return cs.tertiaryContainer;
    if (t.contains('stats')) return cs.secondaryContainer;
    if (t.contains('draw') || t.contains('stroke') || t.contains('path')) {
      return cs.primaryContainer;
    }
    return cs.surfaceContainerHigh;
  }

  Color _eventIconColor(String eventName, ColorScheme cs) {
    final t = eventName.toLowerCase();
    if (t.contains('premium')) return cs.tertiary;
    if (t.contains('stats')) return cs.secondary;
    if (t.contains('draw') || t.contains('stroke') || t.contains('path')) {
      return cs.primary;
    }
    return cs.onSurfaceVariant;
  }
}
