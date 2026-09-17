import 'dart:io';

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
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';
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
    await AppBinding.markOnboardingSeen();
    await Get.offAllNamed(Routes.DRAW);
    return;
  }

  final continueExisting = await AppConfirmDialog.show(
    icon: LucideIcons.brush,
    title: 'continue_or_new_title'.tr,
    message: 'continue_or_new_desc'.tr,
    confirmLabel: 'continue_drawing'.tr,
    cancelLabel: 'start_new'.tr,
    barrierDismissible: true,
  );

  if (continueExisting == null) {
    // 사용자가 다이얼로그를 닫음 — 현재 작품과 화면 상태를 유지하고 진입 취소.
    return;
  }
  if (!continueExisting) {
    ctrl.clearCanvas();
  }
  await AppBinding.markOnboardingSeen();
  await Get.offAllNamed(Routes.DRAW);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

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
            SizedBox(width: 4.w),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(reduceMotion: reduceMotion),
                      const SizedBox(height: 36),
                      const _TitleBlock(),
                      SizedBox(height: 20.h),
                      _FeatureChips(
                        features: _features,
                        reduceMotion: reduceMotion,
                      ),
                      SizedBox(height: 24.h),
                      const _StartDrawingCta(),
                      SizedBox(height: 12.h),
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

/// 히어로 — 최근 작품을 겹쳐 놓은 "종이 묶음". 작품이 없으면 빈 종이 한 장.
/// 장식이 아니라 사용자 자신의 그림이 첫 화면을 채우게 한다.
class _Hero extends StatelessWidget {
  const _Hero({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: ValueListenableBuilder(
        key: const ValueKey('home-hero-artwork'),
        valueListenable: HiveService.to.drawingsBox.listenable(),
        builder: (context, Box<Drawing> box, _) {
          final recent = box.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final paths = [
            for (final d in recent.take(3))
              if (d.thumbnailPath != null) d.thumbnailPath!,
          ];
          return _PaperStack(paths: paths);
        },
      ),
    );
  }
}

class _PaperStack extends StatelessWidget {
  const _PaperStack({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = 168.h.clamp(140.0, 200.0);
    final sheetWidth = height * 0.72;

    Widget sheet({String? path, double angle = 0, double dx = 0}) {
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: sheetWidth,
            height: height - 16,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: path == null
                ? Center(
                    child: Icon(
                      LucideIcons.pencilLine,
                      size: 30.r,
                      color: cs.outlineVariant,
                    ),
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        size: 22.r,
                        color: cs.outline,
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    // 항상 3장을 쌓는다. 작품이 모자라면 빈 종이가 뒤를 채워 "묶음"이 유지된다.
    final slots = <String?>[...paths.take(3)];
    while (slots.length < 3) {
      slots.add(null);
    }
    // slots[0] 이 가장 최근 = 맨 위. 뒤쪽 장일수록 더 기울이고 옆으로 뺀다.
    final children = <Widget>[
      sheet(path: slots[2], angle: -0.06, dx: -16),
      sheet(path: slots[1], angle: 0.04, dx: 12),
      sheet(path: slots[0]),
    ];

    return SizedBox(
      height: height,
      child: Stack(alignment: Alignment.center, children: children),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: const ValueKey('home-title'),
          'app_name'.tr,
          style: TextStyle(
            fontSize: isRtl ? 28.sp : 32.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: isRtl ? 0 : -0.8,
            height: 1.15,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Text(
          key: const ValueKey('home-subtitle'),
          'app_subtitle'.tr,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 도구 요약 — 라벨 있는 작은 칩. 카드로 감싸지 않고 제목 아래에 바로 흘린다.
class _FeatureChips extends StatelessWidget {
  final List<(IconData, String)> features;
  final bool reduceMotion;
  const _FeatureChips({required this.features, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: features.asMap().entries.map((entry) {
        final idx = entry.key;
        final (icon, labelKey) = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: reduceMotion
              ? Duration.zero
              : Duration(milliseconds: 220 + idx * 40),
          curve: Curves.easeOutCubic,
          builder: (ctx, v, child) =>
              Opacity(opacity: v.clamp(0.0, 1.0), child: child),
          child: _FeatureChip(icon: icon, label: labelKey.tr),
        );
      }).toList(),
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: cs.onSurface),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartDrawingCta extends StatelessWidget {
  const _StartDrawingCta();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settingCtrl = SettingController.to;

    return Tooltip(
      key: const ValueKey('home-start-cta'),
      message: 'start_drawing'.tr,
      child: Material(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
          onTap: () => _enterDrawing(settingCtrl),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(LucideIcons.brush, size: 22.r, color: cs.onPrimary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'start_drawing'.tr,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: cs.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.arrowLeft
                      : LucideIcons.arrowRight,
                  size: 20.r,
                  color: cs.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 작품 보관함 진입 — drawings box를 관찰해 작품 수를 실시간 반영.
class _MyArtworksCard extends StatelessWidget {
  const _MyArtworksCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: HiveService.to.drawingsBox.listenable(),
      builder: (context, Box<Drawing> box, _) {
        final count = box.length;
        return AppPanel(
          onTap: () => Get.toNamed(Routes.GALLERY),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              const IconBadge(LucideIcons.images, tone: IconBadgeTone.accent),
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
                        fontSize: 13.sp,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const DirectionalChevron(),
            ],
          ),
        );
      },
    );
  }
}
