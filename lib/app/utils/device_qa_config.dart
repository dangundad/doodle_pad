import 'package:flutter/material.dart';

/// 실제 기기 화면·번역 QA를 위한 컴파일 타임 진입점입니다.
/// 일반 빌드에서는 두 값이 모두 비어 있어 앱 동작에 영향을 주지 않습니다.
abstract final class DeviceQaConfig {
  static const route = String.fromEnvironment('DOODLE_PAD_QA_ROUTE');
  static const localeCode = String.fromEnvironment('DOODLE_PAD_QA_LOCALE');

  static Locale? get locale =>
      localeCode.isEmpty ? null : Locale(localeCode);
}
