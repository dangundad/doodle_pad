# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

자유 드로잉 캔버스 앱. 펜/마커/지우개/수채화/에어브러시 5종 브러시, Undo/Redo, 갤러리 저장, 공유 기능을 제공합니다.

- 패키지명: `com.dangundad.doodlepad`
- 개발사: DangunDad (`dangundad@gmail.com`)
- 설계 크기: 375x812 (ScreenUtil 기준)
- 테마: `FlexScheme.pinkM3` (라이트/다크 모두)

## 기술 스택

| 영역 | 기술 |
|------|------|
| 상태 관리 | GetX (`GetxController`, `.obs`, `Obx()`) |
| 로컬 저장 | Hive_CE (설정/앱 데이터 박스) |
| UI 반응형 | flutter_screenutil |
| 테마 | flex_color_scheme (`FlexScheme.pinkM3`) |
| 캔버스 | CustomPainter (`CanvasPainter`) |
| 이미지 공유 | share_plus |
| 광고 | google_mobile_ads + AdMob 미디에이션 |
| 인앱 구매 | in_app_purchase |
| 다국어 | GetX 번역 (ko) |

## 개발 명령어

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

## 아키텍처

### 프로젝트 구조

```
lib/
├── main.dart
├── app/
│   ├── admob/
│   │   ├── ads_banner.dart
│   │   ├── ads_helper.dart
│   │   ├── ads_interstitial.dart
│   │   └── ads_rewarded.dart
│   ├── bindings/
│   │   └── app_binding.dart
│   ├── controllers/
│   │   ├── doodle_controller.dart   # 캔버스 상태 + 브러시 + 저장/공유
│   │   ├── history_controller.dart
│   │   ├── home_controller.dart
│   │   ├── premium_controller.dart
│   │   ├── setting_controller.dart
│   │   └── stats_controller.dart
│   ├── pages/
│   │   ├── draw/
│   │   │   ├── draw_page.dart
│   │   │   └── widgets/
│   │   │       └── canvas_painter.dart  # CustomPainter 캔버스 렌더링
│   │   ├── gallery/gallery_page.dart
│   │   ├── history/history_page.dart
│   │   ├── home/home_page.dart
│   │   ├── premium/
│   │   │   ├── premium_binding.dart
│   │   │   └── premium_page.dart
│   │   ├── settings/settings_page.dart
│   │   └── stats/stats_page.dart
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── services/
│   │   ├── activity_log_service.dart
│   │   ├── app_rating_service.dart
│   │   ├── hive_service.dart
│   │   └── purchase_service.dart
│   ├── theme/
│   │   └── app_flex_theme.dart
│   ├── translate/
│   │   └── translate.dart
│   └── utils/
│       └── app_constants.dart
```

### 서비스 초기화 흐름

`main()` -> AdMob 동의 폼 초기화 -> `AppBinding.initializeServices()` (Hive 초기화 + 서비스 등록) -> `runApp()`

### GetX 의존성 트리

**영구 서비스 (permanent: true)**
- `HiveService` -- Hive 박스 관리 (`settings`, `app_data` 박스)
- `ActivityLogService` -- 이벤트 로그 (`phase1_activity_log` 박스, 최대 300개)
- `PurchaseService` -- IAP 관리, 프리미엄 상태에 따라 광고 매니저 동적 등록/해제
- `DoodleController` -- 캔버스 상태 (스트로크 목록, 브러시 설정, Undo 스택)
- `SettingController` -- 앱 설정 (`doodle_settings_v1` 박스)
- `InterstitialAdManager` / `RewardedAdManager` -- 광고 (비프리미엄 시)

**LazyPut (필요 시 생성)**
- `HistoryController`, `StatsController`, `PremiumController`

### 라우팅

| 경로 | 페이지 | 바인딩 |
|------|--------|--------|
| `/home` | `HomePage` | `AppBinding` |
| `/draw` | `DrawPage` | -- |
| `/gallery` | `GalleryPage` | -- |
| `/settings` | `SettingsPage` | -- |
| `/history` | `HistoryPage` | -- |
| `/stats` | `StatsPage` | -- |
| `/premium` | `PremiumPage` | `PremiumBinding` |

### 드로잉 핵심 구조

**DoodleController**가 `List<DrawingStroke>.obs`를 관리 (인메모리, Hive 미저장):

**BrushType** (5종):
- `pen`: `StrokeCap.round`, 기본 너비
- `marker`: `StrokeCap.square`, 너비 2.5배
- `eraser`: `BlendMode.clear`, 너비 4.0배
- `watercolor`: `StrokeCap.round`, 너비 2.0배 (보상형 광고로 해금)
- `airbrush`: 스프레이 패턴, 기본 너비 (보상형 광고로 해금)

**DrawingStroke** 속성:
- `points` (List<Offset>) -- 터치 포인트 목록
- `color`, `width`, `isEraser`, `cap`, `brushType`
- `seed` (int) -- 에어브러시 랜덤 시드 (리페인트 시 패턴 안정성)

**CanvasPainter 핵심 패턴**:
- 지우개는 `BlendMode.clear`로 구현 -> 반드시 `canvas.saveLayer()`로 감싸야 동작
- 단일 점: `drawCircle`, 복수 점: Quadratic Bezier 곡선으로 스무딩
- `shouldRepaint`: 스트로크 수 또는 마지막 스트로크의 점 수 변화만 감지

**Undo/Redo**: 최대 20단계 (`_maxUndo`), 새 스트로크 시작 시 Redo 스택 클리어

**색상 팔레트**: 16색 고정 (`DoodleController.colorPalette`)

### 저장/공유 시스템

- `RepaintBoundary` + `toImage(pixelRatio: 3)`로 PNG 캡처
- 저장: `getApplicationDocumentsDirectory()/drawings/` 폴더에 PNG 파일 저장
- 갤러리: 저장된 파일 경로 목록을 Hive에 관리 (존재하지 않는 파일 자동 필터링)
- 공유: 임시 디렉토리에 PNG 생성 후 `share_plus`로 공유

### 스토리지 구조

| Hive 박스 | 용도 | 담당 서비스 |
|-----------|------|-------------|
| `settings` | 범용 설정 (key-value) | `HiveService` |
| `app_data` | 범용 앱 데이터 | `HiveService` |
| `doodle_settings_v1` | 앱 전용 설정 (haptic, language 등) | `SettingController` |
| `phase1_activity_log` | 이벤트 로그 | `ActivityLogService` |

### 다국어

현재 `ko` 키만 정의. 새 문자열은 `lib/app/translate/translate.dart`에 `ko` 섹션에만 추가.

## 개발 가이드라인

- 브러시 추가 시: `BrushType` enum 확장 + `startStroke()` 너비 배율 추가 + `CanvasPainter` 렌더링 분기
- 잠금 브러시(watercolor, airbrush)는 보상형 광고 시청 후 Hive에 해금 상태 저장
- `_currentStroke` 멀티터치 방어: `startStroke()`에서 기존 진행 중 스트로크 제거
- `CanvasPainter`에서 `saveLayer()`는 지우개 동작에 필수
