import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

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
    final cs = Get.theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ExitBottomSheet.show();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: cs.surface.withValues(alpha: 0.85),
          title: Text(
            'app_name'.tr,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.crown, size: 20.r, color: cs.tertiary),
              tooltip: 'premium_title'.tr,
              onPressed: () => Get.toNamed(Routes.PREMIUM),
            ),
            IconButton(
              icon: Icon(LucideIcons.settings, size: 20.r, color: cs.onSurface),
              tooltip: 'settings'.tr,
              onPressed: () => Get.toNamed(Routes.SETTINGS),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
              ),
            ),
          ),
        ),
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
                      vertical: 12.r,
                    ),
                    child: Column(
                      children: [
                        _Hero(),
                        SizedBox(height: 26.h),
                        _TitleBlock(),
                        SizedBox(height: 30.h),
                        _FeatureChipsCard(features: _features),
                        SizedBox(height: 28.h),
                        _StartDrawingCta(pulseAnim: _pulseAnim),
                      ],
                    ),
                  ),
                ),
                Obx(
                  () => PurchaseService.isPremiumActive
                      ? const SizedBox.shrink()
                      : BannerAdWidget(
                          adUnitId: AdHelper.bannerAdUnitId,
                          type: AdHelper.banner,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return TweenAnimationBuilder<double>(
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
    );
  }
}

class _TitleBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Column(
      children: [
        Text(
          'app_name'.tr,
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Text(
          'app_subtitle'.tr,
          style: TextStyle(fontSize: 15.sp, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FeatureChipsCard extends StatelessWidget {
  final List<(IconData, String)> features;
  const _FeatureChipsCard({required this.features});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        alignment: WrapAlignment.center,
        children: features.asMap().entries.map((entry) {
          final idx = entry.key;
          final (icon, labelKey) = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 380 + idx * 60),
            curve: Curves.easeOutBack,
            builder: (ctx, v, child) => Transform.scale(
              scale: v,
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: _FeatureChip(icon: icon, label: labelKey.tr),
          );
        }).toList(),
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
    final cs = Get.theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StartDrawingCta extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _StartDrawingCta({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final settingCtrl = SettingController.to;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) =>
          Transform.scale(scale: pulseAnim.value, child: child),
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
              color: cs.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: cs.tertiary.withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () async {
              if (settingCtrl.hapticEnabled.value) {
                DoodleController.to.hapticSelection();
              }
              DoodleController.to.clearCanvas();
              await Get.toNamed(Routes.DRAW);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.brush_rounded, size: 22.r, color: cs.onPrimary),
                  SizedBox(width: 10.w),
                  Text(
                    'start_drawing'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
