---
template: design
version: 1.3
feature: brush-overhaul
date: 2026-05-08
author: DangunDad
project: doodle_pad
version: 1.0.0+1
---

# brush-overhaul Design Document

> **Summary**: `perfect_freehand` 기반 통합 stroke 엔진과 `BrushPreset` 데이터 객체로 브러시 7-8종 + eraser를 표현. 잠금/광고 해금 시스템은 기존 그대로 유지(Option C: Pragmatic).
>
> **Project**: doodle_pad
> **Version**: 1.0.0+1
> **Author**: DangunDad
> **Date**: 2026-05-08
> **Status**: Draft
> **Planning Doc**: [brush-overhaul.plan.md](../../01-plan/features/brush-overhaul.plan.md)

---

## Context Anchor

| Key | Value |
|-----|-------|
| **WHY** | 단조로운 stroke + brush별 분기 로직 한계. 추가 브러시 도입 비용이 크다. |
| **WHO** | 캐주얼 드로잉/낙서 사용자. 표현 다양성 욕구. |
| **RISK** | RepaintBoundary 캡처 호환성 / DrawingStroke 변경 회귀 / 잠금 자산 UX 충돌. |
| **SUCCESS** | 7-8종 동일 엔진, analyze+test 통과, 신규 brush 추가 ≤ 30줄, 공유 PNG에서 brush 차이 시각 구분. |
| **SCOPE** | M1 stroke 엔진 → M2 BrushPreset+UI → M3 잠금 매핑 점검 → M4 회귀+문서. |

---

## 1. Overview

### 1.1 Design Goals

- 모든 brush(eraser 제외)가 동일한 `perfect_freehand` outline 기반으로 그려진다
- 신규 brush 추가가 데이터 1개 추가로 끝난다
- 기존 광고 해금(watercolor/airbrush), 사진 위 그리기, 공유, undo/redo, 멀티터치 방어가 회귀 없이 유지된다
- 표현력은 향상되지만 평균 캡처 시간/메모리는 기존 대비 +20% 이내

### 1.2 Design Principles

- **Data over Switch**: brush 차이는 코드(switch case)가 아니라 데이터(`BrushPreset`)로 표현
- **Boundary Stability**: 외부 인터페이스(`DoodleController`의 public API, Hive 키, GetX 라우트)는 가능한 한 유지
- **Eraser is Special**: BlendMode.clear는 outline 폴리곤이 아니라 path 직접 처리가 더 안전
- **YAGNI**: pressure 실측, 사용자 정의 brush, infinite canvas 등은 이 사이클 범위 밖

---

## 2. Architecture Options

### 2.0 Architecture Comparison

| Criteria | A: Minimal | B: Clean | **C: Pragmatic** |
|----------|:-:|:-:|:-:|
| New Files | 0 | 3 | 2 |
| Modified Files | 4 | 6+ | 5 |
| Complexity | Low | High | Medium |
| Maintainability | Medium | High | High |
| Effort | Low | High | Medium |
| Risk (regression) | Low | Medium | Low |
| Coding consistency | Low | High | Medium |
| Recommendation | quick prototype | long-term refactor | **Default** |

**Selected**: **Option C — Pragmatic** — Plan의 위험(잠금 회귀, undo/redo 회귀, 멀티터치 방어)을 가장 잘 격리하면서 신규 brush 추가 비용을 1-3줄 수준으로 낮춘다. 광고 해금 자산은 기존 매핑 유지로 사용자 혼란 최소화.

### 2.1 Component Diagram

