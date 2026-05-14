import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_preset.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/mixins/shake_detector_mixin.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';
import 'package:doodle_pad/app/services/export_service.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/utils/app_toast.dart';
import 'package:doodle_pad/app/utils/share_file_cleanup.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vibration/vibration.dart';

enum BrushType {
  pen,
  pencil,
  marker,
  brush,
  highlighter,
  fountainPen,
  crayon,
  watercolor,
  airbrush,
  eraser,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final StrokeCap cap;
  final BrushType brushType;

  /// Fixed seed for the airbrush Random, so the spray pattern is stable
  /// across repaints (avoids flickering when other strokes are updated).
  final int seed;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
    this.cap = StrokeCap.round,
    this.brushType = BrushType.pen,
    int? seed,
  }) : seed = seed ?? DateTime.now().microsecondsSinceEpoch;
}

class DoodleController extends GetxController with ShakeDetectorMixin {
  static DoodleController get to => Get.find();

  static const _maxUndo = 20;

  // Drawing state
  final strokes = <DrawingStroke>[].obs;
  DrawingStroke? _currentStroke;
  final _undoStack = <DrawingStroke>[];

  // Brush settings
  final brushType = BrushType.pen.obs;
  final brushColor = 0xFF000000.obs;
  final brushSize = 6.0.obs;

  /// 사용자가 컬러 피커로 선택한 마지막 커스텀 색상.
  /// null 이면 팔레트 마지막 슬롯이 "+" 추가 버튼으로 표시된다.
  final customColor = Rxn<int>();

  /// 컬러 피커에서 색상이 선택되면 호출.
  Future<void> setCustomColor(int colorValue) async {
    customColor.value = colorValue;
    brushColor.value = colorValue;
    await HiveService.to.setSetting(_customColorKey, colorValue);
  }

  /// 캔버스 배경 색상 (기본: 흰색). 공유 시에도 이 색이 그대로 캡처된다.
  final canvasColor = 0xFFFFFFFF.obs;

  /// 캔버스 배경 프리셋 (6개).
  static const canvasColorPresets = [
    0xFFFFFFFF, // white
    0xFFFDF6E3, // cream
    0xFFF1F1F1, // light gray
    0xFFE3F2FD, // light blue
    0xFFFFF9C4, // light yellow
    0xFF1A1A1A, // dark
  ];

  Future<void> setCanvasColor(int colorValue) async {
    canvasColor.value = colorValue;
    await HiveService.to.setSetting(_canvasColorKey, colorValue);
  }

  /// 드로잉 사용자 선호값(캔버스/커스텀 색상)만 기본값으로 되돌린다.
  /// 보상형 광고로 해금한 브러시 상태와 프리미엄 구매 상태는 유지한다.
  Future<void> resetDrawingPreferences() async {
    canvasColor.value = defaultCanvasColor;
    customColor.value = null;
    final box = HiveService.to.settingsBox;
    await box.delete(_canvasColorKey);
    await box.delete(_customColorKey);
  }

  // Reference image (used by share preview overlay only).
  final referenceImagePath = RxnString();

  // Special brush unlock state
  static const _watercolorUnlockedKey = 'watercolor_unlocked';
  static const _airbrushUnlockedKey = 'airbrush_unlocked';
  final isWatercolorUnlocked = false.obs;
  final isAirbrushUnlocked = false.obs;

  // 캔버스/커스텀 색상 영속화 키
  // (clearAppSettings 등 외부 초기화 코드가 참조할 수 있도록 public 노출.)
  static const canvasColorKey = 'canvas_color';
  static const customColorKey = 'custom_color';
  static const _canvasColorKey = canvasColorKey;
  static const _customColorKey = customColorKey;

  static const int defaultCanvasColor = 0xFFFFFFFF;

