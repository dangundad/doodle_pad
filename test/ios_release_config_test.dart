import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Given an iOS release build', () {
    test('When the AdMob App ID is empty Then the build is rejected', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final validationScript = File('ios/scripts/validate_admob_app_id.sh');

      expect(project, contains('Validate AdMob App ID'));
      expect(validationScript.existsSync(), isTrue);
      final script = validationScript.readAsStringSync();
      expect(script, contains(r'"${CONFIGURATION:-}" = "Release"'));
      expect(script, contains(r'-z "${GAD_APPLICATION_IDENTIFIER:-}"'));
    });

    test('When the App ID is configured Then Info.plist consumes it', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      final releaseConfig = File(
        'ios/Flutter/Release.xcconfig',
      ).readAsStringSync();

      expect(
        infoPlist,
        contains('<string>\$(GAD_APPLICATION_IDENTIFIER)</string>'),
      );
      expect(releaseConfig, contains(r'$(IOS_ADMOB_APP_ID)'));
    });
  });
}
