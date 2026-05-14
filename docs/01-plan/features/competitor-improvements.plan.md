---
template: plan
version: 1.3
feature: competitor-improvements
date: 2026-05-14
author: DangunDad
project: doodle_pad
version_app: 1.0.0+1
---

# competitor-improvements Planning Document

> **Summary**: 경쟁앱(LogicWorkLab SketchPad) 비교 분석으로 도출한 5개 갭(갤러리 저장 / 캔버스 줌·팬 / Shake to Clear / 저장 해상도·포맷 선택 / 작업 갤러리) 보강.
>
> **Project**: doodle_pad
> **Version**: 1.0.0+1
> **Author**: DangunDad
> **Date**: 2026-05-14
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 도구앱 사용자의 핵심 행동인 "갤러리 저장"이 없고 정밀 작업(줌)·작품 보존 흐름이 부재해 경쟁앱 대비 1차 사용자 만족이 떨어진다. |
| **Solution** | gal 패키지 기반 갤러리 저장, InteractiveViewer 줌/팬, 옵션형 Shake-to-Clear, 1x/2x/3x · PNG/JPEG 내보내기, Hive 기반 in-app 작품 갤러리(수동 저장)를 일괄 도입. |
| **Function/UX Effect** | 상단 툴바에 Save 버튼 추가, 두 손가락 핀치 줌, 설정에서 흔들어 지우기 토글, 저장 시 해상도·포맷 선택 시트, 홈에 "내 작품" 진입점 추가. |
| **Core Value** | "낙서 도구" → "작품 만들고 보관·공유하는 도구"로 가치 격상. 경쟁앱 대비 우위(브러시 10종 + 사진 위 드로잉)를 유지하면서 1차 약점을 해소. |

---

## Context Anchor

> Plan에서 자동 생성. Design/Do 문서로 전파되어 세션 간 컨텍스트 연속성을 보장.

| Key | Value |
|-----|-------|
| **WHY** | 도구앱의 기본 행동(갤러리 저장)이 빠져 있고, 작품 보존·정밀 작업 흐름이 없어 사용자 이탈 위험. |
| **WHO** | 안드로이드 doodle/스케치 사용자(취미·아이용), 사진 위에 메모/낙서하는 사용자, 짧은 호흡으로 여러 작품을 만들고 저장·공유하는 사용자. |
| **RISK** | (1) Shake-to-Clear 오작동으로 작품 손실 (2) 줌/팬 도입이 기존 onPan 그리기 회귀 유발 (3) Hive 작품 저장으로 인한 저장 용량 비대. |
| **SUCCESS** | (a) 갤러리 저장 1탭으로 가능 (b) 두 손가락 핀치 줌 동작, 한 손가락 그리기 무회귀 (c) Shake 토글 기본 OFF + 확인 다이얼로그 (d) 1x/2x/3x · PNG/JPEG 선택 가능 (e) 작품 저장·재오픈·삭제 가능, 썸네일 표시. |
| **SCOPE** | Phase 1: 갤러리 저장 + 해상도/포맷 시트. Phase 2: 줌/팬 + Shake. Phase 3: 작품 갤러리(Hive + 페이지 + 홈 진입점). |

---

## 1. Overview

### 1.1 Purpose

경쟁앱 비교 분석에서 드러난 1차 갭(저장 행동 부재, 정밀 작업 불가)을 닫고, 경쟁앱이 가지지 못한 영역(작품 보존)으로 우위를 확장한다.

### 1.2 Background

- 경쟁앱 `com.logicworklab.sketchpad.doodle.drawing.pad`는 브러시 단일 / 사진 위 드로잉 없음에도 "Save 버튼·저장 위치 선택"을 핵심 셀링 포인트로 사용.
- 내 앱은 브러시 10종 · perfect_freehand · 사진 위 드로잉 · 다국어로 마감 우위지만, 사용자가 가장 자주 찾는 "갤러리에 저장" 버튼이 없음. (`draw_page.dart` 상단 툴바는 share만 존재 — line 351–367)
- `DoodleController.clearCanvas()`는 뒤로가기 시 즉시 호출되어 작품이 사라짐 — 보존 흐름 부재.

### 1.3 Related Documents

- Reference: `docs/store/google-store.md`
- Past PDCA: `docs/archive/2026-05/brush-overhaul/` (브러시 시스템 — 본 작업은 그 위에 UX/저장 레이어 추가)
- Competitor: https://play.google.com/store/apps/details?id=com.logicworklab.sketchpad.doodle.drawing.pad

---

## 2. Scope

### 2.1 In Scope

