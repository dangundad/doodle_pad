// ================================================
// DangunDad Flutter App - app_routes.dart Template
// ================================================
// mbti_pro 프로덕션 패턴 기반 (part of 패턴)

// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const HOME = _Paths.HOME;
  static const SETTINGS = _Paths.SETTINGS;
  // ---- 앱별 라우트 추가 ----
}

abstract class _Paths {
  static const HOME = '/home';
  static const SETTINGS = '/settings';
  // ---- 앱별 경로 추가 ----
}
