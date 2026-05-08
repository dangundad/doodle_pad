---
template: plan
version: 1.3
feature: brush-overhaul
date: 2026-05-08
author: DangunDad
project: doodle_pad
version: 1.0.0+1
---

# brush-overhaul Planning Document

> **Summary**: 기존 5종 자체 구현 브러시 시스템을 `perfect_freehand` 기반의 통합 stroke 엔진 + 브러시 프리셋 7-8종으로 재제작한다.
>
> **Project**: doodle_pad
> **Version**: 1.0.0+1
> **Author**: DangunDad
> **Date**: 2026-05-08
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 5종 브러시(pen/marker/eraser/watercolor/airbrush)는 각자 별도 페인트 로직이라 신규 브러시 추가 비용이 크고, stroke 외형이 단순(고정 굵기)해 캐주얼 드로잉 앱 대비 표현력이 부족하다. |
| **Solution** | `perfect_freehand` 라이브러리로 stroke 외곽선을 압력/속도 기반으로 생성하고, 그 위에 brush별 `StrokeOptions` + 후처리(텍스처/blur/투명도) 프리셋 7-8종으로 통일된 브러시 시스템 구축. |
| **Function/UX Effect** | 펜/연필/마커/붓/형광펜/만년필/크레파스 + 기존 watercolor/airbrush를 모두 자연스러운 가변 굵기 stroke 위에서 표현. 신규 브러시 추가 비용은 `BrushPreset` 1개 정의로 축소. |
| **Core Value** | 캐주얼 드로잉 앱 카테고리에서 "표현 다양성"을 핵심 차별 포인트로 끌어올림. 광고 해금/공유/사진 위 그리기 등 기존 자산은 그대로 보존. |

---

## Context Anchor

| Key | Value |
|-----|-------|
| **WHY** | 단조로운 stroke와 brush별 분기 로직의 한계. 추가 브러시 도입 비용이 너무 크다. |
| **WHO** | 캐주얼 드로잉/낙서 사용자. 전문 일러스트보다 "기분에 맞는 브러시 고르기" 욕구가 큼. |
| **RISK** | (1) `perfect_freehand`는 outline 폴리곤을 반환하는 라이브러리이므로 RepaintBoundary 캡처/공유와 호환되는지 검증 필요. (2) 기존 watercolor/airbrush 광고 해금 자산을 새 brush 중 어느 항목으로 매핑할지 사용자 경험 충돌 위험. (3) `_undoStack`/`DrawingStroke` 자료형 변경 시 광범위 회귀. |
| **SUCCESS** | 7-8종 브러시 모두 동일한 stroke 엔진에서 동작 / 기존 `flutter analyze` & `flutter test` 통과 / 공유 PNG 결과물에 brush별 차이 시각적으로 구분 / 신규 brush 추가에 필요한 코드 ≤ 30줄 |
| **SCOPE** | M1 stroke 엔진 교체 → M2 BrushPreset 정의 + UI 매핑 → M3 광고 해금 재매핑 → M4 회귀 테스트 + 문서 |

---

## 1. Overview

### 1.1 Purpose

캐주얼 드로잉 앱으로서의 "브러시 표현력"을 한 단계 끌어올리고, 향후 브러시 추가/조정 비용을 낮춘다.

### 1.2 Background

- 사용자(소유자)가 "펜 종류를 바꾸고 싶다 — 일반펜, 붓, 크레파스" 요청.
- 단순 enum 추가가 아니라 stroke 엔진 자체를 통합/업그레이드해서 다양성을 자연스럽게 늘리는 방향이 합의됨.
- pub.dev 조사 결과 통합 보드 패키지(`flutter_drawing_board`)는 기존 자산(광고 해금, 공유 캡처, 사진 위 그리기, 캔버스 색상)과 충돌이 큼. 라이브러리형 `perfect_freehand`가 적합.

### 1.3 Related Documents

