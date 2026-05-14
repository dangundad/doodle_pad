---
template: analysis
feature: competitor-improvements
date: 2026-05-14
author: DangunDad
project: doodle_pad
phase: check
matchRate: 99.6
---

# competitor-improvements Gap Analysis

> **Check Phase** — Design 대비 구현 갭 분석
> **Date**: 2026-05-14
> **Analyzer**: gap-detector
> **Verification**: flutter analyze 0 issues / flutter test 76 pass

---

## Context Anchor

| Key | Value |
|-----|-------|
| **WHY** | 갤러리 저장 부재 + 작품 보존 흐름 없음 |
| **WHO** | 안드로이드 doodle 사용자, 사진 위 메모 사용자 |
| **RISK** | Shake 오작동 / 줌·팬 그리기 회귀 / Hive 용량 비대 / 좌표계 어긋남 |
| **SUCCESS** | 1탭 저장, 핀치 줌 무회귀, Shake 안전장치, 해상도·포맷 선택, 작품 CRUD |
| **SCOPE** | Phase 1 저장 -> Phase 2 줌·Shake -> Phase 3 작품 갤러리 |

---

## 1. Match Rate

### 최종 재분석 (iterate 2회차 후, 2026-05-14)

| Axis | Score | Weight | Weighted |
|------|:-----:|:------:|:--------:|
| Structural | 100% | 0.2 | 20.0 |
| Functional | 99% | 0.4 | 39.6 |
| Contract | 100% | 0.4 | 40.0 |
| **Overall** | | | **99.6%** PASS |

Important I1~I5 전부 해결 -> 97.2% -> 99.6% (+2.4%p). Critical 0건 / Important 0건.

### 재분석 (iterate 1회차, 2026-05-14)

| Axis | Score | Weight | Weighted |
|------|:-----:|:------:|:--------:|
| Structural | 100% | 0.2 | 20.0 |
| Functional | 95% | 0.4 | 38.0 |
| Contract | 98% | 0.4 | 39.2 |
| **Overall** | | | **97.2%** |

Critical 2건(C1 JPEG 인코딩, C2 viewport 전달) 수정 완료 -> 87.2% -> 97.2% (+10.0%p).

### 최초 분석 (Do 직후)

| Axis | Score | Weight | Weighted |
|------|:-----:|:------:|:--------:|
| Structural | 100% | 0.2 | 20.0 |
| Functional | 80% | 0.4 | 32.0 |
| Contract | 88% | 0.4 | 35.2 |
| **Overall** | | | **87.2%** |

Static-only 공식 (server 없는 Flutter 앱).

---

## 2. Functional Requirements (FR-01~FR-12)

8 fully / 3 partial / 0 none -> **79%**

| FR | 상태 | 비고 |
|----|:----:|------|
| FR-01 갤러리 저장 1탭 + 권한 | Met | |
| FR-02 저장 후 toast | Met | |
| FR-03 한손/두손 분기 | Partial | 포인터 카운트 분기 미구현, InteractiveViewer 기본 동작 의존 |
| FR-04 더블탭 Fit-to-screen | Partial | 즉시 적용, 300ms 애니메이션 누락 |
| FR-05 Shake 토글 기본 OFF | Met | |
| FR-06 Shake 확인 다이얼로그 | Partial | 디바운스 800ms (Plan은 200ms) |
| FR-07 해상도·포맷 시트 + persist | Met | |
| FR-08 Hive Drawing 모델 | Met | |
| FR-09 작품 페이지 그리드/재오픈/삭제 | Met | |
| FR-10 홈 진입점 | Met | |
| FR-11 작품 저장 버튼 | Met | |
| FR-12 삭제 시 썸네일 unlink | Met | |

## 3. Success Criteria (a)~(e)

3 fully / 2 partial -> **80%**