  // Color palette (16 colors)
  static const colorPalette = [
    0xFF000000, // black
    0xFF424242, // dark grey
    0xFF9E9E9E, // grey
    0xFFFFFFFF, // white
    0xFFF44336, // red
    0xFFFF5722, // deep orange
    0xFFFF9800, // orange
    0xFFFFEB3B, // yellow
    0xFF4CAF50, // green
    0xFF009688, // teal
    0xFF2196F3, // blue
    0xFF9C27B0, // purple
    0xFFE91E63, // pink
    0xFF795548, // brown
    0xFF00BCD4, // cyan
    0xFF8BC34A, // light green
  ];

  // Canvas RepaintBoundary key
  final canvasKey = GlobalKey();

  /// Design Ref: §2.2 — InteractiveViewer 줌·팬 상태.
  /// RepaintBoundary는 InteractiveViewer의 child 안쪽에 두므로 캡처는 logical 좌표 그대로.
  final transformController = TransformationController();

  /// 더블탭으로 줌 리셋. 위젯에서 애니메이션을 입혀 호출한다.
  void resetCanvasTransform() {
    transformController.value = Matrix4.identity();
  }

  @override
  void onClose() {
    transformController.dispose();
    super.onClose();
  }

  bool _hasVibrator = false;

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;
  bool get hasPremiumBrushAccess => PurchaseService.isPremiumActive;

  /// 저장/공유가 가능한 컨텐츠가 있는지 여부.
  /// 사용자가 새 stroke를 그렸거나, 갤러리에서 불러온 참조 이미지가 있는 경우 true.
  bool get hasDrawableContent =>
      strokes.isNotEmpty || referenceImagePath.value != null;

  /// 캔버스 캡처 시 사용할 pixel ratio 상한.
  /// 가로 X 세로 X ratio^2 픽셀 수가 이 값을 넘지 않도록 동적으로 낮춘다.
  static const _maxCapturePixels = 8 * 1000 * 1000; // ~8MP
  static const _maxCapturePixelRatio = 3.0;

  @override
  void onInit() {
    super.onInit();
    Vibration.hasVibrator().then((v) => _hasVibrator = v);
    _loadBrushUnlockState();
    _bindShakeToClearSetting();
  }

  /// Design Ref: §2.2 — SettingController.shakeToClearEnabled 변경에 반응해
  /// 가속도계 구독을 켜고 끈다. SettingController 미등록 시 조용히 패스.
  void _bindShakeToClearSetting() {
    if (!Get.isRegistered<SettingController>()) return;
    final settings = SettingController.to;
    if (settings.shakeToClearEnabled.value) {
      enableShakeDetection(_handleShake);
    }
    ever<bool>(settings.shakeToClearEnabled, (enabled) {
      if (enabled) {
        enableShakeDetection(_handleShake);
      } else {
        disableShakeDetection();
      }
    });
  }

  /// 흔들림 감지 콜백.
  /// Plan FR-06: 직접 clear 금지 — 항상 확인 다이얼로그를 거친다.
  void _handleShake() {
    if (!hasDrawableContent) return;
    confirmClearViaShake();
  }

