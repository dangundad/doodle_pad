// ================================================
// DangunDad Flutter App - app_constants.dart Template
// ================================================

// ignore_for_file: constant_identifier_names

/// Hive 키 상수
abstract class HiveKeys {
  static const String IS_FIRST_LAUNCH = 'is_first_launch';
  static const String IS_PREMIUM = 'is_premium';
}

/// ??愿??URL
abstract class AppUrls {
  static const String GOOGLE_PLAY_MOREAPPS =
      'https://play.google.com/store/apps/developer?id=DangunDad';

  static const String PACKAGE_NAME = 'com.dangundad.doodlepad';

  // static const String PRIVACY_POLICY = 'https://...';
}

/// 개발자 정보
abstract class DeveloperInfo {
  static const String DEVELOPER_EMAIL = 'dangundad@gmail.com';
}

abstract class HiveBoxNames {
  static const String SETTINGS = 'settings';
  static const String APP_DATA = 'app_data';
}

/// ?좊땲硫붿씠??吏???쒓컙
abstract class AnimationDurations {
  static const Duration FADE_IN = Duration(milliseconds: 300);
  static const Duration PAGE_TRANSITION = Duration(milliseconds: 500);
}

/// IAP 상품 ID
abstract class PurchaseConstants {
  static const String PREMIUM_WEEKLY_ANDROID =
      '${AppUrls.PACKAGE_NAME}.premium_weekly';
  static const String PREMIUM_MONTHLY_ANDROID =
      '${AppUrls.PACKAGE_NAME}.premium_monthly';
  static const String PREMIUM_YEARLY_ANDROID =
      '${AppUrls.PACKAGE_NAME}.premium_yearly';

  static const List<String> ANDROID_PRODUCT_IDS = [
    PREMIUM_WEEKLY_ANDROID,
    PREMIUM_MONTHLY_ANDROID,
    PREMIUM_YEARLY_ANDROID,
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
