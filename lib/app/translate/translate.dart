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
      'clear': 'Clear',
      'back': 'Back',
      'undo': 'Undo',
      'redo': 'Redo',

      // App
      'app_name': 'Doodle Pad',
      'app_subtitle': 'Express yourself freely',
      'start_drawing': 'Start Drawing',

      // Features
      'feature_pen': 'Pen',
      'feature_marker': 'Marker',
      'feature_eraser': 'Eraser',
      'feature_colors': '16 Colors',
      'feature_undo': 'Undo / Redo',
      'feature_share': 'Share',

      // Canvas
      'clear_canvas': 'Clear Canvas',
      'clear_canvas_confirm': 'This will erase everything. Continue?',
      'eraser_mode': 'Eraser — drag to erase',
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
      'clear': '지우기',
      'back': '뒤로',
      'undo': '실행 취소',
      'redo': '다시 실행',

      // 앱
      'app_name': '두들 패드',
      'app_subtitle': '자유롭게 나만의 그림을 그려보세요',
      'start_drawing': '그림 그리기 시작',

      // 기능
      'feature_pen': '펜',
      'feature_marker': '마커',
      'feature_eraser': '지우개',
      'feature_colors': '16가지 색상',
      'feature_undo': '실행 취소 / 다시 실행',
      'feature_share': '공유',

      // 캔버스
      'clear_canvas': '캔버스 초기화',
      'clear_canvas_confirm': '모든 내용이 삭제됩니다. 계속하시겠어요?',
      'eraser_mode': '지우개 — 드래그하여 지우기',
    },
  };
}
