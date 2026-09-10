import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/gallery_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/utils/app_toast.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

/// 작품 그리드 + 빈 상태 + 길게누름 삭제 + 다중 선택.
class GalleryPage extends GetView<GalleryController> {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.deleteMode.value) {
            return Text(
              '${controller.selectedIds.length}${'gallery_selected_suffix'.tr}',
            );
          }
          return Text('${'gallery_title'.tr} (${controller.artworks.length})');
        }),
        leading: Obx(
          () => IconButton(
            icon: Icon(
              controller.deleteMode.value
                  ? LucideIcons.x
                  : LucideIcons.arrowLeft,
            ),
            onPressed: () {
              if (controller.deleteMode.value) {
                controller.exitDeleteMode();
              } else {
                Get.back();
              }
            },
            tooltip: controller.deleteMode.value
                ? 'gallery_exit_select_mode'.tr
                : 'back'.tr,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.artworks.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                controller.deleteMode.value
                    ? LucideIcons.checkCheck
                    : LucideIcons.listChecks,
              ),
              onPressed: controller.toggleDeleteMode,
              tooltip: controller.deleteMode.value
                  ? 'gallery_exit_select_mode'.tr
                  : 'gallery_select_mode'.tr,
            );
          }),
          SizedBox(width: 4.w),
        ],
      ),
      backgroundColor: cs.surface,
      body: Obx(() {
        if (controller.isLoading.value && controller.artworks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.artworks.isEmpty) {
          return _GalleryEmpty(onStartDrawing: _goToDraw);
        }
        final deleteMode = controller.deleteMode.value;
        return Column(
          children: [
            if (controller.isAboveWarnThreshold)
              _OverLimitBanner(count: controller.artworks.length),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  // 캔버스가 세로로 긴 비율이라 셀도 세로로 키워 그림을 크게 보인다.
                  childAspectRatio: 0.72,
                ),
                itemCount: controller.artworks.length,
                itemBuilder: (context, index) {
                  final art = controller.artworks[index];
                  return Obx(
                    () => _ArtworkCard(
                      artwork: art,
                      deleteMode: controller.deleteMode.value,
                      selected: controller.isSelected(art.id),
                      onOpen: () => _openArtwork(context, art),
                      onDelete: () => _confirmDeleteSingle(context, art),
                      onToggleSelect: () => controller.toggleSelect(art.id),
                    ),
                  );
                },
              ),
            ),
            if (deleteMode)
              _SelectionActionBar(
                onDelete: _confirmDeleteSelected,
                onShare: _shareSelected,
              ),
          ],
        );
      }),
    );
  }

  void _goToDraw() {
    Get.offNamed(Routes.DRAW);
  }

  Future<void> _openArtwork(BuildContext context, Drawing artwork) async {
    final settings = SettingController.to;
    if (settings.hapticEnabled.value) {
      DoodleController.to.hapticSelection();
    }

    // 현재 캔버스에 작업물이 있으면 명시 확인 없이 덮어쓰지 않는다.
    final ctrl = DoodleController.to;
    if (ctrl.hasDrawableContent) {
      final proceed = await AppConfirmDialog.show(
        icon: LucideIcons.folderOpen,
        title: 'artwork_open_overwrite_title'.tr,
        message: 'artwork_open_overwrite_desc'.tr,
        confirmLabel: 'confirm'.tr,
        cancelLabel: 'cancel'.tr,
      );
      if (proceed != true) return;
      if (!context.mounted) return;
    }

    // 재오픈 시 현재 화면 크기를 viewport로 전달해 letterbox 스케일로 좌표를 흡수.
    final viewport = MediaQuery.sizeOf(context);
    ctrl.loadArtwork(artwork, viewport: viewport);

    // 그리기 화면에서 넘어온 경우에는 뒤로 돌아가 스택 중복을 막는다.
    if (Get.previousRoute == Routes.DRAW) {
      Get.back<void>();
      return;
    }
    await Get.offNamed(Routes.DRAW);
  }

  Future<void> _confirmDeleteSingle(
    BuildContext context,
    Drawing artwork,
  ) async {
    final confirmed = await _deleteConfirmDialog(
      title: 'artwork_delete_title'.tr,
      message: 'artwork_delete_confirm'.tr,
    );
    if (confirmed == true) {
      await controller.deleteArtwork(artwork.id);
    }
  }

  Future<void> _confirmDeleteSelected() async {
    if (!controller.hasSelection) return;
    final count = controller.selectedIds.length;
    final confirmed = await _deleteConfirmDialog(
      title: 'artwork_delete_title'.tr,
      message: '$count${'gallery_delete_selected_confirm'.tr}',
    );
    if (confirmed == true) {
      await controller.deleteSelected();
    }
  }

  Future<void> _shareSelected() async {
    if (!controller.hasSelection) return;
    final paths = controller.selectedThumbnailPaths();
    if (paths.isEmpty) {
      AppToast.show(
        AppToastMessage.info(
          title: 'gallery_title'.tr,
          description: 'share_error'.tr,
        ),
      );
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [for (final path in paths) XFile(path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(title: 'error'.tr, description: 'share_error'.tr),
      );
    }
  }

  Future<bool?> _deleteConfirmDialog({
    required String title,
    required String message,
  }) {
    return AppConfirmDialog.show(
      icon: LucideIcons.trash2,
      title: title,
      message: message,
      confirmLabel: 'delete'.tr,
      cancelLabel: 'cancel'.tr,
      destructive: true,
    );
  }
}

