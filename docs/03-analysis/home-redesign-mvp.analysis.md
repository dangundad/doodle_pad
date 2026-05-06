# Analysis — home-redesign-mvp

> Generated: 2026-05-06
> Plan: `docs/01-plan/features/home-redesign-mvp.plan.md`
> Design: `docs/02-design/features/home-redesign-mvp.design.md`

## Context Anchor

| Key | Value |
|---|---|
| WHY | 미니멀 MVP. 홈→그리기 1탭. |
| WHO | doodle_pad Android 사용자. |
| RISK | 갤러리 회수 동선 제거. |
| SUCCESS | analyze/test 통과 + nav_bar 제거 + 단일 홈. |
| SCOPE | UI 단순화 + 페이지/서비스 제거. |

## Match Rate Summary
- Structural: 100%
- Functional: 100%
- Static-only mode (no runtime server). Overall ≈ 100%.

## Success Criteria 검증

| ID | 기준 | 결과 | 증거 |
|---|---|---|---|
| SC-1 | `pubspec.yaml`에 `google_nav_bar` 미존재 | ✅ Met | `pubspec.yaml` grep 결과 0건 |
| SC-2 | 갤러리/기록/통계/main_shell/home_controller/activity_log/two analytic controllers 삭제 | ✅ Met | `lib/app/pages` 하위에 gallery/history/stats 디렉터리 없음. 컨트롤러/서비스 파일 부재 |
| SC-3 | `flutter analyze` 통과 | ✅ Met | `No issues found! (ran in 8.5s)` |
| SC-4 | `flutter test` 통과 | ✅ Met | `All tests passed!` 25/25 |
| SC-5 | INITIAL 진입 시 단일 홈 표시 | ✅ Met | `app_pages.dart`에서 `_Paths.HOME` 페이지가 `HomePage` 단일 위젯 |

## 변경 사항 요약

### 삭제(8 파일)
- `lib/app/pages/gallery/gallery_page.dart`
- `lib/app/pages/history/history_page.dart`
- `lib/app/pages/stats/stats_page.dart`
- `lib/app/pages/home/main_shell_page.dart`
- `lib/app/controllers/history_controller.dart`
- `lib/app/controllers/stats_controller.dart`
- `lib/app/controllers/home_controller.dart`
- `lib/app/services/activity_log_service.dart`
- (테스트) `test/app/pages/home/home_page_test.dart`

### 수정
- `pubspec.yaml` — google_nav_bar 제거.
- `lib/app/routes/app_pages.dart`, `app_routes.dart` — gallery/history/stats 라우트와 상수 제거.
- `lib/app/bindings/app_binding.dart` — Activity/History/Stats 등록 제거.
- `lib/app/controllers/setting_controller.dart` — ActivityLogService 의존, `logEvent`, `recordHomeOpen`, `recordSettingsOpen` 제거. `clearAppSettings`에서 활동 로그 정리 호출 제거.
- `lib/app/controllers/doodle_controller.dart` — `savedDrawings`, `_loadSavedPaths`, `_savePng`, `saveCanvas`, `deleteDrawing`, `_savedPathsKey`, `isSaving` 제거. `shareCanvas`/`hasDrawableContent`/`referenceImagePath` 유지.
- `lib/app/pages/home/home_page.dart` — 단일 `HomePage` 스캐폴드로 재작성. AppBar에 Premium/Settings 액션. 본문은 hero/feature chips/start CTA. 광고 배너는 비프리미엄에서만 노출. PopScope→ExitBottomSheet.
- `lib/app/pages/draw/draw_page.dart` — 저장 버튼 제거, `logEvent` 호출 제거.
- `lib/app/pages/settings/settings_page.dart` — Quick actions에서 history/stats 항목 제거(Premium만 유지). `_track` 제거.
- `test/app/controllers/setting_controller_test.dart` — ActivityLogService 의존 테스트 제거.

## Decision Record 검증
| 결정 | 따랐는가 | 비고 |
|---|---|---|
| Gallery 진입 동선 + 내부 저장 트래킹 제거, 공유만 유지 | ✅ | DrawPage 저장 버튼 제거, share만 노출 |
| ActivityLogService 전체 제거 | ✅ | import/등록/호출처 0건 |
| HomeController 제거 | ✅ | 미사용으로 삭제 |
| 번역 키는 후속 작업 | ✅ | translate.dart 미변경 |
| Quick actions에서 Premium만 유지 | ✅ | settings_page에 단일 항목 |

## Residual References Scan
명령어: `grep -rn "google_nav_bar|MainShellPage|ActivityLogService|HistoryController|StatsController|HomeController|GalleryPage|HistoryPage|StatsPage|saveCanvas|savedDrawings|deleteDrawing|recordHomeOpen|logEvent|Routes\.GALLERY|Routes\.HISTORY|Routes\.STATS" lib test`
결과: **0건**.

## Risks Resolved
- 갤러리 회수 동선 제거 → DrawPage 공유 버튼이 OS 공유 시트 호출(저장 가능).
- 기존 `phase1_activity_log` Hive 박스는 단말에 잔류할 수 있으나 코드 경로가 없으므로 무해.

## Next Phase
→ `report`
