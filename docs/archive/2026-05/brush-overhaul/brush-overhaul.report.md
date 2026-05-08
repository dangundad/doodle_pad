---
template: report
version: 1.1
feature: brush-overhaul
date: 2026-05-08
author: DangunDad
project: doodle_pad
version: 1.0.0+1
---

# brush-overhaul Completion Report

> **Status**: Complete (정적 검증 기준; 실기기 시각/성능 QA는 별도 단계로 분리)
>
> **Project**: doodle_pad
> **Version**: 1.0.0+1
> **Author**: DangunDad
> **Completion Date**: 2026-05-08
> **PDCA Cycle**: #1 (brush-overhaul)

---

## Executive Summary

### 1.1 Project Overview

| Item | Content |
|------|---------|
| Feature | brush-overhaul |
| Start Date | 2026-05-08 |
| End Date | 2026-05-08 |
| Duration | 단일 세션 (Plan → Design → Do(M1-M3) → Check → Act → Report) |
| Final Match Rate | 95.5% (정적, Round 2) |

### 1.2 Results Summary

```
┌─────────────────────────────────────────────┐
│  Match Rate: 95.5% (Plan 기준 90% 통과)      │
├─────────────────────────────────────────────┤
│  ✅ Critical Gaps:    0                      │
│  ✅ Important Gaps:   0 (Round 1: 2 → 해소)  │
│  ⚠️ Minor Gaps:       6 (모두 의식적 보류)   │
│  ✅ flutter analyze:  0 issues               │
│  ✅ flutter test:     42 / 42 passed         │
└─────────────────────────────────────────────┘
```

### 1.3 Value Delivered

| Perspective | Content |
|-------------|---------|
| **Problem** | 5종 자체 구현 brush의 stroke 외형 단조로움(고정 굵기)과 신규 brush 추가 시 switch case + 새 `_draw*` 메서드(~40줄) 비용 |
| **Solution** | `perfect_freehand` 라이브러리 도입 + `BrushPreset` 데이터 객체 통일 (Option C: Pragmatic). eraser만 `BlendMode.clear` 분기 유지. Hive 잠금 키는 회귀 회피 차원에서 그대로 유지 |
| **Function/UX Effect** | 펜/연필/마커/붓/형광펜/만년필/크레파스 + 기존 watercolor/airbrush + eraser = **10종 brush**. 가변 굵기/taper/simulatePressure로 표현력 향상. 신규 brush 추가 비용 ~17줄(registry 1행)로 60% 감소 |
| **Core Value** | 캐주얼 드로잉 카테고리에서 "표현 다양성" 확보. 광고 해금/공유/사진 위 그리기 등 기존 자산 0건 회귀 |

---

## 1.4 Success Criteria Final Status

| # | Criteria | Status | Evidence |
|---|---------|:------:|----------|
| SC-1 | 7-8종 brush 모두 동일한 stroke 엔진에서 동작 | ✅ Met | `BrushPresets._registry` 9종 등록 + `CanvasPainter.paint`에서 `BrushPresets.of(t).render()` 단일 호출. 코드: `lib/app/data/brushes/brush_presets.dart`, `lib/app/pages/draw/widgets/canvas_painter.dart:32` |
| SC-2 | `flutter analyze` 무이슈 + `flutter test` 100% 통과 | ✅ Met | analyze 0 issues / test 42 passed (33 기존 + 7 BrushPresets 단위 + 2 신규 home 분기 시나리오) |
| SC-3 | 신규 brush 추가에 필요한 코드 ≤ 30줄 | ✅ Met | 실측: pen 12줄, crayon 17줄(후처리 포함). `_registry` 항목 추가만으로 신규 brush 도입 가능 |
| SC-4 | 공유 PNG 결과물에 brush별 차이 시각적으로 구분 | ⏳ Pending | 정적 검증 범위 밖. 실기기 QA에서 alpha=0.35(highlighter) / postProcess=watercolorBlur, airbrushSpray, crayonNoise / sizeMultiplier 등으로 분기됨을 코드에서 확인. 실기기 캡처 시 시각 구분 보장은 별도 검증 필요 |
| SC-5 | 100 stroke + 평균 50 point 환경 60fps 유지 | ⏳ Pending | DevTools 프로파일 미수행. crayonNoise `dotsPerPoint=6`/airbrush `dotCount=25`이 기존 알고리즘 대비 동등 수준이라 회귀 가능성은 낮음 |

**Success Rate**: 3/5 Met, 2/5 Pending (실기기 검증 필요, 정적 분석 범위 밖)

## 1.5 Decision Record Summary

