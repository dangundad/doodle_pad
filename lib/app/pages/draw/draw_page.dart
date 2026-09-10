import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';
import 'package:doodle_pad/app/pages/draw/widgets/canvas_painter.dart';
import 'package:doodle_pad/app/pages/draw/widgets/save_options_sheet.dart';
import 'package:doodle_pad/app/pages/gallery/gallery_page.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/export_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

class DrawPage extends GetView<DoodleController> {
  const DrawPage({super.key});

  /// 작업 중 그림이 있을 때 뒤로 나가기를 시도하면 확인 다이얼로그를 표시한다.
  /// 반환값이 true면 호출자가 화면을 닫고, false면 그리기 화면을 유지한다.
  static Future<bool> _confirmDiscardIfNeeded(
    DoodleController ctrl,
    SettingController settingCtrl,
  ) async {
    if (!ctrl.hasDrawableContent) return true;

    final result = await AppConfirmDialog.show(
      icon: LucideIcons.triangleAlert,
      title: 'discard_drawing_title'.tr,
      message: 'discard_drawing_desc'.tr,
      confirmLabel: 'discard'.tr,
      cancelLabel: 'keep_drawing'.tr,
      destructive: true,
      barrierDismissible: false,
      onConfirm: () {
        if (settingCtrl.hapticEnabled.value) ctrl.hapticHeavy();
      },
    );
    return result ?? false;
  }

  /// DrawPage 아래로 돌아갈 라우트가 실제로 남아 있는지.
  ///
  /// `Get.previousRoute`는 시트/다이얼로그를 한 번 띄우면 다시는 비지 않아
  /// "DRAW가 루트인가" 판별에 쓸 수 없다. Navigator에 직접 묻는다.
  static bool _canPopBack(BuildContext context) =>
      Navigator.of(context).canPop();

