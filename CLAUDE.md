# Doodle Pad (Drawing) 개발 가이드

> 문서: `CLAUDE.md`
> This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
> 최종 업데이트: 2026-05-27
> 기준: 현재 앱 저장소 스캔 + `C:\Flutter_WorkSpace\Flutter_Plan\AGENTS.md` 포트폴리오 상태표

## 프로젝트 요약
- 앱 번호: 40
- Phase: 4
- 상태: ✅ 출시 후보 (review_claude.md / review_codex.md 교차 검증, pre-release-audit + pre-release-followup sprint 완료)
- 난이도: ★★☆
- 광고 등급: 중상
- 프로젝트 폴더: `doodle_pad`
- `pubspec` 이름: `doodle_pad`
- Android 패키지: `com.dangundad.doodlepad`
- 버전: `1.0.0+1`
- 핵심 기능: `perfect_freehand` 기반 자유 드로잉, 10종 브러시(펜/연필/마커/붓/형광펜/만년필/크레파스/수채화/에어브러시/지우개), 갤러리 사진 위 드로잉(앱 내부로 영속 복사), 앱 내 작품 보관함(저장·재오픈·삭제), 실행취소, 공유, 흔들어 지우기, 보상형 광고 / Premium(광고 제거 + 프리미엄 브러시)

## 공통 작업 원칙
- 모든 텍스트 파일은 UTF-8로 유지하고, PowerShell에서 파일을 쓸 때는 `-Encoding UTF8`을 명시합니다.
- AI/코드 어시스턴트의 설명, 진행 업데이트, 최종 답변은 기본적으로 한국어로 작성합니다.
- Android 우선 프로젝트이며, 별도 요청 없이 iOS 전용 코드는 추가하지 않습니다.
- 릴리스 빌드는 실행하지 않습니다. 일반 작업에서는 `flutter build apk`/`flutter build ios`를 사용하지 않습니다.
- 코드 변경 후에는 반드시 `flutter analyze`와 `flutter test`를 실행해 결과를 확인합니다.
- Hive `@HiveType` 모델을 추가하거나 수정했다면 `dart run build_runner build --delete-conflicting-outputs`를 실행합니다.
- 상태 관리는 GetX, 로컬 저장은 Hive_CE 패턴을 유지하고 기존 네비게이션/영속성 구조를 임의로 바꾸지 않습니다.
- Windows 표준 경로를 사용하고 WSL 경로(`/mnt/c/...`)는 사용하지 않습니다.
- `2>nul`, `>nul` 리다이렉션은 사용하지 않으며, `nul` 파일이 생기면 정리합니다.

