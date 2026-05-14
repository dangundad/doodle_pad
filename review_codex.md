# Doodle Pad 배포 전 최종 코드 리뷰

검토일: 2026-05-14  
검토 기준: 현재 `C:\Github_WorkSpace\doodle_pad` working tree의 실제 코드, 설정, 문서, 테스트 결과  
검토 범위: `lib/`, `test/`, `android/`, `pubspec.yaml`, `README.md`, `docs/store/*`

## 1. 결론

코드는 드로잉, 공유, 갤러리 저장, 앱 내 작품 보관, 광고/Premium, 설정 흐름까지 MVP 출시 범위에 꽤 가까워졌다. `flutter analyze`는 통과했고, 갤러리 페이지 테스트 1개를 제외한 나머지 테스트 75개는 통과했다.

다만 배포 전 차단에 가까운 항목이 남아 있다.

1. `shake_to_clear` 설정은 현재 프로덕션 바인딩 순서상 동작하지 않을 가능성이 높다.
2. 전체 `flutter test`가 완료되지 않고 `gallery_page_test.dart`의 두 번째 케이스에서 hang이 재현된다.
3. `JPEG` 저장 옵션은 UI에는 노출되지만 실제 인코딩은 PNG bytes로 수행된다.
4. README/스토어 문서가 현재 코드의 갤러리/작품 저장 기능과 서로 어긋난다.

## 2. 검증 결과

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| 정적 분석 | 통과 | `flutter analyze` -> `No issues found! (ran in 17.9s)` |
| 전체 테스트 | 실패/미완료 | `flutter test` -> 904초 제한에서 timeout |
| 갤러리 빈 상태 테스트 | 통과 | `flutter test test/app/pages/gallery/gallery_page_test.dart --plain-name "빈 작품함" --reporter expanded` |
| 갤러리 그리드 테스트 | timeout | `flutter test test/app/pages/gallery/gallery_page_test.dart --plain-name "작품이 있으면" --reporter expanded` -> 124초 제한 timeout |
| 갤러리 페이지 테스트 제외 전체 | 통과 | `flutter test @tests --reporter expanded` (`gallery_page_test.dart` 제외) -> `All tests passed!`, 75개 |
| 릴리스 빌드 | 미실행 | 프로젝트 규칙상 별도 요청 없이 `flutter build apk`/`flutter build ios` 금지 |
| 작업 트리 | 깨끗하지 않음 | `.bkit/*`, `test/app/pages/gallery/gallery_page_test.dart` 변경 존재 |

타임아웃 후 남은 `doodle_pad` 관련 `flutter test` 프로세스는 검증 재시도를 위해 정리했다. 다른 저장소/VS Code 관련 프로세스는 건드리지 않았다.

## 3. 프롬프트 대비 산출물 체크리스트

| 요청 | 반영 위치 | 실제 근거 |
| --- | --- | --- |
| 핵심 로직 위주 최종 점검 | 4장, 6장 | `DoodleController`, `CanvasPainter`, `ArtworkRepository`, `ExportService`, `PurchaseService`, `AdHelper` |
| 사용성 문제 검토 | 5장, 6장 | Home/Draw/Gallery/Settings/Premium 화면 흐름 |
| 설정 옵션 검토 | 4.1, 5.3 | `SettingController`, `SettingsPage`, `DoodleController._bindShakeToClearSetting` |
| 배포 전 설정 검토 | 6장 | Android manifest, Gradle, AdMob dart-define, IAP 상품 ID |
| 문서 작성 | 본 문서 | `review_codex.md` 최신화 |

## 4. 주요 이슈

### P0. `shake_to_clear` 설정이 실제 앱에서 바인딩되지 않을 가능성이 높음

`DoodleController._bindShakeToClearSetting()`은 `SettingController`가 등록되어 있지 않으면 바로 return한다. 그런데 `AppBinding._ensureDependencyServices()`는 `DoodleController`를 먼저 등록하고 `SettingController`를 나중에 등록한다.

결과적으로 실제 앱 초기화 경로에서는 `ever(settings.shakeToClearEnabled, ...)`가 등록되지 않아, 설정 화면에서 `Shake to clear`를 켜도 가속도계 구독이 시작되지 않을 수 있다.