/// 빈 상태 — 빈 종이 한 장 + 안내 + 그리기 시작.
class _GalleryEmpty extends StatelessWidget {
  const _GalleryEmpty({required this.onStartDrawing});
  final VoidCallback onStartDrawing;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.r,
              height: 124.r,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.pencilLine,
                  size: 30.r,
                  color: cs.outlineVariant,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'gallery_empty_title'.tr,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'gallery_empty_desc'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              icon: const Icon(LucideIcons.brush),
              label: Text('start_drawing'.tr),
              onPressed: onStartDrawing,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverLimitBanner extends StatelessWidget {
  const _OverLimitBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 16.r,
            color: cs.onSecondaryContainer,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${'gallery_overlimit_warning'.tr} ($count)',
              style: TextStyle(
                fontSize: 13.sp,
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({required this.onDelete, required this.onShare});

  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final ctrl = GalleryController.to;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => OutlinedButton.icon(
                  icon: Icon(LucideIcons.share2, size: 16.r),
                  label: Text('gallery_share_selected'.tr),
                  onPressed: ctrl.hasSelection ? onShare : null,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Obx(
                () => FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  icon: Icon(LucideIcons.trash2, size: 16.r),
                  label: Text('gallery_delete_selected'.tr),
                  onPressed: ctrl.hasSelection ? onDelete : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 작품 카드 — 종이(흰 표면 + 헤어라인) 위에 그림, 아래에 날짜.
class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artwork,
    required this.deleteMode,
    required this.selected,
    required this.onOpen,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final Drawing artwork;
  final bool deleteMode;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final created = DateTime.fromMillisecondsSinceEpoch(artwork.createdAt);
    final dateText =
        '${created.year}.${created.month.toString().padLeft(2, '0')}.${created.day.toString().padLeft(2, '0')}';
    final radius = BorderRadius.circular(AppTheme.radiusMd.r);
    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            // 삭제 모드: 탭=선택 토글 / 일반 모드: 탭=열기, 길게누름=단건 삭제
            onTap: deleteMode ? onToggleSelect : onOpen,
            onLongPress: deleteMode ? null : onDelete,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ThumbnailView(
                    path: artwork.thumbnailPath,
                    canvasColor: Color(artwork.canvasColor),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12.r,
                        color: cs.outline,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (deleteMode)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
              ),
            ),
          if (deleteMode)
            PositionedDirectional(
              top: 8.r,
              end: 8.r,
              child: Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? cs.primary : cs.surface,
                  border: Border.all(
                    color: selected ? cs.primary : cs.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(LucideIcons.check, size: 15.r, color: cs.onPrimary)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbnailView extends StatelessWidget {
  const _ThumbnailView({required this.path, required this.canvasColor});
  final String? path;
  final Color canvasColor;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    if (path == null) {
      return ColoredBox(
        color: cs.surfaceContainerLow,
        child: Center(
          child: Icon(LucideIcons.image, size: 24.r, color: cs.outline),
        ),
      );
    }
    // 캔버스는 세로로 긴 비율이라 cover 로는 대부분이 잘린다.
    // contain 으로 전체를 보여주고 여백은 캔버스 배경색으로 채워 "종이"처럼 보이게 한다.
    return ColoredBox(
      color: canvasColor,
      child: Image.file(
        File(path!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(LucideIcons.imageOff, size: 24.r, color: cs.outline),
        ),
      ),
    );
  }
}
