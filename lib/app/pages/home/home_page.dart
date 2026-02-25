import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  static const _features = [
    (Icons.edit_rounded, 'feature_pen'),
    (Icons.brush_rounded, 'feature_marker'),
    (Icons.auto_fix_normal_rounded, 'feature_eraser'),
    (Icons.palette_rounded, 'feature_colors'),
    (Icons.undo_rounded, 'feature_undo'),
    (Icons.share_rounded, 'feature_share'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.14),
              cs.surface,
              cs.secondaryContainer.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.r,
                    vertical: 20.r,
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.scale(scale: value, child: child),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 132.r,
                              height: 132.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    cs.primaryContainer,
                                    cs.secondaryContainer,
                                    cs.tertiaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.26),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                            ),
                            Text('🎨', style: TextStyle(fontSize: 56.sp)),
                          ],
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Text(
                        'app_name'.tr,
                        style: TextStyle(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
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
                      SizedBox(height: 34.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: cs.outline.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          alignment: WrapAlignment.center,
                          children: _features.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final (icon, labelKey) = entry.value;
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 380 + idx * 60),
                              curve: Curves.easeOutBack,
                              builder: (ctx, v, child) => Transform.scale(
                                scale: v,
                                child: Opacity(
                                  opacity: v.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                              child: _FeatureChip(
                                icon: icon,
                                label: labelKey.tr,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 36.h),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: SizedBox(
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
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              Container(
                color: cs.surface.withValues(alpha: 0.9),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12.w,
                      right: 12.w,
                      top: 8.h,
                      bottom: 10.h,
                    ),
                    child: BannerAdWidget(
                      adUnitId: AdHelper.bannerAdUnitId,
                      type: AdHelper.banner,
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
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