근거:

- `lib/app/controllers/doodle_controller.dart:202`
- `lib/app/controllers/doodle_controller.dart:203`
- `lib/app/controllers/doodle_controller.dart:208`
- `lib/app/bindings/app_binding.dart:79`
- `lib/app/bindings/app_binding.dart:84`
- `lib/app/pages/settings/settings_page.dart:97`

권장:

- `SettingController`를 `DoodleController`보다 먼저 등록한다.
- 또는 `DoodleController`에서 `SettingController` 준비 이후 바인딩을 재시도한다.
- 이 회귀를 `AppBinding` 통합 테스트로 고정한다.

### P0. 전체 테스트가 갤러리 페이지 테스트에서 완료되지 않음

전체 `flutter test`가 timeout됐고, 단독 재현 결과 `test/app/pages/gallery/gallery_page_test.dart`의 두 번째 테스트가 멈춘다. 현재 변경된 테스트는 `thumbnailPath=null`로 `Image.file` 디코딩 hang을 피하려는 의도지만, `pumpAndSettle()`이 여전히 settle되지 않는다.

근거:

- `test/app/pages/gallery/gallery_page_test.dart:89`
- `test/app/pages/gallery/gallery_page_test.dart:94`
- `test/app/pages/gallery/gallery_page_test.dart:96`

권장:

- 두 번째 테스트의 `pumpAndSettle()`을 필요한 최소 `pump()`로 바꾸거나, settle되지 않는 애니메이션/스크롤 가능 위젯 원인을 확인한다.
- 전체 `flutter test`가 시간 제한 없이 정상 종료되는 상태를 배포 게이트로 둔다.

### P1. `JPEG` 저장 옵션이 실제 JPEG 인코딩을 하지 않음

저장 시트는 PNG/JPEG를 선택하게 하지만, `ExportService._encode()`는 포맷과 무관하게 `ui.ImageByteFormat.png`로만 bytes를 만든다. 파일명만 `.jpg`로 바뀌는 구조라 사용자가 JPEG를 선택해도 실제 데이터는 PNG일 가능성이 높다.

근거:

- `lib/app/pages/draw/widgets/save_options_sheet.dart:182`
- `lib/app/pages/draw/widgets/save_options_sheet.dart:189`
- `lib/app/pages/draw/draw_page.dart:451`
- `lib/app/services/export_service.dart:144`
- `lib/app/services/export_service.dart:149`
- `lib/app/services/export_service.dart:163`

권장:

- 출시 전에는 JPEG 옵션을 제거하고 PNG만 제공한다.
- JPEG를 유지하려면 `image` 패키지 등으로 실제 JPEG 인코딩을 추가하고 저장 결과를 기기에서 확인한다.

### P1. Premium 캐시 상태와 광고 매니저 등록 순서가 어긋남

`PurchaseService`는 저장된 Premium 상태를 먼저 읽고 Premium이면 광고 매니저 삭제를 시도한다. 하지만 `AppBinding`에서는 그 시점에 `InterstitialAdManager`/`RewardedAdManager`가 아직 등록되지 않았고, 이후 `_ensureDependencyServices()`가 두 매니저를 무조건 등록한다.

Store 조회가 늦거나 불가능한 경우, Premium 캐시가 true여도 전면/보상형 광고 매니저가 백그라운드에서 로드될 수 있다. 배너는 위젯에서 Premium guard가 강하지만, 매니저 레벨에서도 Premium guard를 맞추는 편이 안전하다.

근거:

- `lib/app/services/purchase_service.dart:275`
- `lib/app/services/purchase_service.dart:283`
- `lib/app/services/purchase_service.dart:356`
- `lib/app/services/purchase_service.dart:368`
- `lib/app/bindings/app_binding.dart:68`
- `lib/app/bindings/app_binding.dart:88`
- `lib/app/admob/ads_rewarded.dart:31`
- `lib/app/admob/ads_interstitial.dart:32`

권장:

- 광고 매니저 등록 시 `PurchaseService.isPremiumActive`를 확인한다.
- 광고 매니저의 `loadAd()` 진입부에도 Premium guard를 둔다.
- Premium 캐시 true + Store unavailable 케이스를 테스트로 추가한다.

