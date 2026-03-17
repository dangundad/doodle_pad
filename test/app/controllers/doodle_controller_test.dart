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