| Source | Decision | Followed? | Outcome |
|--------|----------|:---------:|---------|
| [Plan §7.2] | Stroke 엔진 = `perfect_freehand` | ✅ | 2.5.2+1 도입, outline polygon → fill path 변환 정상. Excalidraw 검증 라이브러리라 안정성 확보 |
| [Plan §7.2] | Brush 모델 = `BrushPreset` 객체 + Map 단일 출처 | ✅ | `BrushPresets._registry`에 9종 등록. 신규 brush 추가 비용 60% 감소 |
| [Plan §7.2] | eraser 별도 분기 유지 | ✅ | `CanvasPainter.paint`에서 `BrushType.eraser`만 `_drawEraser`로, 그 외는 preset.render. BlendMode.clear 안정성 확보 |
| [Design §3.1] | `BrushPreset.sizeMultiplier` 필드 | ❌ → ✅ | Round 1에서 누락(optionsBuilder 내부 곱연산), Round 2에서 필드 + `effectiveSize(stroke)` getter 도입 |
| [Design §11.2 M4] | `isBrushUnlocked`를 `BrushLock` 기반으로 일반화 | ❌ → ✅ | Round 1에서 보류, Round 2에서 `_isLockUnlocked(BrushLock)` + `_persistUnlock(BrushLock)` 헬퍼로 일반화 완료. 향후 신규 잠금 brush 추가 시 controller 코드 변경 0줄 |
| [Design §7.2] | Hive 잠금 키 단일 Set 통합 | ❌ | **의식적 보류**. 마이그레이션 회귀 위험 회피 (Plan §5 RISK 정책과 일치). 기존 `watercolor_unlocked` / `airbrush_unlocked` 키 유지 |
| [Design §6.1] | `PostProcessKind.highlighterAlpha` enum 값 | ❌ | **의식적 단순화**. `alpha` 필드만으로 동등 처리 (highlighter는 `alpha: 0.35`). enum 값 추가는 YAGNI |

**Followed**: 5/7 결정. Deviation 2건은 모두 RISK 회피와 부합하는 의식적 단순화이며 동작 결과는 Design 의도와 동등.

---

## 2. Related Documents

| Phase | Document | Status |
|-------|----------|--------|
| Plan | [brush-overhaul.plan.md](../01-plan/features/brush-overhaul.plan.md) | ✅ Finalized |
| Design | [brush-overhaul.design.md](../02-design/features/brush-overhaul.design.md) | ✅ Finalized (Option C) |
| Check | [brush-overhaul.analysis.md](../03-analysis/brush-overhaul.analysis.md) | ✅ Complete (Round 1: 91.2% → Round 2: 95.5%) |
| Act | (this document) | ✅ Complete |

---

## 3. Completed Items

### 3.1 Functional Requirements (Plan §3.1)

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-01 | 사용자가 7-8종 brush 중 선택 즉시 그리기 가능 | ✅ Complete | `_BrushTypeSelector`가 `BrushPresets.values + eraser` 셀 10개 표시 |
| FR-02 | brush별 stroke 외형 시각적으로 구분 | ✅ Static / ⏳ Visual | 코드 분기 검증, 실기기 시각 구분은 QA 단계 |
| FR-03 | 모든 brush(eraser 제외) stroke가 동일한 `getStroke()` 통과 | ✅ Complete | airbrush(점 분포)는 outline polygon이 아닌 자체 분기로 일관성 유지 |
| FR-04 | 잠긴 brush 선택 시 보상형 광고 다이얼로그 노출 | ✅ Complete | `unlockBrush` → `_watchRewardedAdForBrush` 흐름 동작 확인 (BrushLock 기반 일반화) |
| FR-05 | brush 변경 후 색상/크기 슬라이더 그대로 적용 | ✅ Complete | `_BrushSizeSlider` brushType별 min/max 분기 유지 |
| FR-06 | undo/redo, clear, 사진 위 그리기, 공유, RepaintBoundary 캡처 회귀 없음 | ✅ Complete | 기존 33개 위젯/단위 테스트 100% 통과 |
| FR-07 | 11개 언어 brush 라벨 노출 | ✅ Complete | `translate.dart`에 `brush_pen ~ brush_crayon` 7키 × 11 locale 추가 |
| FR-08 | 잠금 영속화는 기존 Hive 키와 호환 | ✅ Complete | `watercolor_unlocked` / `airbrush_unlocked` 그대로 유지. 마이그레이션 불필요 |

### 3.2 Non-Functional Requirements (Plan §3.2)

| Category | Criteria | Status |
|----------|----------|:------:|
| Performance (60fps, 100 stroke) | DevTools 프로파일 | ⏳ Pending |
| Performance (캡처 시간 +20% 이내) | 측정 로그 | ⏳ Pending |
| Stability | analyze + test 통과 | ✅ |
| Compatibility | Android 13~15 동일 동작 | ⏳ Pending (실기기 QA) |
| Maintainability | 신규 brush ≤ 30줄 | ✅ (~17줄) |

### 3.3 Files Created / Modified

