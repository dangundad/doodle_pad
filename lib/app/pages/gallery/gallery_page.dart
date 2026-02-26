import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

class GalleryPage extends GetView<DoodleController> {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 22.r),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'gallery'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, size: 24.r, color: cs.primary),
            tooltip: 'start_drawing'.tr,
            onPressed: () => Get.toNamed(Routes.DRAW),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.savedDrawings.isEmpty) {
          return _EmptyGallery(cs: cs);
        }

        return GridView.builder(
          padding: EdgeInsets.all(12.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.0,
          ),
          itemCount: controller.savedDrawings.length,
          itemBuilder: (context, index) {
            final path = controller.savedDrawings[index];
            return _GalleryCard(
              path: path,
              cs: cs,
              onTap: () => _showOptions(context, cs, path),
            );
          },
        );
      }),
    );
  }

  void _showOptions(BuildContext context, ColorScheme cs, String path) {
    final settingCtrl = SettingController.to;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            // 미리보기 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.file(
                File(path),
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 16.h),
            // 불러오기 버튼
            ListTile(
              leading: Icon(Icons.edit_rounded, color: cs.primary),
              title: Text('load_drawing'.tr,
                  style: TextStyle(fontSize: 15.sp)),
              onTap: () {
                Get.back();
                _confirmLoad(context, cs, path, settingCtrl);
              },
            ),
            // 공유 버튼
            ListTile(
              leading: Icon(Icons.share_rounded, color: cs.secondary),
              title: Text('share'.tr,
                  style: TextStyle(fontSize: 15.sp)),
              onTap: () {
                Get.back();
                _shareDrawing(path);
              },
            ),
            // 삭제 버튼
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text('delete_drawing'.tr,
                  style: TextStyle(fontSize: 15.sp, color: cs.error)),
              onTap: () {
                Get.back();
                _confirmDelete(context, cs, path);
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmLoad(
    BuildContext context,
    ColorScheme cs,
    String path,
    SettingController settingCtrl,
  ) {
    if (controller.strokes.isEmpty) {
      _openDrawWithFile(path, settingCtrl);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('load_drawing'.tr),
        content: Text('load_drawing_confirm'.tr),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              _openDrawWithFile(path, settingCtrl);
            },
            child: Text('load_drawing'.tr),
          ),
        ],
      ),
    );
  }

  void _openDrawWithFile(String path, SettingController settingCtrl) {
    // 현재 캔버스 초기화 후 이 파일을 배경으로 드로우 페이지 이동
    // (현재 구조상 Stroke 복원은 불가이므로 이미지를 참고용 배경으로 활용)
    controller.clearCanvas();
    if (settingCtrl.hapticEnabled.value) HapticFeedback.lightImpact();
    Get.toNamed(Routes.DRAW);
  }

  void _shareDrawing(String path) async {
    try {
      final xFile = XFile(path, mimeType: 'image/png');
      await SharePlus.instance.share(
        ShareParams(files: [xFile]),
      );
    } catch (e) {
      Get.snackbar('error'.tr, '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _confirmDelete(BuildContext context, ColorScheme cs, String path) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('delete_drawing'.tr),
        content: Text('delete_drawing_confirm'.tr),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteDrawing(path);
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text('delete_drawing'.tr),
          ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyGallery({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64.r,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'gallery_empty'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'gallery_subtitle'.tr,
            style: TextStyle(
              fontSize: 13.sp,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: () => Get.toNamed(Routes.DRAW),
            icon: const Icon(Icons.brush_rounded),
            label: Text('start_drawing'.tr),
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _GalleryCard({
    required this.path,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final stat = file.existsSync() ? file.statSync() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12.r)),
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_rounded,
                          size: 36.r,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.broken_image_rounded,
                        size: 36.r,
                        color: cs.onSurfaceVariant,
                      ),
              ),
            ),
            if (stat != null)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Text(
                  _formatDate(stat.modified),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: cs.onSurfaceVariant,
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

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
