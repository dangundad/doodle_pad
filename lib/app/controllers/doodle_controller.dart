import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:doodle_pad/app/admob/ads_rewarded.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/utils/app_toast.dart';
import 'package:vibration/vibration.dart';

enum BrushType { pen, marker, eraser, watercolor, airbrush }

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

class DoodleController extends GetxController {
  static DoodleController get to => Get.find();

  static const _maxUndo = 20;
  static const _savedPathsKey = 'saved_drawing_paths';

  // Drawing state
  final strokes = <DrawingStroke>[].obs;
  DrawingStroke? _currentStroke;
  final _undoStack = <DrawingStroke>[];

  // Brush settings
  final brushType = BrushType.pen.obs;
  final brushColor = 0xFF000000.obs;
  final brushSize = 6.0.obs;

  // Gallery state
  final savedDrawings = <String>[].obs;
  final isSaving = false.obs;
  final referenceImagePath = RxnString();

  // Special brush unlock state
  static const _watercolorUnlockedKey = 'watercolor_unlocked';
  static const _airbrushUnlockedKey = 'airbrush_unlocked';
  final isWatercolorUnlocked = false.obs;
  final isAirbrushUnlocked = false.obs;

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

  bool _hasVibrator = false;

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;
  bool get hasPremiumBrushAccess => PurchaseService.isPremiumActive;

  @override
  void onInit() {
    super.onInit();
    Vibration.hasVibrator().then((v) => _hasVibrator = v);
    _loadSavedPaths();
    _loadBrushUnlockState();
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
  }

  void _loadSavedPaths() {
    final hive = HiveService.to;
    final paths = hive.getSetting<List>(_savedPathsKey);
    if (paths != null) {
      // 존재하는 파일만 필터링
      final valid = paths
          .map((e) => e.toString())
          .where((p) => File(p).existsSync())
          .toList();
      savedDrawings.assignAll(valid);
      // 삭제된 파일 제거 후 저장
      if (valid.length != paths.length) {
        hive.setSetting(_savedPathsKey, valid);
      }
    }
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
    final isMarker = type == BrushType.marker;
    final isWatercolor = type == BrushType.watercolor;
    final isAirbrush = type == BrushType.airbrush;

    double widthMultiplier;
    if (isEraser) {
      widthMultiplier = 4.0;
    } else if (isMarker) {
      widthMultiplier = 2.5;
    } else if (isWatercolor) {
      widthMultiplier = 2.0;
    } else if (isAirbrush) {
      widthMultiplier = 1.0;
    } else {
      widthMultiplier = 1.0;
    }

    // Clear redo stack only when the user intentionally starts a new stroke.
    _undoStack.clear();

    _currentStroke = DrawingStroke(
      points: [point],
      color: isEraser ? Colors.transparent : Color(brushColor.value),
      width: brushSize.value * widthMultiplier,
      isEraser: isEraser,
      cap: isMarker ? StrokeCap.square : StrokeCap.round,
      brushType: type,
    );
    strokes.add(_currentStroke!);
  }

  // Special brush unlock via rewarded ad
  void unlockBrush(BrushType type) {
    if (hasPremiumBrushAccess) {
      brushType.value = type;
      return;
    }

    if (!Get.isRegistered<RewardedAdManager>()) return;

    final alreadyUnlocked = type == BrushType.watercolor
        ? isWatercolorUnlocked.value
        : isAirbrushUnlocked.value;
    if (alreadyUnlocked) {
      brushType.value = type;
      return;
    }

    Get.defaultDialog(
      title: type == BrushType.watercolor ? 'watercolor_brush'.tr : 'airbrush_brush'.tr,
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
    if (type != BrushType.watercolor && type != BrushType.airbrush) {
      return true;
    }

    if (hasPremiumBrushAccess) {
      return true;
    }

    return type == BrushType.watercolor
        ? isWatercolorUnlocked.value
        : isAirbrushUnlocked.value;
  }

  void _watchRewardedAdForBrush(BrushType type) {
    RewardedAdManager.to.showAdIfAvailable(
      onUserEarnedReward: (RewardItem reward) {
        if (type == BrushType.watercolor) {
          isWatercolorUnlocked.value = true;
          HiveService.to.setSetting(_watercolorUnlockedKey, true);
        } else if (type == BrushType.airbrush) {
          isAirbrushUnlocked.value = true;
          HiveService.to.setSetting(_airbrushUnlockedKey, true);
        }
        brushType.value = type;
        AppToast.show(
          AppToastMessage.success(
            title: 'brush_unlocked'.tr,
            description: type == BrushType.watercolor
                ? 'watercolor_brush'.tr
                : 'airbrush_brush'.tr,
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

  /// 캔버스를 PNG로 캡처하여 반환
  Future<ui.Image?> _captureCanvas() async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return boundary.toImage(pixelRatio: 3);
  }

  /// 그림을 앱 문서 디렉토리에 PNG로 저장하고 경로 반환
  Future<String?> _savePng({String? suffix}) async {
    final image = await _captureCanvas();
    if (image == null) return null;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final drawingsDir = Directory('${dir.path}/drawings');
    if (!drawingsDir.existsSync()) {
      drawingsDir.createSync(recursive: true);
    }
    final fileName = 'doodle_${suffix ?? DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${drawingsDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// 그림 저장 (갤러리에 추가)
  Future<void> saveCanvas() async {
    if (strokes.isEmpty) {
      AppToast.show(
        AppToastMessage.info(
          title: 'save_canvas'.tr,
          description: 'gallery_empty'.tr,
        ),
      );
      return;
    }

    isSaving.value = true;
    try {
      final path = await _savePng();
      if (path == null) {
        AppToast.show(
          AppToastMessage.error(
            title: 'error'.tr,
            description: 'save_error'.tr,
          ),
        );
        return;
      }

      // 최신 항목이 앞에 오도록 insert
      savedDrawings.insert(0, path);

      // Hive에 경로 목록 저장
      await HiveService.to.setSetting(_savedPathsKey, savedDrawings.toList());

      AppToast.show(
        AppToastMessage.success(
          title: 'save_canvas'.tr,
          description: 'save_success'.tr,
        ),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'save_error'.tr,
        ),
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// 저장된 그림 삭제
  Future<void> deleteDrawing(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }

      savedDrawings.remove(path);
      await HiveService.to.setSetting(_savedPathsKey, savedDrawings.toList());
      AppToast.show(
        AppToastMessage.success(
          title: 'delete_drawing'.tr,
          description: 'delete_drawing_complete'.tr,
        ),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'delete_error'.tr,
        ),
      );
    }
  }

  /// 공유 (임시 파일로 저장 후 공유)
  Future<void> shareCanvas() async {
    if (strokes.isEmpty) {
      AppToast.show(
        AppToastMessage.info(
          title: 'share'.tr,
          description: 'gallery_empty'.tr,
        ),
      );
      return;
    }

    final image = await _captureCanvas();
    if (image == null) return;
    File? tmpFile;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      tmpFile = File(
          '${dir.path}/doodle_${DateTime.now().millisecondsSinceEpoch}.png');
      await tmpFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(tmpFile.path, mimeType: 'image/png')]),
      );
    } catch (_) {
      AppToast.show(
        AppToastMessage.error(
          title: 'error'.tr,
          description: 'share_error'.tr,
        ),
      );
      // 공유 실패 시에만 임시 파일 정리 (성공 시에는 OS가 관리하므로 삭제하지 않음)
      try {
        if (tmpFile != null && tmpFile.existsSync()) tmpFile.deleteSync();
      } catch (_) {}
    }
  }
}
