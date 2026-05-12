# Doodle Pad 배포 전 최종 리뷰

검토일: 2026-05-12  
검토 기준: 현재 working tree의 실제 코드, 설정, 문서, 테스트 결과  
검토 범위: `lib/`, `test/`, `android/`, `pubspec.yaml`, `README.md`, `docs/TODO.md`, `docs/store/*`

## 1. 한 줄 결론

앱 코드는 "빠르게 그리고 바로 공유하는 캐주얼 드로잉 앱"으로 출시 후보 수준에 가깝다. `flutter analyze`와 `flutter test`는 통과했고, 드로잉/공유/사진 참조/광고 해금/Premium/설정 흐름도 주요 방어 로직이 있다.

다만 Play 등록용 스크린샷 가이드와 일부 스토어 문서가 아직 앱에 없는 저장 갤러리, 기록, 통계 기능을 설명한다. 출시 전 가장 먼저 정리해야 할 리스크는 코드보다 스토어 자산의 기능 불일치다.

## 2. 검증 결과

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| 정적 분석 | 통과 | `flutter analyze` -> `No issues found! (ran in 24.7s)` |
| 테스트 | 통과 | `flutter test` -> `All tests passed!`, 총 42개 테스트 |
| 릴리스 빌드 | 미실행 | 프로젝트 규칙상 별도 요청 없이 `flutter build apk`/`flutter build ios` 실행 금지 |
| 작업 트리 | 깨끗하지 않음 | `.bkit/*`, `pubspec.yaml`, `pubspec.lock` 변경 상태 확인 |
| 화면 라우트 | 4개 | `/home`, `/draw`, `/settings`, `/premium` |

현재 변경 상태에는 Firebase 패키지 버전 업데이트가 포함되어 있다. 리뷰는 이 working tree 기준으로 진행했으며, 배포 커밋 전에는 `.bkit/*` 변경과 `pubspec.*` 변경이 의도된 범위인지 따로 확인해야 한다.

## 3. 프롬프트 대비 산출물 체크리스트

| 요청 | 문서 반영 위치 | 실제 근거 |
| --- | --- | --- |
| 핵심 로직 최종 점검 | 4장, 8장 | `DoodleController`, `CanvasPainter`, `PurchaseService`, `AdHelper` |
| 설정 옵션 점검 | 5장 | `SettingController`, `SettingsPage`, Hive box |
| 각 화면 UI/UX 점검 | 6장 | `HomePage`, `DrawPage`, `SettingsPage`, `PremiumPage`, `ExitBottomSheet` |
| 배포 전 설정 확인 | 7장, 8장, 10장 | Android manifest, Gradle, AdMob dart-define, IAP 상품 ID |
| `review_codex.md` 작성 | 본 문서 | `review_codex.md` 갱신 완료 |

## 4. 핵심 로직 리뷰

### 4.1 드로잉 상태와 브러시

현재 드로잉 상태는 `DoodleController`가 단일 source of truth다.

- 브러시 타입은 `BrushType` enum 10종이다: 펜, 연필, 마커, 붓, 형광펜, 만년필, 크레파스, 수채화, 에어브러시, 지우개.
- 실제 브러시 정의는 `BrushPresets` registry에 모여 있고, 지우개만 `CanvasPainter`에서 별도 처리한다.
- Undo/Redo는 stroke 단위이며 redo stack은 새 stroke 시작 시 초기화된다.
- Undo는 최대 20단계다.
- point 간 최소 거리 필터가 있어 작은 움직임으로 인한 repaint 낭비를 줄인다.
- 수채화/에어브러시는 `BrushLock`으로 잠금 처리되고, 보상형 광고 또는 Premium 상태로 접근한다.

좋은 점:

- 브러시 확장 지점이 `BrushPresets`로 정리되어 있다.
- 에어브러시와 크레파스 grain은 stroke seed를 고정해 repaint flicker를 줄인다.
- 지우개가 있는 경우에만 `saveLayer`를 사용해 비용을 제한한다.
- `hasDrawableContent`가 stroke뿐 아니라 참조 이미지 단독 상태도 포함한다.

남은 리스크:

- stroke 자체는 메모리 상에만 존재한다. 앱 종료, 프로세스 kill, OS 회수 후 복원은 없다. 현재 제품 컨셉상 의도된 선택이지만, 스토어 문구에서 "영구 저장 없음"을 계속 명확히 해야 한다.
- `DrawPage`와 `CanvasPainter`의 직접 위젯/렌더링 테스트가 없다. 현재 테스트는 컨트롤러와 일부 페이지 흐름 중심이다.

