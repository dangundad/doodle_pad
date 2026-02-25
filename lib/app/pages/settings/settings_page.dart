import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/routes/app_pages.dart';

class SettingsPage extends GetView<dynamic> {
  const SettingsPage({super.key});

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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                Text(
                  'settings'.tr,
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'settings_page'.tr,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp),
                ),
                SizedBox(height: 20.h),
                _SettingsSection(
                  icon: Icons.apps,
                  title: 'app_name'.tr,
                  children: [
                    _ListItem(
                      icon: Icons.history,
                      title: 'open_history'.tr,
                      subtitle: 'open_history'.tr,
                      onTap: () => Get.toNamed(Routes.HISTORY),
                    ),
                    _ListItem(
                      icon: Icons.bar_chart,
                      title: 'open_stats'.tr,
                      subtitle: 'open_stats'.tr,
                      onTap: () => Get.toNamed(Routes.STATS),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _SettingsSection(
                  icon: Icons.workspace_premium,
                  title: 'premium_title'.tr,
                  children: [
                    _ListItem(
                      icon: Icons.auto_awesome,
                      title: 'premium_title'.tr,
                      subtitle: 'premium_subtitle'.tr,
                      onTap: () => Get.toNamed(Routes.PREMIUM),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _SettingsSection(
                  icon: Icons.support_agent,
                  title: 'send_feedback'.tr,
                  children: [
                    _ListItem(
                      icon: Icons.apps,
                      title: 'more_apps'.tr,
                      subtitle: 'privacy_policy'.tr,
                      onTap: () {},
                      enabled: false,
                    ),
                    _ListItem(
                      icon: Icons.privacy_tip,
                      title: 'privacy_policy'.tr,
                      subtitle: 'privacy_policy'.tr,
                      onTap: () {},
                      enabled: false,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 10.h),
            child: Row(
              children: [
                Icon(icon, size: 18.r, color: cs.primary),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final child in children) child,
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 18.r, color: cs.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18.r),
            ],
          ),
        ),
      ),
    );
  }
}
