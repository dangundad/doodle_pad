# Doodle Pad (Drawing) 개발 가이드

> 문서: `CLAUDE.md`
> This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
> 최종 업데이트: 2026-05-13
> 기준: 현재 앱 저장소 스캔 + `C:\Flutter_WorkSpace\Flutter_Plan\AGENTS.md` 포트폴리오 상태표

## 프로젝트 요약
- 앱 번호: 40
- Phase: 4
- 상태: ✅ 기능구현
- 난이도: ★★☆
- 광고 등급: 중상
- 프로젝트 폴더: `doodle_pad`
- `pubspec` 이름: `doodle_pad`
- Android 패키지: `com.dangundad.doodlepad`
- 버전: `1.0.0+1`
- 핵심 기능: `perfect_freehand` 기반 자유 드로잉, 10종 브러시(펜/연필/마커/붓/형광펜/만년필/크레용/수채화/에어브러시/지우개), 갤러리 사진 위 드로잉, 실행취소, 공유, 보상형 광고 / Premium(광고 제거 + 프리미엄 브러시)

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
cd C:\Flutter_WorkSpace\doodle_pad
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## 현재 의존성 하이라이트
- 기반: `get` ^4.7.3, `hive_ce` ^2.19.3, `hive_ce_flutter` ^2.3.4, `path_provider` ^2.1.5, `shared_preferences` ^2.5.5
- 드로잉/이미지: `perfect_freehand` ^2.5.2, `image_picker` ^1.1.2, `flutter_colorpicker` ^1.1.0
- UI/UX: `flutter_screenutil` ^5.9.3, `flex_color_scheme` ^8.4.0, `google_fonts` ^8.1.0, `lucide_icons_flutter` ^3.1.13, `toastification` ^3.2.0
- 수익화/운영: `google_mobile_ads` ^8.0.0, `gma_mediation_applovin` ^2.5.2, `gma_mediation_pangle` ^3.5.3, `gma_mediation_unity` ^1.6.5, `in_app_purchase` ^3.2.3, `in_app_purchase_android` ^0.4.0+10, `in_app_review` ^2.0.11, `rate_my_app` ^2.4.0, `firebase_core` ^4.8.0, `firebase_analytics` ^12.4.0, `firebase_crashlytics` ^5.2.1, `device_info_plus` ^13.1.0, `share_plus` ^13.1.0, `url_launcher` ^6.3.2, `vibration` ^3.1.8
- 로컬라이제이션: `flutter_localizations` (SDK)
- 개발 도구: `build_runner` ^2.15.0, `hive_ce_generator` ^1.11.1, `flutter_lints` ^6.0.0, `flutter_launcher_icons` ^0.14.4, `flutter_native_splash` ^2.4.7, `change_app_package_name` ^1.5.0, `in_app_purchase_platform_interface` ^1.4.0, `plugin_platform_interface` ^2.1.8

## 현재 코드 구조
- `lib/app` 디렉터리: `admob`, `bindings`, `controllers`, `data`, `pages`, `routes`, `services`, `theme`, `translate`, `utils`, `widgets`
- `admob`: `ads_banner.dart`, `ads_helper.dart`, `ads_interstitial.dart`, `ads_rewarded.dart`
- `bindings`: `app_binding.dart`
- `routes`: `app_pages.dart`, `app_routes.dart`
- `controllers`: `doodle_controller.dart`, `premium_controller.dart`, `setting_controller.dart`
- 기능 중심 컨트롤러: `doodle_controller`
- `services`: `app_rating_service.dart`, `hive_service.dart`, `purchase_service.dart`
- 기능 중심 서비스: 없음
- `pages`: `draw`, `home`, `premium`, `settings`
  - `pages/draw/widgets`: `canvas_painter.dart`
  - `pages/premium`: `premium_binding.dart`, `premium_page.dart`
- `widgets`: `exit_bottom_sheet.dart`
- `mixins`: 없음
- `utils`: `app_constants.dart`, `app_toast.dart`, `share_file_cleanup.dart`
- `translate`: `translate.dart`
- `theme`: `app_theme.dart`
- `data/brushes`: `brush_preset.dart`, `brush_presets.dart`
- `data/models`: 없음 (빈 디렉터리)
- `data/enums`: 없음 (빈 디렉터리)
- `data/constants`: 없음
- `data` 루트 파일: 없음
- 진입점: `lib/main.dart` (Firebase / Hive 초기화 실패 시 `_StartupFailureScreen` fallback)
- `assets`: `fonts`, `images`
- `tests`: `test/app/controllers/{setting,doodle,premium}_controller_test.dart`, `test/app/services/purchase_service_test.dart`, `test/app/admob/{ads_helper,ads_loading}_test.dart`, `test/app/data/brushes/brush_presets_test.dart`, `test/app/helpers/fake_purchase_service.dart`, `test/app/pages/{draw,home,settings}/*_page_test.dart`, `test/app/theme/app_theme_test.dart`, `test/app/utils/{app_toast,share_file_cleanup}_test.dart`, `test/ui/no_gradient_usage_test.dart`, `test/widget_test.dart`

## 문서 유지 규칙
- 새 페이지나 바인딩을 추가하면 이 문서의 `pages`/`bindings` 요약도 함께 갱신합니다.
- 의존성 추가/제거, Android 패키지명 변경, 테스트 확장은 이 문서에 바로 반영합니다.
- 포트폴리오 상태가 바뀌면 메타 레포 `AGENTS.md`, `CLAUDE.md`, 관련 `docs/*.md`와 함께 동기화합니다.
