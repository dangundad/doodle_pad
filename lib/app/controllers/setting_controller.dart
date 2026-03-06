import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/services/activity_log_service.dart';

class SettingController extends GetxController {
  static SettingController get to => Get.find<SettingController>();
  static const String appId = 'doodle_pad';

  static const String _kSettingBox = 'doodle_settings_v1';
  static const String _kIsFirstRunKey = 'is_first_run';
  static const String _kHapticKey = 'haptic_enabled';
  static const String _kShowBrushGuideKey = 'show_brush_guide';
  static const String _kAskBeforeClearKey = 'ask_before_clear';
  static const String _kLanguageKey = 'language';

  final RxBool isFirstRun = true.obs;
  final RxBool hapticEnabled = true.obs;
  final RxBool showBrushGuide = true.obs;
  final RxBool askBeforeClear = true.obs;
  final RxString language = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<Box<dynamic>> _openSettingBox() async {
    if (Hive.isBoxOpen(_kSettingBox)) {
      return Hive.box(_kSettingBox);
    }
    return await Hive.openBox(_kSettingBox);
  }

  Future<void> _load() async {
    final box = await _openSettingBox();
    isFirstRun.value = _readBool(box, _kIsFirstRunKey, true);
    hapticEnabled.value = _readBool(box, _kHapticKey, true);
    showBrushGuide.value = _readBool(box, _kShowBrushGuideKey, true);
    askBeforeClear.value = _readBool(box, _kAskBeforeClearKey, true);
    language.value = _readString(box, _kLanguageKey, 'en');
    Get.updateLocale(language.value == 'ko' ? const Locale('ko') : const Locale('en'));
  }

  Future<void> setHapticEnabled(bool value) async {
    hapticEnabled.value = value;
    final box = await _openSettingBox();
    await box.put(_kHapticKey, value);
  }

  Future<void> setShowBrushGuide(bool value) async {
    showBrushGuide.value = value;
    final box = await _openSettingBox();
    await box.put(_kShowBrushGuideKey, value);
  }

  Future<void> setAskBeforeClear(bool value) async {
    askBeforeClear.value = value;
    final box = await _openSettingBox();
    await box.put(_kAskBeforeClearKey, value);
  }

  Future<void> setLanguage(String value) async {
    language.value = value;
    final box = await _openSettingBox();
    await box.put(_kLanguageKey, value);
    Get.updateLocale(value == 'ko' ? const Locale('ko') : const Locale('en'));
  }

  Future<void> clearAppSettings() async {
    final box = await _openSettingBox();
    await box.clear();
    isFirstRun.value = true;
    hapticEnabled.value = true;
    showBrushGuide.value = true;
    askBeforeClear.value = true;
    language.value = 'en';
    Get.updateLocale(const Locale('en'));
  }

  Future<void> finishFirstRun() async {
    isFirstRun.value = false;
    final box = await _openSettingBox();
    await box.put(_kIsFirstRunKey, false);
  }

  void recordHomeOpen(String routeName) {
    logEvent('home_open', 'home', metadata: {'route': routeName});
  }

  void recordSettingsOpen({String from = 'menu'}) {
    logEvent('settings_open', 'settings', metadata: {'from': from});
  }

  void logEvent(
    String eventName,
    String screen, {
    Map<String, dynamic> metadata = const {},
  }) {
    if (!Get.isRegistered<ActivityLogService>()) {
      return;
    }
    unawaited(
      ActivityLogService.to.logEvent(
        appId: appId,
        eventName: eventName,
        screen: screen,
        route: Get.currentRoute,
        metadata: metadata,
      ),
    );
  }

  bool _readBool(Box box, String key, bool fallback) {
    final value = box.get(key, defaultValue: fallback);
    if (value is bool) return value;
    return fallback;
  }

  String _readString(Box box, String key, String fallback) {
    final value = box.get(key, defaultValue: fallback);
    if (value is String) return value;
    return fallback;
  }
}
