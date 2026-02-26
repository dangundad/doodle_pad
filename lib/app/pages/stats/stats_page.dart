import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/stats_controller.dart';

class StatsPage extends GetView<StatsController> {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                cs.surfaceContainerLowest.withValues(alpha: 0.94),
                cs.surfaceContainerLow.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 14.w, 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'stats'.tr,
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.refresh(),
                      tooltip: 'refresh'.tr,
                      icon: Icon(Icons.refresh, size: 20.r, color: cs.primary),
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.refresh(),
                  color: cs.primary,
                  child: Obx(
                    () => ListView(
                      padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
                      children: [
                        _MetricCard(
                          cs: cs,
                          entries: [
                            _MetricData(
                              'total_events'.tr,
                              '${controller.totalEvents.value}',
                            ),
                            _MetricData(
                              'today_events'.tr,
                              '${controller.todayEvents.value}',
                            ),
                            _MetricData(
                              'week_events'.tr,
                              '${controller.weekEvents.value}',
                            ),
                            _MetricData(
                              'open_stats'.tr,
                              '${controller.openStatsCount.value}',
                            ),
                            _MetricData(
                              'unique_routes'.tr,
                              '${controller.uniqueRoutes.value}',
                            ),
                            _MetricData(
                              'unique_screens'.tr,
                              '${controller.uniqueScreens.value}',
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _SectionCard(
                          cs: cs,
                          title: 'top_events'.tr,
                          child: controller.topEventNames.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: Center(
                                    child: Text(
                                      'no_history'.tr,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: controller.topEventNames.map((
                                    name,
                                  ) {
                                    final count =
                                        controller.eventCountMap[name] ?? 0;
                                    return _TopEventRow(
                                      event: name,
                                      count: count,
                                      cs: cs,
                                    );
                                  }).toList(),
                                ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

class _MetricCard extends StatelessWidget {
  final ColorScheme cs;
  final List<_MetricData> entries;

  const _MetricCard({required this.cs, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: entries
            .map(
              (entry) => SizedBox(
                width: (Get.width - 62.w) / 3,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        entry.label,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ColorScheme cs;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.cs,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TopEventRow extends StatelessWidget {
  final String event;
  final int count;
  final ColorScheme cs;

  const _TopEventRow({
    required this.event,
    required this.count,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(Icons.history, size: 16.r, color: cs.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              event,
              style: TextStyle(color: cs.onSurface, fontSize: 12.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