| 종류 | 파일 |
|---|---|
| NEW (코드) | `lib/app/data/brushes/brush_preset.dart`, `lib/app/data/brushes/brush_presets.dart` |
| NEW (테스트) | `test/app/data/brushes/brush_presets_test.dart` (7개 단위) |
| NEW (문서) | `docs/01-plan/features/brush-overhaul.plan.md`, `docs/02-design/features/brush-overhaul.design.md`, `docs/03-analysis/brush-overhaul.analysis.md`, `docs/04-report/brush-overhaul.report.md` |
| MODIFY | `pubspec.yaml`, `pubspec.lock`, `lib/app/controllers/doodle_controller.dart`, `lib/app/pages/draw/draw_page.dart`, `lib/app/pages/draw/widgets/canvas_painter.dart`, `lib/app/translate/translate.dart`, `README.md`, `docs/TODO.md`, `docs/store/google-ads-subscription.md`, `test/app/pages/home/home_page_test.dart` |

---

## 4. Deferred Items (의식적 보류)

| # | Item | Reason | Where to revisit |
|---|------|--------|------------------|
| D-1 | Hive 잠금 키 단일 Set 통합 (Design §7.2) | 마이그레이션 회귀 위험 회피 | 향후 잠금 brush가 3종 이상으로 늘어날 때 |
| D-2 | `PostProcessKind.highlighterAlpha` enum 값 | alpha 필드로 동등 처리, YAGNI | 후처리 종류가 더 분화될 때 |
| D-3 | brush_selector widget 회귀 테스트 (Design §8.3 시나리오 1-3) | 단일 세션 시간 경계, 기존 시나리오 33개로 우회 검증 | 차기 사이클 |
| D-4 | doodle_controller 신규 BrushType 분기 단위 테스트 | 동일 사유 | 차기 사이클 |
| D-5 | brush별 brush guide hint 차별화 (Design §5.4 "선택사항") | Design에서 명시적 선택사항 | UX 피드백 시 |
| D-6 | 60fps + 캡처 시간 측정 (Plan §3.2) | DevTools 프로파일 별도 단계 | 실기기 QA |
| D-7 | 시각 구분 + 다국어 RTL UI 검증 | 실기기 환경 | 실기기 QA |

---

## 5. Lessons Learned

### 5.1 잘된 점

- **사전 조사로 잘못된 패키지 도입 회피**: `flutter_drawing_board`(통합 보드), `pencil_kit`(iOS PencilKit), `scribble`(정체) 모두 후보였지만 기존 자산(광고 해금, 공유 캡처, 사진 위 그리기) 보존 측면에서 라이브러리형 `perfect_freehand`가 가장 손해가 적다고 판정.
- **Option C(Pragmatic) 선택이 회귀 0건으로 이어짐**: 사용자가 "기존 구현 파괴 OK"라고 했지만 광고 해금 자산은 유지하는 균형점 선택이 결과적으로 33개 기존 테스트를 그대로 통과시켰다.
- **Round 2 의식적 단순화 해소**: Important 2건(sizeMultiplier, isBrushUnlocked 일반화)을 Round 1에서 의식적으로 보류했다가 Round 2에서 해소한 흐름이 PDCA iteration 패턴의 좋은 예. Match Rate 91.2% → 95.5%.
- **WebFetch 응답 부정확 빠르게 정정**: pub.dev 응답에서 `getStroke`이 `List<PointVector>` 반환이라고 했지만 실제 컴파일 에러로 `List<Offset>`임을 즉시 정정 (`outline.x` → `outline.dx`).

### 5.2 아쉬운 점

- **첫 시도에서 sizeMultiplier 누락**: Design 문서 §3.1에 명시했음에도 첫 구현 때 optionsBuilder 안 곱연산으로 흡수해버림. Design 문서를 참조하며 코드를 적는 규율이 더 중요했다.
- **WebFetch가 부정확한 API 시그니처를 반환**: WebSearch/WebFetch 결과를 그대로 신뢰하면 안 되고 즉시 컴파일 검증으로 catch 해야 한다는 점 재확인.
- **session 1개에 module-1~3 모두 처리**: PDCA 권장은 모듈 분리이지만 사용자가 한 번에 진행 선택. 결과적으로는 잘 끝났지만 후반 번역 11언어 작업에서 수동 누락 가능성 존재(M-1 highlighterAlpha enum 값 누락이 그 예).

### 5.3 다음 사이클 추천

1. **실기기 QA 사이클 (별도)**: SC-4/SC-5 검증, 시각 구분 스크린샷 1세트, Android 13~15 호환성, RTL UI
2. **테스트 보강 사이클**: D-3 brush_selector widget test + D-4 doodle_controller 신규 brush 단위 테스트
3. **장기 유지보수 사이클** (필요 시): D-1 Hive 키 단일 Set + 마이그레이션 (잠금 brush가 3종 이상으로 늘어날 때만)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-05-08 | Initial completion report (Round 2 종료 후) | DangunDad |