- 기존 컨트롤러: `lib/app/controllers/doodle_controller.dart`
- 기존 페인터: `lib/app/pages/draw/widgets/canvas_painter.dart`
- 직전 사이클 검토: `review_codex.md`
- 외부 참고: https://pub.dev/packages/perfect_freehand , https://github.com/steveruizok/perfect-freehand

---

## 2. Scope

### 2.1 In Scope

- [ ] `perfect_freehand` 의존성 추가
- [ ] `DrawingStroke` 자료형이 brush별 `StrokeOptions`를 들고 다니도록 확장
- [ ] `BrushPreset` 모델(이름, StrokeOptions, 후처리 옵션, 광고 해금 여부, 아이콘) 정의
- [ ] 신규 브러시 7-8종 프리셋: pen, pencil, marker, brush(붓), highlighter, fountainPen, crayon, + 기존 watercolor/airbrush 재제작 (eraser는 별도 path)
- [ ] `CanvasPainter` 재제작: brush별 outline path + 후처리(텍스처 노이즈, blur, multi-pass alpha)
- [ ] `_BrushTypeSelector` UI: 가로 스크롤 안에서 7-8종 표시 + 잠금 아이콘 처리
- [ ] 보상형 광고 해금 자산 재매핑 (2개 선정)
- [ ] 11개 언어 번역키 (브러시 이름) 추가
- [ ] 기존 단위/위젯 테스트가 새 시스템에서도 통과하도록 갱신
- [ ] README/docs/store 문서의 브러시 목록 업데이트

### 2.2 Out of Scope

- 레이어 기능
- pen pressure 실측(태블릿/스타일러스 압력 API). `simulatePressure` 기반 가변 굵기로 한정.
- zoom/pan, infinite canvas
- 사용자 정의 브러시 에디터(StrokeOptions 슬라이더 노출)
- watercolor/airbrush의 보상형 광고 해금 정책 자체 변경(매핑만 갱신)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 사용자가 7-8종 브러시 중 하나를 선택해 즉시 그리기 가능 | High | Pending |
| FR-02 | brush별로 stroke 외형(굵기 변동, taper, cap, 텍스처)이 시각적으로 구분 | High | Pending |
| FR-03 | 모든 브러시(eraser 제외) stroke가 동일한 `getStroke()` 엔진을 통과 | High | Pending |
| FR-04 | 기존 광고 해금 흐름 유지 — 무료 사용자가 잠긴 브러시를 선택하면 보상형 광고 다이얼로그 노출 | High | Pending |
| FR-05 | brush 변경 후 기존 색상/크기 슬라이더가 그대로 적용 | Medium | Pending |
| FR-06 | undo/redo, clear, 사진 위 그리기, 공유, RepaintBoundary 캡처 모두 정상 동작 | High | Pending |
| FR-07 | 11개 언어 모두에서 새 브러시 이름이 노출 | Medium | Pending |
| FR-08 | 잠금/언락 상태 영속화는 기존 Hive 키와 호환되거나 마이그레이션 명시 | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 100 stroke + 평균 50 point 환경에서 60 fps 유지 (Pixel 6 등 중급 기기 기준) | 수동 + Flutter DevTools 프로파일 |
| Performance | 캔버스 PNG 캡처 시간 변동이 기존 대비 +20% 이내 | 공유 시점 측정 로그 |
| Stability | `flutter analyze` 무이슈 / `flutter test` 100% 통과 | CI 미사용, 로컬 명령 결과 |
| Compatibility | Android 13~15 실제 기기에서 동일 동작 | 실기기 QA |
| Maintainability | 신규 브러시 1종 추가에 필요한 변경 ≤ 30줄 | Design 단계 코드 검사 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] 7-8종 brush 모두 동일한 stroke 엔진에서 그려진다
- [ ] eraser 동작이 BlendMode.clear 기반으로 정상
- [ ] 광고 해금 다이얼로그가 매핑된 브러시 2개에서만 표시됨
- [ ] 기존 home/draw/share 흐름 회귀 없음
- [ ] 단위 + 위젯 테스트 갱신 후 통과
- [ ] README, docs/TODO.md, docs/store/google-store.md(11개 언어 brush 목록), docs/store/google-ads-subscription.md 갱신

