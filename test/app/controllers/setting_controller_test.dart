import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/translate/translate.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp(
      'doodle_pad_setting_controller_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loads persisted settings immediately during init for restart safety', () async {
      final box = await Hive.openBox('doodle_settings_v1');
      await box.put('haptic_enabled', false);
      await box.put('show_brush_guide', false);
      await box.put('ask_before_clear', false);
      await box.put('language', 'ko');

      final controller = SettingController(
        updateLocaleFn: (_) async {},
      );

      controller.onInit();

      expect(controller.hapticEnabled.value, false);
      expect(controller.showBrushGuide.value, false);
      expect(controller.askBeforeClear.value, false);
      expect(controller.language.value, 'ko');
  });

  test('lastExportResolution / lastExportFormat: 저장 후 재구동 시 복원', () async {
    final controller = SettingController(
      loadOnInit: false,
      updateLocaleFn: (_) async {},
    );
    controller.onInit();

    await controller.setLastExportResolution(3);
    await controller.setLastExportFormat('jpeg');

    expect(controller.lastExportResolution.value, 3);
    expect(controller.lastExportFormat.value, 'jpeg');

    // 같은 box를 다시 열고 새 컨트롤러 인스턴스로 readback.
    final reborn = SettingController(updateLocaleFn: (_) async {});
    reborn.onInit();

    expect(reborn.lastExportResolution.value, 3);
    expect(reborn.lastExportFormat.value, 'jpeg');
  });

  test('shakeToClearEnabled: 기본 false, 토글 후 persist + 재구동 시 복원', () async {
    final controller = SettingController(
      loadOnInit: false,
      updateLocaleFn: (_) async {},
    );
    controller.onInit();

    expect(controller.shakeToClearEnabled.value, false);

    await controller.setShakeToClearEnabled(true);
    expect(controller.shakeToClearEnabled.value, true);

    final reborn = SettingController(updateLocaleFn: (_) async {});
    reborn.onInit();

    expect(reborn.shakeToClearEnabled.value, true);
  });

  test('lastExport*: 지원하지 않는 값은 디폴트로 정규화', () async {
    final controller = SettingController(
      loadOnInit: false,
      updateLocaleFn: (_) async {},
    );
    controller.onInit();

    await controller.setLastExportResolution(99); // out of {1,2,3}
    await controller.setLastExportFormat('webp'); // out of {'png','jpeg'}

    expect(
      controller.lastExportResolution.value,
      SettingController.defaultExportResolution,
    );
    expect(
      controller.lastExportFormat.value,
      SettingController.defaultExportFormat,
    );
  });

  test('rateApp delegates to the app rating action', () async {
    var invoked = 0;
    final controller = SettingController(
      loadOnInit: false,
      rateAppFn: () async {
        invoked += 1;
      },
    );

    await controller.rateApp();

    expect(invoked, 1);
  });

  test('sendFeedback launches a mailto uri', () async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    final controller = SettingController(
      loadOnInit: false,
      canLaunchUrlFn: (_) async => true,
      launchUrlFn: (uri, mode) async {
        launchedUri = uri;
        launchedMode = mode;
        return true;
      },
    );

    await controller.sendFeedback();

    expect(launchedUri?.scheme, 'mailto');
    expect(launchedUri?.path, DeveloperInfo.DEVELOPER_EMAIL);
    expect(launchedUri?.queryParameters['subject'], isNotEmpty);
    expect(launchedMode, LaunchMode.platformDefault);
  });

  test(
    'sendFeedback still tries launchUrl when canLaunchUrl reports false',
    () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final controller = SettingController(
        loadOnInit: false,
        canLaunchUrlFn: (_) async => false,
        launchUrlFn: (uri, mode) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      await controller.sendFeedback();

      expect(launchedUri?.scheme, 'mailto');
      expect(launchedUri?.path, DeveloperInfo.DEVELOPER_EMAIL);
      expect(launchedMode, LaunchMode.platformDefault);
    },
  );

  test('openPrivacyPolicy launches the privacy policy externally', () async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    final controller = SettingController(
      loadOnInit: false,
      canLaunchUrlFn: (_) async => true,
      launchUrlFn: (uri, mode) async {
        launchedUri = uri;
        launchedMode = mode;
        return true;
      },
    );

    await controller.openPrivacyPolicy();

    expect(launchedUri, Uri.parse(AppUrls.PRIVACY_POLICY));
    expect(launchedMode, LaunchMode.externalApplication);
  });

  test(
    'clearAppSettings: 동일 박스의 AppBinding 라이프사이클 플래그를 보존',
    () async {
      // 같은 `doodle_settings_v1` 박스에는 SettingController 외에도 AppBinding 이
      // `onboarding_seen_v1`(첫 실행 노출 여부) / `legacy_boxes_purged_v1`
      // (legacy box purge 완료 플래그) 등의 라이프사이클 키를 저장한다.
      // clearAppSettings 가 박스 전체를 비우면 다음 부팅에서 온보딩이 다시 뜨고
      // legacy purge 가 재시도되는 회귀가 발생하므로, owned key 만 정확히 비워야 한다.
      final box = await Hive.openBox('doodle_settings_v1');
      await box.put('haptic_enabled', false);
      await box.put('language', 'ko');
      await box.put('shake_to_clear_enabled', true);
      await box.put('onboarding_seen_v1', true);
      await box.put('legacy_boxes_purged_v1', true);
      // 외부 위젯이 같은 박스에 임의 키를 저장한 경우에도 보존되어야 한다.
      await box.put('foreign_feature_flag', 'keep-me');

      final controller = SettingController(
        loadOnInit: false,
        updateLocaleFn: (_) async {},
      );
      controller.onInit();

      await controller.clearAppSettings();

      // SettingController 소유 키만 비워졌는지 확인.
      expect(box.get('haptic_enabled'), isNull);
      expect(box.get('language'), isNull);
      expect(box.get('shake_to_clear_enabled'), isNull);

      // AppBinding 라이프사이클 플래그 + 외부 키는 보존되어야 한다.
      expect(
        box.get('onboarding_seen_v1'),
        isTrue,
        reason: 'Reset Settings 가 첫 실행 온보딩을 다시 트리거하면 안 된다.',
      );
      expect(
        box.get('legacy_boxes_purged_v1'),
        isTrue,
        reason: 'Reset Settings 가 legacy purge 를 매 부팅 재시도시키면 안 된다.',
      );
      expect(box.get('foreign_feature_flag'), 'keep-me');
    },
  );

  test(
    'clearAppSettings: 인메모리 Rx 와 영속 box 값이 기본값으로 일치',
    () async {
      final controller = SettingController(
        loadOnInit: false,
        updateLocaleFn: (_) async {},
      );
      controller.onInit();

      await controller.setHapticEnabled(false);
      await controller.setShowBrushGuide(false);
      await controller.setAskBeforeClear(false);
      await controller.setLanguage('ko');
      await controller.setLastExportResolution(3);
      await controller.setLastExportFormat('jpeg');
      await controller.setShakeToClearEnabled(true);

      await controller.clearAppSettings();

      // Rx 값이 기본값으로 복귀.
      expect(controller.hapticEnabled.value, isTrue);
      expect(controller.showBrushGuide.value, isTrue);
      expect(controller.askBeforeClear.value, isTrue);
      expect(controller.language.value, 'en');
      expect(
        controller.lastExportResolution.value,
        SettingController.defaultExportResolution,
      );
      expect(
        controller.lastExportFormat.value,
        SettingController.defaultExportFormat,
      );
      expect(controller.shakeToClearEnabled.value, isFalse);

      // 새 인스턴스로 readback 시에도 기본값이 적용된다(영속 일관성).
      final reborn = SettingController(updateLocaleFn: (_) async {});
      reborn.onInit();
      expect(reborn.hapticEnabled.value, isTrue);
      expect(reborn.showBrushGuide.value, isTrue);
      expect(reborn.askBeforeClear.value, isTrue);
      expect(reborn.language.value, 'en');
      expect(
        reborn.lastExportResolution.value,
        SettingController.defaultExportResolution,
      );
      expect(
        reborn.lastExportFormat.value,
        SettingController.defaultExportFormat,
      );
      expect(reborn.shakeToClearEnabled.value, isFalse);
    },
  );

  test(
    'supportedLanguageCodes 는 Languages.supportedLocales 에서 derive 된다',
    () {
      final localeCodes =
          Languages.supportedLocales.map((l) => l.languageCode).toSet();
      expect(SettingController.supportedLanguageCodesForTest, localeCodes);
    },
  );

  test(
    'setLanguage: 지원하지 않는 코드는 en 으로 폴백 + 영속화',
    () async {
      final controller = SettingController(
        loadOnInit: false,
        updateLocaleFn: (_) async {},
      );
      controller.onInit();

      await controller.setLanguage('xx');

      expect(controller.language.value, 'en');
      final box = Hive.box('doodle_settings_v1');
      expect(box.get('language'), 'en');
    },
  );

  test('openMoreApps launches the developer page externally', () async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    final controller = SettingController(
      loadOnInit: false,
      canLaunchUrlFn: (_) async => true,
      launchUrlFn: (uri, mode) async {
        launchedUri = uri;
        launchedMode = mode;
        return true;
      },
    );

    await controller.openMoreApps();

    expect(launchedUri, Uri.parse(AppUrls.GOOGLE_PLAY_MOREAPPS));
    expect(launchedMode, LaunchMode.externalApplication);
  });
}
