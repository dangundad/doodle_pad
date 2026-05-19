# Doodle Pad 최종 점검 리뷰

검토일: 2026-05-19
검토 기준: `C:\Github_WorkSpace\doodle_pad` 현재 working tree
검토 범위: 핵심 드로잉 로직, 설정 옵션, UI/UX, 다국어 처리, 광고/Premium, 저장/공유/갤러리, 테스트
요청 메모: 사용자 요청에는 `reivew_codex.md`로 표기되었지만, 저장소 기존 표준 파일명은 `review_codex.md`입니다. 호환 안내 파일 `reivew_codex.md`도 함께 둡니다.

## 1. 최종 결론

현재 앱은 **출시 후보로 볼 수 있는 상태**입니다. 핵심 드로잉, 브러시 영속화, 갤러리 저장, 앱 내 작품 보관함, 참조 사진 복사, 공유, 흔들어 지우기, 광고/Premium, 설정 초기화, 다국어 키 일관성은 코드와 테스트 기준으로 대체로 정리되어 있습니다.

검증 결과도 양호합니다.

| 항목 | 결과 |
| --- | --- |
| `flutter analyze` | 통과: `No issues found! (ran in 10.5s)` |
| `flutter test` | 통과: `98 tests`, `All tests passed!` |
| 릴리스 빌드 | 미실행: 프로젝트 규칙상 별도 요청 없이 `flutter build apk`/`flutter build ios` 금지 |
| 실제 기기 QA | 미실행: 사진 선택, 갤러리 저장, 공유, 광고, 결제, RTL 레이아웃은 기기/Play Console QA 필요 |

다만 출시 전 정리하면 좋은 항목이 남아 있습니다.

1. **P1: 저장 시트가 해상도 선택 UI를 노출하지 않는데, 문구/스토어 문서는 1x/2x/3x 선택을 말합니다.**
2. **P2: 갤러리 삭제 확인 다이얼로그의 확인 버튼이 `clear` 번역을 재사용합니다.**
3. **P2: 언어 선택 UI의 `_languageOptions`와 `Languages.supportedLocales` 동기화는 주석상 요구되지만 테스트로 고정되어 있지 않습니다.**

## 2. 주요 발견 사항

### P1. 저장 해상도 선택 UI와 문구/문서가 불일치

`SaveOptionsSheet`는 포맷(PNG/JPEG)만 선택하게 하고, 해상도는 `initialResolution`을 그대로 콜백에 넘깁니다. 주석도 `controller persisted (UI hidden)`이라고 되어 있습니다. 반면 번역 키에는 `save_resolution_1x/2x/3x`가 있고, 저장 설명은 "해상도와 포맷 선택"을 말하며, README/스토어 문서도 PNG/JPEG와 1x/2x/3x 저장을 소개합니다.

근거:

- `lib/app/pages/draw/widgets/save_options_sheet.dart:19` `initialResolution`은 UI hidden
- `lib/app/pages/draw/widgets/save_options_sheet.dart:88` 포맷 라벨만 렌더링
- `lib/app/pages/draw/widgets/save_options_sheet.dart:112` 기존 해상도만 전달
- `lib/app/pages/draw/draw_page.dart:495` 마지막 해상도 persist 경로는 있으나 사용자가 바꿀 UI가 없음
- `lib/app/translate/translate.dart:132` 해상도 번역 키 존재
- `README.md:3`, `docs/store/google-store.md:30`은 1x/2x/3x 저장을 설명

권장:

- 실제 요구가 해상도 선택이면 `SaveOptionsSheet`에 1x/2x/3x segmented control을 복구하고 테스트를 추가합니다.
- 제품 정책이 2x 고정이면 번역/README/스토어 문서에서 해상도 선택 표현을 제거합니다.

### P2. 갤러리 삭제 확인 버튼 문구가 부정확

작품 삭제 확인 다이얼로그는 제목과 설명은 삭제 맥락이지만, 확인 버튼은 `clear` 번역을 사용합니다. 영어에서는 `Clear`, 한국어에서는 `지우기` 계열로 보일 수 있어 `Delete`보다 덜 명확합니다.

근거:

- `lib/app/pages/gallery/gallery_page.dart:174` 단건 삭제 확인
- `lib/app/pages/gallery/gallery_page.dart:187` 다중 삭제 확인
- `lib/app/pages/gallery/gallery_page.dart:299` 확인 버튼 `Text('clear'.tr)`
- 이미 `gallery_delete_selected`, `artwork_delete_title`, `artwork_delete_confirm` 삭제 전용 키는 존재

권장:

- `delete` 또는 `artwork_delete_action` 번역 키를 추가해 확인 버튼에 사용합니다.
- 단건/다중 삭제 위젯 테스트에서 버튼 문구도 함께 확인합니다.

### P2. 언어 선택 UI 옵션과 supportedLocales 동기화 테스트가 부족

컨트롤러는 `Languages.supportedLocales`에서 지원 언어 코드를 derive하므로 저장값 정규화는 안전합니다. 하지만 설정 화면의 `_languageOptions`는 별도 수동 map입니다. 주석은 1:1 매칭을 요구하므로, 언어 추가/삭제 시 UI만 누락되는 회귀를 테스트로 막는 편이 좋습니다.

근거:

- `lib/app/translate/translate.dart:5` 11개 supported locale
- `lib/app/controllers/setting_controller.dart:145` 컨트롤러 지원 언어는 supportedLocales에서 derive
- `lib/app/pages/settings/settings_page.dart:14` UI 언어 옵션은 별도 map
- `test/app/controllers/setting_controller_test.dart:290` 컨트롤러 동기화 테스트는 있음

권장:

- `_languageOptions`를 `Languages.supportedLocales` 기반 구조로 옮기거나, 테스트용 getter를 열어 키셋 일치를 검증합니다.

## 3. 핵심 로직 점검

### 드로잉/브러시

판단: **양호**

- `BrushType` 10종이 정의되어 있고, 저장용 stable ID가 enum 순서와 분리되어 있습니다.
- 알 수 없는 stable ID는 `pen`으로 fallback합니다.
- undo/redo는 stroke 단위이고, 새 stroke 시작 시 redo stack을 비웁니다.
- 브러시 해금은 Premium 또는 보상형 광고 흐름과 연결되어 있습니다.
- `flutter test`에 stable ID 고정, brush registry, 빈 캔버스 버튼 disabled, 단일 손가락 드로잉, pinch wrapper 테스트가 포함됩니다.

근거:

- `lib/app/controllers/doodle_controller.dart:30`
- `lib/app/controllers/doodle_controller.dart:53`
- `lib/app/controllers/doodle_controller.dart:70`
- `lib/app/controllers/doodle_controller.dart:653`
- `lib/app/controllers/doodle_controller.dart:832`
- `test/app/controllers/brush_type_persistence_test.dart`
- `test/app/pages/draw/draw_page_test.dart`

### 저장/공유/작품 보관함

판단: **대체로 양호, 해상도 UI 불일치는 정리 필요**

- 공유 전 무효 참조 이미지 경로를 정리하고, 빈 컨텐츠를 방어합니다.
- 공유 파일은 stale cleanup 후 임시 PNG로 생성하며, 성공 직후 삭제하지 않아 OS share sheet 참조 문제를 피합니다.
- 앱 내 작품 저장은 중복 클릭 guard와 random suffix ID를 사용합니다.
- 작품 저장 시 참조 사진을 app support directory로 복사하고, 삭제 시 references 디렉터리 내부 복사본만 삭제합니다.
- JPEG 저장은 `image` 패키지로 실제 JPEG bytes를 생성합니다.

근거:

- `lib/app/controllers/doodle_controller.dart:733`
- `lib/app/controllers/doodle_controller.dart:775`
- `lib/app/controllers/doodle_controller.dart:837`
- `lib/app/controllers/doodle_controller.dart:886`
- `lib/app/services/artwork_repository.dart:68`
- `lib/app/services/artwork_repository.dart:105`
- `lib/app/services/artwork_repository.dart:155`
- `lib/app/services/export_service.dart:156`
- `lib/app/services/export_service.dart:166`
- `test/app/services/artwork_repository_test.dart`
- `test/app/services/export_service_test.dart`

### 흔들어 지우기

판단: **프로덕션 초기화 순서 기준 양호**

- `AppBinding`은 `SettingController`를 `DoodleController`보다 먼저 등록합니다.
- `DoodleController`는 `shakeToClearEnabled` 값을 읽어 가속도계 구독을 켜고, 이후 변경은 `ever`로 반영합니다.
- 관련 테스트는 등록 순서와 토글 동작을 고정합니다.