### 4.2 Quality Criteria

- [ ] `flutter analyze` 0 이슈
- [ ] `flutter test` 전체 통과
- [ ] 새 브러시 비교 스크린샷 1세트(개발자 검수용) 캡처 가능

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `perfect_freehand` outline 폴리곤이 기대만큼 자연스럽지 않다 | Medium | Low | Excalidraw가 동일 라이브러리 사용. 초기 PoC로 pen 1종만 검증 후 진행. |
| 기존 `DrawingStroke` 변경으로 광고 해금/멀티터치/undo 회귀 | High | Medium | `BrushType` enum 유지하면서 내부 stroke 자료형만 확장. 기존 테스트를 우선 통과시키고 신규 테스트 추가. |
| 가로 스크롤 brush 셀렉터에 7-8종이 들어가면 작은 기기에서 답답 | Low | High | 32-44px 셀 + 스크롤 indicator 또는 그룹화. Design에서 결정. |
| watercolor 보상형 광고 해금 자산이 새 매핑에서 사용자에게 어색 | Medium | Medium | "해금된 브러시는 자동 인계"되도록 마이그레이션 로직. Hive 키는 일반화된 이름(`unlocked_brushes`)으로 변경하거나 기존 키와 매핑 테이블 유지. |
| 후처리(텍스처 노이즈)로 PNG 캡처 시 메모리 사용 증가 | Medium | Low | 기존 8MP pixel ratio 제한 유지. multi-pass는 paint reuse로 GC 부하 최소화. |
| Flutter SDK 호환성 (`perfect_freehand` 버전) | Low | Low | Plan 직후 `flutter pub get`으로 즉시 검증. |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| `BrushType` enum | Dart enum | 값 추가/재정의 (eraser는 유지, 나머지는 재정의) |
| `DrawingStroke` 클래스 | Dart class | brush별 옵션을 담을 필드 추가 (`StrokeOptions`, 후처리 메타) |
| `CanvasPainter` | CustomPainter | `_drawNormal/_drawWatercolor/_drawAirbrush` 제거 후 `BrushPreset.render(canvas, stroke)` 호출 구조로 통일 |
| `DoodleController` | GetxController | `brushType` 변경 시 새 BrushPreset에서 옵션 가져오기. `unlock` 키 일반화. |
| `_BrushTypeSelector` | Widget | 7-8종 표시, 잠금 표시, 스크롤 |
| `pubspec.yaml` | Manifest | `perfect_freehand` 의존성 |
| `translate.dart` | i18n | 새 브러시 이름 11개 언어 |
| Hive 설정 키 | Storage | 기존 `watercolor_unlocked` / `airbrush_unlocked` → 새 잠금 매핑으로 마이그레이션 |

### 6.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `BrushType` | READ | `_BrushTypeSelector`, `_BrushSizeSlider`(eraser 분기), `_ColorPalette`(eraser 분기), `CanvasPainter.paint` switch | Breaking — 기존 enum 값 일부 의미 바뀜 |
| `DrawingStroke` | CREATE | `DoodleController.startStroke`, undo/redo 스택 | Breaking — 필드 추가 |
| `_BrushTypeSelector` 잠금 | READ | `DoodleController.isBrushUnlocked` / `unlockBrush` | Breaking — watercolor/airbrush 외 다른 brush가 잠금 자산이 됨 |
| `referenceImagePath` | READ | DrawPage Stack | None — 기존 그대로 |
| `canvasKey` capture | READ | `shareCanvas` | None — RepaintBoundary 캡처 흐름 동일 |
| Hive 설정 | READ/WRITE | `_loadBrushUnlockState`, `unlockBrush` | Needs migration — 기존 키 deprecation 처리 |