```
┌────────────────────────────────────┐
│       DrawPage (UI)                │
│  - PopScope, top/bottom toolbars   │
│  - _BrushTypeSelector (7+ items)   │
└──────────────┬─────────────────────┘
               │ binds
               ▼
┌────────────────────────────────────┐
│   DoodleController (GetX)          │
│  - brushType: Rx<BrushType>        │
│  - brushColor, brushSize, ...      │
│  - isWatercolorUnlocked, ...       │
│  - startStroke / continueStroke /  │
│    endStroke / undo / redo         │
└──────────────┬─────────────────────┘
               │ creates
               ▼
┌────────────────────────────────────┐
│   DrawingStroke (data)             │
│  - points: List<Offset>            │
│  - brushType: BrushType            │
│  - color, baseSize, seed           │
└──────────────┬─────────────────────┘
               │ rendered by
               ▼
┌────────────────────────────────────┐
│   CanvasPainter                    │
│  if eraser: _drawEraser(...)       │
│  else: BrushPresets.of(brushType)  │
│           .render(canvas, stroke)  │
└──────────────┬─────────────────────┘
               │ uses
               ▼
┌────────────────────────────────────┐
│   BrushPreset (data, NEW)          │
│  - strokeOptions: StrokeOptions    │
│  - postProcess: PostProcessKind    │
│  - alpha, multiPass                │
│  - render(canvas, stroke)          │
└──────────────┬─────────────────────┘
               │ depends
               ▼
┌────────────────────────────────────┐
│   perfect_freehand (pub.dev)       │
│  - getStroke(points, options)      │
└────────────────────────────────────┘
```

### 2.2 Data Flow

```
GestureDetector.pan*
  → DoodleController.startStroke / continueStroke / endStroke
  → strokes.add(DrawingStroke{points, brushType, color, baseSize, seed})
  → strokes.refresh() (Obx)
  → CanvasPainter.paint
      → for each stroke:
          if eraser: _drawEraser  (BlendMode.clear, Path 직접)
          else: BrushPresets.of(stroke.brushType).render(canvas, stroke)
                  → getStroke(points, presetOptions) → outline polygon
                  → canvas.drawPath(Path..fillType=nonZero, paint)
                  → optional postProcess: noise dots / blur layer / extra alpha pass
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `BrushPreset` | `perfect_freehand` (StrokeOptions, getStroke) | stroke outline 생성 |
| `CanvasPainter` | `BrushPresets`, `DrawingStroke`, `BrushType` | brush별 렌더 위임 |
| `DoodleController` | `BrushType`, `BrushPresets`(잠금 키 조회) | brush 선택, 잠금 |
| `_BrushTypeSelector` | `BrushPresets`(아이콘, 라벨), `DoodleController` | UI 표시 |

---

## 3. Data Model

### 3.1 Entity Definition

```dart
// lib/app/controllers/doodle_controller.dart (수정)
enum BrushType {
  pen,
  pencil,
  marker,
  brush,        // 새: 속도 기반 굵기 변동 (붓)
  highlighter,  // 새: 반투명 사각 cap
  fountainPen,  // 새: 만년필 (taper 강함)
  crayon,       // 새: 거친 텍스처
  watercolor,   // 유지 (광고 해금 자산)
  airbrush,     // 유지 (광고 해금 자산)
  eraser,       // 유지 (특수 path)
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double baseSize;     // (rename: was `width`) brush 슬라이더 값
  final BrushType brushType;
  final int seed;            // crayon noise / airbrush 패턴 안정성

  // 기존 isEraser/cap/width는 BrushPreset에서 도출되므로 제거 또는 deprecated.
  // 호환성 유지를 위해 getter로 잠시 둘 수 있음.
}
```

```dart
// lib/app/data/brushes/brush_preset.dart (NEW)
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;
import 'package:doodle_pad/app/controllers/doodle_controller.dart';

enum PostProcessKind { none, watercolorBlur, airbrushSpray, crayonNoise, highlighterAlpha }

class BrushPreset {
  final BrushType type;
  final String labelKey;           // translate.dart key (e.g. 'brush_pen')
  final IconData icon;             // Lucide icon
  final pf.StrokeOptions Function(double baseSize) optionsBuilder;
  final PostProcessKind postProcess;
  final double alpha;              // 1.0 = opaque, 0.35 = highlighter
  final double sizeMultiplier;     // baseSize에 곱하는 brush별 스케일

  // 잠금 정책: 기존 키와 매핑.
  final BrushLockKind lock;        // none | watercolor | airbrush

  const BrushPreset({
    required this.type,
    required this.labelKey,
    required this.icon,
    required this.optionsBuilder,
    this.postProcess = PostProcessKind.none,
    this.alpha = 1.0,
    this.sizeMultiplier = 1.0,
    this.lock = BrushLockKind.none,
  });

