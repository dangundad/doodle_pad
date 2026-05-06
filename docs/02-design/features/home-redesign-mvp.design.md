# Design — home-redesign-mvp

> Generated: 2026-05-06
> Plan: `docs/01-plan/features/home-redesign-mvp.plan.md`

## Context Anchor

| Key | Value |
|---|---|
| WHY | 미니멀 MVP — 홈에서 그리기까지 1탭. |
| WHO | doodle_pad Android 사용자. |
| RISK | 갤러리 회수 동선 제거. |
| SUCCESS | analyze/test 통과 + nav_bar 제거 + 단일 홈. |
| SCOPE | UI 단순화 + 페이지/서비스 제거. |

## 1. Architecture (Pragmatic Balance)

선택안: **C — Pragmatic Balance**.
- 기존 GetX + Hive_CE 구조 유지. 페이지/컨트롤러/서비스 단위 삭제만 수행.
- 홈은 `MainShellPage`(IndexedStack + GNav) 제거 후, `HomePage`(스캐폴드 + AppBar + 본문 + 광고 배너 + ExitBottomSheet)로 단일화.

## 2. File Changes

### 2.1 Delete (8 파일)
- `lib/app/pages/gallery/gallery_page.dart`
- `lib/app/pages/history/history_page.dart`
- `lib/app/pages/stats/stats_page.dart`
- `lib/app/pages/home/main_shell_page.dart`
- `lib/app/controllers/history_controller.dart`
- `lib/app/controllers/stats_controller.dart`
- `lib/app/controllers/home_controller.dart`
- `lib/app/services/activity_log_service.dart`

### 2.2 Modify
- `pubspec.yaml` — `google_nav_bar` 의존성 삭제.
- `lib/app/routes/app_pages.dart` — gallery/history/stats GetPage 제거. HOME 페이지를 새 `HomePage`로 교체.
- `lib/app/routes/app_routes.dart` — `GALLERY/HISTORY/STATS` 상수 제거.
- `lib/app/bindings/app_binding.dart` — `HistoryController`, `StatsController`, `ActivityLogService` 등록 제거. 관련 import 제거.
- `lib/app/controllers/setting_controller.dart` — `ActivityLogService` 의존, `logEvent`/`recordHomeOpen`/`recordSettingsOpen` 모두 제거. 호출처 동시 정리.
- `lib/app/controllers/doodle_controller.dart` — `savedDrawings`, `_loadSavedPaths`, `_savePng`, `saveCanvas`, `deleteDrawing`, `_savedPathsKey`, `isSaving`(저장 진입점이 사라져 미사용) 제거. `shareCanvas`/`hasDrawableContent`는 유지(공유 시 사용).
- `lib/app/pages/home/home_page.dart` — 단일 홈 스캐폴드로 재작성. `HomePage` 위젯으로 export. `_SavedDrawingsCard` 제거. AppBar에 settings/premium 액션 노출. body는 hero(이모지 원) + feature chips + start CTA. 하단에 광고 배너(비프리미엄). PopScope → ExitBottomSheet.
- `lib/app/pages/draw/draw_page.dart` — 상단툴바에서 저장 버튼 + `logEvent` 호출 제거.
- `lib/app/pages/settings/settings_page.dart` — Quick actions에서 history/stats 항목 제거(premium만 유지). `_track` 호출 제거(logEvent 폐지).

### 2.3 Tests
- `test/app/pages/home/home_page_test.dart` — `MainShellPage`/`ActivityLogService`/`HistoryController`/`StatsController` 의존 테스트 삭제 또는 새 `HomePage` 기준으로 단순화.
- `test/app/controllers/setting_controller_test.dart` — `ActivityLogService` 의존 테스트(`clearAppSettings also clears persisted activity history`) 삭제.

## 3. Routes 변화

| Path | Before | After |
|---|---|---|
| `/home` | `MainShellPage` | `HomePage` |
| `/draw` | `DrawPage` | `DrawPage` (저장 버튼 제거) |
| `/settings` | `SettingsPage` | `SettingsPage` (Quick actions 정리) |
| `/premium` | `PremiumPage` | `PremiumPage` |
| `/gallery` `/history` `/stats` | 존재 | 제거 |

## 4. UI 사양 — HomePage

- AppBar
  - Title: `'app_name'.tr`
  - Bottom: 3px primary→tertiary 그라디언트 라인
  - Actions: Settings(아이콘), Premium(아이콘)
- Body Stack
  - 배경 그라디언트(primary alpha + surface + secondaryContainer alpha)
  - SafeArea + SingleChildScrollView
  - Hero: 132.r 원 + 이모지 🎨
  - Title + Subtitle
  - Feature Chips Wrap (pen/marker/eraser/colors/undo/share)
  - Start Drawing CTA(그라디언트 + pulse 애니메이션) → `Routes.DRAW`
- Bottom: 광고 배너(비프리미엄)
- PopScope → ExitBottomSheet

## 5. 영향 분석

| Item | Impact |
|---|---|
| `DoodleController.saveCanvas` 호출처 | DrawPage 저장 버튼만 사용 → 동시 제거 |
| `DoodleController.shareCanvas` 호출처 | DrawPage 공유 버튼 → 유지 |
| `SettingController.logEvent` 호출처 | home_page, draw_page, settings_page → 모두 제거 |
| `Routes.GALLERY` 호출처 | home_page 단 1곳 → 제거 |
| Hive 박스 `phase1_activity_log` | 더 이상 쓰지 않음. 디바이스에 잔류 가능(무해). |
| `pubspec.yaml` lock | google_nav_bar 제거 후 `flutter pub get` 자동 실행됨 — Plan 단계에서는 수동 호출. |

## 6. Implementation Order
1. Code 삭제: 페이지 4종, 컨트롤러 3종, 서비스 1종.
2. `app_routes.dart` / `app_pages.dart` / `app_binding.dart` 정리.
3. `setting_controller.dart` 로깅 제거 + `clearAppSettings` 단순화.
4. `doodle_controller.dart` 갤러리 로직 제거.
5. 새 `home_page.dart` 작성(단일 HomePage).
6. `draw_page.dart` 저장 버튼/로깅 제거.
7. `settings_page.dart` Quick actions 정리.
8. `pubspec.yaml`에서 google_nav_bar 제거.
9. 테스트 갱신/삭제.
10. `flutter pub get` → `flutter analyze` → `flutter test`.

## 7. Test Plan
- L1 단위: `setting_controller_test.dart`의 잔존 테스트(언어 로드, rateApp, sendFeedback, openMoreApps, openPrivacyPolicy)는 그대로 통과해야 함.
- L2 위젯: 새 `HomePage`가 `Routes.DRAW` 진입 트리거 가능. Quick actions 정리 후 `settings_page_test.dart` 통과.
- L3 통합: `widget_test.dart` 스모크 테스트(앱 부팅) 통과.