### P1. 저장 작품의 참조 이미지는 영속 복사되지 않음

앱 내 작품 저장은 strokes, canvas color, thumbnail, reference image path를 저장한다. 하지만 가져온 사진 파일 자체를 앱 support directory로 복사하지 않는다. 원본 파일이 이동/삭제되거나 picker cache가 정리되면 저장 작품을 다시 열 때 배경 사진은 사라지고 stroke만 남을 수 있다.

썸네일은 저장 당시 캡처본이라 갤러리 목록에서는 정상처럼 보일 수 있어, 사용자가 열었을 때 손실로 느낄 수 있다.

근거:

- `lib/app/controllers/doodle_controller.dart:558`
- `lib/app/controllers/doodle_controller.dart:567`
- `lib/app/controllers/doodle_controller.dart:751`
- `lib/app/controllers/doodle_controller.dart:759`
- `lib/app/controllers/doodle_controller.dart:793`
- `lib/app/pages/draw/draw_page.dart:188`
- `lib/app/pages/draw/draw_page.dart:196`
- `lib/app/services/artwork_repository.dart:50`
- `lib/app/services/artwork_repository.dart:70`

권장:

- 작품 저장 시 참조 이미지를 app support directory로 복사하고, 삭제 시 함께 정리한다.
- 복사하지 않는 정책이면 UI/문서에서 “참조 사진은 원본에 의존”한다고 명확히 안내한다.

### P1. 문서와 실제 기능이 서로 충돌함

코드에는 `GalleryPage`, `ArtworkRepository`, `Drawing` Hive model, 앱 내 작품 저장/불러오기가 존재한다. 하지만 README와 스토어 문서는 여전히 “앱 내 저장 갤러리 없음”, “영구 저장하지 않음”, “gallery/history/stats 없음”을 말한다.

반대로 스토어 스크린샷 문서에는 아직 없는 `history/stats`, 하단 내비게이션, 상세 통계 혜택, `5종 브러시` 표현도 남아 있다.

근거:

- `README.md:3`
- `README.md:11`
- `README.md:30`
- `README.md:94`
- `lib/app/routes/app_routes.dart:12`
- `lib/app/pages/gallery/gallery_page.dart:16`
- `lib/app/services/artwork_repository.dart:13`
- `docs/store/google-store-image.md:8`
- `docs/store/google-store-image.md:75`
- `docs/store/google-store-image.md:99`
- `docs/store/google-store-image.md:117`
- `docs/store/google-ads-subscription.md:17`
- `docs/store/google-ads-subscription.md:61`
- `docs/store/google-ads-subscription.md:121`

권장:

- README를 현재 앱 내 작품 저장/갤러리 기준으로 갱신한다.
- 스토어 문서에서 `history`, `stats`, 하단 내비게이션, 상세 통계 혜택을 제거한다.
- `5종 브러시` 표현을 `10종 브러시`로 통일한다.

### P2. 작품 저장 버튼에 중복 실행 guard가 없음

`bookmarkPlus` 버튼은 `ctrl.saveAsArtwork()`를 호출하지만 await/loading guard가 없다. 사용자가 빠르게 여러 번 누르면 캡처/파일쓰기/Hive put이 중복 실행될 수 있다. ID는 millisecond timestamp 기반이라 실제 충돌 가능성은 낮지만, 중복 저장 UX는 발생할 수 있다.

근거:

- `lib/app/pages/draw/draw_page.dart:397`
- `lib/app/pages/draw/draw_page.dart:402`
- `lib/app/controllers/doodle_controller.dart:751`

권장:

- `isSavingArtwork` RxBool로 버튼 disabled/loading 상태를 둔다.
- ID는 timestamp만 쓰기보다 UUID 또는 timestamp+random suffix를 사용한다.

### P2. iOS placeholder와 미사용 전면 광고 매니저

Android 우선 프로젝트라 출시 차단은 아니지만, `APP_STORE_ID = '0000000000'`와 미사용 `InterstitialAdManager`는 배포 문서에서 명확히 처리하는 편이 좋다.

근거:

- `lib/app/utils/app_constants.dart:55`
- `lib/app/admob/ads_interstitial.dart:84`

## 5. 핵심 로직 리뷰

### 5.1 드로잉/브러시

