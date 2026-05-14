import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

import '../helpers/fake_purchase_service.dart';

/// Regression: `DoodleController._bindShakeToClearSetting()`는 호출 시점에
/// `SettingController`가 등록되어 있지 않으면 조용히 early-return한다.
/// 따라서 `AppBinding._ensureDependencyServices()`에서 SettingController는
/// 반드시 DoodleController보다 먼저 등록되어야 한다.
///
/// 회귀를 두 축에서 고정한다.
///   1) lexical: `app_binding.dart` 안에서 SettingController 등록이
///      DoodleController 등록보다 앞서야 한다.
///   2) behavioral: SettingController가 먼저 등록된 환경이면 shake 토글이
///      DoodleController의 가속도계 구독을 켜고 끈다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'AppBinding._ensureDependencyServices registers SettingController before DoodleController',
    () {
      final source = File(
        'lib/app/bindings/app_binding.dart',
      ).readAsStringSync();
      final settingIdx = source.indexOf('Get.put(SettingController()');
      final doodleIdx = source.indexOf('Get.put(DoodleController()');
      expect(
        settingIdx,
        greaterThanOrEqualTo(0),
        reason: 'SettingController 등록 라인을 찾을 수 없다.',
      );
      expect(
        doodleIdx,
        greaterThanOrEqualTo(0),
        reason: 'DoodleController 등록 라인을 찾을 수 없다.',
      );
      expect(
        settingIdx,
        lessThan(doodleIdx),
        reason:
            'SettingController는 DoodleController보다 먼저 등록되어야 한다. '
            '순서가 바뀌면 DoodleController.onInit -> _bindShakeToClearSetting()이 '
            'SettingController를 찾지 못해 ever 리스너가 부착되지 않는다.',
      );
    },
  );

  group('DoodleController shake binding (SettingController 선등록)', () {
    const vibrationChannel = MethodChannel('vibration');
    late Directory tempDir;

    setUp(() async {
      Get.testMode = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      tempDir = await Directory.systemTemp.createTemp(
        'doodle_pad_shake_binding_test_',
      );
      Hive.init(tempDir.path);
      await Hive.openBox(HiveService.SETTINGS_BOX);
      await Hive.openBox(HiveService.APP_DATA_BOX);
      await Hive.openBox('doodle_settings_v1');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(vibrationChannel, (_) async => null);

      Get.put<HiveService>(HiveService(), permanent: true);
      Get.put<PurchaseService>(FakePurchaseService(), permanent: true);
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

    test(
      'SettingController가 먼저 등록되면 shake 토글이 가속도계 구독을 켠다',
      () async {
        // 프로덕션 AppBinding과 같은 순서: SettingController 먼저, DoodleController 다음.
        Get.put<SettingController>(
          SettingController(
            loadOnInit: false,
            updateLocaleFn: (_) async {},
          ),
          permanent: true,
        );
        Get.put<DoodleController>(DoodleController(), permanent: true);

        final settings = SettingController.to;
        final doodle = DoodleController.to;

        // 실제 sensors_plus stream 대신 broadcast controller를 주입한다.
        final shakeController =
            StreamController<UserAccelerometerEvent>.broadcast();
        addTearDown(shakeController.close);
        doodle.shakeStreamFactoryForTest = () => shakeController.stream;

        expect(settings.shakeToClearEnabled.value, isFalse);
        expect(doodle.isShakeDetectionActive, isFalse);

        settings.shakeToClearEnabled.value = true;
        await Future<void>.delayed(Duration.zero);
        expect(
          doodle.isShakeDetectionActive,
          isTrue,
          reason: 'ever<bool> 리스너가 부착되어 있어야 shake 구독이 시작된다.',
        );

        settings.shakeToClearEnabled.value = false;
        await Future<void>.delayed(Duration.zero);
        expect(doodle.isShakeDetectionActive, isFalse);
      },
    );

    test(
      'SettingController가 늦게 등록되면 DoodleController는 listener를 attach하지 못한다 (현재 회귀 형상)',
      () async {
        // 잘못된 순서를 의도적으로 재현: DoodleController 먼저, SettingController 나중.
        Get.put<DoodleController>(DoodleController(), permanent: true);
        Get.put<SettingController>(
          SettingController(
            loadOnInit: false,
            updateLocaleFn: (_) async {},
          ),
          permanent: true,
        );

        final settings = SettingController.to;
        final doodle = DoodleController.to;

        final shakeController =
            StreamController<UserAccelerometerEvent>.broadcast();
        addTearDown(shakeController.close);
        doodle.shakeStreamFactoryForTest = () => shakeController.stream;

        settings.shakeToClearEnabled.value = true;
        await Future<void>.delayed(Duration.zero);

        // listener가 부착되지 않았으므로 토글해도 구독은 시작되지 않는다.
        expect(
          doodle.isShakeDetectionActive,
          isFalse,
          reason: '이 expectation이 실패한다면 _bindShakeToClearSetting의 contract가 바뀐 것이다.',
        );
      },
    );
  });
}