  /// 상태바 아이콘 밝기를 "캔버스 색"에 맞춘다.
  /// DrawPage에는 AppBar가 없어 직전 화면 스타일이 남는 문제를 막고,
  /// 다크 테마에서도 흰 캔버스 위 시계·배터리가 보이게 한다.
  static SystemUiOverlayStyle _overlayStyleFor({
    required int canvasColorValue,
    required Brightness themeBrightness,
  }) {
    final canvasIsLight = Color(canvasColorValue).computeLuminance() > 0.5;
    final themeIsLight = themeBrightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: canvasIsLight
          ? Brightness.dark
          : Brightness.light,
      statusBarBrightness: canvasIsLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: themeIsLight
          ? Brightness.dark
          : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final themeBrightness = Theme.of(context).brightness;

    return Obx(
      () => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyleFor(
          canvasColorValue: controller.canvasColor.value,
          themeBrightness: themeBrightness,
        ),
        child: _buildScaffold(context, settingCtrl, cs, reduceMotion),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    SettingController settingCtrl,
    ColorScheme cs,
    bool reduceMotion,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPopBack = _canPopBack(context);
        final shouldPop = await _confirmDiscardIfNeeded(
          controller,
          settingCtrl,
        );
        if (!shouldPop) return;
        controller.clearCanvas();
        if (canPopBack) {
          Get.back();
        } else {
          ExitBottomSheet.show();
        }
      },
      child: Scaffold(
        // 캔버스 바깥(줌아웃 시 보이는 영역)은 종이보다 한 단계 어두운 책상색.
        backgroundColor: cs.surfaceContainerHigh,
        body: Stack(
          children: [
            // Full-screen drawing canvas.
            // InteractiveViewer가 outer, RepaintBoundary가 inner라 캡처는
            // logical 캔버스 기준으로 일관된다.
            // 한 손가락 = 그리기, 두 손가락 = 핀치 줌.
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: controller.transformController,
                panEnabled: false,
                scaleEnabled: false,
                minScale: 0.5,
                maxScale: 5.0,
                child: RepaintBoundary(
                  key: controller.canvasKey,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (d) {
                      if (d.pointerCount >= 2) {
                        controller.cancelCurrentStroke();
                        controller.beginPinch(d.localFocalPoint);
                      } else {
                        if (settingCtrl.hapticEnabled.value) {
                          controller.hapticSelection();
                        }
                        controller.startStroke(d.localFocalPoint);
                      }
                    },
                    onScaleUpdate: (d) {
                      if (d.pointerCount >= 2) {
                        if (!controller.isPinching) {
                          controller.cancelCurrentStroke();
                          controller.beginPinch(d.localFocalPoint);
                        }
                        controller.updatePinch(d.scale, d.localFocalPoint);
                      } else {
                        if (controller.isPinching) return;
                        controller.continueStroke(d.localFocalPoint);
                      }
                    },
                    onScaleEnd: (_) {
                      if (controller.isPinching) {
                        controller.endPinch();
                      } else {
                        controller.endStroke();
                      }
                    },
                    onDoubleTap: () {
                      if (settingCtrl.hapticEnabled.value) {
                        controller.hapticSelection();
                      }
                      controller.resetCanvasTransform();
                    },
                    child: Obx(() {
                      final referencePath = controller.referenceImagePath.value;
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
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (controller.referenceImagePath.value ==
                                        referencePath) {
                                      controller.clearReferenceDrawing();
                                    }
                                  });
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
                key: const ValueKey('draw-top-toolbar-entrance'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                builder: (ctx, v, child) {
                  return Transform.translate(
                    offset: Offset(0, -48 * (1 - v)),
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
                key: const ValueKey('draw-bottom-toolbar-entrance'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                builder: (ctx, v, child) {
                  return Transform.translate(
                    offset: Offset(0, 48 * (1 - v)),
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

// ───────────────────────────── Top Toolbar ─────────────────────────────
//
// 한 줄 필. [홈] | [실행취소 재실행] | [보관함 저장 갤러리 공유] | [지우기] [더보기]
// 그룹 사이는 헤어라인 세로선으로만 나눈다. 아이콘 색은 잉크(onSurface) 하나,
// 비활성은 alpha, 파괴적 액션(지우기)만 error.

class _TopToolbar extends StatelessWidget {
  final DoodleController ctrl;
  const _TopToolbar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: _floatingPanel(cs),
      // 기본 IconButton(48dp)로는 9개 액션이 일반 폰 폭을 넘긴다.
      // 밀도를 낮춰 한 화면에 모두 넣고, 320dp에서는 가운데 그룹만 스크롤한다.
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 40),
            fixedSize: const Size(34, 40),
            iconSize: 19.r,
            foregroundColor: cs.onSurface,
            disabledForegroundColor: cs.onSurface.withValues(alpha: 0.28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        child: Obx(() {
          final hasContent = ctrl.hasDrawableContent;
          return Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.house),
                onPressed: () async {
                  _maybeHaptic(settingCtrl);
                  final canPopBack = DrawPage._canPopBack(context);
                  final shouldPop = await DrawPage._confirmDiscardIfNeeded(
                    ctrl,
                    settingCtrl,
                  );
                  if (!shouldPop) return;
                  ctrl.clearCanvas();
                  if (canPopBack) {
                    Get.back();
                  } else {
                    await Get.offAllNamed(Routes.HOME);
                  }
                },
                tooltip: 'home'.tr,
              ),
              _ToolbarDivider(cs: cs),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.undo2),
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
                        icon: const Icon(LucideIcons.redo2),
                        onPressed: ctrl.canRedo
                            ? () {
                                _maybeHaptic(settingCtrl);
                                ctrl.redo();
                              }
                            : null,
                        tooltip: 'redo'.tr,
                      ),
                      _ToolbarDivider(cs: cs),
                      // 보관함은 캔버스를 유지한 채 이동한다 (홈 버튼과 다름).
                      IconButton(
                        icon: const Icon(LucideIcons.images),
                        onPressed: () {
                          _maybeHaptic(settingCtrl);
                          // 보관함이 "돌아갈 DrawPage가 아래에 있다"를 알 수
                          // 있게 인자를 넘긴다. Get.previousRoute 는 다이얼로그를
                          // 한 번 띄우면 오염되므로 판별에 쓰지 않는다.
                          Get.toNamed(
                            Routes.GALLERY,
                            arguments: GalleryPage.fromDrawArguments,
                          );
                        },
                        tooltip: 'gallery_title'.tr,
                      ),
                      // 앱 내 작품 보관 — 저장 진행 중에는 연타 방지로 비활성.
                      IconButton(
                        icon: const Icon(LucideIcons.bookmarkPlus),
                        onPressed: (hasContent && !ctrl.isSavingArtwork.value)
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
                        icon: const Icon(LucideIcons.download),
                        onPressed: hasContent
                            ? () => _openSaveSheet(context, settingCtrl)
                            : null,
                        tooltip: 'save_to_gallery_title'.tr,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.share2),
                        onPressed: hasContent
                            ? () {
                                if (settingCtrl.hapticEnabled.value) {
                                  ctrl.hapticMedium();
                                }
                                ctrl.shareCanvas();
                              }
                            : null,
                        tooltip: 'share'.tr,
                      ),
                      _ToolbarDivider(cs: cs),
                      IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: hasContent
                              ? cs.error
                              : cs.error.withValues(alpha: 0.3),
                        ),
                        onPressed: hasContent
                            ? () => _confirmClear(settingCtrl)
                            : null,
                        tooltip: 'clear_canvas'.tr,
                      ),
                    ],
                  ),
                ),
              ),
              // 더보기는 스크롤 영역 밖에 고정 — 좁은 화면에서도 항상 닿는다.
              IconButton(
                icon: const Icon(LucideIcons.ellipsis),
                onPressed: () {
                  _maybeHaptic(settingCtrl);
                  MoreActionsSheet.show(
                    ctrl: ctrl,
                    settingCtrl: settingCtrl,
                    hasReferenceImage: ctrl.referenceImagePath.value != null,
                    onCanvasColor: () =>
                        _openCanvasColorPicker(context, settingCtrl),
                  );
                },
                tooltip: 'more_actions'.tr,
              ),
            ],
          );
        }),
      ),
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
      AppSheetShell(
        icon: LucideIcons.paintBucket,
        title: 'canvas_color'.tr,
        subtitle: 'canvas_color_desc'.tr,
        scrollable: false,
        child: Obx(() {
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
              onTap: () => _openCanvasCustomColorPicker(context, settingCtrl),
            ),
          ];
          return Wrap(spacing: 12.w, runSpacing: 12.h, children: swatches);
        }),
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
    final checkColor = color.computeLuminance() > 0.6
        ? Colors.black
        : Colors.white;
    final hex = _hexOf(colorValue);
    return Semantics(
      key: ValueKey('canvas-color-$hex'),
      button: true,
      selected: selected,
      label: '${'canvas_color'.tr} #$hex',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(LucideIcons.check, size: 22.r, color: checkColor)
              : null,
        ),
      ),
    );
  }

  /// 캔버스 배경용 커스텀 색상 슬롯. 프리셋에 없는 색이면 미리보기로 표시.
  Widget _buildCanvasCustomSlot({
    required ColorScheme cs,
    required int? customColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final hasCustom = customColor != null;
    final color = hasCustom ? Color(customColor) : cs.surfaceContainerHigh;
    final fgColor = color.computeLuminance() > 0.6
        ? Colors.black
        : Colors.white;
    return Semantics(
      key: const ValueKey('canvas-custom-color'),
      button: true,
      selected: selected,
      label: 'pick_color'.tr,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
            border: Border.all(
              color: selected ? cs.primary : cs.outline,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Icon(
            selected ? LucideIcons.check : LucideIcons.pipette,
            size: 20.r,
            color: hasCustom ? fgColor : cs.onSurfaceVariant,
          ),
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
    final picked = await pickRichColor(
      context: context,
      initial: Color(ctrl.canvasColor.value),
    );
    if (picked == null) return;
    await ctrl.setCanvasColor(picked);
    if (Get.isBottomSheetOpen ?? false) Get.back<void>();
  }

  void _confirmClear(SettingController settingCtrl) {
    if (!settingCtrl.askBeforeClear.value) {
      ctrl.clearCanvas();
      return;
    }
    AppConfirmDialog.show(
      icon: LucideIcons.trash2,
      title: 'clear_canvas'.tr,
      message: 'clear_canvas_confirm'.tr,
      confirmLabel: 'clear'.tr,
      cancelLabel: 'cancel'.tr,
      destructive: true,
      onConfirm: () {
        ctrl.clearCanvas();
        if (settingCtrl.hapticEnabled.value) ctrl.hapticHeavy();
      },
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      color: cs.outlineVariant,
    );
  }
}

/// 캔버스 위에 떠 있는 패널 공통 장식 — 종이색 + 헤어라인 + 아주 옅은 그림자.
BoxDecoration _floatingPanel(ColorScheme cs, {double radius = 16}) {
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(radius.r),
    border: Border.all(color: cs.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: cs.shadow.withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ─────────────────────────── Bottom Toolbar ────────────────────────────
//
// 3단: [브러시 퀵] · [굵기] · [색상 퀵]. 각 행은 Expanded 슬롯을 균등 분배해
// 320dp에서도 스크롤 없이 44dp 터치 타깃을 유지한다. 전체 목록은 "+" 슬롯이
// 여는 시트에서 고른다.

class _BottomToolbar extends StatelessWidget {
  final DoodleController ctrl;
  const _BottomToolbar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
      decoration: _floatingPanel(cs, radius: AppTheme.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrushQuickRow(ctrl: ctrl),
          SizedBox(height: 2.h),
          _BrushSizeRow(ctrl: ctrl),
          SizedBox(height: 2.h),
          _ColorQuickRow(ctrl: ctrl),
          Obx(
            () => settingCtrl.showBrushGuide.value
                ? Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'brush_guide_desc'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// 1행 — 최근 사용 브러시 + 항상 고정되는 지우개 + 전체 목록 열기.
class _BrushQuickRow extends StatelessWidget {
  final DoodleController ctrl;
  const _BrushQuickRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    return Obx(() {
      final selected = ctrl.brushType.value;
      return Row(
        children: [
          for (final type in ctrl.recentBrushes)
            Expanded(
              child: _BrushSlot(
                ctrl: ctrl,
                settingCtrl: settingCtrl,
                type: type,
                selected: selected == type,
              ),
            ),
          Expanded(
            child: _BrushSlot(
              ctrl: ctrl,
              settingCtrl: settingCtrl,
              type: BrushType.eraser,
              selected: selected == BrushType.eraser,
            ),
          ),
          Expanded(
            child: _MoreSlot(
              slotKey: const ValueKey('draw-brush-more'),
              label: 'brush_all_title'.tr,
              onTap: () {
                if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
                BrushSheet.show(ctrl, settingCtrl);
              },
            ),
          ),
        ],
      );
    });
  }
}

class _BrushSlot extends StatelessWidget {
  const _BrushSlot({
    required this.ctrl,
    required this.settingCtrl,
    required this.type,
    required this.selected,
  });

  final DoodleController ctrl;
  final SettingController settingCtrl;
  final BrushType type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final isEraser = type == BrushType.eraser;
    final preset = isEraser ? null : BrushPresets.of(type);
    final locked = !isEraser && !ctrl.isBrushUnlocked(type);
    final label = isEraser ? 'feature_eraser'.tr : preset!.labelKey.tr;

    void handleTap() {
      if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
      if (locked) {
        ctrl.unlockBrush(type);
      } else {
        ctrl.useBrush(type);
      }
    }

    return Semantics(
      key: ValueKey('draw-brush-${type.name}'),
      button: true,
      selected: selected,
      label: label,
      hint: locked ? 'brush_unlock_message'.tr : null,
      onTap: handleTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: handleTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: _BrushGlyph(
              icon: isEraser ? LucideIcons.eraser : preset!.icon,
              selected: selected,
              locked: locked,
              size: 38,
              cs: cs,
            ),
          ),
        ),
      ),
    );
  }
}

/// 브러시 아이콘 타일. 퀵 행과 전체 시트가 같은 모양을 공유한다.
/// 선택 = 잉크 블루 채움. 잠금 = 흐린 아이콘 + 자물쇠. 나머지는 투명 배경.
class _BrushGlyph extends StatelessWidget {
  const _BrushGlyph({
    required this.icon,
    required this.selected,
    required this.locked,
    required this.size,
    required this.cs,
  });

  final IconData icon;
  final bool selected;
  final bool locked;
  final double size;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (selected) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (locked) {
      bg = cs.surfaceContainerLow;
      fg = cs.onSurface.withValues(alpha: 0.5);
    } else {
      bg = cs.surfaceContainerHigh;
      fg = cs.onSurface;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size * 0.5, color: fg),
          if (locked)
            PositionedDirectional(
              end: 3,
              bottom: 3,
              child: Icon(LucideIcons.lock, size: 9.r, color: cs.secondary),
            ),
        ],
      ),
    );
  }
}

