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
import 'package:doodle_pad/app/utils/app_toast.dart';

/// Plan FR-09 — 작품 그리드 + 빈 상태 + 길게누름 삭제.
/// Design Ref: §5.3 — 2열 정사각 썸네일, AppBar에 작품 수 표시.
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
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            );
          }
          return Text(
            '${'gallery_title'.tr} (${controller.artworks.length})',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          );
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
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
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

    // 현재 캔버스에 작업물이 있으면 사용자 명시 확인 없이 덮어쓰지 않는다.
    // 홈 진입의 "이어 그리기 / 새로 시작" 다이얼로그와 같은 손실 방어 원칙.
    final ctrl = DoodleController.to;
    if (ctrl.hasDrawableContent) {
      final proceed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('continue_or_new_title'.tr),
          content: Text(
            'continue_or_new_desc'.tr,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text('confirm'.tr),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      if (proceed != true) return;
      if (!context.mounted) return;
    }

    // Design Ref: §6.2 — 재오픈 시 현재 화면 크기를 viewport로 전달해
    // 저장 시점과 비율이 다른 기기/회전에서도 letterbox 스케일로 좌표를 흡수한다.
    // DrawPage 캔버스는 Positioned.fill이므로 화면 크기를 근사값으로 사용.
    final viewport = MediaQuery.sizeOf(context);
    ctrl.loadArtwork(artwork, viewport: viewport);
    await Get.toNamed(Routes.DRAW);
  }

  /// 단건 길게누름 삭제 (일반 모드).
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

  /// 다중 선택 삭제 (삭제 모드).
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

  /// 선택된 작품의 썸네일을 공유한다.
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
          files: [
            for (final path in paths) XFile(path, mimeType: 'image/png'),
          ],
        ),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'share_error'.tr,
        ),
      );
    }
  }

  Future<bool?> _deleteConfirmDialog({
    required String title,
    required String message,
  }) {
    final cs = Get.theme.colorScheme;
    return Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAlias,
        backgroundColor: cs.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
              child: Column(
                children: [
                  Container(
                    width: 52.r,
                    height: 52.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.errorContainer,
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 26.r,
                      color: cs.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      ),
                      onPressed: () => Get.back(result: true),
                      child: Text('clear'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryEmpty extends StatelessWidget {
  const _GalleryEmpty({required this.onStartDrawing});
  final VoidCallback onStartDrawing;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.images, size: 56.r, color: cs.outlineVariant),
            SizedBox(height: 16.h),
            Text(
              'gallery_empty_title'.tr,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'gallery_empty_desc'.tr,
              style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      margin: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 16.r,
            color: cs.onErrorContainer,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${'gallery_overlimit_warning'.tr} ($count)',
              style: TextStyle(
                fontSize: 12.sp,
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
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
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14.r),
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
                Expanded(child: _ThumbnailView(path: artwork.thumbnailPath)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (deleteMode)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? cs.primary : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          if (deleteMode)
            Positioned(
              top: 6.r,
              right: 6.r,
              child: Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? cs.primary : cs.surface,
                  border: Border.all(color: cs.outline),
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
  const _ThumbnailView({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    if (path == null) {
      return ColoredBox(
        color: cs.surfaceContainerHigh,
        child: Center(
          child: Icon(LucideIcons.image, size: 24.r, color: cs.outline),
        ),
      );
    }
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: cs.surfaceContainerHigh,
        child: Center(
          child: Icon(LucideIcons.imageOff, size: 24.r, color: cs.outline),
        ),
      ),
    );
  }
}
