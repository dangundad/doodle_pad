import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  children: [
                    SizedBox(height: 32.h),

                    // Animated app icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 120.r,
                        height: 120.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primaryContainer,
                              cs.secondaryContainer,
                              cs.tertiaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32.r),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.brush_rounded,
                          size: 60.r,
                          color: cs.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: 28.h),

                    Text(
                      'app_name'.tr,
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'app_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 40.h),

                    // Feature chips
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureChip(
                          icon: Icons.edit_rounded,
                          label: 'feature_pen'.tr,
                        ),
                        _FeatureChip(
                          icon: Icons.brush_rounded,
                          label: 'feature_marker'.tr,
                        ),
                        _FeatureChip(
                          icon: Icons.auto_fix_normal_rounded,
                          label: 'feature_eraser'.tr,
                        ),
                        _FeatureChip(
                          icon: Icons.palette_rounded,
                          label: 'feature_colors'.tr,
                        ),
                        _FeatureChip(
                          icon: Icons.undo_rounded,
                          label: 'feature_undo'.tr,
                        ),
                        _FeatureChip(
                          icon: Icons.share_rounded,
                          label: 'feature_share'.tr,
                        ),
                      ],
                    ),

                    SizedBox(height: 48.h),

                    // Start drawing CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: FilledButton.icon(
                        onPressed: () => Get.toNamed(Routes.DRAW),
                        icon: Icon(Icons.brush_rounded, size: 22.r),
                        label: Text(
                          'start_drawing'.tr,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),

            BannerAdWidget(
              adUnitId: AdHelper.bannerAdUnitId,
              type: AdHelper.banner,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: cs.primary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