근거:

- `lib/app/controllers/doodle_controller.dart:21`
- `lib/app/controllers/doodle_controller.dart:60`
- `lib/app/controllers/doodle_controller.dart:160`
- `lib/app/controllers/doodle_controller.dart:346`
- `lib/app/data/brushes/brush_presets.dart:13`
- `lib/app/data/brushes/brush_presets.dart:114`
- `lib/app/pages/draw/widgets/canvas_painter.dart`

### 4.2 사진 참조와 공유

사진 기반 드로잉은 현재 실제 UI 진입점까지 연결되어 있다.

- 그리기 상단 툴바의 image 버튼에서 `pickReferenceImage()` 호출.
- `ImagePicker`로 갤러리 이미지를 선택하고, `Image.file`을 캔버스 배경 위에 표시.
- 파일이 사라진 경우 `errorBuilder`와 `shareCanvas()`에서 참조 상태를 정리한다.
- 공유는 `RepaintBoundary`를 PNG로 캡처한 뒤 `share_plus`로 Android share sheet에 전달한다.
- 캡처 pixel ratio는 약 8MP 예산으로 제한해 OOM 위험을 줄인다.

좋은 점:

- 참조 이미지 단독 상태도 공유 가능하게 처리되어 있다.
- 캡처 실패, byte 변환 실패, 빈 캔버스 공유는 토스트로 사용자 피드백을 준다.
- 공유 성공 시 임시 파일을 즉시 삭제하지 않아 공유 시트가 파일을 참조하는 동안 사라지는 문제를 피한다.

남은 리스크:

- 성공 공유 후 임시 파일 정리 정책은 없다. OS temp 정리에 맡기는 구조라 장기간 사용 시 캐시 누적 가능성이 있다.
- 사진 선택, 참조 이미지 삭제, 공유 결과를 실제 Android 13~15 기기에서 확인해야 한다.

근거:

- `lib/app/controllers/doodle_controller.dart:404`
- `lib/app/controllers/doodle_controller.dart:450`
- `lib/app/pages/draw/draw_page.dart:314`
- `lib/app/pages/draw/draw_page.dart:357`

### 4.3 광고와 Premium

광고/결제 구조는 무료 + 후원형 Premium 모델과 맞다.

- 광고 ID는 release에서 `String.fromEnvironment`로 주입한다.
- UMP 동의 후 `AdHelper.canRequestAds`가 true일 때만 광고 매니저가 로드한다.
- 배너는 홈 하단에 노출되고 Premium 상태에서는 숨김 처리된다.
- 보상형 광고는 수채화/에어브러시 해금에 사용된다.
- Premium 구매 시 광고 매니저를 `force: true`로 정리한다.
- Premium 상품은 Android managed product 3개다.

좋은 점:

- release 광고 ID가 비어 있으면 광고 요청을 건너뛰므로 잘못된 테스트 ID 노출을 피한다.
- 결제 UI 실행 실패(`buyNonConsumable == false`) 시 loading이 풀리도록 처리되어 있다.
- 복원 시 store purchase를 다시 조회해 stale premium cache를 정리한다.

남은 리스크:

- release 빌드에서 `--dart-define`이 빠지면 광고가 조용히 비활성화된다.
- Premium 권한 부여는 클라이언트 purchase stream / past purchases 기반이다. 서버에서 purchase token을 검증하는 구조는 없다.
- `InterstitialAdManager`는 등록되고 로드 로직도 있지만 현재 사용자 동작에서 호출되지 않는다. 정책/테스트 범위를 줄이려면 제거하거나 "미사용 준비 코드"로 명시하는 편이 낫다.

근거:

- `lib/app/admob/ads_helper.dart:10`
- `lib/app/admob/ads_helper.dart:53`
- `lib/app/admob/ads_banner.dart:76`
- `lib/app/controllers/doodle_controller.dart:330`
- `lib/app/services/purchase_service.dart:164`
- `lib/app/services/purchase_service.dart:256`
- `lib/app/services/purchase_service.dart:290`
- `lib/app/services/purchase_service.dart:356`
- `lib/app/admob/ads_interstitial.dart:84`

### 4.4 시작, 초기화, 장애 대응

- Firebase 초기화 실패는 앱 부팅 자체를 막지 않는다.
- Hive 등 core service 초기화 실패 시 `_StartupFailureScreen`으로 빈 화면 회귀를 막는다.
- release mode에서는 `debugPrint`를 비활성화한다.
- 세로 화면으로 고정하고 edge-to-edge UI를 사용한다.

