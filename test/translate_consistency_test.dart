import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/pages/settings/settings_page.dart';
import 'package:doodle_pad/app/translate/translate.dart';

/// 11개 언어가 모두 동일한 키셋을 갖는지 검증한다.
/// 신규 문자열을 한 언어만 빠뜨리는 회귀를 자동 차단 (module-polish).
void main() {
  test('모든 지원 언어는 en과 동일한 번역 키셋을 가진다', () {
    final keys = Languages().keys;
    expect(keys.containsKey('en'), isTrue, reason: 'en은 기준 언어');

    final baseKeys = keys['en']!.keys.toSet();
    final supportedCodes = Languages.supportedLocales
        .map((l) => l.languageCode)
        .toList();

    for (final code in supportedCodes) {
      expect(
        keys.containsKey(code),
        isTrue,
        reason: 'supportedLocales의 $code 가 keys 맵에 없음',
      );
      final langKeys = keys[code]!.keys.toSet();

      final missing = baseKeys.difference(langKeys);
      final extra = langKeys.difference(baseKeys);

      expect(
        missing,
        isEmpty,
        reason: '$code 에 누락된 키: $missing',
      );
      expect(
        extra,
        isEmpty,
        reason: '$code 에 en에 없는 잉여 키: $extra',
      );
    }
  });

  test(
    'SettingsPage 언어 옵션 키셋이 Languages.supportedLocales 와 정확히 일치',
    () {
      // settings_page 의 `_languageOptions` 는 별도 수동 map 이므로,
      // translate.dart 한쪽에만 언어를 추가/삭제하면 UI 만 누락되는 회귀가
      // 가능하다. 두 컬렉션의 키셋이 정확히 일치하는지 고정한다.
      final localeCodes = Languages.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      final uiCodes = SettingsPage.languageOptionsForTest.keys.toSet();
      expect(
        uiCodes,
        localeCodes,
        reason:
            'settings_page._languageOptions 와 Languages.supportedLocales 의 '
            '언어 코드 집합이 어긋났다. 한쪽만 변경된 회귀일 가능성이 높다.',
      );

      // SettingController 의 화이트리스트도 동일해야 한다 (derive 회귀 차단).
      expect(
        SettingController.supportedLanguageCodesForTest,
        localeCodes,
        reason:
            'SettingController._supportedLanguageCodes 와 '
            'Languages.supportedLocales 가 어긋났다.',
      );
    },
  );

  test('SettingsPage 언어 옵션 라벨은 비어 있지 않다 (endonym 표기 보장)', () {
    for (final entry in SettingsPage.languageOptionsForTest.entries) {
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason: '언어 ${entry.key} 의 표시 라벨이 비어 있다.',
      );
    }
  });

  test('module-save / canvas / artwork 신규 키가 모든 언어에 존재', () {
    final keys = Languages().keys;
    const requiredNewKeys = [
      'save',
      'save_to_gallery_title',
      'save_resolution_1x',
      'save_format_png',
      'save_success',
      'shake_to_clear_title',
      'shake_to_clear_desc',
      'artwork_title',
      'artwork_save_action',
      'gallery_title',
      'gallery_empty_title',
      'gallery_overlimit_warning',
    ];

    for (final entry in keys.entries) {
      for (final k in requiredNewKeys) {
        expect(
          entry.value.containsKey(k),
          isTrue,
          reason: '언어 ${entry.key} 에 키 "$k" 누락',
        );
      }
    }
  });
}