  void render(Canvas canvas, DrawingStroke stroke) {
    // perfect_freehand outline → Path → canvas.drawPath
    // postProcess가 있으면 추가 paint pass
  }
}

enum BrushLockKind { none, watercolor, airbrush }
```

```dart
// lib/app/data/brushes/brush_presets.dart (NEW)
class BrushPresets {
  BrushPresets._();
  static final Map<BrushType, BrushPreset> _registry = {
    BrushType.pen: BrushPreset(
      type: BrushType.pen,
      labelKey: 'brush_pen',
      icon: LucideIcons.pen,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
      ),
    ),
    BrushType.pencil: BrushPreset(
      type: BrushType.pencil,
      labelKey: 'brush_pencil',
      icon: LucideIcons.pencil,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 0.7,
        thinning: 0.6,
        smoothing: 0.4,
        streamline: 0.5,
        simulatePressure: true,
      ),
      alpha: 0.85,
      postProcess: PostProcessKind.crayonNoise, // 약한 grain
    ),
    BrushType.marker: BrushPreset(
      type: BrushType.marker,
      labelKey: 'brush_marker',
      icon: LucideIcons.brush,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 2.0,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
        start: pf.StrokeEndOptions.start(cap: false),
        end: pf.StrokeEndOptions.end(cap: false),
      ),
    ),
    BrushType.brush: BrushPreset(
      type: BrushType.brush,
      labelKey: 'brush_brush',
      icon: LucideIcons.paintbrush,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 1.5,
        thinning: 0.7,
        smoothing: 0.6,
        streamline: 0.6,
        simulatePressure: true,
      ),
    ),
    BrushType.highlighter: BrushPreset(
      type: BrushType.highlighter,
      labelKey: 'brush_highlighter',
      icon: LucideIcons.highlighter,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 2.4,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
        start: pf.StrokeEndOptions.start(cap: false),
        end: pf.StrokeEndOptions.end(cap: false),
      ),
      alpha: 0.35,
      postProcess: PostProcessKind.highlighterAlpha,
    ),
    BrushType.fountainPen: BrushPreset(
      type: BrushType.fountainPen,
      labelKey: 'brush_fountain_pen',
      icon: LucideIcons.feather,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.85,
        smoothing: 0.6,
        streamline: 0.7,
        simulatePressure: true,
        start: pf.StrokeEndOptions.start(taperEnabled: true, taper: 12),
        end: pf.StrokeEndOptions.end(taperEnabled: true, taper: 12),
      ),
    ),
    BrushType.crayon: BrushPreset(
      type: BrushType.crayon,
      labelKey: 'brush_crayon',
      icon: LucideIcons.palette,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 1.4,
        thinning: 0.4,
        smoothing: 0.4,
        streamline: 0.3,
        simulatePressure: true,
      ),
      alpha: 0.85,
      postProcess: PostProcessKind.crayonNoise,
    ),
    BrushType.watercolor: BrushPreset(
      type: BrushType.watercolor,
      labelKey: 'watercolor_brush',
      icon: LucideIcons.droplet,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s * 1.6,
        thinning: 0.3,
        smoothing: 0.7,
        streamline: 0.7,
        simulatePressure: true,
      ),
      alpha: 0.28,
      postProcess: PostProcessKind.watercolorBlur,
      lock: BrushLockKind.watercolor,
    ),
    BrushType.airbrush: BrushPreset(
      type: BrushType.airbrush,
      labelKey: 'airbrush_brush',
      icon: LucideIcons.sprayCan,
      // airbrush는 outline polygon이 아닌 점 분포라 optionsBuilder는 placeholder.
      optionsBuilder: (s) => pf.StrokeOptions(size: s),
      alpha: 1.0,
      postProcess: PostProcessKind.airbrushSpray,
      lock: BrushLockKind.airbrush,
    ),
    // eraser는 BrushPresets에 등록하지 않는다 (CanvasPainter에서 분기).
  };

  static BrushPreset of(BrushType t) => _registry[t]!;
  static List<BrushPreset> get values => _registry.values.toList();
}
```

### 3.2 Entity Relationships

```
DrawingStroke 1 ── 1 BrushType
BrushType    1 ── 1 BrushPreset (registry lookup)
BrushPreset  1 ── 1 PostProcessKind
BrushPreset  1 ── 1 BrushLockKind  (none / watercolor / airbrush)
DoodleController.isBrushUnlocked(type)
  = (preset.lock == none) ||
    (preset.lock == watercolor && isWatercolorUnlocked) ||
    (preset.lock == airbrush  && isAirbrushUnlocked)  ||
    hasPremiumBrushAccess
