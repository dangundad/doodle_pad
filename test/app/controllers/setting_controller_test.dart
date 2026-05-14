import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
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