/// 2행 — 굵기. [미리보기 점] [슬라이더] [수치].
/// 미리보기는 브러시 배율·농도를 반영해 "실제로 그어질 굵기"를 보여준다.
class _BrushSizeRow extends StatelessWidget {
  final DoodleController ctrl;
  const _BrushSizeRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      final isEraser = ctrl.brushType.value == BrushType.eraser;
      final minSize = isEraser ? 10.0 : 2.0;
      final maxSize = isEraser ? 60.0 : 30.0;
      final size = ctrl.brushSize.value.clamp(minSize, maxSize);
      if (size != ctrl.brushSize.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctrl.brushSize.value = size;
        });
      }
      final preset = isEraser
          ? null
          : BrushPresets.maybeOf(ctrl.brushType.value);
      final effectiveSize = isEraser
          ? size * 4.0
          : size * (preset?.sizeMultiplier ?? 1.0);
      final dotSize = (effectiveSize * 0.55).clamp(5.0, 22.0);

      return SizedBox(
        height: 36,
        child: Row(
          children: [
            SizedBox(
              width: 30.r,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: dotSize.r,
                  height: dotSize.r,
                  decoration: BoxDecoration(
                    color: isEraser
                        ? cs.surfaceContainerHighest
                        : Color(
                            ctrl.brushColor.value,
                          ).withValues(alpha: preset?.alpha ?? 1.0),
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outline),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                label: 'brush_size'.tr,
                child: Slider(
                  value: size,
                  min: minSize,
                  max: maxSize,
                  onChanged: (v) => ctrl.brushSize.value = v,
                ),
              ),
            ),
            SizedBox(
              width: 30.r,
              child: Text(
                size.round().toString(),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// 3행 — 최근 사용 색상 + 전체 팔레트 열기.
class _ColorQuickRow extends StatelessWidget {
  final DoodleController ctrl;
  const _ColorQuickRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final settingCtrl = SettingController.to;
    final cs = Get.theme.colorScheme;
    return Obx(() {
      // 지우개는 색상 개념이 없으므로 같은 높이의 안내로 대체해 레이아웃 점프를 막는다.
      if (ctrl.brushType.value == BrushType.eraser) {
        return SizedBox(
          height: 44,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.eraser,
                  size: 14.r,
                  color: cs.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'eraser_mode'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
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

      final current = ctrl.brushColor.value;
      return Row(
        children: [
          for (final color in ctrl.recentColors)
            Expanded(
              child: _ColorSlot(
                colorValue: color,
                selected: current == color,
                onTap: () {
                  if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
                  ctrl.useColor(color);
                },
              ),
            ),
          Expanded(
            child: _MoreSlot(
              slotKey: const ValueKey('draw-color-more'),
              label: 'pick_color'.tr,
              circular: true,
              onTap: () {
                if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
                ColorSheet.show(ctrl, settingCtrl);
              },
            ),
          ),
        ],
      );
    });
  }
}

class _ColorSlot extends StatelessWidget {
  const _ColorSlot({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final hex = _hexOf(colorValue);
    return Semantics(
      key: ValueKey('draw-color-$hex'),
      button: true,
      selected: selected,
      label: '${'pick_color'.tr} #$hex',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: _ColorDot(
              colorValue: colorValue,
              selected: selected,
              cs: cs,
            ),
          ),
        ),
      ),
    );
  }
}

/// 색상 원. 선택 시 바깥에 잉크색 링을 두른다 (색 자체는 가리지 않는다).
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.colorValue,
    required this.selected,
    required this.cs,
    this.baseSize = 28,
  });

  final int colorValue;
  final bool selected;
  final ColorScheme cs;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final ringSize = baseSize + 8;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: ringSize,
      height: ringSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant),
        ),
      ),
    );
  }
}

