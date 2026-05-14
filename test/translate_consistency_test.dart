import 'package:flutter_test/flutter_test.dart';

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
