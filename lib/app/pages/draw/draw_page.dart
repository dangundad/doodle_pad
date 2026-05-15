import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';
import 'package:doodle_pad/app/pages/draw/widgets/canvas_painter.dart';
import 'package:doodle_pad/app/pages/draw/widgets/save_options_sheet.dart';
import 'package:doodle_pad/app/services/export_service.dart';

class DrawPage extends GetView<DoodleController> {
  const DrawPage({super.key});

  /// 작업 중 그림이 있을 때 뒤로 나가기를 시도하면 확인 다이얼로그를 표시한다.
  /// 반환값이 true면 호출자가 화면을 닫고, false면 그리기 화면을 유지한다.
  static Future<bool> _confirmDiscardIfNeeded(
    DoodleController ctrl,
    SettingController settingCtrl,
  ) async {
    if (!ctrl.hasDrawableContent) return true;

    final cs = Get.theme.colorScheme;
    final result = await Get.dialog<bool>(
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
                      LucideIcons.triangleAlert,
                      size: 26.r,
                      color: cs.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'discard_drawing_title'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'discard_drawing_desc'.tr,
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
                      child: Text('keep_drawing'.tr),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      ),
                      onPressed: () {
                        if (settingCtrl.hapticEnabled.value) {
                          ctrl.hapticHeavy();
                        }
                        Get.back(result: true);
                      },
                      child: Text('discard'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardIfNeeded(
          controller,
          settingCtrl,
        );
        if (shouldPop) {
          controller.clearCanvas();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerHighest,
        body: Stack(
          children: [
            // Full-screen drawing canvas
            // Design Ref: §2.2 — InteractiveViewer가 outer, RepaintBoundary가 inner.
            // 캡처는 logical 캔버스(transform 미적용) 기준으로 일관됨.
            // 한 손가락 = GestureDetector 그리기, 두 손가락 = InteractiveViewer 핀치 줌.
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: controller.transformController,
                // panEnabled=false: 한 손가락 pan은 InteractiveViewer가 거부 →
                // 아래 GestureDetector가 그리기 제스처를 잡는다.
                panEnabled: false,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: RepaintBoundary(
                  key: controller.canvasKey,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) {
                      if (settingCtrl.hapticEnabled.value) {
                        controller.hapticSelection();
                      }
                      controller.startStroke(d.localPosition);
                    },
                    onPanUpdate: (d) =>
                        controller.continueStroke(d.localPosition),
                    onPanEnd: (_) => controller.endStroke(),
                    // Plan FR-04: 더블탭 시 Fit-to-screen으로 복귀.
                    onDoubleTap: () {
                      if (settingCtrl.hapticEnabled.value) {
                        controller.hapticSelection();
                      }
                      controller.resetCanvasTransform();
                    },
                    child: Obx(() {
                      final referencePath =
                          controller.referenceImagePath.value;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: Color(controller.canvasColor.value),
                          ),
                          if (referencePath != null)
                            IgnorePointer(
                              child: Image.file(
                                File(referencePath),
                                key: ValueKey(
                                  'draw-reference-image-$referencePath',
                                ),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // 캐시 정리/권한 변경 등으로 파일이 사라지면
                                  // 화면에서도 사라지지만 hasDrawableContent는 true로 남아
                                  // 빈 캔버스가 공유될 수 있다. 상태를 즉시 정리한다.
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) {
                                      if (controller.referenceImagePath.value ==
                                          referencePath) {
                                        controller.clearReferenceDrawing();
                                      }
                                    },
                                  );
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          CustomPaint(
                            painter: CanvasPainter(
                              strokes: controller.strokes.toList(),
                              bgColor: Colors.transparent,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Top toolbar with slide-down entrance animation
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (ctx, v, child) {
                  return Transform.translate(
                    offset: Offset(0, -60 * (1 - v)),
                    child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                  );
                },
                child: SafeArea(child: _TopToolbar(ctrl: controller)),
              ),
            ),

            // Bottom toolbar with slide-up entrance animation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (ctx, v, child) {
                  return Transform.translate(
                    offset: Offset(0, 60 * (1 - v)),
                    child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                  );
                },
                child: SafeArea(child: _BottomToolbar(ctrl: controller)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Top Toolbar

class _TopToolbar extends StatelessWidget {
  final DoodleController ctrl;
  const _TopToolbar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Obx(() {
        return Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () async {
                _maybeHaptic(settingCtrl);
                final shouldPop = await DrawPage._confirmDiscardIfNeeded(
                  ctrl,
                  settingCtrl,
                );
                if (shouldPop) {
                  ctrl.clearCanvas();
                  Get.back();
                }
              },
              tooltip: 'back'.tr,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.undo2,
                        color: ctrl.canUndo
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed: ctrl.canUndo
                          ? () {
                              if (settingCtrl.hapticEnabled.value) {
                                ctrl.hapticLight();
                              }
                              ctrl.undo();
                            }
                          : null,
                      tooltip: 'undo'.tr,
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.redo2,
                        color: ctrl.canRedo
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed: ctrl.canRedo
                          ? () {
                              _maybeHaptic(settingCtrl);
                              ctrl.redo();
                            }
                          : null,
                      tooltip: 'redo'.tr,
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.paintBucket, color: cs.onSurface),
                      onPressed: () =>
                          _openCanvasColorPicker(context, settingCtrl),
                      tooltip: 'canvas_color'.tr,
                    ),
                    IconButton(
                      icon: Icon(
                        ctrl.referenceImagePath.value != null
                            ? LucideIcons.imageMinus
                            : LucideIcons.imagePlus,
                        color: cs.onSurface,
                      ),
                      onPressed: () async {
                        _maybeHaptic(settingCtrl);
                        if (ctrl.referenceImagePath.value != null) {
                          ctrl.clearReferenceDrawing();
                        } else {
                          await ctrl.pickReferenceImage();
                        }
                      },
                      tooltip: ctrl.referenceImagePath.value != null
                          ? 'remove_image'.tr
                          : 'import_image'.tr,
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.trash2,
                        color: ctrl.hasDrawableContent
                            ? cs.error
                            : cs.error.withValues(alpha: 0.3),
                      ),
                      onPressed: ctrl.hasDrawableContent
                          ? () => _confirmClear(context, cs, settingCtrl)
                          : null,
                      tooltip: 'clear_canvas'.tr,
                    ),
                    // Design Ref: §5.1 — Save 버튼은 Share 좌측에 배치.
                    // Plan FR-01/FR-07: Save 시트로 해상도·포맷 선택 후 갤러리 저장.
                    IconButton(
                      icon: Icon(
                        LucideIcons.download,
                        color: ctrl.hasDrawableContent
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed: ctrl.hasDrawableContent
                          ? () => _openSaveSheet(context, settingCtrl)
                          : null,
                      tooltip: 'save_to_gallery_title'.tr,
                    ),
                    // Plan FR-11: 작품 저장 버튼 — 갤러리 저장과 별개로 in-app 보관.
                    // 저장 진행 중에는 연타로 인한 중복 저장을 막기 위해 비활성화한다.
                    // 이 Row는 상위 Obx 안이라 isSavingArtwork 읽기가 반응형으로 추적된다.
                    IconButton(
                      icon: Icon(
                        LucideIcons.bookmarkPlus,
                        color:
                            (ctrl.hasDrawableContent &&
                                !ctrl.isSavingArtwork.value)
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed:
                          (ctrl.hasDrawableContent &&
                              !ctrl.isSavingArtwork.value)
                          ? () {
                              if (settingCtrl.hapticEnabled.value) {
                                ctrl.hapticMedium();
                              }
                              ctrl.saveAsArtwork();
                            }
                          : null,
                      tooltip: 'artwork_save_action'.tr,
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.share2,
                        color: ctrl.hasDrawableContent
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed: ctrl.hasDrawableContent
                          ? () {
                              if (settingCtrl.hapticEnabled.value) {
                                ctrl.hapticMedium();
                              }
                              ctrl.shareCanvas();
                            }
                          : null,
                      tooltip: 'share'.tr,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _maybeHaptic(SettingController settingCtrl) {
    if (!settingCtrl.hapticEnabled.value) return;
    ctrl.hapticSelection();
  }

  void _openSaveSheet(BuildContext context, SettingController settingCtrl) {
    if (settingCtrl.hapticEnabled.value) {
      ctrl.hapticMedium();
    }
    SaveOptionsSheet.show(
      context: context,
      settingCtrl: settingCtrl,
      onConfirm: (resolution, format) async {
        // 마지막 선택 persist + 갤러리 저장 위임.
        // Plan FR-07: 마지막 선택을 Hive에 저장해 다음 호출 시 prefill.
        await Future.wait<void>([
          settingCtrl.setLastExportResolution(resolution),
          settingCtrl.setLastExportFormat(
            format == ExportImageFormat.jpeg ? 'jpeg' : 'png',
          ),
        ]);
        await ctrl.exportToGallery(
          resolutionMultiplier: resolution,
          format: format,
        );
      },
    );
  }

  void _openCanvasColorPicker(
    BuildContext context,
    SettingController settingCtrl,
  ) {
    if (settingCtrl.hapticEnabled.value) {
      ctrl.hapticSelection();
    }
    final cs = Get.theme.colorScheme;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.paintBucket, size: 18.r, color: cs.primary),
                SizedBox(width: 8.w),
                Text(
                  'canvas_color'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'canvas_color_desc'.tr,
              style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.h),
            Obx(() {
              final current = ctrl.canvasColor.value;
              final presets = DoodleController.canvasColorPresets;
              final isPresetSelected = presets.contains(current);
              final swatches = <Widget>[
                for (final c in presets)
                  _buildCanvasColorSwatch(
                    cs: cs,
                    colorValue: c,
                    selected: current == c,
                    onTap: () {
                      if (settingCtrl.hapticEnabled.value) {
                        ctrl.hapticSelection();
                      }
                      ctrl.setCanvasColor(c);
                      Get.back();
                    },
                  ),
                _buildCanvasCustomSlot(
                  cs: cs,
                  customColor: isPresetSelected ? null : current,
                  selected: !isPresetSelected,
                  onTap: () => _openCanvasCustomColorPicker(
                    context,
                    settingCtrl,
                  ),
                ),
              ];
              return Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: swatches,
              );
            }),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }

  Widget _buildCanvasColorSwatch({
    required ColorScheme cs,
    required int colorValue,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = Color(colorValue);
    final luminance = color.computeLuminance();
    final checkColor = luminance > 0.6 ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(LucideIcons.check, size: 22.r, color: checkColor)
            : null,
      ),
    );
  }

  /// 캔버스 배경에 사용할 커스텀 색상 슬롯.
  /// 현재 캔버스 색상이 프리셋에 없으면 그 색상을 미리보기로 표시한다.
  Widget _buildCanvasCustomSlot({
    required ColorScheme cs,
    required int? customColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final hasCustom = customColor != null;
    final color = hasCustom ? Color(customColor) : cs.surfaceContainerHigh;
    final luminance = color.computeLuminance();
    final fgColor = luminance > 0.6 ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Icon(
          selected ? LucideIcons.check : LucideIcons.plus,
          size: 22.r,
          color: hasCustom ? fgColor : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _openCanvasCustomColorPicker(
    BuildContext context,
    SettingController settingCtrl,
  ) async {
    if (settingCtrl.hapticEnabled.value) {
      ctrl.hapticSelection();
    }
    final cs = Get.theme.colorScheme;
    Color picked = Color(ctrl.canvasColor.value);

    await Get.dialog(
      Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'pick_color'.tr,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              ColorPicker(
                pickerColor: picked,
                onColorChanged: (c) => picked = c,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaHeightPercent: 0.6,
                displayThumbColor: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // 알파 채널은 항상 0xFF 로 강제.
                        // ignore: deprecated_member_use
                        final argb = picked.value | 0xFF000000;
                        ctrl.setCanvasColor(argb);
                        // bottomSheet 도 닫는다 (다이얼로그 -> 시트 순).
                        Get.back();
                        if (Get.isBottomSheetOpen ?? false) Get.back();
                      },
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(
    BuildContext context,
    ColorScheme cs,
    SettingController settingCtrl,
  ) {
    if (!settingCtrl.askBeforeClear.value) {
      ctrl.clearCanvas();
      return;
    }

    Get.dialog(
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
                    'clear_canvas'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'clear_canvas_confirm'.tr,
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
                      onPressed: Get.back,
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
                      onPressed: () {
                        ctrl.clearCanvas();
                        if (settingCtrl.hapticEnabled.value) {
                          ctrl.hapticHeavy();
                        }
                        Get.back();
                      },
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

// Bottom Toolbar

class _BottomToolbar extends StatelessWidget {
  final DoodleController ctrl;
  const _BottomToolbar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _BrushTypeSelector(ctrl: ctrl)),
              _BrushSizeSlider(ctrl: ctrl),
            ],
          ),
          SizedBox(height: 10.h),
          _ColorPalette(ctrl: ctrl),
          SizedBox(height: 4.h),
          // 설정 변경 시 즉시 반영되도록 Obx로 감싼다.
          Obx(
            () => settingCtrl.showBrushGuide.value
                ? Text(
                    'brush_guide_desc'.tr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Brush Type Selector

class _BrushTypeSelector extends StatelessWidget {
  final DoodleController ctrl;
  const _BrushTypeSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: BrushType.values.map((type) {
            final selected = ctrl.brushType.value == type;
            final isEraser = type == BrushType.eraser;
            final preset = isEraser ? null : BrushPresets.of(type);
            final isLocked = !isEraser && !ctrl.isBrushUnlocked(type);

            final IconData icon = isEraser ? LucideIcons.eraser : preset!.icon;

            // 선택된 도구는 primary 배경 + onPrimary 아이콘으로 충분한 대비 확보.
            final Color bgColor;
            final Color iconColor;
            if (selected) {
              bgColor = cs.primary;
              iconColor = cs.onPrimary;
            } else if (isLocked) {
              bgColor = cs.surfaceContainerLow;
              iconColor = cs.onSurface.withValues(alpha: 0.35);
            } else {
              bgColor = cs.surfaceContainerHigh;
              iconColor = cs.onSurfaceVariant;
            }

            return GestureDetector(
              onTap: () {
                if (settingCtrl.hapticEnabled.value) {
                  ctrl.hapticSelection();
                }
                if (isLocked) {
                  ctrl.unlockBrush(type);
                } else {
                  ctrl.brushType.value = type;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 6.w),
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 20.r, color: iconColor),
                    if (isLocked)
                      Positioned(
                        right: 4.r,
                        bottom: 4.r,
                        child: Icon(
                          LucideIcons.lock,
                          size: 10.r,
                          color: cs.tertiary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

// Brush Size Slider

class _BrushSizeSlider extends StatelessWidget {
  final DoodleController ctrl;
  const _BrushSizeSlider({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      final brushT = ctrl.brushType.value;
      final isEraser = brushT == BrushType.eraser;
      final minSize = isEraser ? 10.0 : 2.0;
      final maxSize = isEraser ? 60.0 : 30.0;
      final size = ctrl.brushSize.value.clamp(minSize, maxSize);
      // Sync the observable if it was clamped (e.g. switching eraser -> pen)
      if (size != ctrl.brushSize.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctrl.brushSize.value = size;
        });
      }
      final dotSize = (size * 0.6).clamp(4.0, 24.0);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live preview dot — 현재 선택된 색상을 시각적으로 보여준다.
          SizedBox(
            width: 32.r,
            height: 32.r,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: dotSize.r,
                height: dotSize.r,
                decoration: BoxDecoration(
                  color: isEraser ? cs.outline : Color(ctrl.brushColor.value),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant, width: 1),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
            child: Slider(
              value: size,
              min: minSize,
              max: maxSize,
              onChanged: (v) => ctrl.brushSize.value = v,
            ),
          ),
        ],
      );
    });
  }
}

// Color Palette

class _ColorPalette extends StatelessWidget {
  final DoodleController ctrl;
  const _ColorPalette({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    return Obx(() {
      final brushT = ctrl.brushType.value;
      final isEraser = brushT == BrushType.eraser;

      if (isEraser) {
        return SizedBox(
          height: 40.r,
          child: Center(
            child: Text(
              'eraser_mode'.tr,
              style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      // 팔레트 + 마지막 슬롯(커스텀 컬러 피커).
      final paletteLength = DoodleController.colorPalette.length;
      // +1 = 커스텀 슬롯
      final itemCount = paletteLength + 1;

      return SizedBox(
        height: 40.r,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (ctx, i) {
            // 마지막 슬롯: 커스텀 컬러 피커
            if (i == paletteLength) {
              return _CustomColorSlot(ctrl: ctrl, settingCtrl: settingCtrl);
            }

            final c = DoodleController.colorPalette[i];
            final selected = ctrl.brushColor.value == c;
            return _ColorSwatch(
              colorValue: c,
              selected: selected,
              onTap: () {
                if (settingCtrl.hapticEnabled.value) {
                  ctrl.hapticSelection();
                }
                ctrl.brushColor.value = c;
              },
            );
          },
        ),
      );
    });
  }
}

class _ColorSwatch extends StatelessWidget {
  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final color = Color(colorValue);
    // 흰색 등 밝은 색상에서도 체크 표시가 보이도록 휘도 기반 대비 색상 선택.
    final luminance = color.computeLuminance();
    final checkColor = luminance > 0.6 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 40.r : 32.r,
        height: selected ? 40.r : 32.r,
        margin: EdgeInsets.symmetric(
          horizontal: 3.w,
          vertical: selected ? 0 : 4.r,
        ),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(LucideIcons.check, size: 18.r, color: checkColor)
            : null,
      ),
    );
  }
}

class _CustomColorSlot extends StatelessWidget {
  final DoodleController ctrl;
  final SettingController settingCtrl;

  const _CustomColorSlot({required this.ctrl, required this.settingCtrl});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final custom = ctrl.customColor.value;
    final hasCustom = custom != null;
    // 커스텀 색상이 설정되어 있고 현재 선택과 같으면 "선택됨" 표시.
    final selected = hasCustom && ctrl.brushColor.value == custom;

    final color = hasCustom ? Color(custom) : cs.surfaceContainerHigh;
    final luminance = color.computeLuminance();
    final fgColor = luminance > 0.6 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () => _openPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 40.r : 32.r,
        height: selected ? 40.r : 32.r,
        margin: EdgeInsets.symmetric(
          horizontal: 3.w,
          vertical: selected ? 0 : 4.r,
        ),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Icon(
          selected ? LucideIcons.check : LucideIcons.plus,
          size: 18.r,
          color: hasCustom ? fgColor : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    if (settingCtrl.hapticEnabled.value) {
      ctrl.hapticSelection();
    }
    final cs = Get.theme.colorScheme;
    Color picked = Color(ctrl.customColor.value ?? ctrl.brushColor.value);

    await Get.dialog(
      Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'pick_color'.tr,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              ColorPicker(
                pickerColor: picked,
                onColorChanged: (c) => picked = c,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaHeightPercent: 0.6,
                displayThumbColor: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // 알파 채널은 항상 0xFF 로 강제.
                        // ignore: deprecated_member_use
                        final argb = picked.value | 0xFF000000;
                        ctrl.setCustomColor(argb);
                        Get.back();
                      },
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