근거:

- `lib/app/bindings/app_binding.dart:98`
- `lib/app/bindings/app_binding.dart:103`
- `lib/app/bindings/app_binding.dart:107`
- `lib/app/controllers/doodle_controller.dart:276`
- `lib/app/controllers/doodle_controller.dart:282`
- `test/app/bindings/app_binding_shake_order_test.dart`

## 4. 설정 옵션 점검

판단: **대체로 양호**

| 옵션 | 상태 | 판단 |
| --- | --- | --- |
| 햅틱 피드백 | Hive 저장, 컨트롤러/툴바 동작에 반영 | 양호 |
| 브러시 가이드 | Draw 하단 안내 토글 | 양호 |
| 지우기 전 확인 | destructive action 확인 흐름 | 양호 |
| 흔들어 지우기 | 기본 OFF, 설정 변경 즉시 반영 | 양호 |
| 언어 | 11개 locale, unsupported code는 `en` fallback | 양호 |
| 저장 포맷 | PNG/JPEG persist 및 실제 JPEG 인코딩 | 양호 |
| 저장 해상도 | 값 persist 구조는 있으나 UI 선택이 숨겨짐 | 정리 필요 |
| 설정 초기화 | SettingController 소유 키만 삭제, 온보딩/legacy purge flag 보존 | 양호 |

중요한 개선점은 최근 변경된 `clearAppSettings()`입니다. 기존처럼 settings box 전체를 비우지 않고, SettingController 소유 키만 `deleteAll`하므로 같은 box에 있는 `onboarding_seen_v1`, `legacy_boxes_purged_v1` 같은 라이프사이클 플래그가 보존됩니다.

근거:

- `lib/app/controllers/setting_controller.dart:50`
- `lib/app/controllers/setting_controller.dart:114`
- `lib/app/controllers/setting_controller.dart:145`
- `lib/app/controllers/setting_controller.dart:207`
- `lib/app/controllers/setting_controller.dart:217`
- `test/app/controllers/setting_controller_test.dart:191`
- `test/app/controllers/setting_controller_test.dart:236`
- `test/app/controllers/setting_controller_test.dart:289`

## 5. UI/UX 점검

판단: **출시 후보 수준, 일부 카피 정리 필요**

### Home

- 첫 화면에서 `Start Drawing` CTA와 `My Artworks` 진입이 분명합니다.
- Premium 상태에서는 배너를 숨깁니다.
- feature chip은 Wrap 기반이라 좁은 폭 대응이 비교적 안전합니다.

근거: `lib/app/pages/home/home_page.dart:191`, `lib/app/pages/home/home_page.dart:212`, `lib/app/pages/home/home_page.dart:384`, `lib/app/pages/home/home_page.dart:459`

### Draw

- 상단 툴바는 horizontal scroll로 overflow 위험을 낮췄습니다.
- 빈 캔버스에서는 clear/save/artwork/share를 disabled 처리합니다.
- 브러시/색상/커스텀 컬러/캔버스 색상/사진 참조/저장/공유가 한 화면에서 접근됩니다.
- 브러시 가이드는 설정값 변경 즉시 반영됩니다.

근거: `lib/app/pages/draw/draw_page.dart:340`, `lib/app/pages/draw/draw_page.dart:410`, `lib/app/pages/draw/draw_page.dart:424`, `lib/app/pages/draw/draw_page.dart:441`, `lib/app/pages/draw/draw_page.dart:849`

### Gallery

- 빈 상태, 2열 그리드, 100개 초과 경고, 다중 선택 액션바가 있습니다.
- 저장 작품을 열기 전 현재 캔버스에 작업물이 있으면 확인 다이얼로그를 띄웁니다.
- 썸네일 파일이 깨졌거나 없을 때 fallback 아이콘을 보여줍니다.
- 삭제 확인 버튼 문구만 `clear` 대신 삭제 전용 키로 바꾸는 것이 좋습니다.

근거: `lib/app/pages/gallery/gallery_page.dart:79`, `lib/app/pages/gallery/gallery_page.dart:88`, `lib/app/pages/gallery/gallery_page.dart:132`, `lib/app/pages/gallery/gallery_page.dart:376`, `lib/app/pages/gallery/gallery_page.dart:557`