좋은 점:

- `BrushPresets` registry로 10종 브러시 정의를 모아 확장 지점이 명확하다.
- undo/redo는 stroke 단위이며 redo stack은 새 stroke 시작 시 비워진다.
- 지우개가 있을 때만 `saveLayer`를 사용해 렌더링 비용을 제한한다.
- airbrush/crayon 계열은 stroke seed를 저장해 repaint flicker를 줄인다.
- 빈 캔버스에서 clear/share/save 버튼은 disabled 처리된다.

주의:

- `BrushType` 저장은 enum index 기반이다. 향후 enum 순서를 바꾸면 저장된 작품의 브러시가 다르게 해석될 수 있다.
- pinch zoom과 drawing gesture가 같은 영역에 있으므로 실제 기기에서 두 손가락 줌 중 accidental stroke가 없는지 QA가 필요하다.

근거:

- `lib/app/controllers/doodle_controller.dart:30`
- `lib/app/controllers/doodle_controller.dart:69`
- `lib/app/controllers/doodle_controller.dart:358`
- `lib/app/controllers/doodle_controller.dart:524`
- `lib/app/pages/draw/widgets/canvas_painter.dart:19`
- `lib/app/pages/draw/draw_page.dart:143`

### 5.2 저장/공유/갤러리

좋은 점:

- `shareCanvas()`는 무효 참조 이미지 path를 먼저 정리하고 빈 컨텐츠를 방어한다.
- 공유용 임시 파일은 stale cleanup을 수행하고, 성공 직후 삭제하지 않아 share sheet 참조 문제를 피한다.
- 갤러리 저장은 `ExportService`, 앱 내 작품 저장은 `ArtworkRepository`로 IO 책임이 분리되어 있다.
- 작품 삭제 시 썸네일 파일도 함께 삭제한다.
- 갤러리 목록은 최신순 정렬과 100개 초과 경고 banner가 있다.

주의:

- `JPEG` 옵션은 앞서 언급한 대로 실제 JPEG가 아니다.
- 참조 사진 영속 복사 정책이 없다.
- 갤러리 그리드 테스트가 현재 전체 테스트를 막는다.

근거:

- `lib/app/controllers/doodle_controller.dart:603`
- `lib/app/controllers/doodle_controller.dart:646`
- `lib/app/controllers/doodle_controller.dart:672`
- `lib/app/controllers/doodle_controller.dart:703`
- `lib/app/services/artwork_repository.dart:46`
- `lib/app/services/artwork_repository.dart:80`
- `lib/app/services/artwork_repository.dart:90`
- `lib/app/controllers/gallery_controller.dart:14`

### 5.3 설정 옵션

| 옵션 | 현재 상태 | 판단 |
| --- | --- | --- |
| 햅틱 피드백 | Hive 저장, 도구 상호작용에 사용 | 적절함 |
| 브러시 가이드 | Draw 하단 가이드 표시 토글 | 적절함 |
| 지우기 전 확인 | clear dialog 우회 가능 | 적절함 |
| 흔들어 지우기 | UI/저장 로직은 있으나 바인딩 순서 문제 | 출시 전 수정 필요 |
| 언어 | 11개 locale, unsupported code는 `en` fallback | 적절함 |
| 저장 해상도/포맷 | 마지막 선택 저장 | JPEG 인코딩 불일치 수정 필요 |
| 설정 초기화 | 설정/드로잉 preference reset, Premium/해금 유지 | 정책은 적절하나 문구는 “설정 초기화”로 유지 필요 |

근거:

- `lib/app/controllers/setting_controller.dart:45`
- `lib/app/controllers/setting_controller.dart:48`
- `lib/app/controllers/setting_controller.dart:146`
- `lib/app/controllers/setting_controller.dart:176`
- `lib/app/controllers/setting_controller.dart:201`
- `lib/app/pages/settings/settings_page.dart:61`

### 5.4 광고/Premium

좋은 점:

- release 광고 단위 ID는 `--dart-define`으로 주입되어 테스트 ID가 release에 하드코딩되지 않는다.
- UMP consent 및 `MobileAds.initialize()` 완료 후 `canRequestAds`가 true가 된다.
- 배너는 Premium 상태에서 숨김 처리된다.
- 구매 실패/취소/loading 상태 처리와 restore 경로가 있다.
- Premium purchase 후 광고 매니저 삭제 흐름이 있다.