이 구조는 출시 전 안정성 관점에서 좋다. 다만 Crashlytics가 Firebase 초기화 이후에만 연결되므로 Firebase 초기화 실패 자체는 debugPrint 외에는 원격 수집되지 않는다.

## 5. 설정 옵션 리뷰

| 옵션 | 현재 동작 | 판단 |
| --- | --- | --- |
| 햅틱 피드백 | `hapticEnabled`, 기본 true, 도구/버튼 상호작용에 사용 | 적절함 |
| 브러시 가이드 표시 | `showBrushGuide`, 기본 true, 하단 툴바 설명 표시 | 적절함 |
| 지우기 전 확인 | `askBeforeClear`, 기본 true, clear dialog 우회 가능 | 적절함 |
| 언어 | 11개 locale 선택, 미지원 코드는 `en` 폴백 | 적절함 |
| 로컬 데이터 초기화 | 설정 box 초기화 + 드로잉 선호값 초기화 | 적절함 |
| Premium/광고 해금 상태 | 초기화에서 의도적으로 보존 | 적절함 |
| 캔버스 배경색 | Draw 화면에서 6개 프리셋, Hive 저장 | 적절함 |
| 커스텀 브러시 색상 | Draw 화면에서 color picker, Hive 저장 | 적절함 |

주의할 점:

- `SettingController`는 `doodle_settings_v1` box를 쓰고, `DoodleController`의 캔버스/커스텀 색상은 `HiveService.settingsBox`에 저장된다. 의도된 분리로 보이지만, 유지보수자가 헷갈리지 않도록 문서에 남겨두는 것이 좋다.
- `SettingsPage`의 fallback 문구 중 `clear_data_desc`가 "usage history"를 언급한다. 실제 번역 key는 현재 "preferences" 기준이라 일반 사용자에게 보일 가능성은 낮지만, 코드 fallback도 현재 기능에 맞춰 바꾸는 편이 깔끔하다.

근거:

- `lib/app/controllers/setting_controller.dart:40`
- `lib/app/controllers/setting_controller.dart:81`
- `lib/app/controllers/setting_controller.dart:113`
- `lib/app/controllers/setting_controller.dart:140`
- `lib/app/pages/settings/settings_page.dart:69`
- `lib/app/pages/settings/settings_page.dart:99`
- `lib/app/pages/settings/settings_page.dart:119`

## 6. 화면별 UI/UX 리뷰

### 6.1 Home

현재 역할:

- 앱 이름, 주요 기능 칩, 시작 CTA.
- Premium / Settings 진입.
- Premium이 아니면 하단 배너 광고.
- 뒤로가기 시 종료 바텀시트.
- 작업 중인 그림이 있으면 "이어 그리기 / 새로 시작" 선택.

좋은 점:

- 메인 행동이 `Start Drawing` 하나로 명확하다.
- 저장 갤러리 없는 제품 컨셉과 잘 맞는 단순 홈이다.
- 이전 그림 보존 여부를 홈 진입에서 다시 물어 UX 손실을 줄인다.

주의할 점:

- 홈 기능 칩은 6개만 노출한다. 실제 기능 10종 브러시/사진 위 드로잉/배경색까지 충분히 보여주지는 않는다. 스토어 스크린샷에서 보완하는 것이 좋다.

근거:

- `lib/app/pages/home/home_page.dart:17`
- `lib/app/pages/home/home_page.dart:134`
- `lib/app/pages/home/home_page.dart:151`
- `lib/app/pages/home/home_page.dart:200`

### 6.2 Draw

현재 역할:

- 풀스크린 캔버스.
- 뒤로가기/Undo/Redo/배경색/사진 불러오기/지우기/공유 상단 툴바.
- 브러시 선택, 크기, 팔레트, 커스텀 컬러 하단 툴바.
- 작업물이 있을 때 이탈 확인.

좋은 점:

- 핵심 툴이 한 화면에 다 있고 조작 경로가 짧다.
- 브러시 selector와 색상 팔레트는 horizontal scroll로 처리되어 브러시 수 증가에 대응한다.
- 빈 캔버스에서는 clear/share 버튼이 disabled 상태가 된다.
- 지우기 전 확인과 화면 이탈 확인이 분리되어 있다.

중요 리스크:

- 상단 툴바는 `Row` 안에 `IconButton` 7개와 `Spacer`를 고정 배치한다. 320dp급 좁은 기기, 큰 display size, 일부 폴더블/분할 화면에서 overflow가 날 수 있다. 출시 전 실제 작은 폭 또는 widget test로 확인하고, 필요하면 가로 스크롤 또는 overflow menu로 바꾸는 것을 권장한다.

근거:

- `lib/app/pages/draw/draw_page.dart:18`
- `lib/app/pages/draw/draw_page.dart:119`
- `lib/app/pages/draw/draw_page.dart:259`
- `lib/app/pages/draw/draw_page.dart:277`
- `lib/app/pages/draw/draw_page.dart:345`
- `lib/app/pages/draw/draw_page.dart:624`
- `lib/app/pages/draw/draw_page.dart:929`

### 6.3 Settings

현재 역할:

- Premium 진입.
- 드로잉 옵션 3개와 언어 선택.
- 데이터 초기화, 피드백, 앱 평가, 더 많은 앱, 개인정보 처리방침.

좋은 점:

- 설정이 현재 제품 범위에 맞게 간결하다.
- 언어 선택은 11개 locale 모두 명시적으로 노출된다.
- 외부 링크 실패는 toast로 안내한다.

주의할 점:

- 11개 언어 ChoiceChip이 한 화면에 많이 노출되어 작은 기기에서는 섹션이 길다. ListView라 기능 문제는 아니지만, 실제 RTL/긴 문자열 QA가 필요하다.
- "Clear local data"는 Premium/해금 상태를 보존한다. 좋은 정책이지만 화면 문구에서도 "구매/해금은 유지"를 명확히 할지 검토할 만하다.

근거:

- `lib/app/pages/settings/settings_page.dart:14`
- `lib/app/pages/settings/settings_page.dart:69`
- `lib/app/pages/settings/settings_page.dart:99`
- `lib/app/pages/settings/settings_page.dart:118`
- `lib/app/controllers/setting_controller.dart:169`
- `lib/app/controllers/setting_controller.dart:182`

### 6.4 Premium

현재 역할:

- Small / Medium / Large 3개 후원 옵션.
- Medium 기본 선택.
- 광고 제거, Premium 브러시, 1회 후원 혜택 표시.
- 구매, 복원, 구매 완료 화면.

좋은 점:

- 세 상품의 기능 차이가 없고 후원 금액만 다르다는 모델과 UI가 맞다.
- loading 중 구매/복원 버튼을 비활성화한다.
- 이미 Premium이면 소유 화면으로 단순하게 전환한다.

주의할 점:

- 실제 Play Console 상품 가격/지역 가격이 query 결과로 잘 표시되는지 기기 테스트가 필요하다.
- 서버 검증이 없으므로, 고가 상품이나 구독형으로 확장할 계획이면 결제 검증 구조를 먼저 바꾸는 편이 맞다.

근거:

- `lib/app/controllers/premium_controller.dart`
- `lib/app/pages/premium/premium_page.dart:187`
- `lib/app/services/purchase_service.dart:191`

### 6.5 Exit / Startup

현재 역할:

- 홈 뒤로가기 시 종료 바텀시트.
- Premium이 아니면 Premium 안내 영역 표시.
- 초기화 실패 시 startup failure 화면 표시.

좋은 점:

- 앱 종료 실수를 줄인다.
- 초기화 실패 시 빈 화면 대신 복구 메시지를 보여준다.

주의할 점:

- 종료 바텀시트는 광고 네이티브 영역을 쓰지 않는다. 현재 광고 문서도 이 상태와 맞춰야 한다.

## 7. Android / 배포 설정 리뷰

현재 확인된 설정:

- package/applicationId: `com.dangundad.doodlepad`
- version: `1.0.0+1`
- namespace/applicationId 일치.
- minSdk는 최소 24 이상.
- targetSdk는 최소 36 이상.
- release build는 `android/key.properties` 없으면 실패하도록 되어 있어 debug key 릴리스 방지.
- release minify/shrink resources 활성화.
- AndroidManifest 권한: `AD_ID`, `INTERNET`, `BILLING`, `VIBRATE`.
- AdMob App ID가 manifest에 하드코딩되어 있음.

출시 전 필수 확인:

