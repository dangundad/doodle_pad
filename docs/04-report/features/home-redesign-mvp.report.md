# Report — home-redesign-mvp

> Generated: 2026-05-06
> Plan / Design / Analysis 완료, Match Rate 100%

## Executive Summary

| 관점 | 결과 |
|---|---|
| Problem | 4개 탭 + 분석 화면 + 갤러리 트래킹으로 본질(그리기) 흐름이 분산되었음. |
| Solution | 홈/그리기/설정/프리미엄 4개 화면 구조로 축소. `google_nav_bar` 의존성 제거, ActivityLogService 및 갤러리 로직 제거. |
| Function/UX | AppBar 우상단 Premium/Settings 진입 + 단일 Start CTA. 그리기 화면에서는 Share만 유지. |
| Core Value | 코드량/패키지/Hive 박스/번역 부담 감소. `flutter analyze` 0 issue, `flutter test` 25/25 통과. |

### Value Delivered (1.3)
| 지표 | 결과 |
|---|---|
| 삭제된 페이지 | 4개 (gallery/history/stats/main_shell) |
| 삭제된 컨트롤러/서비스 | 4개 (HomeController/HistoryController/StatsController/ActivityLogService) |
| 제거된 의존성 | google_nav_bar |
| flutter analyze | 0 issues |
| flutter test | 25 passed / 0 failed |
| 잔존 참조 (grep) | 0 |

## Key Decisions & Outcomes

| 결정 (Plan/Design) | 실제 결과 |
|---|---|
| Pragmatic Balance — 페이지/컨트롤러 단위 삭제만 수행 | ✅ 계획대로 |
| 공유만 유지, 내부 저장 트래킹 제거 | ✅ DrawPage 저장 버튼 제거 |
| ActivityLogService 완전 제거 | ✅ 0건 잔존 |
| 번역 키 정리는 후속 작업으로 보류 | ✅ translate.dart 미변경 |

## Success Criteria Final Status

| ID | 기준 | 상태 |
|---|---|---|
| SC-1 | google_nav_bar 미존재 | ✅ Met |
| SC-2 | 대상 8 파일 삭제 | ✅ Met |
| SC-3 | flutter analyze 통과 | ✅ Met |
| SC-4 | flutter test 통과 | ✅ Met |
| SC-5 | INITIAL → 단일 HomePage | ✅ Met |

Overall Success Rate: 5/5 (100%)

## Verification Log

```
flutter pub get  → Got dependencies!
flutter analyze  → No issues found! (ran in 8.5s)
flutter test     → 00:10 +25: All tests passed!
```

## Follow-ups — 적용 완료

### 1. 미사용 번역 키 정리 ✅
- `lib/app/translate/translate.dart`에서 19개 키 × 11개 locale = **209 라인 제거**.
- 제거 키: `nav_home`, `nav_gallery`, `nav_history`, `nav_stats`, `gallery`, `gallery_subtitle`, `saved_drawings`, `delete_drawing`, `delete_drawing_complete`, `delete_drawing_confirm`, `delete_error`, `save_canvas`, `save_success`, `save_error`, `history_subtitle`, `open_history`, `open_history_desc`, `open_stats`, `open_stats_desc`.
- `gallery_empty`는 `DoodleController.shareCanvas` fallback 메시지로 사용 중이므로 보존.
- 파일 크기: 1455 → 1246 라인.

### 2. Hive 레거시 박스 정리 ✅
- `lib/app/bindings/app_binding.dart`에 `_legacyBoxNames` 상수 + `_purgeLegacyHiveBoxes()` 도입.
- `initializeCoreServices()` 종료 시 `phase1_activity_log` 박스를 닫고 디스크에서 삭제.
- 실패는 `Get.log`로만 기록(앱 부팅 흐름 차단 방지).

### 3. HomePage 위젯 테스트 ✅
- 신규 `test/app/pages/home/home_page_test.dart` — 6 케이스:
  - 프리미엄 활성 시 `BannerAdWidget` 미표시.
  - 프리미엄 비활성 시 `BannerAdWidget` 표시.
  - Settings 아이콘 탭 → `/settings`.
  - Premium 아이콘 탭 → `/premium`.
  - "Start Drawing" CTA 탭 → 캔버스 초기화 + `/draw`.
  - 시스템 백 → `ExitBottomSheet` 노출.

### 검증
```
flutter analyze  → No issues found! (ran in 79.0s)
flutter test     → 31 passed (기존 25 + HomePage 신규 6)
```