### 6.3 Verification

- [ ] 모든 consumer 검증 완료
- [ ] watercolor/airbrush 잠금 자산이 새 매핑으로 자동 인계되는지 확인
- [ ] 기존 단위/위젯 테스트가 새 enum 값에서 깨지지 않도록 업데이트

---

## 7. Architecture Considerations

### 7.1 Project Level Selection

본 프로젝트는 Flutter Android 앱이라 위 표(Web Starter/Dynamic/Enterprise)는 직접 적용되지 않는다. 다만 앱 단위로는 **Dynamic 수준의 feature 모듈 구조**를 유지한다.

### 7.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Stroke 엔진 | 자체 quadratic bezier / `perfect_freehand` / `flutter_drawing_board` 내장 | **perfect_freehand** | Excalidraw 사용 검증, 라이브러리형이라 기존 자산 보존 가능, pressure 시뮬 |
| Brush 정의 모델 | enum + switch / `BrushPreset` 데이터 객체 | **BrushPreset 객체 (Map<BrushType, BrushPreset>)** | 신규 brush 추가를 데이터 추가 1줄로 축소 |
| 잠금 키 저장 | brush별 Hive bool 키 / 단일 `unlocked_brushes` Set | **단일 Set + 기존 키 마이그레이션** | brush 종류가 늘어남에 따른 키 증식 방지 |
| eraser 처리 | `perfect_freehand` 통과 / 별도 분기 | **별도 분기 유지** | BlendMode.clear는 외곽선 폴리곤이 아니라 path 기반이 더 안전 |
| 후처리(textures, blur) | shader / multi-pass paint / Image asset | **multi-pass paint + Random noise** | 외부 shader 의존 없이 코드 내 결정. 기존 watercolor blur 방식 재사용. |
| 광고 해금 자산 매핑 | crayon+fountainPen / brush+crayon / pencil+highlighter | **Design 단계에서 확정** | UX 어색하지 않은 조합을 mock UI 보면서 결정 |

### 7.3 Clean Architecture Approach

Flutter Dynamic 수준 — `lib/app/{controllers, pages, widgets, services, theme, translate, utils}` 기존 구조 유지. 신규 추가:

```
lib/app/
├── controllers/
│   └── doodle_controller.dart        # BrushType enum, BrushPreset 매핑 사용
├── data/
│   └── brushes/
│       ├── brush_preset.dart         # BrushPreset 모델 (NEW)
│       └── brush_presets.dart        # 7-8종 프리셋 정의 (NEW)
└── pages/draw/widgets/
    └── canvas_painter.dart           # BrushPreset.render(canvas, stroke) 호출
```

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [x] `CLAUDE.md` 프로젝트 규칙 (한국어 소통, Android 우선, GetX/Hive 패턴 유지)
- [x] `analysis_options.yaml` (flutter_lints)
- [x] `pubspec.yaml` 기존 의존성 패턴

### 8.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Brush 식별 키 네이밍** | snake_case (`watercolor_unlocked`) | `BrushType.name`을 그대로 잠금 Set의 원소로 사용 | High |
| **새 폴더 `data/brushes/`** | 없음 | Plan 7.3 구조 신설 | Medium |
| **퍼블릭 API 노출** | DoodleController에 직접 노출 | BrushPreset은 데이터 클래스, 외부 노출 안 함 | Low |

### 8.3 Environment Variables Needed

해당 없음 — 클라이언트 전용 변경.

---

## 9. Next Steps

1. [ ] `/pdca design brush-overhaul` — 3가지 아키텍처 옵션 비교 후 선택
2. [ ] PoC: `perfect_freehand` 단독 pen 렌더링 검증 (기존 stroke 자료형 임시 매핑)
3. [ ] BrushPreset 매핑 표 확정 (광고 해금 2종 선정)
4. [ ] 회귀 테스트 보강 후 구현 진입

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-08 | Initial draft | DangunDad |
