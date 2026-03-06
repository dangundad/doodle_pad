import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