주의:

- Premium cached true 상태에서 광고 매니저 등록 순서 문제가 있다.
- 결제 검증은 클라이언트 `purchaseStream`/past purchases 기반이다. 후원형 MVP로는 가능하지만 서버 검증은 없다.
- `InterstitialAdManager`는 현재 사용자 동작에 연결되지 않는다.

근거:

- `lib/app/admob/ads_helper.dart:10`
- `lib/app/admob/ads_helper.dart:53`
- `lib/app/admob/ads_banner.dart:73`
- `lib/app/services/purchase_service.dart:138`
- `lib/app/services/purchase_service.dart:191`
- `lib/app/services/purchase_service.dart:290`

## 6. 화면별 사용성 리뷰

### Home

- `Start Drawing` CTA와 `My Artworks` 진입이 명확하다.
- 홈의 feature chip은 여전히 저장/갤러리/커스텀 컬러/사진 드로잉을 충분히 드러내지 않는다.
- README는 “갤러리 없음”이라고 하지만 실제 홈에는 `My Artworks` 카드가 있다.

근거:

- `lib/app/pages/home/home_page.dart:197`
- `lib/app/pages/home/home_page.dart:199`
- `lib/app/pages/home/home_page.dart:222`

### Draw

- 상단 툴바는 horizontal scroll로 바뀌어 이전 좁은 화면 overflow 리스크가 줄었다.
- save, artwork save, share가 모두 상단에 있어 기능 밀도는 높다.
- 빈 컨텐츠에서 주요 destructive/export action을 disable하는 점은 좋다.
- `Save to Gallery`와 `Save as artwork`가 둘 다 저장이라 초보 사용자에게 차이가 불명확할 수 있다. tooltip만으로 충분한지 실제 QA가 필요하다.

근거:

- `lib/app/pages/draw/draw_page.dart:300`
- `lib/app/pages/draw/draw_page.dart:377`
- `lib/app/pages/draw/draw_page.dart:390`
- `lib/app/pages/draw/draw_page.dart:407`

### Gallery

- 빈 상태, 2열 그리드, long press 삭제, 100개 초과 경고가 있다.
- 삭제 버튼 label이 `clear` 번역을 재사용한다. 의미상 “Delete”가 더 정확하다.
- 저장 작품을 열 때 현재 작업 중인 캔버스가 있으면 별도 확인 없이 `loadArtwork()`로 교체된다. 홈 진입에는 이어 그리기 확인이 있으므로, 갤러리 진입도 같은 손실 방어가 필요한지 검토할 만하다.

근거:

- `lib/app/pages/gallery/gallery_page.dart:41`
- `lib/app/pages/gallery/gallery_page.dart:46`
- `lib/app/pages/gallery/gallery_page.dart:77`
- `lib/app/pages/gallery/gallery_page.dart:84`
- `lib/app/pages/gallery/gallery_page.dart:157`

### Settings

- 현재 기능 범위에 맞게 간결하다.
- 언어 선택은 11개 ChoiceChip으로 노출되어 작은 화면/RTL에서 줄바꿈 QA가 필요하다.
- `Clear local data` fallback은 있지만 실제 번역은 “설정 초기화”에 가깝다. 갤러리 작품까지 삭제하지 않는 정책과 맞추려면 “설정 초기화” 표현을 유지하는 편이 안전하다.

근거:

- `lib/app/pages/settings/settings_page.dart:107`
- `lib/app/pages/settings/settings_page.dart:123`
- `lib/app/controllers/setting_controller.dart:213`

### Premium

- 세 후원 옵션의 기능 차이가 없다는 모델과 UI가 맞다.
- loading 중 구매/복원 버튼 disabled 처리가 있다.
- “상세 통계” 같은 실제 없는 혜택은 코드에는 없고, 문서에만 남아 있다.

근거:

- `lib/app/controllers/premium_controller.dart:33`
- `lib/app/pages/premium/premium_page.dart:37`
- `lib/app/pages/premium/premium_page.dart:404`

## 7. Android/배포 설정 리뷰

현재 확인:

- package/applicationId/namespace: `com.dangundad.doodlepad`
- version: `1.0.0+1`
- minSdk: 최소 24
- targetSdk: 최소 36
- release signing key가 없으면 release build 실패
- release minify/shrink resources 활성화
- 권한: `AD_ID`, `INTERNET`, `BILLING`, `VIBRATE`
- AdMob App ID는 manifest에 하드코딩

근거:

- `android/app/build.gradle.kts:36`
- `android/app/build.gradle.kts:51`
- `android/app/build.gradle.kts:52`
- `android/app/build.gradle.kts:53`
- `android/app/build.gradle.kts:72`
- `android/app/src/main/AndroidManifest.xml:4`
- `android/app/src/main/AndroidManifest.xml:27`

출시 전 확인:

- manifest AdMob App ID가 운영 앱 ID와 일치하는지 확인.
- `DOODLE_PAD_ADMOB_BANNER_ANDROID`, `DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID`, `DOODLE_PAD_ADMOB_REWARDED_ANDROID` release 주입 확인.
- Play Console managed product 3개가 `PurchaseConstants`와 일치하는지 확인.
- minify 환경에서 광고/구매/공유/image picker/gal 저장 실제 기기 테스트.
- 개인정보 처리방침과 Play Data Safety를 갤러리 저장/사진 참조/광고/결제/Firebase 사용 범위에 맞게 갱신.

## 8. 좋은 점

- Firebase 실패와 core service 실패를 분리해 startup blank screen 위험을 줄였다.
- 드로잉 컨트롤러와 영속화 repository, export service의 책임 분리가 명확하다.
- 광고 요청은 UMP/MobileAds 준비 후 시작하는 guard가 있다.
- Premium 구매/복원, 광고 제거, 보상형 해금이 한 흐름으로 연결되어 있다.
- 앱 내 작품 저장/삭제와 썸네일 파일 정리가 생겨 제품 완성도가 올라갔다.
- 대부분의 컨트롤러/서비스/주요 위젯 테스트가 존재하고, 갤러리 테스트를 제외하면 75개가 통과한다.

## 9. 출시 전 우선순위 체크리스트

- [ ] `SettingController`/`DoodleController` 등록 순서 또는 바인딩 로직 수정.
- [ ] `shake_to_clear` 실제 동작을 테스트로 고정.
- [ ] `gallery_page_test.dart` hang 원인 수정 후 전체 `flutter test` 통과 확인.
- [ ] JPEG 옵션 제거 또는 실제 JPEG 인코딩 구현.
- [ ] Premium cached true 상태에서 광고 매니저가 등록/로드되지 않는지 수정 및 테스트.
- [ ] 참조 이미지가 포함된 작품 저장/재오픈 정책 결정: 이미지 복사 또는 사용자 안내.
- [ ] README, `docs/store/google-store-image.md`, `docs/store/google-ads-subscription.md`를 현재 기능 기준으로 갱신.
- [ ] Android 13/14/15 실제 기기에서 사진 선택, 갤러리 저장, 작품 저장/열기/삭제, 공유 확인.
- [ ] 라이선스 테스터로 Premium 구매/복원, 광고 제거, Premium 브러시 즉시 접근 확인.
- [ ] release dart-define 포함/미포함 상태에서 광고 동작 확인.
- [ ] RTL/긴 문자열/작은 화면에서 Home, Draw, Gallery, Settings, Premium 확인.

## 10. 최종 판단

현재 상태는 “조건부 출시 후보”다. 핵심 드로잉 기능과 저장/공유/갤러리 구조는 제품으로 보이지만, 설정 옵션 1개가 실제 동작하지 않을 가능성이 높고 전체 테스트가 완료되지 않는다.

배포 전 최소 기준은 다음이다.

1. `flutter analyze` 통과 유지.
2. 전체 `flutter test` 정상 종료.
3. `shake_to_clear`, JPEG 저장 옵션, Premium 광고 매니저 순서 문제 정리.
4. README/스토어 문서를 실제 기능 기준으로 정리.

이 네 가지를 끝내면 Doodle Pad는 “빠르게 그리고, 저장하고, 다시 열고, 공유하는 캐주얼 드로잉 앱”으로 더 정직하게 출시할 수 있다.
