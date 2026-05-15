import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/bindings/app_binding.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

/// 홈에서 그리기 화면으로 진입할 때 호출.
/// 작업 중인 그림이 남아 있으면 "이어 그리기 / 새로 시작" 다이얼로그를 띄우고,
/// 사용자가 새로 시작을 고르거나 캔버스가 비어있으면 자동으로 clearCanvas() 한다.
Future<void> _enterDrawing(SettingController settingCtrl) async {
  final ctrl = DoodleController.to;
  if (settingCtrl.hapticEnabled.value) {
    ctrl.hapticSelection();
  }

  if (!ctrl.hasDrawableContent) {
    ctrl.clearCanvas();
    // Item 3: 온보딩 완료 표시 + 스택 교체 — 이후 back은 ExitBottomSheet로 흐른다.
    await AppBinding.markOnboardingSeen();
    await Get.offAllNamed(Routes.DRAW);
    return;
  }

  final cs = Get.theme.colorScheme;
  final continueExisting = await Get.dialog<bool>(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: cs.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(
                LucideIcons.brush,
                size: 26.r,
                color: cs.onPrimaryContainer,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'continue_or_new_title'.tr,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Text(
              'continue_or_new_desc'.tr,
              style: TextStyle(fontSize: 14.sp, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('start_new'.tr),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('continue_drawing'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );

  if (continueExisting == null) return;
  if (!continueExisting) {
    ctrl.clearCanvas();
  }
  // Item 3: 온보딩 완료 표시 + 스택 교체.
  await AppBinding.markOnboardingSeen();
  await Get.offAllNamed(Routes.DRAW);
}

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
    (LucideIcons.pen, 'feature_pen'),
    (LucideIcons.brush, 'feature_marker'),
    (LucideIcons.eraser, 'feature_eraser'),
    (LucideIcons.palette, 'feature_colors'),
    (LucideIcons.undo2, 'feature_undo'),
    (LucideIcons.share2, 'feature_share'),
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
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(
            'app_name'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.crown, size: 20.r),
              tooltip: 'premium_title'.tr,
              onPressed: () => Get.toNamed(Routes.PREMIUM),
            ),
            IconButton(
              icon: Icon(LucideIcons.settings, size: 20.r),
              tooltip: 'settings'.tr,
              onPressed: () => Get.toNamed(Routes.SETTINGS),
            ),
          ],
        ),
        body: SafeArea(
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
                      SizedBox(height: 14.h),
                      const _MyArtworksCard(),
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
    );
  }
}

/// Plan FR-10 — 홈에서 작품 갤러리로 진입.
/// drawings box를 listenable로 관찰해 작품 수를 실시간 반영.
class _MyArtworksCard extends StatelessWidget {
  const _MyArtworksCard();

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return ValueListenableBuilder(
      valueListenable: HiveService.to.drawingsBox.listenable(),
      builder: (context, Box<Drawing> box, _) {
        final count = box.length;
        return Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => Get.toNamed(Routes.GALLERY),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.secondaryContainer,
                    ),
                    child: Icon(
                      LucideIcons.images,
                      size: 20.r,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'gallery_title'.tr,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${'gallery_saved_count'.tr} $count',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18.r,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      child: Tooltip(
        message: 'app_subtitle'.tr,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 132.r,
              height: 132.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
            ),
            Text('🎨', style: TextStyle(fontSize: 56.sp)),
          ],
        ),
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
    return Tooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cs.outlineVariant),
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
      child: Tooltip(
        message: 'start_drawing'.tr,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => _enterDrawing(settingCtrl),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.brush, size: 22.r, color: cs.onPrimary),
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
      ),
    );
  }
}