- `android/app/src/main/AndroidManifest.xml`의 AdMob App ID가 운영 앱 ID와 일치하는지 확인.
- `DOODLE_PAD_ADMOB_BANNER_ANDROID`, `DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID`, `DOODLE_PAD_ADMOB_REWARDED_ANDROID`를 release 빌드에 주입.
- Play Console managed product 3개가 `PurchaseConstants`와 정확히 일치하는지 확인.
- ProGuard/minify 환경에서 광고, 구매, 공유, image picker가 실제 기기에서 동작하는지 확인.
- 개인정보 처리방침 URL과 Play Data Safety를 실제 수집/공유 범위에 맞게 입력.

근거:

- `android/app/build.gradle.kts:36`
- `android/app/build.gradle.kts:51`
- `android/app/build.gradle.kts:53`
- `android/app/build.gradle.kts:74`
- `android/app/build.gradle.kts:76`
- `android/app/src/main/AndroidManifest.xml:4`
- `android/app/src/main/AndroidManifest.xml:27`

## 8. 출시 전 주요 이슈

### P0. 스토어 스크린샷 가이드가 실제 앱에 없는 기능을 설명함

`docs/store/google-store-image.md`는 아직 저장 갤러리, 기록, 통계, 하단 내비게이션, 상세 통계 혜택을 스크린샷 구성으로 요구한다. 현재 앱에는 gallery/history/stats 라우트가 없고 저장 갤러리도 없다.

이 문서는 Play 등록 자산을 만드는 기준이므로 출시 전 반드시 고쳐야 한다.

수정 방향:

- 4장: "사진 위에 그리기" 또는 "배경색/커스텀 컬러"로 교체.
- 5장: "설정과 다국어"로 교체.
- "저장/갤러리/기록/통계/상세 통계" 표현 제거.
- "5종 브러시"를 "10종 브러시"로 갱신.
- 하단 내비게이션 언급 제거.

근거:

- `docs/store/google-store-image.md:8`
- `docs/store/google-store-image.md:61`
- `docs/store/google-store-image.md:75`
- `docs/store/google-store-image.md:99`
- `docs/store/google-store-image.md:117`
- `docs/store/google-store-image.md:119`
- `lib/app/routes/app_pages.dart:18`
- `lib/app/routes/app_routes.dart:15`

### P0. 출시 운영값은 아직 실제 환경에서 검증되지 않음

코드는 운영 ID/상품을 받을 준비가 되어 있지만, 이번 리뷰에서는 release build와 실제 기기 결제/광고 검증을 실행하지 않았다.

출시 차단 체크:

- release dart-define 3개 주입 여부.
- AdMob App ID와 광고 단위 ID 일치 여부.
- Play Console 상품 3개 등록/활성화 여부.
- 라이선스 테스터 계정으로 구매/복원 확인.
- Premium 후 광고 제거와 특수 브러시 즉시 접근 확인.

### P1. Draw 상단 툴바 overflow 가능성

상단 툴바가 고정 `Row` 구조라 작은 화면에서 폭이 부족할 수 있다. 실제 작은 폭 기기에서 overflow가 보이면 출시 전에 수정해야 한다.

권장 수정:

- 뒤로/공유 등 핵심 3~4개만 상단에 남기고 나머지는 overflow menu로 이동.
- 또는 top toolbar를 horizontal scroll로 감싸고 시각적으로 scroll 가능함을 보여준다.
- 최소 320dp 폭, font scale 1.3 이상, Arabic locale에서 확인.

### P1. 결제 검증은 클라이언트 기반

`PurchaseService`는 purchase update 또는 past purchases에서 product ID와 status를 보고 Premium을 저장한다. Play Billing 운영 권장 수준의 서버 token 검증은 없다.

현재 후원형 1회 구매 MVP로는 받아들일 수 있는 선택일 수 있지만, 출시 문서에는 이 리스크를 명시해야 한다. 장기적으로는 서버 검증 또는 Play Integrity/API 검증 구조를 고려하는 것이 좋다.

### P1. DrawPage / CanvasPainter 회귀 테스트 부족

현재 테스트는 컨트롤러, 구매, 광고, 홈/설정 일부 위젯을 잘 커버한다. 하지만 실제 사용자 체감 핵심인 드로잉 화면의 레이아웃, 브러시 선택, 잠금 해금 dialog, 이미지 import 버튼, 지우기 confirm, painter output은 직접 테스트가 부족하다.

권장 추가 테스트:

- 좁은 폭에서 DrawPage toolbar overflow 없음.
- 작업물이 있을 때 뒤로가기 confirm 표시.
- 빈 캔버스에서 share/clear disabled.
- Premium false일 때 수채화/에어브러시 lock 표시.
- Premium true일 때 특수 브러시 바로 선택.
- CanvasPainter 단일 점, 긴 stroke, eraser, airbrush seed 안정성.

