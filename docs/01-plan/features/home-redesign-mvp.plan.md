# Plan — home-redesign-mvp

> Generated: 2026-05-06
> Source: `modify.md`

## Executive Summary

| 관점 | 요약 |
|---|---|
| Problem | 홈 화면에 4개 탭(홈/갤러리/기록/통계)이 노출되며 본질 기능(그리기)에서 주의가 분산됨. `google_nav_bar` 의존성과 분석성 화면(History/Stats)이 유지 비용을 키움. |
| Solution | 미니멀 MVP 형태로 홈/설정/프리미엄/그리기 4개 화면만 남기고, 단일 홈에서 곧장 그리기 진입. 분석/갤러리 기능 및 활동 로깅 제거. |
| Function/UX 효과 | 진입 1탭(홈) → CTA 1개(그리기 시작). 하단탭/저장 갤러리 제거로 시각적 노이즈 감소, 광고 배너는 그대로 유지. |
| Core Value | 핵심 기능 집중과 유지보수 비용 감소. 코드/패키지/번역 부담 동시 절감. |

## Context Anchor

| Key | Value |
|---|---|
| WHY | "미니멀 MVP" 방향. 사용자가 핵심(그리기)에 즉시 도달하도록 구조 단순화. |
| WHO | DangunDad doodle_pad Android 사용자. |
| RISK | 저장된 그림 데이터 회수 동선 사라짐 — 공유(Share)로 대체. 기존 사용자 PNG 파일은 앱 내부 docs에 잔류(접근 UI 없음). |
| SUCCESS | (1) 빌드/테스트 통과, (2) 홈→그리기까지 1탭, (3) `google_nav_bar` 미참조, (4) `flutter analyze` 0 issue. |
| SCOPE | UI 단순화 + 페이지/패키지/서비스 제거. 기능 추가 없음. |

## 1. Background

`modify.md` 요청: 홈 UI 전면 개편 + `google_nav_bar` 제거 + 홈/설정/프리미엄만 유지하고 나머지 화면/기능 제거. 미니멀 MVP 지향.

## 2. Requirements

### 2.1 기능
- 단일 홈 화면(타이틀, 핵심 기능 칩, 그리기 시작 CTA, 저장 그림 카드 제거).
- 홈 → 그리기 진입(`Routes.DRAW`).
- 홈 우상단에서 설정/프리미엄 진입.
- DrawPage 상단툴바: 뒤로/Undo/Redo/지우기/공유. 저장 버튼 제거.
- Settings: Quick actions에서 history/stats 제거, premium만 유지.

### 2.2 비기능
- `flutter analyze` 0 issue.
- `flutter test` 통과(영향 받는 테스트 갱신).
- 광고 배너 유지(비프리미엄 유저).
- 시스템 백버튼 → ExitBottomSheet 유지.

## 3. Non-goals
- 다국어 미사용 키 일괄 정리(후속 작업).
- iOS 전용 변경.
- 디자인 토큰/테마 재정의.
- 새 기능 추가.

## 4. Success Criteria
- SC-1: `pubspec.yaml`에 `google_nav_bar` 미존재.
- SC-2: `lib/app/pages/{gallery,history,stats}/`, `main_shell_page.dart`, `home_controller.dart`, `activity_log_service.dart`, 두 컨트롤러(history/stats) 삭제.
- SC-3: `flutter analyze` 통과.
- SC-4: `flutter test` 통과(필요 시 테스트 수정).
- SC-5: 라우트 진입 — 시작 시 단일 홈에 도달.

## 5. Risks & Mitigations
| Risk | Mitigation |
|---|---|
| 기존 저장 그림 회수 불가 | 공유 기능 유지로 OS 공유 시트로 외부 저장 가능. |
| 테스트 회귀 | 영향 받는 테스트(home_page_test, setting_controller_test) 즉시 갱신. |
| 미사용 import 잔존 | analyze 단계에서 잡고 정리. |

## 6. Out of Scope (Deferred)
- 미사용 번역 키 정리.
- Hive 박스(`phase1_activity_log`) 사용자 단말 정리.
