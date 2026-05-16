# PRD — Pre-Release Audit Sprint

> Sprint ID: `pre-release-audit`
> Trust Level: L3 (prd → report 자동, archive 수동)
> 작성일: 2026-05-16
> 근거 문서: `review_claude.md` (배포 전 4영역 감사 결과)

## Context Anchor

- **WHY**: 1.0.0 스토어 제출 직전, 정책 위반·운영 사고로 직결되는 Blocker 5건을 제거해 안전한 첫 출시를 보장한다.
- **WHO**: 단독 운영자(@DangunDad). 단일 디바이스 빌드 + Play Console 제출 흐름.
- **RISK**: 테스트 광고 ID로 릴리스 시 AdMob 정책 위반, iOS App Store ID 미입력으로 평점/링크 깨짐, local.properties 기본값으로 Play Console 버전 충돌, UX 막다른 길로 부정 리뷰.
- **SUCCESS**: (1) flutter analyze 0 error, (2) flutter test 전부 통과, (3) Blocker 5건 코드 반영, (4) 회귀 없음.
- **SCOPE**: 코드 수정은 5개 Blocker에만 한정. Major/Minor는 1.0.1 백로그로 이관.

## Features (5)

| ID | 제목 | 파일 | 수용 조건 |
|----|------|------|-----------|
| B1 | iOS App Store ID 입력 | `lib/app/utils/app_constants.dart:55` | placeholder 제거 또는 iOS 비대상 명시 + 평점 흐름 분기 검증 |
| B2 | AdMob 환경변수 폴백 차단 | `lib/app/admob/ads_helper.dart:10-269` | 릴리스 빌드에서 env 미설정 시 즉시 fail-fast |
| B3 | local.properties 버전 동기화 | `android/local.properties` | pubspec(1.0.0+1)과 일치 + 문서화 |
| B4 | HomePage 다이얼로그 탈출 | `lib/app/pages/home/home_page.dart:21-109` | 취소 버튼 또는 barrierDismissible 허용 |
| B5 | 설정 데이터 삭제 후 일관성 | `lib/app/pages/settings/settings_page.dart:178-217` | 컨트롤러 재초기화 또는 재진입 안내 |

## Out of Scope

- Major 14건(영수증 검증, 그리드 반응형 등) → `docs/01-plan/TODO.md` 또는 1.0.1 sprint
- Minor 24건(접근성, 색맹 대응) → 백로그

## Quality Gates

- M3 critical issues: 0
- S1 data flow integrity: N/A(이번 sprint는 정적 감사)
- 분석/테스트: `flutter analyze` & `flutter test` 모두 통과