### Settings

- 설정은 그리기 옵션, 데이터/지원 옵션으로 구분되어 있고, 긴 문자열은 `maxLines`/ellipsis 처리가 많습니다.
- 언어 선택은 `Wrap + ChoiceChip` 구조라 좁은 폭에서 줄바꿈됩니다.
- 설정 초기화 문구는 "사용 기록 삭제"가 아니라 "설정 초기화"에 맞춰져 있어 실제 동작과 맞습니다.

근거: `lib/app/pages/settings/settings_page.dart:97`, `lib/app/pages/settings/settings_page.dart:123`, `lib/app/pages/settings/settings_page.dart:181`, `lib/app/pages/settings/settings_page.dart:245`, `test/app/pages/settings/settings_page_test.dart`

### Premium

- 3개 후원 옵션은 기능 차이가 없는 모델과 UI가 일치합니다.
- loading 중 구매/복원 버튼 disabled 상태가 있습니다.
- Premium active 상태는 광고 매니저/배너 guard로 중복 방어됩니다.

근거: `lib/app/pages/premium/premium_page.dart:77`, `lib/app/pages/premium/premium_page.dart:404`, `lib/app/pages/premium/premium_page.dart:437`, `lib/app/services/purchase_service.dart:370`

## 6. 다국어 처리 점검

판단: **기능적 구조는 양호**

- 지원 locale은 `en`, `ko`, `ja`, `de`, `ru`, `fr`, `es`, `pt`, `id`, `zh`, `ar` 총 11개입니다.
- `GetMaterialApp`에 `supportedLocales`, Flutter localization delegates, `Languages()` translations, `fallbackLocale: Locale('en')`이 설정되어 있습니다.
- `SettingController`는 지원하지 않는 언어 코드를 `en`으로 정규화하고 저장합니다.
- `translate_consistency_test.dart`가 모든 언어의 키셋이 `en`과 동일한지 확인합니다.
- `rg`로 화면/컨트롤러/서비스의 직접 하드코딩 visible string 패턴을 확인했으며, 번역 키 없는 명백한 `Text('...')` 노출은 발견하지 못했습니다.

근거:

- `lib/app/translate/translate.dart:5`
- `lib/main.dart:170`
- `lib/main.dart:176`
- `lib/main.dart:178`
- `lib/app/controllers/setting_controller.dart:145`
- `lib/app/controllers/setting_controller.dart:207`
- `test/translate_consistency_test.dart`

남은 한계:

- 아랍어 RTL 실제 화면 배치, 긴 독일어/러시아어 문자열의 실제 기기 overflow는 자동 테스트만으로 충분히 보장하기 어렵습니다.
- 최종 출시 전 최소 폭 Android 기기와 RTL locale에서 Home/Draw/Gallery/Settings/Premium을 직접 확인해야 합니다.

## 7. 광고/Premium 점검

판단: **구조는 양호, 운영 값은 출시 전 재확인 필요**

- release 광고 단위 ID는 `--dart-define` 기반이고, 비어 있으면 로드를 건너뜁니다.
- UMP consent와 MobileAds 초기화 이후 `canRequestAds`가 true가 됩니다.
- Premium 상태는 storage cache를 onInit에서 먼저 prime하고, 광고 매니저 삭제/재등록과 각 광고 로드 guard로 이중 방어합니다.
- 배너, 전면, 보상형 광고 모두 Premium active 상태에서 로드를 피합니다.
- Play product ID는 3개 후원 tier로 정리되어 있고 테스트가 있습니다.

근거:

- `lib/app/admob/ads_helper.dart:10`
- `lib/app/admob/ads_helper.dart:53`
- `lib/app/admob/ads_interstitial.dart:32`
- `lib/app/admob/ads_rewarded.dart:33`
- `lib/app/admob/ads_banner.dart:111`
- `lib/app/services/purchase_service.dart:25`
- `lib/app/services/purchase_service.dart:53`
- `lib/app/services/purchase_service.dart:370`
- `test/app/admob/ads_loading_test.dart`
- `test/app/services/purchase_service_test.dart`

출시 전 확인:

- `DOODLE_PAD_ADMOB_BANNER_ANDROID`, `DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID`, `DOODLE_PAD_ADMOB_REWARDED_ANDROID` 운영 값 주입
- Play Console managed product 3개와 `PurchaseConstants` 일치
- 라이선스 테스터로 구매/복원/광고 제거/Premium 브러시 즉시 접근 확인

