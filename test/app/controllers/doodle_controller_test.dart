import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

class _BlockingHiveService extends HiveService {
  final Completer<void> _setCompleter = Completer<void>();
  bool settingWriteStarted = false;
  bool settingWriteCompleted = false;

  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;

  @override
  Future<void> setSetting(String key, dynamic value) async {
    if (key == DoodleController.canvasColorKey) {
      settingWriteStarted = true;
      await _setCompleter.future;
      settingWriteCompleted = true;
    }
  }

  void completeSettingWrite() {
    if (!_setCompleter.isCompleted) {
      _setCompleter.complete();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vibrationChannel = MethodChannel('vibration');

  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_doodle_controller_test_',
    );
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.SETTINGS_BOX);
    await Hive.openBox(HiveService.APP_DATA_BOX);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, (call) async {
          switch (call.method) {
            case 'hasVibrator':
              return true;
            case 'vibrate':
              return null;
            default:
              return null;
          }
        });

    Get.put<HiveService>(HiveService(), permanent: true);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, null);
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('hasDrawableContent is true when only a reference image is loaded', () {
    final controller = DoodleController();
    expect(controller.hasDrawableContent, isFalse);

    controller.loadReferenceDrawing('C:\\temp\\reference.png');
    expect(controller.strokes, isEmpty);
    expect(controller.hasDrawableContent, isTrue);

    controller.clearReferenceDrawing();
    expect(controller.hasDrawableContent, isFalse);
  });

  test('clearCanvas resets both strokes and reference image', () {
    final controller = DoodleController();
    controller.strokes.add(
      DrawingStroke(
        points: const [Offset(1, 1)],
        color: Colors.black,
        width: 4,
      ),
    );
    controller.referenceImagePath.value = 'C:\\temp\\reference.png';

    controller.clearCanvas();

    expect(controller.strokes, isEmpty);
    expect(controller.referenceImagePath.value, isNull);
    expect(controller.hasDrawableContent, isFalse);
  });

  test('loadReferenceDrawing keeps the selected image and resets strokes', () {
    final controller = DoodleController();
    controller.strokes.add(
      DrawingStroke(
        points: const [Offset(1, 1)],
        color: Colors.black,
        width: 4,
      ),
    );

    controller.loadReferenceDrawing('C:\\temp\\reference.png');

    expect(controller.referenceImagePath.value, 'C:\\temp\\reference.png');
    expect(controller.strokes, isEmpty);
  });

  test(
    'setCanvasColor waits for settings persistence before completing',
    () async {
      final hive = _BlockingHiveService();
      Get.delete<HiveService>(force: true);
      Get.put<HiveService>(hive, permanent: true);
      final controller = DoodleController();

      var completed = false;
      final save = controller.setCanvasColor(0xFFE3F2FD).then((_) {
        completed = true;
      });

      await Future<void>.delayed(Duration.zero);

      expect(hive.settingWriteStarted, isTrue);
      expect(hive.settingWriteCompleted, isFalse);
      expect(completed, isFalse);

      hive.completeSettingWrite();
      await save;

      expect(completed, isTrue);
      expect(hive.settingWriteCompleted, isTrue);
    },
  );

  test(
    'unlockBrush allows premium users to select special brushes without rewarded ads',
    () {
      final purchaseService = FakePurchaseService()..isPremium.value = true;
      Get.put<PurchaseService>(purchaseService, permanent: true);

      final controller = DoodleController();

      controller.unlockBrush(BrushType.watercolor);

      expect(controller.brushType.value, BrushType.watercolor);
    },
  );

  test('saveAsArtwork: 이미 저장 중이면 즉시 null을 반환하고 중복 실행하지 않는다', () async {
    final controller = DoodleController();
    controller.strokes.add(
      DrawingStroke(
        points: const [Offset(1, 1)],
        color: Colors.black,
        width: 4,
      ),
    );

    // 첫 호출이 진행 중인 상태를 모사한다.
    controller.isSavingArtwork.value = true;

    final result = await controller.saveAsArtwork();

    // 연타 가드로 빠졌으므로 캡처/저장 없이 null, 플래그도 건드리지 않는다.
    expect(result, isNull);
    expect(controller.isSavingArtwork.value, isTrue);
  });

  test('useBrush: 최근 목록 맨 앞으로 당기고 상한을 지킨다', () async {
    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    controller.recentBrushes.assignAll(DoodleController.defaultRecentBrushes);

    await controller.useBrush(BrushType.highlighter);

    expect(controller.brushType.value, BrushType.highlighter);
    expect(controller.recentBrushes.first, BrushType.highlighter);
    expect(
      controller.recentBrushes.length,
      DoodleController.maxRecentBrushes,
      reason: '툴바 칸 수가 흔들리지 않도록 상한을 유지해야 한다',
    );

    // 이미 목록에 있는 브러시는 중복 없이 앞으로만 이동한다.
    await controller.useBrush(BrushType.pen);
    expect(controller.recentBrushes.first, BrushType.pen);
    expect(controller.recentBrushes.where((b) => b == BrushType.pen).length, 1);
  });

  test('useBrush: eraser는 최근 목록을 오염시키지 않는다', () async {
    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    controller.recentBrushes.assignAll(DoodleController.defaultRecentBrushes);

    await controller.useBrush(BrushType.eraser);

    // 지우개는 툴바에 항상 고정 노출되므로 최근 목록에서는 제외한다.
    expect(controller.brushType.value, BrushType.eraser);
    expect(controller.recentBrushes.contains(BrushType.eraser), isFalse);
    expect(controller.recentBrushes, DoodleController.defaultRecentBrushes);
  });

  test('useColor: 최근 색상을 앞으로 당기고 Hive에 영속화한다', () async {
    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    controller.recentColors.assignAll(DoodleController.defaultRecentColors);

    const teal = 0xFF009688;
    await controller.useColor(teal);

    expect(controller.brushColor.value, teal);
    expect(controller.recentColors.first, teal);
    expect(controller.recentColors.length, DoodleController.maxRecentColors);

    final stored = HiveService.to.getSetting<List<dynamic>>(
      DoodleController.recentColorsKey,
    );
    expect(stored?.first, teal, reason: '재실행 시 복원되도록 저장되어야 한다');
  });

  test('setCustomColor: 커스텀 색상도 최근 목록에 합류한다', () async {
    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    controller.recentColors.assignAll(DoodleController.defaultRecentColors);

    const custom = 0xFF123456;
    await controller.setCustomColor(custom);

    expect(controller.customColor.value, custom);
    expect(controller.brushColor.value, custom);
    expect(controller.recentColors.first, custom);
  });

  test('저장된 최근 목록이 모자라면 기본값으로 칸을 채운다', () async {
    // 색상 1개만 저장된 상태 — 툴바는 여전히 정확히 maxRecentColors 칸이어야 한다.
    const saved = 0xFF9C27B0;
    await HiveService.to.setSetting(DoodleController.recentColorsKey, [saved]);
    await HiveService.to.setSetting(DoodleController.recentBrushesKey, [
      BrushType.crayon.stableId,
    ]);

    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    controller.onInit();

    expect(controller.recentColors.first, saved);
    expect(controller.recentColors.length, DoodleController.maxRecentColors);
    expect(controller.recentBrushes.first, BrushType.crayon);
    expect(controller.recentBrushes.length, DoodleController.maxRecentBrushes);
  });

  test('resetDrawingPreferences: 최근 목록도 기본값으로 되돌린다', () async {
    final controller = DoodleController();
    Get.put<DoodleController>(controller);
    await controller.useColor(0xFF009688);
    await controller.useBrush(BrushType.crayon);

    await controller.resetDrawingPreferences();

    expect(controller.recentColors, DoodleController.defaultRecentColors);
    expect(controller.recentBrushes, DoodleController.defaultRecentBrushes);
  });
}
