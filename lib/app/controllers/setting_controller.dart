import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/services/app_rating_service.dart';
import 'package:doodle_pad/app/services/activity_log_service.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';
import 'package:doodle_pad/app/utils/app_toast.dart';

typedef CanLaunchUrlFn = Future<bool> Function(Uri uri);
typedef LaunchUrlFn = Future<bool> Function(Uri uri, LaunchMode mode);
typedef RateAppFn = Future<void> Function();
typedef UpdateLocaleFn = Future<void> Function(Locale locale);

class SettingController extends GetxController {
  SettingController({
    bool loadOnInit = true,
    CanLaunchUrlFn? canLaunchUrlFn,
    LaunchUrlFn? launchUrlFn,
    RateAppFn? rateAppFn,
    UpdateLocaleFn? updateLocaleFn,
  }) : _loadOnInit = loadOnInit,
       _launchUrlFn =
           launchUrlFn ?? ((uri, mode) => launchUrl(uri, mode: mode)),
       _rateAppFn = rateAppFn ?? (() => AppRatingService.to.openStoreListing()),
       _updateLocaleFn = updateLocaleFn ?? Get.updateLocale;

  static SettingController get to => Get.find<SettingController>();
  static const String appId = 'doodle_pad';

  static const String _kSettingBox = 'doodle_settings_v1';
  static const String _kHapticKey = 'haptic_enabled';
  static const String _kShowBrushGuideKey = 'show_brush_guide';
  static const String _kAskBeforeClearKey = 'ask_before_clear';
  static const String _kLanguageKey = 'language';

  final RxBool hapticEnabled = true.obs;
  final RxBool showBrushGuide = true.obs;
  final RxBool askBeforeClear = true.obs;
  final RxString language = 'en'.obs;
  final bool _loadOnInit;
  final LaunchUrlFn _launchUrlFn;
  final RateAppFn _rateAppFn;
  final UpdateLocaleFn _updateLocaleFn;

  static Future<void> ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_kSettingBox)) {
      await Hive.openBox(_kSettingBox);
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (_loadOnInit) {
      _loadSync();
    }
  }

  Box<dynamic>? _settingBoxOrNull() {
    if (!Hive.isBoxOpen(_kSettingBox)) {
      return null;
    }
    return Hive.box(_kSettingBox);
  }

  Future<Box<dynamic>> _openSettingBox() async {
    await ensureBoxOpen();
    return Hive.box(_kSettingBox);
  }

  void _loadSync() {
    final box = _settingBoxOrNull();
    if (box == null) {
      return;
    }

    hapticEnabled.value = _readBool(box, _kHapticKey, true);
    showBrushGuide.value = _readBool(box, _kShowBrushGuideKey, true);
    askBeforeClear.value = _readBool(box, _kAskBeforeClearKey, true);
    language.value = _readString(box, _kLanguageKey, 'en');
    unawaited(_updateLocaleFn(currentLocale));
  }

  Locale get currentLocale =>
      language.value == 'ko' ? const Locale('ko') : const Locale('en');

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
    await _updateLocaleFn(currentLocale);
  }

  Future<void> clearAppSettings() async {
    final box = await _openSettingBox();
    await box.clear();
    hapticEnabled.value = true;
    showBrushGuide.value = true;
    askBeforeClear.value = true;
    language.value = 'en';
    await _updateLocaleFn(const Locale('en'));

    if (Get.isRegistered<ActivityLogService>()) {
      await ActivityLogService.to.clearEvents(appId: appId);
    }
  }
  Future<void> rateApp() async {
    logEvent('tap_rate_app', 'settings');
    try {
      await _rateAppFn();
    } catch (_) {
      _showLinkError();
    }
  }

  Future<void> sendFeedback() async {
    logEvent('tap_send_feedback', 'settings');
    final uri = Uri(
      scheme: 'mailto',
      path: DeveloperInfo.DEVELOPER_EMAIL,
      query: _encodeQueryParameters({'subject': 'feedback_email_subject'.tr}),
    );
    await _openExternalLink(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> openMoreApps() async {
    logEvent('tap_more_apps', 'settings');
    await _openExternalLink(Uri.parse(AppUrls.GOOGLE_PLAY_MOREAPPS));
  }

  Future<void> openPrivacyPolicy() async {
    logEvent('tap_privacy_policy', 'settings');
    await _openExternalLink(Uri.parse(AppUrls.PRIVACY_POLICY));
  }

  Future<void> _openExternalLink(
    Uri uri, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    try {
      final launched = await _launchUrlFn(uri, mode);
      if (!launched) {
        _showLinkError();
      }
    } catch (_) {
      _showLinkError();
    }
  }

  void _showLinkError() {
    AppToast.show(
      AppToastMessage.error(
        title: 'error'.tr,
        description: 'link_open_error'.tr,
      ),
    );
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

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }
}