## 8. Android/배포 설정 점검

판단: **Android 우선 출시 기준으로 대체로 정리됨**

- namespace/applicationId는 `com.dangundad.doodlepad`입니다.
- minSdk는 최소 24, targetSdk는 최소 36입니다.
- release signing key가 없으면 debug key로 release signing하지 않고 실패하도록 되어 있습니다.
- release minify/shrink resources가 활성화되어 있습니다.
- 권한은 광고 ID, 인터넷, 결제, 진동 중심입니다.
- AdMob App ID는 manifest에 존재합니다.

근거:

- `android/app/build.gradle.kts:36`
- `android/app/build.gradle.kts:51`
- `android/app/build.gradle.kts:52`
- `android/app/build.gradle.kts:53`
- `android/app/build.gradle.kts:72`
- `android/app/src/main/AndroidManifest.xml:4`
- `android/app/src/main/AndroidManifest.xml:27`

주의:

- `RateMyAppConfig.APP_STORE_ID`는 iOS placeholder `0000000000`입니다. Android 우선 프로젝트라 차단은 아니지만, iOS 출시를 열 때는 반드시 교체해야 합니다.

## 9. 문서/스토어 설명 점검

판단: **대부분 현재 기능과 동기화됨, 저장 해상도 표현만 재확인 필요**

- README는 10종 브러시, 앱 내 작품 보관함, 참조 사진 앱 내부 복사, Premium 3단계 후원 모델을 설명합니다.
- `docs/store/google-ads-subscription.md`, `docs/store/google-store-image.md`, `docs/store/google-store.md`도 갤러리/광고/Premium 설명이 현재 코드와 대체로 맞습니다.
- 단, 앞서 지적한 해상도 선택 UI가 실제로 숨겨져 있으므로, 1x/2x/3x 선택 표현은 코드 또는 문서 중 하나에 맞춰야 합니다.

근거:

- `README.md:3`
- `README.md:25`
- `README.md:31`
- `README.md:101`
- `docs/store/google-ads-subscription.md:16`
- `docs/store/google-store.md:30`

## 10. 출시 전 체크리스트

- [ ] `SaveOptionsSheet`에 1x/2x/3x 해상도 선택 UI를 복구하거나, 문서/문구에서 해상도 선택 표현 제거
- [ ] 갤러리 삭제 확인 버튼을 `clear`가 아닌 삭제 전용 번역 키로 변경
- [ ] 설정 언어 옵션과 `Languages.supportedLocales` 키셋 일치 테스트 추가
- [ ] 최소 폭 Android 기기에서 Home/Draw/Gallery/Settings/Premium 긴 문자열 확인
- [ ] `ar` locale에서 RTL 방향, ChoiceChip wrap, Premium CTA, Gallery action bar 확인
- [ ] 실제 기기에서 image_picker, Gal 저장, Share sheet, 참조 사진 재오픈 확인
- [ ] AdMob 운영 ID `--dart-define` 주입 상태 확인
- [ ] Play Console 상품 ID와 앱 내 `PurchaseConstants` 일치 확인
- [ ] 라이선스 테스터로 구매/복원/광고 제거/Premium 브러시 접근 확인
- [ ] release minify 환경에서 광고/결제/공유/이미지 저장 smoke test

## 11. 최종 판단

현재 Doodle Pad는 코드/테스트 기준으로 **핵심 로직, 설정 옵션, UI/UX, 다국어 처리 모두 출시 후보 수준**입니다. 이전 리뷰에서 차단급이었던 shake binding, gallery test hang, JPEG 가짜 인코딩, Premium 광고 race, 참조 사진 영속 복사, 작품 저장 중복 클릭 문제는 현재 코드에서 정리되어 있습니다.

남은 핵심은 기능 안정성보다 **사용자에게 말하는 내용과 실제 UI의 일치**입니다. 특히 저장 해상도 선택은 코드/문구/스토어 문서 중 어느 쪽을 제품 의도로 삼을지 결정해 맞추면 됩니다. 그 다음 실제 기기 QA와 Play Console 운영 값 검증을 통과하면 1.0.0 배포 준비 상태로 판단할 수 있습니다.
