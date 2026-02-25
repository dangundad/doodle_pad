// ================================================
// DangunDad Flutter App - app_constants.dart Template
// ================================================
// {package}, doodlepad 移섑솚 ???ъ슜
// mbti_pro ?꾨줈?뺤뀡 ?⑦꽩 湲곕컲

// ignore_for_file: constant_identifier_names

/// Hive ???곸닔
abstract class HiveKeys {
  static const String IS_FIRST_LAUNCH = 'is_first_launch';
  static const String IS_PREMIUM = 'is_premium';
  // ---- ?깅퀎 ??異붽? ----
}

/// ??愿??URL
abstract class AppUrls {
  static const String GOOGLE_PLAY_MOREAPPS =
      'https://play.google.com/store/apps/developer?id=DangunDad';

  static const String PACKAGE_NAME = 'com.dangundad.doodlepad';

  // TODO: 媛쒖씤?뺣낫泥섎━諛⑹묠 URL 異붽?
  // static const String PRIVACY_POLICY = 'https://...';
}

/// 媛쒕컻???뺣낫
abstract class DeveloperInfo {
  static const String DEVELOPER_EMAIL = 'dangundad@gmail.com';
}

/// Hive Box ?대쫫 (HiveService? ?숆린??
abstract class HiveBoxNames {
  static const String SETTINGS = 'settings';
  static const String APP_DATA = 'app_data';
  // ---- ?깅퀎 Box 異붽? ----
}

/// ?좊땲硫붿씠??吏???쒓컙
abstract class AnimationDurations {
  static const Duration FADE_IN = Duration(milliseconds: 300);
  static const Duration PAGE_TRANSITION = Duration(milliseconds: 500);
  // ---- ?깅퀎 ?좊땲硫붿씠??異붽? ----
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
