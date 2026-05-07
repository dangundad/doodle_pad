import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/services/app_rating_service.dart';
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

  /// translate.dart 의 supportedLocales 와 동일한 화이트리스트.
  /// 알 수 없는 코드가 저장되어 있으면 'en' 으로 폴백한다.
  static const _supportedLanguageCodes = <String>{
    'en',
    'ko',
    'ja',
    'de',
    'ru',
    'fr',
    'es',
    'pt',
    'id',
    'zh',
    'ar',
  };

  Locale get currentLocale {
    final code = language.value;
    if (_supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return const Locale('en');
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
    // 지원하지 않는 코드는 'en' 으로 정규화. 손상된 저장값이나 외부 주입에 의해
    // language.value 와 실제 적용되는 locale 이 어긋나는 회귀를 막는다.
    final normalized = _supportedLanguageCodes.contains(value) ? value : 'en';
    language.value = normalized;
    final box = await _openSettingBox();
    await box.put(_kLanguageKey, normalized);
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

    // 드로잉 사용자 선호값(캔버스/커스텀 색상)도 함께 리셋.
    // 보상형 광고로 해금한 브러시(watercolor/airbrush) 상태와 인앱 결제(is_premium)는
    // 의도적으로 보존한다. 사용자가 광고/결제로 얻은 권한이 사라지는 회귀를 막기 위함.
    if (Get.isRegistered<DoodleController>()) {
      try {
        await DoodleController.to.resetDrawingPreferences();
      } catch (_) {
        // HiveService 미등록 등 비정상 상황에서는 조용히 패스 — UI 초기화는 계속 진행.
      }
    }
  }

  Future<void> rateApp() async {
    try {
      await _rateAppFn();
    } catch (_) {
      _showLinkError();
    }
  }

  Future<void> sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: DeveloperInfo.DEVELOPER_EMAIL,
      query: _encodeQueryParameters({'subject': 'feedback_email_subject'.tr}),
    );
    await _openExternalLink(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> openMoreApps() async {
    await _openExternalLink(Uri.parse(AppUrls.GOOGLE_PLAY_MOREAPPS));
  }

  Future<void> openPrivacyPolicy() async {
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
