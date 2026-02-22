// ================================================
// DangunDad Flutter App - translate.dart Template
// ================================================
// mbti_pro 프로덕션 패턴 기반
// 개발 시 한국어(ko)만 정의, 다국어는 추후 추가

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Languages extends Translations {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
    'en': {
      // Common
      'settings': 'Settings',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'reset': 'Reset',
      'done': 'Done',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'no_data': 'No data',

      // Settings
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'about': 'About',
      'version': 'Version',
      'rate_app': 'Rate App',
      'privacy_policy': 'Privacy Policy',
      'remove_ads': 'Remove Ads',

      // Feedback
      'send_feedback': 'Send Feedback',
      'more_apps': 'More Apps',

      // ---- App-specific translations ----
    },
    'ko': {
      // 공통
      'settings': '설정',
      'save': '저장',
      'cancel': '취소',
      'delete': '삭제',
      'edit': '편집',
      'share': '공유',
      'reset': '초기화',
      'done': '완료',
      'ok': '확인',
      'yes': '예',
      'no': '아니오',
      'error': '오류',
      'success': '성공',
      'loading': '로딩 중...',
      'no_data': '데이터 없음',

      // 설정
      'dark_mode': '다크 모드',
      'language': '언어',
      'about': '앱 정보',
      'version': '버전',
      'rate_app': '앱 평가',
      'privacy_policy': '개인정보처리방침',
      'remove_ads': '광고 제거',

      // 피드백
      'send_feedback': '피드백 보내기',
      'more_apps': '더 많은 앱',

      // ---- 앱별 번역 추가 ----
    },
  };
}