/// 전체 목록을 여는 "+" 슬롯. 선택 항목과 구분되도록 중립 배경 + 점선 느낌의 외곽선.
class _MoreSlot extends StatelessWidget {
  const _MoreSlot({
    required this.slotKey,
    required this.label,
    required this.onTap,
    this.circular = false,
  });

  final Key slotKey;
  final String label;
  final VoidCallback onTap;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    final size = circular ? 28.0 : 38.0;
    return Semantics(
      key: slotKey,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: cs.surface,
                shape: circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circular
                    ? null
                    : BorderRadius.circular(AppTheme.radiusSm.r),
                border: Border.all(color: cs.outline, width: 1.2),
              ),
              child: Icon(
                LucideIcons.plus,
                size: circular ? 15.r : 18.r,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _hexOf(int colorValue) => colorValue
    .toUnsigned(32)
    .toRadixString(16)
    .padLeft(8, '0')
    .substring(2)
    .toUpperCase();

// ───────────────────────────────── Sheets ──────────────────────────────

/// 상단 툴바 더보기 시트 — 캔버스 배경색 / 참조 사진.
class MoreActionsSheet {
  const MoreActionsSheet._();

  static Future<void> show({
    required DoodleController ctrl,
    required SettingController settingCtrl,
    required bool hasReferenceImage,
    required VoidCallback onCanvasColor,
  }) {
    return Get.bottomSheet<void>(
      AppSheetShell(
        title: 'more_actions'.tr,
        child: AppPanel(
          color: Get.theme.colorScheme.surfaceContainerLow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppListRow(
                key: const ValueKey('draw-more-canvas-color'),
                icon: LucideIcons.paintBucket,
                title: 'canvas_color'.tr,
                subtitle: 'canvas_color_desc'.tr,
                trailing: const DirectionalChevron(),
                onTap: () {
                  Get.back<void>();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => onCanvasColor(),
                  );
                },
              ),
              const Divider(height: 1),
              AppListRow(
                key: const ValueKey('draw-more-reference-image'),
                icon: hasReferenceImage
                    ? LucideIcons.imageMinus
                    : LucideIcons.imagePlus,
                title: hasReferenceImage
                    ? 'remove_image'.tr
                    : 'import_image'.tr,
                trailing: const DirectionalChevron(),
                onTap: () {
                  if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
                  Get.back<void>();
                  if (hasReferenceImage) {
                    ctrl.clearReferenceDrawing();
                  } else {
                    ctrl.pickReferenceImage();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// 전체 브러시 시트.
class BrushSheet {
  const BrushSheet._();

  static Future<void> show(
    DoodleController ctrl,
    SettingController settingCtrl,
  ) {
    final cs = Get.theme.colorScheme;
    // 시트는 선택 즉시 닫히므로 열리는 시점의 상태를 캡처해 정적으로 그린다.
    final selected = ctrl.brushType.value;
    return Get.bottomSheet<void>(
      AppSheetShell(
        icon: LucideIcons.paintbrush,
        title: 'brush_all_title'.tr,
        child: Builder(
          builder: (context) {
            final tiles = <Widget>[
              for (final preset in BrushPresets.values)
                _SheetBrushTile(
                  ctrl: ctrl,
                  settingCtrl: settingCtrl,
                  type: preset.type,
                  icon: preset.icon,
                  label: preset.labelKey.tr,
                  selected: selected == preset.type,
                  cs: cs,
                ),
              _SheetBrushTile(
                ctrl: ctrl,
                settingCtrl: settingCtrl,
                type: BrushType.eraser,
                icon: LucideIcons.eraser,
                label: 'feature_eraser'.tr,
                selected: selected == BrushType.eraser,
                cs: cs,
              ),
            ];
            return Wrap(spacing: 8.w, runSpacing: 12.h, children: tiles);
          },
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _SheetBrushTile extends StatelessWidget {
  const _SheetBrushTile({
    required this.ctrl,
    required this.settingCtrl,
    required this.type,
    required this.icon,
    required this.label,
    required this.selected,
    required this.cs,
  });

  final DoodleController ctrl;
  final SettingController settingCtrl;
  final BrushType type;
  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final locked = type != BrushType.eraser && !ctrl.isBrushUnlocked(type);

    void handleTap() {
      if (settingCtrl.hapticEnabled.value) ctrl.hapticSelection();
      Get.back<void>();
      if (locked) {
        ctrl.unlockBrush(type);
      } else {
        ctrl.useBrush(type);
      }
    }

    return Semantics(
      key: ValueKey('draw-sheet-brush-${type.name}'),
      button: true,
      selected: selected,
      label: label,
      hint: locked ? 'brush_unlock_message'.tr : null,
      onTap: handleTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: handleTap,
        child: SizedBox(
          width: 60.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrushGlyph(
                icon: icon,
                selected: selected,
                locked: locked,
                size: 46,
                cs: cs,
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  height: 1.15,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전체 색상 시트 — 16색 팔레트 + 커스텀 피커.
class ColorSheet {
  const ColorSheet._();

  static Future<void> show(
    DoodleController ctrl,
    SettingController settingCtrl,
  ) {
    final cs = Get.theme.colorScheme;
    final current = ctrl.brushColor.value;
    final custom = ctrl.customColor.value;
    return Get.bottomSheet<void>(
      AppSheetShell(
        icon: LucideIcons.palette,
        title: 'pick_color'.tr,
        child: Builder(
          builder: (context) {
            return Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final color in DoodleController.colorPalette)
                  _SheetColorTile(
                    colorValue: color,
                    selected: current == color,
                    cs: cs,
                    onTap: () {
                      if (settingCtrl.hapticEnabled.value) {
                        ctrl.hapticSelection();
                      }
                      ctrl.useColor(color);
                      Get.back<void>();
                    },
                  ),
                Semantics(
                  key: const ValueKey('draw-sheet-custom-color'),
                  button: true,
                  selected: custom != null && current == custom,
                  label: 'pick_color'.tr,
                  onTap: () =>
                      _openBrushColorPicker(ctrl, settingCtrl, context),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: () =>
                        _openBrushColorPicker(ctrl, settingCtrl, context),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: custom != null ? Color(custom) : cs.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.outline, width: 1.2),
                          ),
                          child: Icon(
                            LucideIcons.pipette,
                            size: 15.r,
                            color: custom != null
                                ? (Color(custom).computeLuminance() > 0.6
                                      ? Colors.black
                                      : Colors.white)
                                : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _SheetColorTile extends StatelessWidget {
  const _SheetColorTile({
    required this.colorValue,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hex = _hexOf(colorValue);
    return Semantics(
      key: ValueKey('draw-sheet-color-$hex'),
      button: true,
      selected: selected,
      label: '${'pick_color'.tr} #$hex',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _ColorDot(
              colorValue: colorValue,
              selected: selected,
              cs: cs,
              baseSize: 30,
            ),
          ),
        ),
      ),
    );
  }
}

/// 브러시 색상용 리치 컬러 피커. 확정 시 색상 시트도 함께 닫는다.
Future<void> _openBrushColorPicker(
  DoodleController ctrl,
  SettingController settingCtrl,
  BuildContext context,
) async {
  if (settingCtrl.hapticEnabled.value) {
    ctrl.hapticSelection();
  }
  final picked = await pickRichColor(
    context: context,
    initial: Color(ctrl.brushColor.value),
    recentColors: ctrl.recentColors.map(Color.new).toList(),
  );
  if (picked == null) return;
  await ctrl.setCustomColor(picked);
  if (Get.isBottomSheetOpen ?? false) Get.back<void>();
}

/// 앱 공통 리치 컬러 피커.
/// 취소하면 null, 확정하면 불투명(alpha 0xFF) 색상을 돌려준다.
Future<int?> pickRichColor({
  required BuildContext context,
  required Color initial,
  List<Color> recentColors = const <Color>[],
}) async {
  final cs = Get.theme.colorScheme;
  Color picked = initial;

  final confirmed =
      await ColorPicker(
        color: initial,
        onColorChanged: (color) => picked = color,
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.primary: true,
          ColorPickerType.accent: true,
          ColorPickerType.bw: true,
          ColorPickerType.wheel: true,
        },
        enableShadesSelection: true,
        enableOpacity: false,
        showRecentColors: recentColors.isNotEmpty,
        maxRecentColors: DoodleController.maxRecentColors,
        recentColors: recentColors,
        showColorCode: true,
        colorCodeHasColor: true,
        copyPasteBehavior: const ColorPickerCopyPasteBehavior(
          copyButton: true,
          pasteButton: true,
          longPressMenu: true,
          // 사용자에게는 "#RRGGBB"만 보여준다. Dart 형식(0xAARRGGBB)은 좁은
          // 입력칸에서 잘리고 알파 접두어가 혼란을 준다.
          copyFormat: ColorPickerCopyFormat.numHexRRGGBB,
        ),
        heading: Text(
          'pick_color'.tr,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
        ),
        subheading: Text(
          'color_shades'.tr,
          style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
        ),
        wheelSubheading: Text(
          'color_shades'.tr,
          style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
        ),
        recentColorsSubheading: Text(
          'color_recent'.tr,
          style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
        ),
        pickerTypeLabels: <ColorPickerType, String>{
          ColorPickerType.primary: 'color_type_primary'.tr,
          ColorPickerType.accent: 'color_type_accent'.tr,
          ColorPickerType.bw: 'color_type_bw'.tr,
          ColorPickerType.wheel: 'color_wheel'.tr,
        },
        width: 34,
        height: 34,
        borderRadius: 17,
        spacing: 4,
        runSpacing: 4,
        wheelDiameter: 190,
        actionButtons: const ColorPickerActionButtons(
          dialogActionButtons: true,
          dialogActionOnlyOkButton: false,
        ),
      ).showPickerDialog(
        context,
        backgroundColor: cs.surface,
        constraints: const BoxConstraints(
          minHeight: 480,
          minWidth: 300,
          maxWidth: 340,
        ),
      );

  if (!confirmed) return null;
  return picked.toARGB32() | 0xFF000000;
}