- [ ] **F1 — 갤러리 저장**: `gal` 패키지 사용, 상단 툴바에 Save 아이콘(`LucideIcons.download`), Toast 피드백(toastification).
- [ ] **F2 — 캔버스 줌/팬**: `InteractiveViewer`로 캔버스 래핑, 한 손가락 그리기 / 두 손가락 줌·팬 분기, 더블탭 Fit-to-screen.
- [ ] **F3 — Shake to Clear**: `sensors_plus` 가속도계, 설정에 토글(기본 OFF), 트리거 시 기존 `_confirmClear` 다이얼로그 재사용.
- [ ] **F4 — 저장 해상도·포맷 선택**: BottomSheet에 1x/2x/3x · PNG/JPEG 선택, 마지막 선택 Hive에 저장.
- [ ] **F5 — In-app 작품 갤러리**: Hive `Drawing` 모델(stroke list + 메타 + 썸네일 경로), "내 작품" 페이지, 홈에 진입점, 작품 카드에서 재오픈/삭제/공유.

### 2.2 Out of Scope

- 레이어, 도형/텍스트 도구, 캔버스 사이즈 변경, 클라우드 동기화.
- 경쟁앱의 "게임 카테고리 등록" — Google 정책 리스크로 제외.
- iOS 전용 코드(CLAUDE.md 원칙 준수).
- 작품 자동 저장(사용자 결정으로 수동 저장만).

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 상단 툴바에 Save 버튼을 추가하고 1탭으로 PNG/JPEG를 시스템 갤러리에 저장한다. 권한이 없으면 자동 요청한다. | High | Pending |
| FR-02 | 저장 직후 toastification으로 "저장됨" 메시지를 3초간 표시한다. | High | Pending |
| FR-03 | 캔버스에서 한 손가락은 기존대로 그리고, 두 손가락은 핀치 줌(0.5x~5.0x) + 팬으로 동작한다. | High | Pending |
| FR-04 | 줌 상태에서 더블탭하면 Fit-to-screen으로 복귀한다. | Medium | Pending |
| FR-05 | 설정에 "흔들어 지우기" 토글(기본 OFF)을 추가한다. ON일 때만 가속도계 리스너 활성화. | Medium | Pending |
| FR-06 | 흔들기 감지 시 기존 `_confirmClear` 다이얼로그를 띄운다(직접 삭제 금지). 임계값 25 m/s², 디바운스 800ms (오작동 방지를 위해 보수적으로 설정). | Medium | Pending |
| FR-07 | Save 버튼 탭 시 해상도(1x/2x/3x) · 포맷(PNG/JPEG) 선택 시트를 띄운다. 마지막 선택은 Hive에 저장. | High | Pending |
| FR-08 | Hive `Drawing` 모델로 작품(stroke 리스트 + 캔버스 색 + 참조 이미지 경로 + 썸네일 경로 + createdAt)을 저장한다. | High | Pending |
| FR-09 | "내 작품" 페이지: 그리드 썸네일, 작품 탭 시 캔버스로 재오픈(편집 가능), 길게 누름 시 삭제 확인. | High | Pending |
| FR-10 | 홈 페이지에 "내 작품" 진입점(카드 또는 IconButton)을 추가한다. | Medium | Pending |
| FR-11 | 작품 저장 버튼은 갤러리 저장과 별개로 상단 툴바에 추가한다(`LucideIcons.bookmarkPlus`). | High | Pending |
| FR-12 | 작품 갤러리에서 작품 삭제 시 썸네일 파일도 디스크에서 함께 제거한다. | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| 성능 | 3x 해상도 PNG 저장이 1080p 캔버스 기준 2초 이내 | `Stopwatch`로 측정, 디버그 로그 |
| 호환성 | Android 13+(SDK 33) READ_MEDIA_IMAGES 권한 모델 대응 | gal 패키지 가이드 준수, 실기기 검증 |
| 회귀 | InteractiveViewer 도입으로 한 손가락 그리기 회귀 없음 | 기존 `draw_page_test.dart` 통과 + 신규 위젯 테스트 |
| 용량 | 작품 1개 평균 메타 ≤ 50KB, 썸네일 ≤ 200KB | Hive box 크기 측정 |
| 접근성 | 모든 신규 IconButton에 tooltip + 다국어 키 제공 | `flutter analyze` + 수동 검증 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] FR-01~FR-12 모두 구현 완료
- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` 전부 통과 (신규 테스트 포함)
- [ ] CLAUDE.md의 `pages`/`bindings`/`현재 코드 구조` 섹션 갱신
- [ ] 신규 다국어 키 `lib/app/translate/translate.dart` 전 언어에 추가

### 4.2 Quality Criteria

- [ ] 신규 코드 위젯 테스트 커버 (Save 시트, 작품 갤러리 페이지, Shake 토글)
- [ ] `dart run build_runner build --delete-conflicting-outputs` 후 `*.g.dart` 커밋
- [ ] 기존 `test/ui/no_gradient_usage_test.dart` 룰 위반 0건

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Shake-to-Clear 오작동으로 작품 손실 | High | Medium | 기본 OFF + 임계값 보수적 + 항상 확인 다이얼로그 경유 + 설정 화면에 경고 문구 |
| InteractiveViewer가 기존 onPan 그리기 회귀 유발 | High | High | 포인터 수에 따라 InteractiveViewer 활성/비활성 분기. 위젯 테스트로 한 손가락 stroke가 정상 기록되는지 회귀 가드 |
| gal 패키지가 일부 OEM(Xiaomi/MIUI)에서 권한 거부 | Medium | Medium | 실패 시 fallback으로 앱 외부 디렉터리에 저장 후 share intent 제공 |
| Hive 작품 데이터가 누적되어 앱 용량 비대 | Medium | Medium | 작품당 썸네일 200KB 상한, 갤러리에서 다중 선택 삭제 지원, 100개 초과 시 경고 |
| Stroke 직렬화(Offset 리스트 + Color) Hive 어댑터 누락 | High | Medium | `@HiveType` + `dart run build_runner` 워크플로 명시, 모델별 단위 테스트 |
| 작품 재오픈 시 좌표가 화면 크기에 따라 어긋남 | High | High | 작품 저장 시 캔버스 논리 크기(width/height)도 함께 저장, 재오픈 시 viewport에 맞춰 스케일 변환 |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| `lib/app/pages/draw/draw_page.dart` | Widget | 상단 툴바 Save·작품저장 버튼 추가, 캔버스 InteractiveViewer 래핑, 포인터 분기 |
| `lib/app/controllers/doodle_controller.dart` | Controller | `saveToGallery`, `saveAsArtwork`, `loadArtwork`, 줌 상태 관리, Shake 리스너 토글 추가 |
| `lib/app/controllers/setting_controller.dart` | Controller | `shakeToClearEnabled`, `lastExportResolution`, `lastExportFormat` 추가 |
| `lib/app/services/hive_service.dart` | Service | `Drawing` 박스 등록, CRUD 메서드 |
| `lib/app/data/models/drawing.dart` | Model (NEW) | `@HiveType` Drawing 모델 + `*.g.dart` |
| `lib/app/pages/gallery/` | Page (NEW) | 작품 갤러리 페이지·바인딩·라우트 |
| `lib/app/pages/home/` | Page | 진입점 카드 추가 |
| `lib/app/translate/translate.dart` | i18n | 신규 키 (save / shake / resolution / artwork / my_works …) 다국어 |
| `pubspec.yaml` | Config | `gal`, `sensors_plus` 추가 |
| `android/app/src/main/AndroidManifest.xml` | Config | gal 가이드 권한 추가 (`READ_MEDIA_IMAGES` 등) |

### 6.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `DoodleController.strokes` | READ | `draw_page.dart` CanvasPainter 렌더링 | Needs verification — InteractiveViewer transform 적용 시 좌표계 확인 |
| `DoodleController.shareCanvas` | READ | `draw_page.dart` 상단 share 버튼 | None — 그대로 유지, 옆에 Save 추가 |
| `DoodleController.clearCanvas` | CALL | 뒤로 가기 / 휴지통 / discard 다이얼로그 | None — Shake 트리거도 동일 경로 |
| `HiveService.to.setSetting` | CRUD | setting_controller, doodle_controller | None — 키 추가만 |
| `SettingController` 토글 | READ | settings_page UI | Needs verification — 신규 토글 UI 추가 |
| `app_pages.dart` 라우트 | READ | `Get.toNamed` 호출부 | Needs verification — gallery 라우트 추가 |
| `home_page` | READ | 사용자 진입 | Needs verification — 카드 추가로 레이아웃 영향 |

### 6.3 Verification

- [ ] 한 손가락 stroke가 InteractiveViewer 아래에서도 정확히 기록되는지 골든 테스트
- [ ] Shake 토글 OFF일 때 sensors_plus 리스너가 dispose되는지 확인 (배터리 영향)
- [ ] gal 저장 실패 시 fallback 경로가 한 번 더 노출되는지
- [ ] Hive `Drawing` 어댑터가 빌드된 후 기존 box와 충돌하지 않는지

---

## 7. Architecture Considerations

### 7.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| Starter | 단순 구조 | 정적 페이지 | ☐ |
| **Dynamic** | 기능별 모듈 / GetX·Hive 패턴 유지 | 본 앱처럼 GetX + Hive 기반 mobile fullstack | ☑ |
| Enterprise | 엄격한 레이어 분리 | 대규모 백엔드 연동 | ☐ |

> 본 작업은 mobile 단독 앱이며, 기존 GetX/Hive_CE 구조 위에 page/service/model을 더하는 형태라 Dynamic 수준이 적합.

### 7.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| 상태 관리 | GetX / Riverpod / Bloc | **GetX (유지)** | 프로젝트 전역 패턴, CLAUDE.md 규칙 준수 |
| 로컬 저장 | Hive_CE / SharedPreferences / SQLite | **Hive_CE (유지)** | 이미 box 운용 중, `@HiveType` 패턴 일관 |
| 갤러리 저장 라이브러리 | gal / saver_gallery / image_gallery_saver | **gal** | Android 13+ 권한 자동, iOS 호환, 활발한 유지보수 |
| 줌/팬 구현 | InteractiveViewer / 직접 GestureDetector 확장 | **InteractiveViewer (1차)** | Flutter 표준 위젯, 빠른 도입. 포인터 수로 그리기와 분기. 필요 시 Design 단계에서 GestureDetector 확장 재검토 |
| 가속도 센서 | sensors_plus / 직접 채널 | **sensors_plus** | 표준 패키지, Android/iOS 호환, 토글로 dispose 가능 |
| 토스트 | toastification (유지) | **toastification** | 이미 의존성 보유 |
| Stroke 직렬화 | JSON / Hive type adapter | **Hive type adapter** | Offset/Color 어댑터 작성, build_runner 활용 |

### 7.3 Folder Structure Preview

```
lib/app/
├── controllers/
│   ├── doodle_controller.dart      [modify]
│   └── setting_controller.dart     [modify]
├── data/
│   └── models/
│       ├── drawing.dart            [NEW] @HiveType
│       └── drawing.g.dart          [GEN]
├── pages/
│   ├── draw/
│   │   ├── draw_page.dart          [modify]
│   │   └── widgets/
│   │       ├── canvas_painter.dart [maybe modify]
│   │       └── save_options_sheet.dart [NEW]
│   ├── gallery/
│   │   ├── gallery_page.dart       [NEW]
│   │   └── gallery_binding.dart    [NEW]
│   └── home/                       [modify — 진입점]
├── services/
│   └── hive_service.dart           [modify — Drawing box]
└── translate/
    └── translate.dart              [modify — 신규 키]