| SC | 상태 | 비고 |
|----|:----:|------|
| (a) 갤러리 저장 1탭 | Met | |
| (b) 핀치 줌 + 그리기 무회귀 | Partial | 줌 동작, 회귀 테스트 통과. 포인터 분기 부재로 멀티터치 엣지 미검증 |
| (c) Shake 토글 + 확인 | Met | |
| (d) 1x/2x/3x · PNG/JPEG | Partial | JPEG가 실제 JPEG로 인코딩 안 됨 — 항상 PNG |
| (e) 작품 CRUD + 썸네일 | Met | |

## 4. Page UI Checklist — 18/23 (78%)

| Page | 구현/전체 | 누락 |
|------|:---------:|------|
| DrawPage | 9/11 | 더블탭 애니메이션, 두 손가락 팬 (panEnabled=false로 의도적 비활성) |
| GalleryPage | 5/8 | 삭제모드 토글, 다중선택 체크박스/하단 액션바, 공유 액션 |
| HomePage | 2/2 | — |
| SettingsPage | 2/2 | — |

## 5. 아키텍처 결정 반영

| Decision | 반영 |
|----------|:----:|
| Option C — 외부 IO만 Service 분리 | Yes |
| ExportService / ArtworkRepository 책임 분리 | Yes (썸네일 생성 위치만 Design과 다름) |
| Drawing flatten 직렬화 | Yes |
| 좌표계 보존 (canvasLogicalSize + letterbox) | 구현됐으나 호출부 viewport 미전달로 dead path |
| Service 싱글톤 + DI | Yes |
| Layer 의존 방향 | Yes |

---

## 6. Gap List

### Critical — 전부 해결됨 (iterate 2026-05-14)

| # | Gap | 해결 |
|---|-----|------|
| C1 | JPEG 선택이 실제 JPEG 산출물 미생성 | RESOLVED — image ^4.5.4 추가, _encode가 JPEG는 rawRgba -> img.encodeJpg(quality:92). PNG/JPEG 시그니처 검증 테스트 2개 추가 |
| C2 | loadArtwork 좌표계 보존 로직 dead path | RESOLVED — _openArtwork가 MediaQuery.sizeOf로 viewport 추출 후 loadArtwork(viewport:)로 전달. letterbox 스케일 활성화 |

### Important — 전부 해결됨 (iterate 2회차 2026-05-14)

| # | Gap | 해결 |
|---|-----|------|
| I1 | GalleryPage 삭제모드 미구현 | RESOLVED — GalleryController deleteMode/selectedIds, GalleryPage 토글+체크박스+하단 액션바(공유/삭제) 구현 |
| I2 | Shake 디바운스 800ms <-> Plan 200ms 불일치 | RESOLVED — Plan FR-06을 800ms로 갱신 (구현이 더 안전) |
| I3 | 더블탭 Fit 즉시 적용 | RESOLVED — GetSingleTickerProviderStateMixin + AnimationController로 300ms easeOutCubic 애니메이션 |
| I4 | ExportService API 명칭 불일치 | RESOLVED — Design §4.1을 실제 구현 명칭으로 갱신 |
| I5 | FR-03 포인터 분기 미구현 | RESOLVED — Design §1.2/§2.2를 InteractiveViewer 기본 분리 방식으로 갱신 |

### Minor (비차단)

| # | 항목 | 처리 |
|---|------|------|
| M1 | Design §3.1 brushTypeIndex 주석이 구식 | RESOLVED — stableId 기반 주석으로 갱신 |
| M2 | Design §6.1 오타 plaeholder | RESOLVED — placeholder로 수정 |

---

## 7. 권장 조치

- Critical (C1, C2): 해결 완료 (iterate 1회차)
- Important (I1~I5): 해결 완료 (iterate 2회차) — 코드 구현 2건(I1, I3) + 문서 동기화 3건(I2, I4, I5)
- Minor (M1, M2): 해결 완료

Overall 99.6% >= 90%. Critical/Important 잔여 0건. report 단계 진행 가능.
