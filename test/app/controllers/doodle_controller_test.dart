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
}