```

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [x] `CLAUDE.md` 보유 (한국어 소통, Android 우선, build_runner 워크플로 명시)
- [ ] `docs/01-plan/conventions.md` 없음 (필요 시 생성)
- [x] `analysis_options.yaml` (flutter_lints 6.0 기반으로 가정)
- [x] `pubspec.yaml`에 build_runner 보유

### 8.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **다국어 키 네이밍** | 일부 snake_case (`brush_pen`, `discard_drawing_title`) | 신규 키 prefix: `gallery_*`, `save_*`, `shake_*`, `artwork_*` | High |
| **신규 라우트 경로** | `Routes.draw` 등 정적 상수 | `Routes.gallery` 추가 | High |
| **Hive box 이름** | 기존 settings box 1개 | `'drawings'` box 신규 | High |
| **썸네일 저장 위치** | 없음 | `ApplicationSupportDirectory/thumbnails/{uuid}.png` | Medium |

### 8.3 Environment Variables Needed

해당 없음 — mobile 앱, 환경 변수 의존 없음.

### 8.4 Pipeline Integration

해당 없음 — 9-phase Development Pipeline 미사용 프로젝트.

---

## 9. Next Steps

1. [ ] Design 문서 작성 (`/pdca design competitor-improvements`) — 3가지 아키텍처 옵션 비교 + Session Guide 생성
2. [ ] Phase 3(작품 갤러리) 좌표계 처리 방안 Design에서 확정
3. [ ] Shake 임계값/디바운스 Design에서 수치 확정
4. [ ] InteractiveViewer vs GestureDetector 확장 최종 결정 (Design Option A/B/C로 제시)
5. [ ] Do 단계는 `--scope module-1` (저장)부터 인크리멘털 진행 권장

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-14 | 초기 작성 — 경쟁앱 비교 기반 5개 갭 통합 Plan | DangunDad |
