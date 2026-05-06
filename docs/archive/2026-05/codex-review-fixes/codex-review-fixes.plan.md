# Plan: Codex 리뷰 후속 개선 (codex-review-fixes)

- 작성일: 2026-05-06
- 기준 문서: `docs/review_codex.md`

## Executive Summary

| Problem | Solution | Function/UX Effect | Core Value |
|---|---|---|---|
| 출시 직전 차단 요소(P0)와 일부 P1 항목이 코드에 그대로 남아 있음 | 핵심 코드 변경으로 릴리스 안정성과 사용자 경험을 동시에 개선 | 광고 동의 게이트, 메모리 안전한 캡처, 새 그림 진입 시 깨끗한 상태 | 출시 가능한 빌드와 신뢰할 수 있는 사용자 흐름 |

## Context Anchor

| 키 | 값 |
|---|---|
| WHY | Codex 리뷰에서 P0/P1 차단 요소가 다수 발견되어 릴리스 안전성을 확보해야 함 |
| WHO | 광고 노출/구매가 포함된 전 사용자 (특히 EU/UK) |
| RISK | 동의 전 광고 요청, 릴리스 빌드 실패, 캡처 OOM, 새 그림 진입 시 이전 stroke 잔존 |
| SUCCESS | analyze + test 통과, 광고 매니저는 동의 후에만 로드, 출시 ProGuard 규칙 존재 |
| SCOPE | P0-1, P0-2/P1-10, P1-1, P1-4, P1-5, P1-8 |

## 1. 범위 (선택적 채택)

본 문서에서 다루는 항목은 다음과 같다. 그 외 항목은 별도 사이클에서 다룬다.

채택:
- P0-1 ProGuard 규칙 누락
- P0-2 광고 동의 게이트 (P1-10 permanent 광고 매니저 강제 삭제 포함)
- P1-1 캡처 pixelRatio 동적화 + ui.Image dispose
- P1-4 새 그림 진입 시 strokes 초기화
- P1-5 참조 이미지만 있는 상태의 저장/공유 허용
- P1-8 supportedLocales를 실제 번역(en/ko)으로 제한

보류 (별도 작업으로 분리):
- P0-3 Privacy Policy URL: 코드 변경 외 외부 페이지 배포 필요
- P1-2 임시 PNG 정리: 최근 커밋(`447d29a`)으로 1차 처리됨
- P1-3 stroke repaint 최적화: 큰 리팩토링
- P1-6 갤러리 “불러오기” 의미: 문구/모델 재설계 필요
- P1-7 탭/route 흐름: 네비게이션 재설계 필요
- P1-9 IAP 상태 UI: 별도 사이클
- P1-11 IAP entitlement 서버 검증: 인프라 필요
- P1-12 ActivityLog 동시성: 별도 사이클
- P1-13 접근성 semantics: 별도 사이클
- P2 항목 전반

## 2. 요구사항

| ID | 요구사항 |
|---|---|
| R-1 | 릴리스 빌드가 참조하는 `android/app/proguard-rules.pro`가 존재한다 |
| R-2 | 광고 매니저(전면/보상/배너)는 UMP 동의 + MobileAds 초기화 완료 후에만 광고 요청을 보낸다 |
| R-3 | 프리미엄 활성화 시 permanent로 등록된 광고 매니저가 강제 삭제된다 |
| R-4 | 캔버스 캡처는 캔버스 크기에 비례해 pixelRatio를 동적으로 낮추고, `ui.Image`를 dispose한다 |
| R-5 | 홈/갤러리에서 “새 그림 시작” 진입 시 이전 stroke가 남지 않는다 |
| R-6 | 참조 이미지만 있어도 저장/공유가 가능하다 |
| R-7 | `Languages.supportedLocales`는 실제 번역 키가 채워진 locale만 노출한다 |

## 3. Success Criteria

- SC-1: `flutter analyze`가 `No issues found`로 통과
- SC-2: `flutter test`가 모든 케이스 통과 (신규 케이스 포함)
- SC-3: ProGuard 파일이 git에 추가됨
- SC-4: 광고 매니저가 `AdHelper.canRequestAds`가 true 가 되기 전에는 외부 플랫폼 채널 호출을 보내지 않음 (테스트로 고정)
- SC-5: `DoodleController.hasDrawableContent`가 strokes/reference 어느 한쪽이라도 있으면 true (테스트로 고정)