```

### 3.3 Database Schema

해당 없음. Hive 잠금 키는 기존 그대로 유지:
- `watercolor_unlocked: bool`
- `airbrush_unlocked: bool`

새 brush(crayon, pencil 등)는 무료라 키 없음. 향후 잠금이 필요하면 새 키 1개 추가하는 패턴.

---

## 4. API Specification

해당 없음 — 클라이언트 전용 변경.

---

## 5. UI/UX Design

### 5.1 Screen Layout

`DrawPage` 변경 없음 (Top toolbar / Canvas / Bottom toolbar 그대로). Bottom toolbar 안의 `_BrushTypeSelector`만 7-8종으로 확장.

```
┌───────────────────────────────────────────────────────┐
│ [back] [spacer] [undo][redo][bg][img][trash][share]   │  Top toolbar (변경 없음)
├───────────────────────────────────────────────────────┤
│                                                       │
│                  Canvas (RepaintBoundary)             │
│                                                       │
├───────────────────────────────────────────────────────┤
│ ◀ [pen][pencil][marker][brush][hl][fp][cr][🔒wc][🔒ab][er] ▶  size slider │
│ [color palette + custom slot]                         │
│ "brush guide hint"                                    │
└───────────────────────────────────────────────────────┘
```

### 5.2 User Flow

```
DrawPage 진입
  → BrushPresets.values 순회해 brush 셀 표시
  → 사용자 brush 셀 탭
      → preset.lock != none && !isUnlocked
          → 보상형 광고 다이얼로그 (기존 로직)
      → 잠금 해제됨
          → DoodleController.brushType = preset.type
  → pan 시작 → DoodleController.startStroke (preset 정보는 paint 시점에 조회)
