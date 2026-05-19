import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/services/app_rating_service.dart';
import 'package:doodle_pad/app/translate/translate.dart';
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
  // Design Ref: §3.2 — 마지막 저장 옵션을 기억해 다음 저장 시 prefill.
  static const String _kLastExportResolutionKey = 'last_export_resolution';
  static const String _kLastExportFormatKey = 'last_export_format';
  // Design Ref: §5.5 — 흔들어 지우기 옵션. 기본 OFF로 작품 손실 방지.
  static const String _kShakeToClearEnabledKey = 'shake_to_clear_enabled';

  /// `clearAppSettings()` 가 명시적으로 삭제하는 SettingController 소유 키 집합.
  /// 같은 박스에 AppBinding 의 `onboarding_seen_v1` 같은 라이프사이클 플래그가
  /// 함께 저장되므로, `box.clear()` 로 전체를 비우면 다음 부팅 시 온보딩이
  /// 다시 노출되거나 legacy box purge 가 재시도되는 회귀가 생긴다.
  static const List<String> _ownedSettingKeys = <String>[
    _kHapticKey,
    _kShowBrushGuideKey,
    _kAskBeforeClearKey,
    _kLanguageKey,
    _kLastExportResolutionKey,
    _kLastExportFormatKey,
    _kShakeToClearEnabledKey,
  ];

  /// 회귀 테스트에서 owned-key 집합을 참조할 수 있도록 read-only 노출.
  @visibleForTesting
  static List<String> get ownedSettingKeysForTest =>
      List.unmodifiable(_ownedSettingKeys);

  static const int defaultExportResolution = 2; // 1x / 2x / 3x 중 HD
  static const String defaultExportFormat = 'png';
  static const Set<int> supportedExportResolutions = {1, 2, 3};
  static const Set<String> supportedExportFormats = {'png', 'jpeg'};

  final RxBool hapticEnabled = true.obs;
  final RxBool showBrushGuide = true.obs;
  final RxBool askBeforeClear = true.obs;
  final RxString language = 'en'.obs;
  final RxInt lastExportResolution = defaultExportResolution.obs;
  final RxString lastExportFormat = defaultExportFormat.obs;
  final RxBool shakeToClearEnabled = false.obs;
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
    lastExportResolution.value = _readExportResolution(box);
    lastExportFormat.value = _readExportFormat(box);
    shakeToClearEnabled.value = _readBool(box, _kShakeToClearEnabledKey, false);
    unawaited(_updateLocaleFn(currentLocale));
  }

  int _readExportResolution(Box box) {
    final raw = box.get(
      _kLastExportResolutionKey,
      defaultValue: defaultExportResolution,
    );
    if (raw is int && supportedExportResolutions.contains(raw)) return raw;
    return defaultExportResolution;
  }

  String _readExportFormat(Box box) {
    final raw = box.get(
      _kLastExportFormatKey,
      defaultValue: defaultExportFormat,
    );
    if (raw is String && supportedExportFormats.contains(raw)) return raw;
    return defaultExportFormat;
  }

  /// translate.dart 의 `Languages.supportedLocales` 에서 자동 derive 한
  /// 화이트리스트. 알 수 없는 코드가 저장되어 있으면 'en' 으로 폴백한다.
  /// translate.dart 한쪽에만 언어를 추가하고 컨트롤러를 잊는 회귀를 차단한다.
  static final Set<String> _supportedLanguageCodes = <String>{
    for (final locale in Languages.supportedLocales) locale.languageCode,
  };

  /// 회귀 테스트에서 지원 언어 코드 집합을 참조할 수 있도록 read-only 노출.
  @visibleForTesting
  static Set<String> get supportedLanguageCodesForTest =>
      Set.unmodifiable(_supportedLanguageCodes);

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

  /// Design Ref: §3.2 — 저장 옵션 시트 "저장" 시 호출.
  /// 지원하지 않는 값은 디폴트로 정규화해 저장한다.
  Future<void> setLastExportResolution(int value) async {
    final normalized = supportedExportResolutions.contains(value)
        ? value
        : defaultExportResolution;
    lastExportResolution.value = normalized;
    final box = await _openSettingBox();
    await box.put(_kLastExportResolutionKey, normalized);
  }

  /// Design Ref: §5.5 — 토글 변경 시 즉시 persist + Rx 알림(ever 리스너 호출).
  Future<void> setShakeToClearEnabled(bool value) async {
    shakeToClearEnabled.value = value;
    final box = await _openSettingBox();
    await box.put(_kShakeToClearEnabledKey, value);
  }

  Future<void> setLastExportFormat(String value) async {
    final normalized = supportedExportFormats.contains(value)
        ? value
        : defaultExportFormat;
    lastExportFormat.value = normalized;
    final box = await _openSettingBox();
    await box.put(_kLastExportFormatKey, normalized);
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
    // `box.clear()` 는 같은 박스에 사는 `onboarding_seen_v1` /
    // `legacy_boxes_purged_v1` 같은 AppBinding 라이프사이클 플래그까지 함께
    // 비워, 다음 부팅 시 온보딩 재노출 / legacy box purge 재시도가 발생한다.
    // SettingController 가 소유한 키만 정확히 지운다.
    await box.deleteAll(_ownedSettingKeys);
    hapticEnabled.value = true;
    showBrushGuide.value = true;
    askBeforeClear.value = true;
    language.value = 'en';
    lastExportResolution.value = defaultExportResolution;
    lastExportFormat.value = defaultExportFormat;
    shakeToClearEnabled.value = false;
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