### P2. 미사용 전면 광고 매니저

`InterstitialAdManager`는 등록되지만 사용자 액션에서 호출되지 않는다. 지금 정책상 문제는 아니지만, 출시 표면을 줄이려면 제거하거나 문서에 "현재 미사용"을 유지해야 한다.

### P2. iOS placeholder

Android 우선 프로젝트지만 `RateMyAppConfig.APP_STORE_ID = '0000000000'`가 남아 있다. iOS 출시 계획이 없다면 큰 문제는 아니나, 장기적으로 혼동을 줄이려면 Android-only 주석을 명확히 하거나 iOS 출시 시점에 교체한다.

### P2. 일부 문서 표현 드리프트

`docs/store/google-ads-subscription.md`에도 "상세 통계 혜택", "5종 브러시" 표현이 남아 있다. `README.md`와 `docs/TODO.md`는 현재 코드 기준으로 비교적 정직하게 정리되어 있으므로, store 문서만 추가 정리하면 된다.

근거:

- `docs/store/google-ads-subscription.md:61`
- `docs/store/google-ads-subscription.md:121`
- `README.md:3`
- `docs/TODO.md:8`

## 9. 좋은 점 요약

- 앱의 핵심 제품 방향이 명확하다: 저장 갤러리보다 즉시 그리기/공유에 집중한다.
- 브러시 정의가 registry 기반으로 모여 있어 확장과 테스트가 쉽다.
- 빈 캔버스 공유, 무효 참조 이미지, 광고 미준비, 구매 불가 같은 실패 경로에 사용자 피드백이 있다.
- Premium 상태와 광고 매니저 정리 흐름이 분리되어 있다.
- Firebase/Hive 초기화 실패에 대한 fallback이 있어 startup blank screen 위험을 줄인다.
- 테스트 42개가 컨트롤러, 구매 복원, 광고 초기화, 홈/설정 UI 일부를 커버한다.

## 10. 출시 전 QA 체크리스트

- [ ] Android 13, 14, 15 실제 기기에서 앱 시작, 홈 CTA, 뒤로가기 종료 확인.
- [ ] 320dp급 좁은 화면 또는 작은 기기에서 Draw 상단 툴바 overflow 확인.
- [ ] font scale 1.3 이상에서 Home / Draw / Settings / Premium 텍스트 truncation 확인.
- [ ] Arabic locale에서 RTL, toolbar, settings chip, premium card 확인.
- [ ] 사진 불러오기: 선택, 취소, 파일 삭제/권한 변경 후 오류 처리 확인.
- [ ] 긴 stroke 100개 이상에서 undo/redo, 지우개, 공유 성능 확인.
- [ ] 빈 캔버스 share/clear disabled 또는 toast 확인.
- [ ] 수채화/에어브러시 무료 상태: lock, 보상형 광고 미준비 안내, 보상 후 해금 확인.
- [ ] Premium 구매 후: 배너 제거, 특수 브러시 바로 선택, 복원 확인.
- [ ] release dart-define 없이 광고가 비활성화되는 것을 의도한 실패로 확인.
- [ ] release dart-define 포함 상태에서 배너/보상형 광고 실제 로드 확인.
- [ ] Play Console 상품 3개 가격이 Premium 화면에 표시되는지 확인.
- [ ] 개인정보 처리방침 URL 열기, 피드백 mailto, 더 많은 앱 링크 확인.
- [ ] Store screenshot 문서에서 저장/갤러리/기록/통계 문구 제거 후 자산 제작.

## 11. 최종 판단

코드 기준으로는 조건부 출시 가능이다. 배포를 막는 컴파일/테스트 실패는 없고, 핵심 드로잉 흐름도 현재 제품 컨셉과 맞다.

출시 전 반드시 처리할 것은 2가지다.

1. `docs/store/google-store-image.md`와 `docs/store/google-ads-subscription.md`의 실제 기능 불일치 수정.
2. 실제 Android 기기에서 광고, 구매/복원, 사진 불러오기, 공유, 작은 화면/RTL UI QA 수행.

이 두 가지가 끝나면 Doodle Pad는 "저장 갤러리 없는 공유 중심 드로잉 앱"으로 정직하게 출시할 수 있다. 저장/갤러리/작품 복원을 경쟁 기준으로 끌어올리는 작업은 출시 후 P1 개선 과제로 두는 것이 현실적이다.