  /// Plan FR-06 — Shake 트리거용 확인 다이얼로그.
  /// _confirmClear와 같은 모양의 다이얼로그를 컨트롤러에서 띄운다.
  /// 이미 다른 dialog/sheet가 떠 있으면 중복 호출을 막는다.
  Future<void> confirmClearViaShake() async {
    if (Get.isDialogOpen ?? false) return;
    if (Get.isBottomSheetOpen ?? false) return;
    if (!hasDrawableContent) return;

    final cs = Get.theme.colorScheme;
    final settings = Get.isRegistered<SettingController>()
        ? SettingController.to
        : null;

    if (settings != null && !settings.askBeforeClear.value) {
      // 사용자가 확인 다이얼로그를 끈 상태라도 Shake로 인한 손실은 방지.
      // 명시적으로 한 번 더 확인을 띄운다.
    }

    await Get.dialog<void>(
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
                    'shake_to_clear_title'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
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
                        clearCanvas();
                        if (settings?.hapticEnabled.value ?? false) {
                          hapticHeavy();
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
      barrierDismissible: true,
    );
  }

  void hapticSelection() {
    if (_hasVibrator) Vibration.vibrate(duration: 30);
  }

  void hapticLight() {
    if (_hasVibrator) Vibration.vibrate(duration: 50);
  }

  void hapticMedium() {
    if (_hasVibrator) Vibration.vibrate(duration: 100);
  }

  void hapticHeavy() {
    if (_hasVibrator) Vibration.vibrate(duration: 200);
  }

  void _loadBrushUnlockState() {
    final hive = HiveService.to;
    isWatercolorUnlocked.value =
        hive.getSetting<bool>(_watercolorUnlockedKey) ?? false;
    isAirbrushUnlocked.value =
        hive.getSetting<bool>(_airbrushUnlockedKey) ?? false;

    final savedCanvas = hive.getSetting<int>(_canvasColorKey);
    if (savedCanvas != null) canvasColor.value = savedCanvas;
    final savedCustom = hive.getSetting<int>(_customColorKey);
    if (savedCustom != null) customColor.value = savedCustom;
  }

  void startStroke(Offset point) {
    // If a stroke was already in progress (multi-touch or interrupted gesture),
    // remove the dangling incomplete stroke from the list before starting fresh.
    if (_currentStroke != null) {
      strokes.remove(_currentStroke);
      _currentStroke = null;
    }

    final type = brushType.value;
    final isEraser = type == BrushType.eraser;

    // Clear redo stack only when the user intentionally starts a new stroke.
    _undoStack.clear();

    // BrushPreset이 brush별 size multiplier/cap을 책임지므로 여기서는
    // 사용자 슬라이더 값(brushSize.value)을 그대로 baseSize로 저장한다.
    // eraser만 BrushPreset 등록 대상이 아니라서 기존 4배율을 유지.
    final baseWidth = isEraser ? brushSize.value * 4.0 : brushSize.value;

    _currentStroke = DrawingStroke(
      points: [point],
      color: isEraser ? Colors.transparent : Color(brushColor.value),
      width: baseWidth,
      isEraser: isEraser,
      cap: StrokeCap.round,
      brushType: type,
    );
    strokes.add(_currentStroke!);
  }

  /// 잠금 카테고리(watercolor/airbrush)별 현재 unlock 상태.
  bool _isLockUnlocked(BrushLock lock) {
    switch (lock) {
      case BrushLock.none:
        return true;
      case BrushLock.watercolor:
        return isWatercolorUnlocked.value;
      case BrushLock.airbrush:
        return isAirbrushUnlocked.value;
    }
  }

  /// 보상형 광고 시청 후 호출되는 unlock 적용 + Hive 영속화.
  Future<void> _persistUnlock(BrushLock lock) async {
    switch (lock) {
      case BrushLock.none:
        return;
      case BrushLock.watercolor:
        isWatercolorUnlocked.value = true;
        await HiveService.to.setSetting(_watercolorUnlockedKey, true);
        break;
      case BrushLock.airbrush:
        isAirbrushUnlocked.value = true;
        await HiveService.to.setSetting(_airbrushUnlockedKey, true);
        break;
    }
  }

  // Special brush unlock via rewarded ad
  void unlockBrush(BrushType type) {
    final preset = BrushPresets.maybeOf(type);

    // eraser나 등록되지 않은 brush는 잠금 개념 자체가 없다.
    if (preset == null || preset.lock == BrushLock.none) {
      brushType.value = type;
      return;
    }

    if (hasPremiumBrushAccess) {
      brushType.value = type;
      return;
    }

    if (!Get.isRegistered<RewardedAdManager>()) return;

    if (_isLockUnlocked(preset.lock)) {
      brushType.value = type;
      return;
    }

    Get.defaultDialog(
      title: preset.labelKey.tr,
      titleStyle: TextStyle(color: Get.theme.colorScheme.onSurface),
      backgroundColor: Get.theme.colorScheme.surface,
      middleText: 'brush_unlock_message'.tr,
      middleTextStyle: TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
      textConfirm: 'watch_ad'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Get.theme.colorScheme.onPrimary,
      cancelTextColor: Get.theme.colorScheme.onSurface,
      buttonColor: Get.theme.colorScheme.primary,
      onConfirm: () {
        Get.back();
        _watchRewardedAdForBrush(type);
      },
    );
  }

  bool isBrushUnlocked(BrushType type) {
    final preset = BrushPresets.maybeOf(type);
    if (preset == null || preset.lock == BrushLock.none) {
      return true;
    }
    if (hasPremiumBrushAccess) {
      return true;
    }
    return _isLockUnlocked(preset.lock);
  }

  void _watchRewardedAdForBrush(BrushType type) {
    final preset = BrushPresets.maybeOf(type);
    if (preset == null || preset.lock == BrushLock.none) return;

    final adManager = RewardedAdManager.to;
    // 광고가 준비되지 않은 상태에서는 사용자가 누른 결과가 조용히 무시되지 않도록
    // 안내 토스트를 띄우고, 백그라운드 로드만 트리거한다.
    if (!adManager.isAdReady.value) {
      AppToast.show(
        AppToastMessage.info(
          title: 'brush_unlock_pending_title'.tr,
          description: 'brush_unlock_pending_desc'.tr,
        ),
      );
      adManager.loadAd();
      return;
    }
    adManager.showAdIfAvailable(
      onUserEarnedReward: (RewardItem reward) async {
        await _persistUnlock(preset.lock);
        brushType.value = type;
        AppToast.show(
          AppToastMessage.success(
            title: 'brush_unlocked'.tr,
            description: preset.labelKey.tr,
          ),
        );
      },
    );
  }

  // Minimum squared distance between successive points to avoid redundant
  // repaint work for tiny sub-pixel movements.
  static const _minPointDistSq = 4.0; // 2px threshold

  void continueStroke(Offset point) {
    if (_currentStroke == null) return;
    final pts = _currentStroke!.points;
    if (pts.isNotEmpty) {
      final last = pts.last;
      final dx = point.dx - last.dx;
      final dy = point.dy - last.dy;
      if (dx * dx + dy * dy < _minPointDistSq) return;
    }
    pts.add(point);
    strokes.refresh();
  }

  void endStroke() {
    // Remove strokes that have no drawable content (shouldn't happen normally
    // but guards against edge cases like interrupted gestures).
    if (_currentStroke != null && _currentStroke!.points.isEmpty) {
      strokes.remove(_currentStroke);
    }
    _currentStroke = null;
  }

  void undo() {
    if (strokes.isEmpty) return;
    final stroke = strokes.removeLast();
    if (_undoStack.length >= _maxUndo) _undoStack.removeAt(0);
    _undoStack.add(stroke);
  }

  void redo() {
    if (_undoStack.isEmpty) return;
    strokes.add(_undoStack.removeLast());
  }

  void clearCanvas() {
    clearReferenceDrawing();
    clearStrokes();
  }

  void clearStrokes() {
    strokes.clear();
    _undoStack.clear();
  }

  void loadReferenceDrawing(String path) {
    referenceImagePath.value = path;
    clearStrokes();
  }

  void clearReferenceDrawing() {
    referenceImagePath.value = null;
  }

  /// 갤러리에서 사진을 골라 참조 이미지로 설정한다.
  /// Android 13+에서는 시스템 Photo Picker가 권한 없이 동작한다.
  /// 실패 시 토스트로 안내하고 false를 반환.
  Future<bool> pickReferenceImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 4096,
      );
      if (picked == null) return false;
      referenceImagePath.value = picked.path;
      return true;
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'import_image_failed'.tr,
        ),
      );
      return false;
    }
  }

  /// 캔버스를 PNG로 캡처하여 반환.
  /// pixelRatio는 캔버스 크기에 따라 동적으로 낮춰 OOM을 방지한다.
  Future<ui.Image?> _captureCanvas() async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final size = boundary.size;
    final ratio = _resolveCapturePixelRatio(size);
    return boundary.toImage(pixelRatio: ratio);
  }

  double _resolveCapturePixelRatio(Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return _maxCapturePixelRatio;
    final maxRatioByPixelBudget = math.sqrt(_maxCapturePixels / (w * h));
    final ratio = maxRatioByPixelBudget < _maxCapturePixelRatio
        ? maxRatioByPixelBudget
        : _maxCapturePixelRatio;
    // 너무 작아지면 1.0 까지 내림.
    return ratio < 1.0 ? 1.0 : ratio;
  }

  /// 공유 (임시 파일로 저장 후 공유)
  Future<void> shareCanvas() async {
    // 참조 이미지 경로가 캐시 정리/권한 변경 등으로 무효화된 경우,
    // 화면에는 사진이 사라졌지만 상태는 그대로 남아 빈 캔버스가 공유될 수 있다.
    final refPath = referenceImagePath.value;
    if (refPath != null && !await File(refPath).exists()) {
      clearReferenceDrawing();
    }

    if (!hasDrawableContent) {
      AppToast.show(
        AppToastMessage.info(title: 'share'.tr, description: 'canvas_empty'.tr),
      );
      return;
    }

    ui.Image? image;
    File? tmpFile;
    try {
      image = await _captureCanvas();
      if (image == null) {
        // 캔버스가 아직 렌더링되지 않았거나 boundary 를 찾지 못한 경우.
        // 사용자가 아무 반응을 못 느끼는 회귀를 막기 위해 명시적으로 안내.
        AppToast.show(
          AppToastMessage.error(
            title: 'error'.tr,
            description: 'share_error'.tr,
          ),
        );
        return;
      }
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        AppToast.show(
          AppToastMessage.error(
            title: 'error'.tr,
            description: 'share_error'.tr,
          ),
        );
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      await ShareFileCleanup.deleteStaleDoodleShareFiles(dir);
      tmpFile = File(
        '${dir.path}/doodle_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tmpFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(tmpFile.path, mimeType: 'image/png')]),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(title: 'error'.tr, description: 'share_error'.tr),
      );
      // 공유 실패 시에만 임시 파일 정리 (성공 시에는 OS가 관리하므로 삭제하지 않음)
      try {
        if (tmpFile != null && tmpFile.existsSync()) tmpFile.deleteSync();
      } catch (_) {}
    } finally {
      image?.dispose();
    }
  }

  /// 갤러리 저장.
  /// Design Ref: §4.1 — ExportService에 위임, 결과에 따라 toast 분기.
  /// Plan SC (a): 1탭 갤러리 저장 / (d): 해상도·포맷 선택.
  ///
  /// [exportService]는 테스트 주입용. 기본값은 싱글톤.
  Future<ExportResult> exportToGallery({
    required int resolutionMultiplier,
    required ExportImageFormat format,
    ExportService? exportService,
  }) async {
    // shareCanvas와 동일하게 stale ref 정리.
    final refPath = referenceImagePath.value;
    if (refPath != null && !await File(refPath).exists()) {
      clearReferenceDrawing();
    }

    if (!hasDrawableContent) {
      AppToast.show(
        AppToastMessage.info(title: 'save'.tr, description: 'canvas_empty'.tr),
      );
      return const ExportResult.failed(ExportFailure.noContent);
    }

    final service = exportService ?? ExportService.instance;
    final result = await service.saveCanvasToGallery(
      canvasKey: canvasKey,
      resolutionMultiplier: resolutionMultiplier,
      format: format,
    );
    _showExportResultToast(result);
    return result;
  }

  /// Plan FR-08/FR-11 — 현재 캔버스를 작품으로 저장.
  /// canvasKey 캡처(1.0x) → PNG bytes → ArtworkRepository.save 위임.
  /// Design Ref: §4.2 — 외부 IO는 모두 ArtworkRepository로 위임.
  Future<Drawing?> saveAsArtwork({
    String? name,
    ArtworkRepository? repository,
  }) async {
    if (!hasDrawableContent) {
      AppToast.show(
        AppToastMessage.info(
          title: 'artwork_title'.tr,
          description: 'canvas_empty'.tr,
        ),
      );
      return null;
    }

    ui.Image? image;
    Uint8List? bytes;
    Size canvasSize = Size.zero;
    try {
      final boundary =
          canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      canvasSize = boundary?.size ?? Size.zero;
      image = await _captureCanvas();
      if (image == null) {
        AppToast.show(
          AppToastMessage.error(
            title: 'error'.tr,
            description: 'artwork_save_failed'.tr,
          ),
        );
        return null;
      }
      final bd = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = bd?.buffer.asUint8List();
    } finally {
      image?.dispose();
    }

    if (bytes == null || canvasSize == Size.zero) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'artwork_save_failed'.tr,
        ),
      );
      return null;
    }

    final serial = strokes.map(_serializeStroke).toList();
    final id = 'artwork_${DateTime.now().millisecondsSinceEpoch}';
    final repo = repository ?? ArtworkRepository.instance;
    try {
      final saved = await repo.save(
        id: id,
        canvasColor: canvasColor.value,
        canvasLogicalSize: canvasSize,
        referenceImagePath: referenceImagePath.value,
        strokes: serial,
        thumbnailPngBytes: bytes,
        name: name,
      );
      AppToast.show(
        AppToastMessage.success(
          title: 'artwork_title'.tr,
          description: 'artwork_save_success'.tr,
        ),
      );
      return saved;
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'artwork_save_failed'.tr,
        ),
      );
      return null;
    }
  }

  /// 작품을 현재 캔버스로 로드해 편집 가능 상태로 만든다.
  /// Design Ref: §6.2 — viewport 비율 차이는 letterbox 스케일로 흡수.
  void loadArtwork(Drawing drawing, {Size? viewport}) {
    final targetW = viewport?.width ?? drawing.canvasLogicalWidth;
    final targetH = viewport?.height ?? drawing.canvasLogicalHeight;
    final sx = targetW / drawing.canvasLogicalWidth;
    final sy = targetH / drawing.canvasLogicalHeight;
    final scale = sx < sy ? sx : sy;

    clearCanvas();
    canvasColor.value = drawing.canvasColor;
    referenceImagePath.value = drawing.referenceImagePath;
    final restored = drawing.strokes
        .map((s) => _deserializeStroke(s, scale))
        .toList();
    strokes.assignAll(restored);
    transformController.value = Matrix4.identity();
  }

  SerializableStroke _serializeStroke(DrawingStroke s) {
    final flat = <double>[];
    for (final p in s.points) {
      flat.add(p.dx);
      flat.add(p.dy);
    }
    return SerializableStroke(
      colorArgb: s.color.toARGB32(),
      width: s.width,
      isEraser: s.isEraser,
      brushTypeIndex: s.brushType.index,
      seed: s.seed,
      pointsXY: flat,
    );
  }

  DrawingStroke _deserializeStroke(SerializableStroke s, double scale) {
    final pts = <Offset>[];
    for (var i = 0; i + 1 < s.pointsXY.length; i += 2) {
      pts.add(Offset(s.pointsXY[i] * scale, s.pointsXY[i + 1] * scale));
    }
    final idx = s.brushTypeIndex.clamp(0, BrushType.values.length - 1);
    return DrawingStroke(
      points: pts,
      color: Color(s.colorArgb),
      width: s.width * scale,
      isEraser: s.isEraser,
      brushType: BrushType.values[idx],
      seed: s.seed,
    );
  }

  void _showExportResultToast(ExportResult result) {
    if (result.success) {
      AppToast.show(
        AppToastMessage.success(
          title: 'save'.tr,
          description: 'save_success'.tr,
        ),
      );
      return;
    }
    final failure = result.failure;
    if (failure == null) return;
    switch (failure) {
      case ExportFailure.noContent:
        AppToast.show(
          AppToastMessage.info(
            title: 'save'.tr,
            description: 'canvas_empty'.tr,
          ),
        );
      case ExportFailure.permissionDenied:
        AppToast.show(
          AppToastMessage.error(
            title: 'save'.tr,
            description: 'save_permission_denied'.tr,
          ),
        );
      case ExportFailure.encoderError:
      case ExportFailure.ioError:
      case ExportFailure.unexpected:
        AppToast.show(
          AppToastMessage.error(
            title: 'save'.tr,
            description: 'save_failed'.tr,
          ),
        );
    }
  }
}
