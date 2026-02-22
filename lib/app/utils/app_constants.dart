// ================================================
// DangunDad Flutter App - app_constants.dart Template
// ================================================
// {package}, doodlepad 치환 후 사용
// mbti_pro 프로덕션 패턴 기반

// ignore_for_file: constant_identifier_names

/// Hive 키 상수
abstract class HiveKeys {
  static const String IS_FIRST_LAUNCH = 'is_first_launch';
  // ---- 앱별 키 추가 ----
}

/// 앱 관련 URL
abstract class AppUrls {
  static const String GOOGLE_PLAY_MOREAPPS =
      'https://play.google.com/store/apps/developer?id=DangunDad';

  static const String PACKAGE_NAME = 'com.dangundad.doodlepad';

  // TODO: 개인정보처리방침 URL 추가
  // static const String PRIVACY_POLICY = 'https://...';
}

/// 개발자 정보
abstract class DeveloperInfo {
  static const String DEVELOPER_EMAIL = 'dangundad@gmail.com';
}

/// Hive Box 이름 (HiveService와 동기화)
abstract class HiveBoxNames {
  static const String SETTINGS = 'settings';
  static const String APP_DATA = 'app_data';
  // ---- 앱별 Box 추가 ----
}

/// 애니메이션 지속 시간
abstract class AnimationDurations {
  static const Duration FADE_IN = Duration(milliseconds: 300);
  static const Duration PAGE_TRANSITION = Duration(milliseconds: 500);
  // ---- 앱별 애니메이션 추가 ----
}
