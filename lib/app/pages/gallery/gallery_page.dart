import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/gallery_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

/// Plan FR-09 — 작품 그리드 + 빈 상태 + 길게누름 삭제.
/// Design Ref: §5.3 — 2열 정사각 썸네일, AppBar에 작품 수 표시.
class GalleryPage extends GetView<GalleryController> {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            '${'gallery_title'.tr} (${controller.artworks.length})',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: Get.back,
          tooltip: 'back'.tr,
        ),
      ),
      backgroundColor: cs.surface,
      body: Obx(() {
        if (controller.isLoading.value && controller.artworks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.artworks.isEmpty) {
          return _GalleryEmpty(onStartDrawing: _goToDraw);
        }
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
                  return _ArtworkCard(
                    artwork: art,
                    onOpen: () => _openArtwork(art),
                    onDelete: () => _confirmDelete(context, art),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _goToDraw() {
    Get.offNamed(Routes.DRAW);
  }

  Future<void> _openArtwork(Drawing artwork) async {
    final settings = SettingController.to;
    if (settings.hapticEnabled.value) {
      DoodleController.to.hapticSelection();
    }
    // viewport는 DrawPage에서 strokes 좌표계가 자동 적용되므로,
    // 여기서는 저장 시점 로지컬 크기를 그대로 써서 비율 보존.
    DoodleController.to.loadArtwork(artwork);
    await Get.toNamed(Routes.DRAW);
  }

  Future<void> _confirmDelete(BuildContext context, Drawing artwork) async {
    final cs = Get.theme.colorScheme;
    final confirmed = await Get.dialog<bool>(
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
                    'artwork_delete_title'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'artwork_delete_confirm'.tr,
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
    if (confirmed == true) {
      await controller.deleteArtwork(artwork.id);
    }
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

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artwork,
    required this.onOpen,
    required this.onDelete,
  });

  final Drawing artwork;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

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
      child: InkWell(
        onTap: onOpen,
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ThumbnailView(path: artwork.thumbnailPath)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
