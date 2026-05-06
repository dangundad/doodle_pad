// ================================================
// DangunDad Flutter App - app_constants.dart Template
// ================================================

// ignore_for_file: constant_identifier_names

/// Hive 키 상수
abstract class HiveKeys {
  static const String IS_FIRST_LAUNCH = 'is_first_launch';
  static const String IS_PREMIUM = 'is_premium';
}

/// 관련 URL
abstract class AppUrls {
  static const String GOOGLE_PLAY_MOREAPPS =
      'https://play.google.com/store/apps/developer?id=DangunDad';

  static const String PACKAGE_NAME = 'com.dangundad.doodlepad';
  static const String PRIVACY_POLICY =
      'https://dangundad.github.io/privacy/doodle-pad';
}

/// 개발자 정보
abstract class DeveloperInfo {
  static const String DEVELOPER_EMAIL = 'dangundad@gmail.com';
}

abstract class HiveBoxNames {
  static const String SETTINGS = 'settings';
  static const String APP_DATA = 'app_data';
}

/// 애니메이션 지속 시간
abstract class AnimationDurations {
  static const Duration FADE_IN = Duration(milliseconds: 300);
  static const Duration PAGE_TRANSITION = Duration(milliseconds: 500);
}

/// IAP 상품 ID
abstract class PurchaseConstants {
  static const String PREMIUM_SMALL_ANDROID = 'doodle_pad_premium_small';
  static const String PREMIUM_MEDIUM_ANDROID = 'doodle_pad_premium_medium';
  static const String PREMIUM_LARGE_ANDROID = 'doodle_pad_premium_large';

  static const List<String> ANDROID_PRODUCT_IDS = [
    PREMIUM_SMALL_ANDROID,
    PREMIUM_MEDIUM_ANDROID,
    PREMIUM_LARGE_ANDROID,
  ];
}

/// 앱 평가 설정
abstract class RateMyAppConfig {
  static const String PREFIX = 'doodlePad_rateMyApp_';
  static const int MIN_DAYS = 3;
  static const int MIN_LAUNCHES = 5;
  static const int REMIND_DAYS = 7;
  static const int REMIND_LAUNCHES = 10;
  static const String APP_STORE_ID = '0000000000'; // TODO: App Store Connect ID
}