```

### 5.3 Component List

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `BrushPreset` | `lib/app/data/brushes/brush_preset.dart` (NEW) | brush 1종 데이터 + render() |
| `BrushPresets` | `lib/app/data/brushes/brush_presets.dart` (NEW) | brush registry |
| `_BrushTypeSelector` | `lib/app/pages/draw/draw_page.dart` (수정) | 7-9종 horizontal scroll |
| `CanvasPainter` | `lib/app/pages/draw/widgets/canvas_painter.dart` (수정) | preset.render 위임, eraser만 분기 |
| `DoodleController` | `lib/app/controllers/doodle_controller.dart` (수정) | BrushType enum 확장, isBrushUnlocked 일반화 |

### 5.4 Page UI Checklist

#### DrawPage (Bottom toolbar)

- [ ] _BrushTypeSelector: 9개 항목(pen, pencil, marker, brush, highlighter, fountainPen, crayon, watercolor, airbrush) + eraser = 10개 셀, 가로 스크롤
- [ ] 각 셀: 44.r × 44.r AnimatedContainer, BorderRadius 12.r
- [ ] 선택 셀: cs.primary 배경 + cs.onPrimary 아이콘
- [ ] 잠긴 셀(watercolor/airbrush 무료 사용자): 우하단 자물쇠 아이콘 (10.r, cs.tertiary)
- [ ] 잠긴 셀 탭 → "watch_ad" 다이얼로그 노출 (기존 로직 유지)
- [ ] _BrushSizeSlider: brush별 적정 min/max 적용 (eraser는 10~60, 그 외는 2~30 유지)
- [ ] _ColorPalette: eraser 선택 시 "eraser_mode" 라벨, 그 외에는 16색 + 커스텀 슬롯
- [ ] brush guide hint: 설정에서 활성화된 경우 brush별 다른 힌트 텍스트 표시 (선택사항, 시간 남으면)

#### DrawPage (Top toolbar) — 변경 없음

- [ ] back, undo, redo, canvas color, image import/remove, clear, share 버튼 모두 기존 동작 유지

---

## 6. Error Handling

### 6.1 Error Code Definition

| 상황 | 처리 |
|---|---|
| `BrushPresets.of(unknownType)` 누락 | 컴파일 시점에 `_registry[t]!`이 npe → 모든 BrushType 등록 강제 (eraser 제외). 테스트로 enforce |
| `perfect_freehand.getStroke` 결과가 빈 폴리곤 (단일 점) | preset.render에서 단일 점 감지 시 `canvas.drawCircle` fallback |
| postProcess 단계에서 RNG seed 부재 | DrawingStroke.seed 필수 보장 (기존 패턴 유지) |
| 사용자가 잠긴 brush 선택, 광고 미준비 | 기존 `_watchRewardedAdForBrush` 흐름 — `brush_unlock_pending_*` 토스트 |

### 6.2 Error Response Format

해당 없음 (UI 토스트만 사용, 기존 `AppToast` 유지).

---

## 7. Security Considerations

해당 없음 — 클라이언트 전용 변경, 외부 입력 없음. `image_picker`로 가져온 사진은 기존 흐름과 동일하게 read-only.

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool | Phase |
|------|--------|------|-------|
| L1: Unit (controller) | `DoodleController.startStroke / unlockBrush / isBrushUnlocked` | Flutter `flutter_test` | Do |
| L1: Unit (preset) | `BrushPresets.of(type)` 모든 BrushType 커버, `preset.optionsBuilder` 안정성 | `flutter_test` | Do |
| L2: Widget | `_BrushTypeSelector`가 9개 무료 + 2개 잠금 셀 표시, 잠금 셀 탭 시 다이얼로그 | `flutter_test` (WidgetTester) | Do |
| L2: Widget (regression) | 기존 home/draw/share 흐름 (33개 테스트) | `flutter_test` | Do |
| L3: Manual | 실기기에서 9종 brush 시각 차이 확인 + 공유 PNG 결과 | 수동 (Android 13~15) | Check |

### 8.2 L1: Unit Test Scenarios

| # | 대상 | 시나리오 | 기대 |
|---|------|---------|------|
| 1 | BrushPresets | `BrushType.values.where(eraser 제외).every((t) => BrushPresets.of(t) != null)` | 모든 무-eraser brush 등록 |
| 2 | BrushPreset.optionsBuilder | baseSize=2.0~30.0 범위에서 size 양수 | 모든 preset에서 stroke 생성 가능 |
| 3 | DoodleController.isBrushUnlocked | watercolor 무료 + watercolor unlock false → false | 기존 흐름 유지 |
| 4 | DoodleController.isBrushUnlocked | crayon → true (lock=none) | 신규 brush 무료 |
| 5 | DoodleController.isBrushUnlocked | premium 활성 → 모든 brush true | 기존 동작 |
| 6 | DoodleController.startStroke | 신규 brush 선택 후 `strokes.last.brushType == 선택값` | 정상 |
| 7 | DoodleController.unlockBrush | crayon (lock=none)에 호출 → no-op | 안전 |

### 8.3 L2: Widget Test Scenarios

| # | 화면 | 동작 | 기대 |
|---|------|------|------|
| 1 | DrawPage | pump | _BrushTypeSelector에 BrushType.values.length개 셀 렌더 |
| 2 | DrawPage | crayon 셀 탭 | brushType == crayon, 다이얼로그 미노출 |
| 3 | DrawPage | watercolor 셀 탭 (무료, unlocked=false, RewardedAdManager 미등록) | 다이얼로그 미노출 (기존 가드) |
| 4 | DrawPage | back IconButton (작업물 있음) | 기존 _confirmDiscardIfNeeded 다이얼로그 표시 |
| 5 | HomePage | 기존 3개 시작 버튼 시나리오 | 회귀 없음 |
| 6 | DrawPage | brushType 변경 후 size 슬라이더 조작 | brushSize.value 갱신 |

### 8.4 L3: E2E Manual Scenarios

| # | 시나리오 | 단계 | 성공 조건 |
|---|---------|------|----------|
| 1 | 9종 brush 시각 차이 | DrawPage 진입 → 각 brush 선택 → 동일 색/크기로 한 줄씩 | PNG 캡처에서 9개 brush가 시각적으로 구분 |
| 2 | 잠금 자산 회귀 | 무료 상태 → watercolor 셀 탭 → 광고 시청 → 해제 | 기존 흐름 동일 |
| 3 | 공유 캡처 | 여러 brush로 그린 결과 → share | PNG에 모든 stroke 보존 |
| 4 | 사진 위 그리기 | 사진 import → 9종 brush로 다양하게 그리기 → share | 사진 + brush 모두 PNG에 합성 |
| 5 | undo/redo 일관성 | brush 변경하며 5-stroke 그린 후 undo×3 → redo×3 | 정확히 복원 |
| 6 | 다국어 brush 라벨 | 설정에서 한국어/영어/아랍어 전환 | 셀 tooltip이 모두 번역되어 표시 |
| 7 | 캡처 메모리 | 100 stroke 환경에서 share | OOM 없이 PNG 완료 |

### 8.5 Seed Data Requirements

해당 없음 — 클라이언트 전용.

---

## 9. Clean Architecture

### 9.1 Layer Structure (Flutter Dynamic 수준)

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI, gesture, GetX 위젯 트리 | `lib/app/pages/`, `lib/app/widgets/` |
| **Application** | GetX 컨트롤러, 사용자 흐름 | `lib/app/controllers/` |
| **Domain (Data)** | brush 정의, 상수, 모델 | `lib/app/data/brushes/` (NEW), `lib/app/controllers/doodle_controller.dart`의 enum/model |
| **Infrastructure** | Hive, AdMob, 외부 라이브러리 어댑터 | `lib/app/services/`, `lib/app/admob/`, `pubspec.yaml: perfect_freehand` |

### 9.2 Dependency Rules

```
DrawPage (Presentation)
   ↓
