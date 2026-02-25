import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
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

  final SettingController _settingController = Get.find<SettingController>();
  bool _didShowWelcome = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SettingController.to.recordHomeOpen(Get.currentRoute);
      _maybeShowWelcome();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _maybeShowWelcome() {
    if (_didShowWelcome) return;
    if (!_settingController.isFirstRun.value) return;
    _didShowWelcome = true;

    Get.dialog(
      AlertDialog(
        title: Text('onboarding_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('onboarding_message'.tr),
            SizedBox(height: 14.h),
            _FeatureChip(icon: Icons.gesture, label: 'brush_guide'.tr),
            SizedBox(height: 10.h),
            _FeatureChip(icon: Icons.undo_rounded, label: 'feature_undo'.tr),
            SizedBox(height: 10.h),
            _FeatureChip(icon: Icons.ios_share, label: 'share'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _settingController.setShowBrushGuide(false);
              await _settingController.finishFirstRun();
              Get.back();
            },
            child: Text('onboarding_skip'.tr),
          ),
          FilledButton(
            onPressed: () async {
              await _settingController.finishFirstRun();
              Get.back();
            },
            child: Text('onboarding_start'.tr),
          ),
        ],
      ),
    );
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
              _HomeTopActions(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.r,
                    vertical: 12.r,
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
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.tertiary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () async {
                                if (_settingController.hapticEnabled.value) {
                                  HapticFeedback.selectionClick();
                                }
                                await Get.toNamed(Routes.DRAW);
                                if (_settingController
                                    .showBrushGuide.value) {
                                  HapticFeedback.mediumImpact();
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.brush_rounded,
                                      size: 22.r,
                                      color: cs.onPrimary,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'start_drawing'.tr,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      TextButton.icon(
                        onPressed: () {
                          _settingController.recordSettingsOpen(
                            from: 'home_button',
                          );
                          Get.toNamed(Routes.SETTINGS);
                        },
                        icon: Icon(Icons.settings_rounded, size: 18.r),
                        label: Text('settings'.tr),
                      ),
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

class _HomeTopActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.toNamed(Routes.GALLERY),
            icon: Icon(Icons.photo_library_rounded, color: cs.primary),
            tooltip: 'gallery'.tr,
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.HISTORY),
            icon: Icon(Icons.history_rounded, color: cs.onSurface),
            tooltip: 'open_history'.tr,
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.STATS),
            icon: Icon(Icons.bar_chart_rounded, color: cs.onSurface),
            tooltip: 'open_stats'.tr,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.toNamed(Routes.SETTINGS),
            icon: Icon(Icons.settings_rounded, color: cs.onSurface),
            tooltip: 'settings'.tr,
          ),
        ],
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
