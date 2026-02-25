import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Languages extends Translations {
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ko')];

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
      'history': 'History',
      'stats': 'Stats',
      'settings_page': 'Settings',
      'open_history': 'History',
      'open_stats': 'Stats',
      'clear_all': 'Clear All',
      'refresh': 'Refresh',
      'no_history': 'No history',
      'unknown_event': 'Unknown Event',
      'history_subtitle': 'Screen: @screen / Route: @route',
      'total_events': 'Total Events',
      'today_events': 'Today',
      'week_events': 'This Week',
      'unique_routes': 'Routes',
      'unique_screens': 'Screens',
      'top_events': 'Top Events',

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
      'eraser_mode': 'Eraser ??drag to erase',
    },
    'ko': {},
  };
}
