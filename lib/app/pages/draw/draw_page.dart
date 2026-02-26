import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/draw/widgets/canvas_painter.dart';

class DrawPage extends GetView<DoodleController> {
  const DrawPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        children: [
          // Full-screen drawing canvas
          Positioned.fill(
            child: RepaintBoundary(
              key: controller.canvasKey,
              child: GestureDetector(
                onPanStart: (d) {
                  if (settingCtrl.hapticEnabled.value) {
                    HapticFeedback.selectionClick();
                  }
                  controller.startStroke(d.localPosition);
                },
                onPanUpdate: (d) => controller.continueStroke(d.localPosition),
                onPanEnd: (_) => controller.endStroke(),
                child: Obx(() {
                  return CustomPaint(
                    painter: CanvasPainter(
                      strokes: controller.strokes,
                      bgColor: Colors.white,
                    ),
                    child: const SizedBox.expand(),
                  );
                }),
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
                  child: Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: child,
                  ),
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
                  child: Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: SafeArea(child: _BottomToolbar(ctrl: controller)),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                _maybeHaptic(settingCtrl);
                Get.back();
              },
              tooltip: 'back'.tr,
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.undo_rounded,
                color: ctrl.canUndo
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.3),
              ),
              onPressed: ctrl.canUndo
                  ? () {
                      if (settingCtrl.hapticEnabled.value) {
                        HapticFeedback.lightImpact();
                      }
                      ctrl.undo();
                    }
                  : null,
              tooltip: 'undo'.tr,
            ),
            IconButton(
              icon: Icon(
                Icons.redo_rounded,
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
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: () => _confirmClear(context, cs, settingCtrl),
              tooltip: 'clear_canvas'.tr,
            ),
            // 저장 버튼
            Obx(() => IconButton(
              icon: ctrl.isSaving.value
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Icon(Icons.save_rounded, color: cs.primary),
              onPressed: ctrl.isSaving.value
                  ? null
                  : () {
                      _maybeHaptic(settingCtrl);
                      ctrl.saveCanvas();
                    },
              tooltip: 'save_canvas'.tr,
            )),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                if (settingCtrl.hapticEnabled.value) {
                  HapticFeedback.mediumImpact();
                }
                ctrl.shareCanvas();
              },
              tooltip: 'share'.tr,
            ),
          ],
        );
      }),
    );
  }

  void _maybeHaptic(SettingController settingCtrl) {
    if (!settingCtrl.hapticEnabled.value) return;
    HapticFeedback.selectionClick();
  }

  void _confirmClear(
    BuildContext context,
    ColorScheme cs,
    SettingController settingCtrl,
  ) {
    if (!settingCtrl.askBeforeClear.value) {
      settingCtrl.logEvent(
        'clear_canvas_direct',
        'draw',
        metadata: {'source': 'toolbar', 'confirm': false},
      );
      ctrl.clearCanvas();
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('clear_canvas'.tr),
        content: Text('clear_canvas_confirm'.tr),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              settingCtrl.logEvent(
                'clear_canvas',
                'draw',
                metadata: {'source': 'toolbar', 'confirm': true},
              );
              ctrl.clearCanvas();
              if (settingCtrl.hapticEnabled.value) {
                HapticFeedback.heavyImpact();
              }
              Get.back();
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text('clear'.tr),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _BrushTypeSelector(ctrl: ctrl),
              const Spacer(),
              _BrushSizeSlider(ctrl: ctrl),
            ],
          ),
          SizedBox(height: 10.h),
          _ColorPalette(ctrl: ctrl),
          SizedBox(height: 4.h),
          if (settingCtrl.showBrushGuide.value)
            Text(
              'brush_guide_desc'.tr,
              style: TextStyle(
                fontSize: 11.sp,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: BrushType.values.map((type) {
            final selected = ctrl.brushType.value == type;
            final isSpecial =
                type == BrushType.watercolor || type == BrushType.airbrush;
            final isLocked = isSpecial &&
                (type == BrushType.watercolor
                    ? !ctrl.isWatercolorUnlocked.value
                    : !ctrl.isAirbrushUnlocked.value);

            return GestureDetector(
              onTap: () {
                if (settingCtrl.hapticEnabled.value) {
                  HapticFeedback.selectionClick();
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
                  color: selected
                      ? cs.primaryContainer
                      : isLocked
                          ? cs.surfaceContainerLow
                          : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: selected
                        ? cs.primary
                        : isSpecial
                            ? cs.tertiary.withValues(alpha: 0.5)
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _brushIcon(type),
                      size: 20.r,
                      color: selected
                          ? cs.primary
                          : isLocked
                              ? cs.onSurface.withValues(alpha: 0.35)
                              : cs.onSurfaceVariant,
                    ),
                    if (isLocked)
                      Positioned(
                        right: 4.r,
                        bottom: 4.r,
                        child: Icon(
                          Icons.lock_rounded,
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

  IconData _brushIcon(BrushType type) {
    switch (type) {
      case BrushType.pen:
        return Icons.edit_rounded;
      case BrushType.marker:
        return Icons.brush_rounded;
      case BrushType.eraser:
        return Icons.auto_fix_normal_rounded;
      case BrushType.watercolor:
        return Icons.water_drop_rounded;
      case BrushType.airbrush:
        return Icons.blur_on_rounded;
    }
  }
}

// Brush Size Slider

class _BrushSizeSlider extends StatelessWidget {
  final DoodleController ctrl;
  const _BrushSizeSlider({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final brushT = ctrl.brushType.value;
      final isEraser = brushT == BrushType.eraser;
      final minSize = isEraser ? 10.0 : 2.0;
      final maxSize = isEraser ? 60.0 : 30.0;
      final size = ctrl.brushSize.value.clamp(minSize, maxSize);
      final dotSize = (size * 0.6).clamp(4.0, 24.0);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live preview dot
          SizedBox(
            width: 32.r,
            height: 32.r,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: dotSize.r,
                height: dotSize.r,
                decoration: BoxDecoration(
                  color: isEraser
                      ? cs.outline
                      : Color(ctrl.brushColor.value),
                  shape: BoxShape.circle,
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
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final brushT = ctrl.brushType.value;
      final isEraser = brushT == BrushType.eraser;
      final isWatercolor = brushT == BrushType.watercolor;
      final isAirbrush = brushT == BrushType.airbrush;

      if (isEraser || isWatercolor || isAirbrush) {
        String modeText;
        if (isEraser) {
          modeText = 'eraser_mode'.tr;
        } else if (isWatercolor) {
          modeText = 'watercolor_mode'.tr;
        } else {
          modeText = 'airbrush_mode'.tr;
        }
        return SizedBox(
          height: 36.r,
          child: Center(
            child: Text(
              modeText,
              style: TextStyle(
                fontSize: 12.sp,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: 36.r,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: DoodleController.colorPalette.length,
          itemBuilder: (ctx, i) {
            final c = DoodleController.colorPalette[i];
            final selected = ctrl.brushColor.value == c;
            return GestureDetector(
              onTap: () {
                if (settingCtrl.hapticEnabled.value) {
                  HapticFeedback.selectionClick();
                }
                ctrl.brushColor.value = c;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 36.r : 30.r,
                height: selected ? 36.r : 30.r,
                margin: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: selected ? 0 : 3.r,
                ),
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Color(c).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