## 빠른 명령어
```bash
cd C:\Github_WorkSpace\doodle_pad
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## 현재 의존성 하이라이트
- 기반: `get` ^4.7.3, `hive_ce` ^2.19.3, `hive_ce_flutter` ^2.3.4, `path_provider` ^2.1.5, `shared_preferences` ^2.5.5
- 드로잉/이미지: `perfect_freehand` ^2.5.2+1, `image_picker` ^1.2.3, `flex_color_picker` ^3.8.0, `gal` ^2.3.3, `image` ^4.9.1, `sensors_plus` ^7.1.0
- UI/UX: `flutter_screenutil` ^5.9.3, `flex_color_scheme` ^8.4.0, `google_fonts` ^8.2.1, `lucide_icons_flutter` ^3.1.14+2, `toastification` ^3.2.0
- 수익화/운영: `google_mobile_ads` ^9.0.0, `gma_mediation_applovin` ^2.6.2, `gma_mediation_pangle` ^4.0.0, `gma_mediation_unity` ^1.9.0, `app_tracking_transparency` ^2.0.7, `in_app_purchase` ^3.3.0, `in_app_purchase_android` ^0.5.2, `in_app_review` ^2.0.12, `rate_my_app` ^2.4.1, `firebase_core` ^4.12.1, `firebase_crashlytics` ^5.2.6, `share_plus` ^13.3.0, `url_launcher` ^6.3.2, `vibration` ^3.2.0
- 로컬라이제이션: `flutter_localizations` (SDK)
- 개발 도구: `build_runner` ^2.15.0, `hive_ce_generator` ^1.11.2, `flutter_lints` ^6.0.0, `flutter_launcher_icons` ^0.14.4, `flutter_native_splash` ^2.4.7, `change_app_package_name` ^1.5.0, `in_app_purchase_platform_interface` ^1.4.0, `plugin_platform_interface` ^2.1.8

## 현재 코드 구조
- `lib/app` 디렉터리: `admob`, `bindings`, `controllers`, `data`, `pages`, `routes`, `services`, `theme`, `translate`, `utils`, `widgets`
- `admob`: `ads_banner.dart`, `ads_helper.dart`, `ads_interstitial.dart`, `ads_rewarded.dart`
- `bindings`: `app_binding.dart`
- `routes`: `app_pages.dart`, `app_routes.dart`
- `controllers`: `doodle_controller.dart`, `gallery_controller.dart`, `premium_controller.dart`, `setting_controller.dart`
- `services`: `app_rating_service.dart`, `artwork_repository.dart` (작품 영속화 + 썸네일 IO), `export_service.dart`, `hive_service.dart`, `purchase_service.dart`
- `pages`: `draw`, `gallery`, `home`, `premium`, `settings`
  - `pages/draw`: `draw_page.dart`
  - `pages/draw/widgets`: `canvas_painter.dart`, `save_options_sheet.dart`
  - `pages/gallery`: `gallery_binding.dart`, `gallery_page.dart`
  - `pages/home`: `home_page.dart`
  - `pages/premium`: `premium_binding.dart`, `premium_page.dart`
  - `pages/settings`: `settings_page.dart`
- `widgets`: `exit_bottom_sheet.dart`
- `mixins`: `shake_detector_mixin.dart`
- `utils`: `app_constants.dart`, `app_toast.dart`, `share_file_cleanup.dart`
- `translate`: `translate.dart`
- `theme`: `app_theme.dart`
- `data/brushes`: `brush_preset.dart`, `brush_presets.dart`
- `data/models`: `drawing.dart` (+ `drawing.g.dart` — `@HiveType` Drawing/SerializableStroke, build_runner 생성)
- 진입점: `lib/main.dart` (Firebase / Hive 초기화 실패 시 `_StartupFailureScreen` fallback)
- Firebase 설정: `lib/firebase_options.dart` (FlutterFire CLI 생성)
- Hive 어댑터 레지스트라: `lib/hive_registrar.g.dart` (build_runner 생성, `HiveService.init`에서 `Hive.registerAdapters()` 호출)
- `assets`: `fonts`, `images`
- `test/`: `app/controllers/` (doodle·gallery·premium·setting·brush_type_persistence), `app/services/` (purchase·export·artwork_repository), `app/admob/`, `app/data/brushes/`, `app/bindings/` (app_binding_shake_order), `app/pages/{draw,gallery,home,settings}/`, `app/mixins/`, `app/theme/`, `app/utils/`, `app/helpers/fake_purchase_service.dart`, `translate_consistency_test.dart`, `ui/no_gradient_usage_test.dart`, `widget_test.dart`

## 최근 감사 이력
- 2026-05-08 핵심 로직 + UI gradient 1차 감사 통과
- 2026-05-16~17 Wave 3 2차 감사 (설정/광고/strings/Haptic) + release_settings_intro Card 정리
- 2026-08-03 컬러 피커 고도화: `flutter_colorpicker`(단일 HSV 영역)를 제거하고 `flex_color_picker` ^3.8.0으로 교체. 브러시 색상·캔버스 배경색 모두 공통 `pickRichColor()`를 쓰며 Material 기본/강조 팔레트(색조 포함) · 흑백 · 자유 컬러휠 · HEX 입력/복사붙여넣기 · 최근 사용 색상을 한 다이얼로그에서 제공한다. 피커의 recentColors는 `DoodleController.recentColors`와 연결돼 툴바 퀵 행과 동일한 목록을 공유한다. 피커 라벨은 `color_shades`/`color_wheel`/`color_recent`/`color_type_{primary,accent,bw}` 6개 키로 11개 언어 지원. 알파는 항상 0xFF로 강제(투명도는 지우개 담당).
- 2026-08-03 그리기 화면 → 작품 보관함 진입점 추가. 기존에는 보관함으로 가려면 홈 버튼을 거쳐야 했는데 홈 버튼은 캔버스를 비우고 나가므로, 작업 중인 그림을 잃지 않고는 저장한 작품에 접근할 수 없었다. 상단 툴바에 "내 작품"(`LucideIcons.images` → `Get.toNamed(Routes.GALLERY)`, 확인 다이얼로그 없음)을 추가하고, 자리 확보를 위해 캔버스 색상·사진 불러오기를 `MoreActionsSheet`(더보기 `···`)로 이동했다. 더보기 버튼은 스크롤 영역 밖에 고정해 320dp에서도 항상 보인다. 갤러리에서 작품을 열 때 이전 라우트가 DRAW면 `Get.back()`으로 복귀해 그리기 화면이 스택에 중복 쌓이지 않는다.
- 2026-08-03 시트/화면 대비·잘림 감사(골든 렌더 스크린샷으로 전 화면 육안 검수). 고친 것: (1) 저장 시트 포맷 버튼 — 선택 시 아이콘이 `primary`라 주황 배경 위 주황으로 사라지던 문제를 `onPrimaryContainer`(흰색)로 수정, (2) 해상도 버튼 — `1x  Standard`처럼 배수+이름을 한 줄에 넣어 좁은 화면/130% 배율에서 `3x Ultr…`로 잘리던 것을 배수(코드 렌더)+화질명(번역) 2줄 구조로 변경(번역값은 화질명만 보유), (3) 프리미엄 소유 화면 왕관 아이콘 동일 버그 수정, (4) 프리미엄 히어로 제목 — `primaryContainer @0.55` 연한 배경 위 흰 글씨 → `onSurface`, (5) 툴바 "+" 더보기 슬롯이 선택 상태처럼 보이던 것을 중립 배경+primary 외곽선으로 분리, (6) 잠금 브러시 아이콘 alpha 0.35→0.5, (7) 상단 툴바 9개 액션이 잘린 채 스크롤되던 것을 IconButton 밀도 조정(38×40, iconSize 19)으로 일반 폰 폭에 모두 노출, (8) 긴 라벨 축약(`watercolor_brush`, `brush_fountain_pen`, ko `show_brush_guide`). **규칙: `primaryContainer` 계열 배경 위 전경은 반드시 `onPrimaryContainer`(단, alpha를 낮춘 연한 패널은 `onSurface`).**
- 2026-08-03 하단 툴바 3단 재설계: 브러시 셀렉터와 굵기 슬라이더가 한 행을 나눠 쓰며 가로 스크롤로 잘리던 문제를 제거. `[브러시 퀵] · [굵기] · [색상 퀵]` 3행으로 분리하고 각 행은 `Expanded` 슬롯을 균등 분배해 320dp에서도 44dp 터치 타깃을 유지한 채 스크롤이 없다. 최근 사용 브러시 4종(+지우개 고정) / 최근 색상 5종만 노출하고 나머지는 "+" 슬롯이 여는 바텀시트에서 선택한다. `DoodleController.useBrush`/`useColor`가 선택 단일 진입점이며 최근 목록을 Hive(`recent_brushes`/`recent_colors`)에 영속화한다. 시트는 선택 즉시 닫히므로 열릴 때의 상태를 캡처해 정적으로 렌더한다(반응형 불필요). ⚠️ **위젯 테스트 함정**: `testWidgets` 안에서 Hive 쓰기가 발생하면 FakeAsync에 묶여 완료되지 않고 tearDown의 `Hive.close()`가 영원히 대기해 테스트 프로세스가 멈춘다(타임아웃도 못 잡음). 따라서 탭으로 영속화를 유발하는 시나리오는 위젯 테스트로 만들지 말고 `doodle_controller_test`(순수 `test()`)에서 검증한다.
- 2026-08-03 번역 간결화: 11개 언어 × 30개 키(총 330개 문자열)를 모바일 그림판 톤에 맞게 축약. 전체 문자수 13.8% 감소, 40자 초과 문자열 78→22개. 원칙 — 스낵바/다이얼로그 제목은 마침표 없는 짧은 구(`purchase_error`='구매 실패'), 본문은 한 문장(`purchase_failed`='다시 시도해 주세요.'), 설정 부제는 제목과 다른 정보를 짧게(`ask_before_clear`/`_desc` 중복 제거). `shake_to_clear_desc`의 ko 하드코딩 줄바꿈+word-joiner(`⁠`) 하이픈 방지 꼼수를 짧은 한 줄로 대체(관련 회귀 테스트도 새 문구로 갱신).
- 2026-08-03 시작 흐름 단순화: 첫 실행 온보딩(HomePage) 분기를 제거하고 앱 시작 시 항상 DrawPage로 직진입 (`main.dart` initialRoute). HomePage는 DrawPage 상단 홈 버튼으로 접근하는 허브(설정/갤러리/프리미엄/배너) 역할 유지. `AppBinding.isOnboardingSeen`은 라우팅에서 더 이상 사용되지 않음.
- 2026-08-03 iOS 배포 준비(siren `IOS_DEPLOYMENT_GUIDE.md` 기준 적용, 결과는 루트 `IOS_DEPLOYMENT_GUIDE.md`). (1) `ios/Runner/PrivacyInfo.xcprivacy` 생성(UserDefaults CA92.1 + DeviceID 추적 + 추적 도메인) 및 pbxproj 등록, (2) `ios/Runner/<lang>.lproj/InfoPlist.strings` 11개 언어(앱 이름=translate `app_name`, 사진/추적 권한 문구) 생성 + `knownRegions`/`PBXVariantGroup` 등록, `Info.plist` 기본 문구는 영어 폴백으로 전환, (3) ATT 사전 설명 다이얼로그(`att_*` 3키 × 11언어, CupertinoAlertDialog) 추가, (4) `ExitBottomSheet` 종료 버튼 iOS 분기(시트만 닫음). 남은 스토어 측 작업: App Store Connect 앱 레코드/IAP 상품 3종 등록, DSA 거래자 정보, Nutrition Label.
- 2026-08-03 iOS 최종 로직 감사. (1) iOS 광고 단위 ID를 릴리스 테스트 ID 하드코딩에서 Android와 동일한 `--dart-define=DOODLE_PAD_ADMOB_{BANNER,INTERSTITIAL,REWARDED}_IOS` 주입 방식으로 전환(미주입 시 광고 스킵 + 경고 로그), (2) `Info.plist`에 SKAdNetworkItems 40종 추가, (3) App Store ID를 `--dart-define=DOODLE_PAD_APP_STORE_ID` 주입으로 전환(미주입 시 인앱 리뷰 폴백), (4) 갤러리 작품 열기 다이얼로그를 공통 스타일 + 전용 문구(`artwork_open_overwrite_*`, 11개 언어)로 교체. `flutter analyze` / `flutter test` 117개 통과, iPhone 12 Pro Max 실기기 실행 검증.
- 2026-09-10 실기기/에뮬레이터 전 기능 QA (상세: `docs/04-report/sprints/device-qa-2026-09-10/README.md`). 화면 조작 + 스크린샷 + logcat + MediaStore 조회로 11건 수정.
  - **홈 버튼/시스템 백이 동작하지 않던 출시 차단 버그**: `Get.previousRoute.isEmpty` 로 "DRAW가 루트인가"를 판별했는데 GetX의 previousRoute는 시트/다이얼로그를 한 번 띄우면 다시는 비지 않는다. 한 번이라도 시트를 연 사용자는 설정/프리미엄에 도달할 수 없고 홈 버튼을 누르면 캔버스만 지워졌다. `Navigator.of(context).canPop()` 으로 교체. **판별 로직에 `Get.previousRoute` 를 다시 쓰지 말 것.**
  - **릴리스 서명 가드가 debug 빌드까지 막던 문제**: `buildTypes { release { throw ... } }` 는 configuration 단계에서 항상 평가된다. `gradle.taskGraph.whenReady` 로 이동해 실제 릴리스 태스크에서만 실패시킨다.
  - **상태바 아이콘 불가시**: DrawPage에 AppBar가 없어 직전 화면(주황 AppBar = 흰 아이콘) 스타일이 남았다. `AnnotatedRegion<SystemUiOverlayStyle>` 을 **캔버스 색 휘도** 기준으로 선언해 다크 테마까지 함께 해결.
  - **갤러리 저장 파일명 이중 확장자**(`doodle_x.png.png`): gal 은 `name` 에 확장자를 넣으면 안 되고 스스로 붙인다. 기본 파일명을 `doodle_<ts>` 로 변경.
  - **API ≤29 갤러리 저장 불가**: minSdk 24 인데 `WRITE_EXTERNAL_STORAGE(maxSdkVersion=29)` + `requestLegacyExternalStorage` 선언이 없어 Android 7~10 에서 권한 요청이 즉시 거부됐다. 매니페스트에 추가.
  - 그 외: 마지막 브러시 영속화(`last_brush_type`, 미저장 시 퀵 행에 선택 표시가 사라짐), 작품 썸네일 `BoxFit.contain` + 그리드 `childAspectRatio: 0.72`, 첫 실행 언어 기기 로케일 반영(`deviceLocaleFn` seam), 연필/크레용 grain 을 outline 과 같은 streamline 중심선에 정렬, 굵기 미리보기에 `sizeMultiplier`/`alpha` 반영, 잠금 브러시 다이얼로그를 앱 공통 스타일로 통일.
  - **미해결(제품 판단 필요)**: 전면광고가 매 실행 로드되지만 노출 지점이 코드에 없다. 노출 위치를 만들거나 `AppBinding` 등록을 제거해야 한다.
  - `flutter analyze` 0 issue, `flutter test` 137개 통과(신규 회귀 7건 추가), Android `assembleDebug` 통과.
- 2026-09-10 리뉴얼 후 실기기 최종 점검 (상세: `docs/04-report/sprints/device-final-qa-2026-09-10/README.md`). SM-G781N에서 34개 시나리오 adb 주입 + 스크린샷 + logcat: 기능 결함 0, Flutter 예외 0. 수정 6건 — (1) `DoodleController` 안 해금/흔들어 지우기 다이얼로그를 `AppConfirmDialog`로 통일, (2) 리치 피커 HEX 칸 `#RRGGBB` 형식(`copyFormat: numHexRRGGBB`), (3) `AppToast`를 종이 테마(표면색 카드 + 헤어라인 + 의미색 아이콘)로, (4) 설정 초기화 `AlertDialog` → `AppConfirmDialog`, (5) **출시 차단급 버그**: 보관함에서 그리기로 돌아갈 때 DrawPage가 이중 적재되어 같은 `canvasKey`(GlobalKey) 충돌로 **아래 DrawPage 캔버스가 빈 화면**이 되던 것. 원인은 `Get.previousRoute == DRAW` 판별(다이얼로그 후 오염). DrawPage→GALLERY 이동 시 `arguments: GalleryPage.fromDrawArguments`를 넘기고 보관함은 `Get.arguments`로만 판별. 회귀 테스트 추가(140개), (6) 종료 시트 프리미엄 배너 탭 → 프리미엄 이동. **규칙: (a) 다이얼로그는 예외 없이 `AppConfirmDialog`만 쓴다(컨트롤러 포함). (b) `Get.previousRoute`는 어떤 판별에도 쓰지 않는다 — 라우트 인자나 `Navigator.canPop`을 쓴다. (c) DrawPage는 스택에 한 장만 존재해야 한다(`canvasKey` GlobalKey).**
- 2026-09-10 UI/UX 전면 리뉴얼 "종이 + 잉크" (상세: `docs/04-report/sprints/design-renewal-2026-09-10/README.md`). `FlexScheme.shadOrange`를 버리고 `AppTheme.lightScheme/darkScheme`(수동 `ColorScheme`)를 FCS에 주입. 따뜻한 종이색 표면 + 잉크 블루(`primary`) 단일 강조색, 노랑(`secondary`)은 프리미엄/경고, 초록(`tertiary`)은 혜택 체크에만. **규칙**: (1) AppBar는 표면색·왼쪽 정렬·잉크 아이콘(칠하지 않음), (2) 위계는 그림자 대신 헤어라인(`outlineVariant`) + `surfaceContainer*` 단계로, (3) 선택 상태 = primary 채움 또는 primary 테두리(글로우·확대 금지), (4) 반경은 `AppTheme.radiusSm/Md/Lg`(10/14/20) 3단계만, (5) 다이얼로그/시트/목록 행/아이콘 배지는 `lib/app/widgets/app_ui.dart`(`AppConfirmDialog`·`AppSheetShell`·`AppPanel`·`AppListRow`·`IconBadge`·`SectionLabel`)를 쓰고 페이지에서 직접 만들지 않는다. 홈 히어로는 최근 작품 3장을 겹친 종이 묶음(없으면 빈 종이). 설정의 `release_settings_intro` 카드는 제거됨. 모든 테스트 키/툴팁 유지, `flutter test` 139개 통과, Pixel AVD 라이트/다크 스크린샷 검수 완료.
- 2026-09-10 Google Play 스토어 스크린샷 13장 촬영 (`docs/store/screenshot/`, README 포함). SM-G781N 실기기, 영어 로케일(`DOODLE_PAD_QA_LOCALE=en`). 빈 화면이 아닌 실제 작품이 보이도록 `lib/app/utils/store_screenshot_seed.dart`를 추가 — `--dart-define=DOODLE_PAD_QA_SEED_ARTWORKS=true`일 때만 앱 시작 시 보관함을 비우고 프로그램 생성 작품 8점(브러시 10종 혼용, 다크 캔버스 포함)을 `ArtworkRepository.save`로 심는다(썸네일은 `CanvasPainter`로 3x 렌더, 최근 브러시/색상도 함께 심음). 일반 빌드에서는 상수 폴딩으로 제거. 광고 배너는 촬영 중 네트워크를 꺼서 숨겼다. ⚠️ `flutter run` 재실행은 실행 중 프로세스를 재시작하지 않을 수 있으니 시드 코드 변경 후에는 `am force-stop` 후 재실행. 발견 메모: `keep_drawing` 영어 라벨이 360dp에서 `Keep drawi…`로 잘림(미수정).
- 2026-05-27 Phase 1~4 Wave 3B 사전배포 감사 통과. 실제 경로는 `C:\Github_WorkSpace\doodle_pad`이며 Firebase Core/Crashlytics와 `google-services.json`은 유지하고 미사용 Firebase Analytics/기기정보 직접 의존성은 제거했습니다. `flutter pub outdated --no-transitive` 기준 `image`는 최신 resolvable `4.8.0`으로 유지했고, `flutter analyze`, `flutter test` 101개, Android `processDebugResources`/`assembleDebug`를 통과했습니다.

## 문서 유지 규칙
- 새 페이지나 바인딩을 추가하면 이 문서의 `pages`/`bindings` 요약도 함께 갱신합니다.
- 의존성 추가/제거, Android 패키지명 변경, 테스트 확장은 이 문서에 바로 반영합니다.
- 포트폴리오 상태가 바뀌면 메타 레포 `AGENTS.md`, `CLAUDE.md`, 관련 `docs/*.md`와 함께 동기화합니다.