DoodleController (Application)
   ↓
BrushPresets / BrushPreset (Domain/Data)
   ↓
perfect_freehand (Infrastructure)
```

CanvasPainter는 Presentation이지만 BrushPreset에 의존(허용). BrushPreset은 perfect_freehand에 의존(허용).

### 9.3 File Import Rules

| From | Can Import |
|------|-----------|
| `pages/draw/*` | `controllers/`, `data/brushes/`, `widgets/` |
| `data/brushes/*` | `perfect_freehand` 패키지, Flutter material |
| `controllers/doodle_controller.dart` | `data/brushes/` (BrushLockKind 조회용) |

순환 의존 없음.

---

## 10. Coding Convention Reference

### 10.1 Naming

| Target | Rule | Example |
|--------|------|---------|
| Dart class | PascalCase | `BrushPreset` |
| enum | PascalCase + lowerCamel value | `BrushType.fountainPen` |
| 상수 (top-level) | lowerCamelCase | `defaultBrushBaseSize` |
| 파일 (Dart) | snake_case | `brush_preset.dart` |
| Translate key | snake_case | `brush_pen`, `brush_fountain_pen` |

### 10.2 Import Order (Dart 관행)

```dart
// 1. Dart core
import 'dart:math' as math;
import 'dart:ui' as ui;

// 2. External packages
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;

// 3. Project absolute
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_preset.dart';
```

### 10.3 Environment Variables

해당 없음 (perfect_freehand는 빌드 타임 의존성).

### 10.4 This Feature's Conventions

- BrushType enum 확장 시 **항상** BrushPresets `_registry`에 매핑 추가 (eraser 제외)
- BrushPreset의 `labelKey`는 11개 언어 translate.dart에 모두 등록
- 잠금이 필요한 신규 brush는 BrushLockKind에 케이스 추가 + Hive 키 1개 추가 + DoodleController.isBrushUnlocked 분기 1줄 추가

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/app/
├── controllers/
│   └── doodle_controller.dart          # MODIFY (enum 확장, DrawingStroke 정리, isBrushUnlocked 일반화)
├── data/
│   └── brushes/                         # NEW
│       ├── brush_preset.dart           # NEW
│       └── brush_presets.dart          # NEW
├── pages/draw/
│   ├── draw_page.dart                   # MODIFY (_BrushTypeSelector → BrushPresets.values 순회)
│   └── widgets/
│       └── canvas_painter.dart          # MODIFY (eraser 분기 + preset.render 위임)
└── translate/
    └── translate.dart                   # MODIFY (brush_* 라벨 11개 언어)

pubspec.yaml                             # MODIFY (perfect_freehand 추가)

test/app/
├── controllers/
│   └── doodle_controller_test.dart      # MODIFY (신규 brush 회귀)
├── data/
│   └── brushes/
│       └── brush_presets_test.dart      # NEW (registry 완전성, optionsBuilder 안정성)
└── pages/draw/
    └── brush_selector_test.dart         # NEW (UI 셀 개수, 잠금 표시)
```

### 11.2 Implementation Order

1. **M1: stroke 엔진 PoC**
   - `pubspec.yaml`에 `perfect_freehand` 추가, `flutter pub get`
   - `BrushPreset` + `BrushPresets` 최소 구현 (pen만)
   - `CanvasPainter`에서 pen만 preset.render 경로로 라우팅, 나머지는 기존 `_drawNormal` 유지
   - 수동 PoC: pen으로 그렸을 때 기존 stroke와 자연스러움 비교
2. **M2: BrushType + DrawingStroke 정리**
   - `BrushType` enum에 신규 5종 추가
   - `DrawingStroke`의 `width` → `baseSize` rename, `cap`/`isEraser` 제거 또는 deprecated
   - `startStroke`에서 brush별 width multiplier 분기 제거 (preset.optionsBuilder가 담당)
3. **M3: BrushPresets 전 brush 등록 + 후처리 구현**
   - watercolor (blur), airbrush (점 분포), crayon (noise grain), highlighter (alpha) postProcess
   - 단일 점 fallback (drawCircle)
4. **M4: UI 통합**
   - `_BrushTypeSelector`를 `BrushPresets.values` 순회로 교체
   - eraser 셀 추가 (분리해서 마지막에)
   - `isBrushUnlocked`를 BrushLockKind 기반으로 일반화
5. **M5: 번역 + 테스트**
   - 11개 언어 brush 라벨 추가 (brush_pen, brush_pencil, brush_marker, brush_brush, brush_highlighter, brush_fountain_pen, brush_crayon — watercolor/airbrush는 기존 키 재사용)
   - 신규 unit/widget 테스트 작성, 기존 33개 회귀 검증
6. **M6: 문서**
   - README, docs/TODO.md, docs/store/google-store.md(11개 언어 영역에 brush 목록 추가), docs/store/google-ads-subscription.md 갱신

### 11.3 Session Guide

#### Module Map

| Module | Scope Key | Description | Estimated Turns |
|--------|-----------|-------------|:---------------:|
| stroke 엔진 + preset 골격 | `module-1` | M1 + M2 (perfect_freehand 도입, BrushPreset 모델, DrawingStroke 정리) | 25-35 |
| 전 brush 프리셋 + 후처리 | `module-2` | M3 (9종 등록, 후처리 4종) | 30-40 |
| UI + 잠금 일반화 + 테스트 + 문서 | `module-3` | M4 + M5 + M6 | 35-45 |

#### Recommended Session Plan

| Session | Phase | Scope | Turns |
|---------|-------|-------|:-----:|
| Session 1 (현재) | Plan + Design | 전체 | ~25 |
| Session 2 | Do | `--scope module-1` | 25-35 |
| Session 3 | Do | `--scope module-2` | 30-40 |
| Session 4 | Do + Check | `--scope module-3` + analyze | 35-45 |
| Session 5 | Iterate(필요 시) + Report | 전체 | 15-25 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-08 | Initial draft, Option C selected | DangunDad |
