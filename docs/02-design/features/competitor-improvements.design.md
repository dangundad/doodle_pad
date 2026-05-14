---
template: design
version: 1.3
feature: competitor-improvements
date: 2026-05-14
author: DangunDad
project: doodle_pad
version_app: 1.0.0+1
---

# competitor-improvements Design Document

> **Summary**: 경쟁앱 갭 해소를 위한 갤러리 저장 / 줌·팬 / Shake / 해상도·포맷 시트 / 작품 갤러리의 Flutter+GetX+Hive 설계 (Option C — Pragmatic).
>
> **Project**: doodle_pad
> **Version**: 1.0.0+1
> **Author**: DangunDad
> **Date**: 2026-05-14
> **Status**: Draft
> **Planning Doc**: [competitor-improvements.plan.md](../../01-plan/features/competitor-improvements.plan.md)

---

## Context Anchor

> Plan에서 복사. Design → Do 핸드오프에서 전략적 컨텍스트 유지.

| Key | Value |
|-----|-------|
| **WHY** | 갤러리 저장 부재 + 작품 보존 흐름 없음으로 도구앱 1차 사용자 만족 저하 |
| **WHO** | 안드로이드 doodle 사용자, 사진 위 메모 사용자, 짧은 호흡 다작 사용자 |
| **RISK** | Shake 오작동 / 줌·팬 그리기 회귀 / Hive 용량 비대 / 작품 좌표계 어긋남 / OEM 권한 거부 |
| **SUCCESS** | 1탭 갤러리 저장, 핀치 줌 무회귀, Shake 안전장치, 해상도·포맷 선택, 작품 CRUD + 썸네일 |
| **SCOPE** | Phase 1 저장(F1/F2/F4/F7) → Phase 2 줌·Shake(F3/F5/F6) → Phase 3 작품 갤러리(F8~F12) |

---

## 1. Overview

### 1.1 Design Goals

- 기존 GetX·Hive_CE·perfect_freehand 패턴을 깨지 않고 책임을 분리한다.
- 외부 IO(gal / 디스크 / Hive)는 `services/` 레이어로 추출해 테스트 가능하게 만든다.
- 캔버스 라이프사이클에 묶이는 책임(줌 변환, Shake)은 `DoodleController`에 mixin으로 합성한다.
- 좌표계 안정성: 작품을 저장·복원할 때 캔버스 논리 크기를 함께 저장해 viewport 차이에 둔감하게 만든다.

### 1.2 Design Principles

1. **Single Responsibility per Service**: `ExportService`는 픽셀화·저장만, `ArtworkRepository`는 영속화·썸네일 IO만.
2. **No silent destruction**: Shake / Clear는 반드시 확인 다이얼로그를 거친다.
3. **Pointer-aware Gesture**: 줌(2 손가락) ↔ 그리기(1 손가락) 분기는 InteractiveViewer(panEnabled=false, scaleEnabled=true)의 기본 제스처 분리에 위임 — 한 손가락 pan은 InteractiveViewer가 거부해 하위 GestureDetector가 받는다.
4. **Backwards-compatible Persistence**: Hive `Drawing` 모델은 nullable·default를 활용해 미래 필드 추가에 둔감.
5. **i18n First**: 신규 문자열은 모두 `translate.dart` 다국어 키로 추가, 하드코딩 금지.

---

## 2. Architecture

### 2.0 Architecture Comparison

| Criteria | Option A: Minimal | Option B: Clean | **Option C: Pragmatic ⭐** |
|----------|:-:|:-:|:-:|
| **Approach** | DoodleController 비대화 | 완전 레이어 분리 | 외부 IO만 Service로 분리 |
| **New Files** | ~5 | ~12 | **~7** |
| **Modified Files** | 5 | 7 | **6** |
| **Complexity** | Low | High | **Medium** |
| **Maintainability** | Medium | High | **High** |
| **Effort** | Low | High | **Medium** |
| **Risk** | Medium (coupling) | Low | **Low** |
| **Recommendation** | hotfix | 장기 멀티개발자 | **본 작업 디폴트** |

**Selected**: **Option C** — *Rationale*: 본 작업은 단일 개발자 단기 PDCA이지만 `DoodleController`는 이미 ~600 라인 수준으로 추가 부담을 줄여야 한다. gal/Hive 같은 외부 IO만 별도 Service로 빼면 단위 테스트와 모킹이 쉬워지면서도 GetX 패턴이 유지된다.

### 2.1 Component Diagram

```
┌────────────────────────────────────────────────────────┐
│                  Presentation (Pages)                  │
│  ┌────────────┐  ┌─────────────┐  ┌────────────────┐   │
│  │ DrawPage   │  │ GalleryPage │  │ SettingsPage   │   │
│  │ (수정)     │  │ (NEW)       │  │ (Shake 토글)   │   │
│  └─────┬──────┘  └──────┬──────┘  └────────┬───────┘   │
└────────┼────────────────┼──────────────────┼───────────┘
         │                │                  │
         ▼                ▼                  ▼
┌────────────────────────────────────────────────────────┐
│                Controllers (GetX, Rx)                  │
│  ┌──────────────────────────┐  ┌─────────────────────┐ │
│  │ DoodleController         │  │ GalleryController   │ │
│  │  + ShakeDetectorMixin    │  │   - artworkList     │ │
│  │  + zoomTransform Rx      │  │   - delete()        │ │
│  └────────┬─────────────────┘  └──────────┬──────────┘ │
└───────────┼───────────────────────────────┼────────────┘
            │                               │
            ▼                               ▼
┌────────────────────────────────────────────────────────┐
│                  Services (Stateless)                  │
│  ┌──────────────────┐    ┌──────────────────────────┐  │
│  │ ExportService    │    │ ArtworkRepository        │  │
│  │  saveToGallery() │    │  save / load / delete    │  │
│  │  renderToPng()   │    │  thumbnail IO            │  │
│  └────────┬─────────┘    └───────────┬──────────────┘  │
└───────────┼──────────────────────────┼─────────────────┘
            │                          │
            ▼                          ▼
       gal package              HiveService + 파일시스템
                                (drawings box + thumbnails/)
```

### 2.2 Data Flow

**갤러리 저장 (F1/F4/F7)**
```
사용자 Save 탭 → SaveOptionsSheet (1x/2x/3x · PNG/JPEG)
  → DoodleController.exportToGallery(opts)
  → ExportService.saveToGallery(canvasKey, opts)
      → RepaintBoundary → ui.Image → 포맷 인코딩
      → gal.putImage(bytes)
  → toastification 표시 (성공/실패/권한거부 분기)
  → SettingController.lastExportFormat·Resolution = opts (Hive persist)
```

**작품 저장 (F8/F11)**
```
사용자 작품저장 탭 → DoodleController.saveAsArtwork(name?)
  → ArtworkRepository.save(Drawing model)
      → strokes 직렬화 (Hive type adapter)
      → 썸네일 256px PNG 생성 → ApplicationSupportDirectory/thumbnails/{uuid}.png
      → Hive drawings box put
  → toastification "작품 저장됨"
```

**작품 재오픈 (F9)**
```
GalleryPage → 작품 카드 탭
  → GalleryController.openArtwork(id)
  → DoodleController.loadArtwork(drawing)
      → canvasLogicalSize · strokes · canvasColor · referenceImagePath 복원
      → 현재 viewport에 맞춰 stroke 좌표 스케일 변환
  → Get.toNamed(Routes.draw)
```

**줌/팬 (F3/F4)** — 실제 구현 기준
```
InteractiveViewer(panEnabled: false, scaleEnabled: true, minScale: 0.5, maxScale: 5.0)
  → 한 손가락 pan: InteractiveViewer가 거부 → 하위 GestureDetector.onPan*가 그리기 처리
  → 두 손가락 핀치: InteractiveViewer가 scale transform 처리 (두 손가락 pan은 scope out)
  → RepaintBoundary는 InteractiveViewer의 child 안쪽 → 캡처는 항상 logical 좌표
더블탭 → DoodleController.resetCanvasTransform()
       → Matrix4Tween(현재 → identity) 300ms easeOutCubic 애니메이션
```

**Shake (F5/F6)**
```
SettingController.shakeToClearEnabled.listen
  ON → ShakeDetectorMixin.subscribe(UserAccelerometerEvents)
       → magnitude > 25 m/s² && lastTrigger > 800ms 전
       → DoodleController._confirmClear() (재사용)
  OFF → 구독 cancel, 배터리 절약
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `ExportService` | `gal` 패키지, `dart:ui`, `RepaintBoundary` | 캔버스 → 갤러리 |
| `ArtworkRepository` | `HiveService`, `path_provider`, `dart:ui` | 작품 영속화 + 썸네일 |
| `DoodleController` | `ExportService`, `ArtworkRepository`, `ShakeDetectorMixin` | 호출 위임 |
| `GalleryController` | `ArtworkRepository`, `DoodleController` | 목록·열기·삭제 |
| `ShakeDetectorMixin` | `sensors_plus`, `SettingController.shakeToClearEnabled` | 토글 기반 구독 |
| `SaveOptionsSheet` | `SettingController` (lastExportFormat/Resolution) | 마지막 선택 기억 |

---

## 3. Data Model

### 3.1 Entity Definition

#### `Drawing` (Hive @HiveType, typeId: 2)

```dart
@HiveType(typeId: 2)
class Drawing extends HiveObject {
  @HiveField(0) String id;                 // uuid v4
  @HiveField(1) int createdAt;             // epoch ms
  @HiveField(2) int updatedAt;             // epoch ms
  @HiveField(3) String? name;              // 사용자 입력 없으면 null
  @HiveField(4) int canvasColor;           // ARGB int
  @HiveField(5) double canvasLogicalWidth; // 저장 시점 viewport
  @HiveField(6) double canvasLogicalHeight;
  @HiveField(7) String? referenceImagePath;
  @HiveField(8) List<SerializableStroke> strokes;
  @HiveField(9) String? thumbnailPath;     // ApplicationSupportDirectory 상대 경로
}

@HiveType(typeId: 3)
class SerializableStroke {
  @HiveField(0) int colorArgb;
  @HiveField(1) double width;
  @HiveField(2) bool isEraser;
  @HiveField(3) int brushTypeIndex; // BrushType의 stable ID (enum 선언 순서 비의존)
  @HiveField(4) int seed;
  @HiveField(5) List<double> pointsXY; // flatten: [x0,y0,x1,y1,...] (Offset 어댑터 생략, 용량 ↓)
}
```

> `Offset` 직렬화 대신 flatten double 리스트를 채택. 작품당 1k stroke·200pt 기준 약 40KB 절약. 복원 시 `for (int i = 0; i < pointsXY.length; i += 2) offsets.add(Offset(pointsXY[i], pointsXY[i+1]));`

### 3.2 Entity Relationships

```
SettingController (Hive settings box)
   ├── shakeToClearEnabled : bool (default false)
   ├── lastExportResolution: int (default 2)   // 1/2/3
   └── lastExportFormat    : String (default "png")

HiveService.drawingsBox
   └── Drawing[] (key = drawing.id)
        └── thumbnailPath → ApplicationSupportDirectory/thumbnails/{id}.png
```

### 3.3 Hive Box Schema

| Box Name | Type | Key | Value | Notes |
|----------|------|-----|-------|-------|
| `settings` (기존) | dynamic | string | dynamic | 추가 키 3개 |
| `drawings` (신규) | `Drawing` | `drawing.id` | `Drawing` | 어댑터 등록 필요 |

**Adapter 등록 순서** (`main.dart` Hive 초기화):
```dart
Hive.registerAdapter(DrawingAdapter());
Hive.registerAdapter(SerializableStrokeAdapter());
await Hive.openBox<Drawing>('drawings');
```

---

## 4. Service / API Specification

### 4.1 ExportService

```dart
// 실제 구현 기준 (Design 초안의 명칭에서 갱신됨)
class ExportService {
  ExportService({GalPutBytesFn? putBytes, GalRequestAccessFn? requestAccess,
      String? defaultAlbumName});
  static final ExportService instance = ExportService();

  /// canvasKey의 RepaintBoundary를 캡처해 갤러리에 저장한다.
  /// PNG는 Flutter 내장 인코더, JPEG는 image 패키지(encodeJpg quality:92)로 인코딩.
  /// 권한 거부 시 1회 재요청 후 재시도, 실패는 ExportResult.failure로 구분 반환.
  Future<ExportResult> saveCanvasToGallery({
    required GlobalKey canvasKey,
    required int resolutionMultiplier, // 1 / 2 / 3
    required ExportImageFormat format, // png / jpeg
    String? fileName,
  });
}

enum ExportImageFormat { png, jpeg }

class ExportResult {
  const ExportResult.success();
  const ExportResult.failed(ExportFailure failure);
  final bool success;
  final ExportFailure? failure;
}

enum ExportFailure { noContent, permissionDenied, encoderError, ioError, unexpected }
```

> **Note (Design 갱신 2026-05-14)**: 초안의 `saveToGallery` / `ImageFormat` /
> `ExportResult.savedPath` / `renderArtworkThumbnail`는 실제 구현에서
> `saveCanvasToGallery` / `ExportImageFormat` / (savedPath 제거) /
> (별도 thumbnail 렌더링 메서드 없음 — 작품 썸네일은 `DoodleController.saveAsArtwork`가
> `canvasKey` 캡처로 직접 생성) 로 정착했다. 위 시그니처가 source of truth.

### 4.2 ArtworkRepository

```dart
class ArtworkRepository {
  ArtworkRepository._();
  static final ArtworkRepository instance = ArtworkRepository._();

  Future<Drawing> save({
    required List<DrawingStroke> strokes,
    required Color canvasColor,
    required String? referenceImagePath,
    required Size logicalSize,
    String? name,
  });

  Future<List<Drawing>> listAll(); // updatedAt desc
  Future<Drawing?> findById(String id);
  Future<void> delete(String id);  // 썸네일 파일도 unlink
  Future<int> count();
  Future<int> totalSizeBytes();    // 100개 초과 경고용
}
```

**에러 시나리오**

| Source | Failure | UX |
|--------|---------|-----|
| `gal.putImage` permission | `GalSavePermissionException` | toast "갤러리 권한이 필요합니다" + 설정 진입 액션 |
| `gal.putImage` 일반 실패 | `GalSaveFailedException` | toast "저장 실패. 잠시 후 다시 시도" |
| 디스크 IO 실패 | `FileSystemException` | toast "저장소 공간이 부족합니다" |
| Hive box not open | `HiveError` | 앱 부팅 가드: `_StartupFailureScreen`로 escalate |

---

## 5. UI/UX Design

### 5.1 DrawPage Top Toolbar (수정)

```
┌─ Top Toolbar ──────────────────────────────────────────────┐
│ ← │ ↺ │ ↻ │ 🎨bg │ 🖼+ │ 🗑 │ 💾Save │ 🔖Artwork │ ↗Share │
└────────────────────────────────────────────────────────────┘
                          ▲          ▲
                          │          └─ NEW (LucideIcons.bookmarkPlus) F11
                          └─ NEW (LucideIcons.download) F1
```

> Save / Artwork / Share 셋은 모두 `hasDrawableContent`일 때만 활성. 비활성 시 알파 0.3.

### 5.2 SaveOptionsSheet (BottomSheet, NEW)

```
┌────────────────────────────────────┐
│ 갤러리에 저장                       │
│ 해상도와 포맷을 선택하세요          │
├────────────────────────────────────┤
│ 해상도                             │
│  ( ) 1x  표준                       │
│  (●) 2x  HD     ← 마지막 선택       │
│  ( ) 3x  Ultra HD                   │
├────────────────────────────────────┤
│ 포맷                                │
│  [PNG]  [JPEG]   ← 토글             │
├────────────────────────────────────┤
│         [취소]   [저장]             │
└────────────────────────────────────┘
```

> 사용자가 "저장" 누른 시점에 `SettingController.lastExportResolution/Format` 동기 저장.

### 5.3 GalleryPage (NEW)

```
┌─ AppBar ─────────────────────────────────────────┐
│ ← │ 내 작품 (12)                       │ 삭제모드 │
├──────────────────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │
│ │ thumb  │ │ thumb  │ │ thumb  │ │ thumb  │     │
│ │        │ │        │ │        │ │        │     │
│ │ 5/12   │ │ 5/11   │ │ 5/10   │ │ 5/9    │     │
│ └────────┘ └────────┘ └────────┘ └────────┘     │
│ ┌────────┐                                       │
│ │ thumb  │ ...                                   │
│ └────────┘                                       │
├──────────────────────────────────────────────────┤
│   [↗공유]  [🗑 삭제]  (삭제모드 토글 시 표시)    │
└──────────────────────────────────────────────────┘
```

- 그리드: 2열 (`flutter_screenutil` 기준 가로 padding 12.w · spacing 12.w)
- 카드 길게 누름 → 삭제 모드 진입(체크박스 + 하단 액션 바)
- 카드 탭(일반 모드) → `loadArtwork` 후 DrawPage 이동
- 비어있을 때: 일러스트 + "아직 작품이 없어요" + "그리러 가기" 버튼

### 5.4 HomePage 진입점

기존 홈 페이지에 카드 추가:
```
┌─ "내 작품" 카드 ──────────────────┐
│  🗂  내 작품                       │
│      저장한 그림 N개  ▶            │
└────────────────────────────────────┘
```
N은 `ArtworkRepository.count()` 결과를 Rx로 관찰.

### 5.5 SettingsPage 신규 토글

```
┌─ 그리기 옵션 ─────────────────────┐
│ 흔들어 지우기                ⬤◯  │
│   기기를 흔들면 캔버스를 지웁니다  │
│   ⚠ 작품이 사라질 수 있어 기본    │
│      OFF. 항상 확인 다이얼로그     │
│      을 거칩니다.                  │
└────────────────────────────────────┘
```

### 5.6 Page UI Checklist

#### DrawPage (수정)
- [ ] 상단 툴바에 Save 버튼(LucideIcons.download) — `hasDrawableContent` 비활성 분기
- [ ] 상단 툴바에 Artwork 저장 버튼(LucideIcons.bookmarkPlus) — `hasDrawableContent` 비활성 분기
- [ ] Save 탭 시 SaveOptionsSheet 표시
- [ ] SaveOptionsSheet에 해상도 라디오 3개 (1x/2x/3x) + 라벨(표준/HD/Ultra HD)
- [ ] SaveOptionsSheet에 포맷 SegmentedButton (PNG/JPEG)
- [ ] 저장 성공 시 toastification success ("갤러리에 저장됨")
- [ ] 권한 거부 시 toastification warning ("갤러리 권한이 필요합니다")
- [ ] 두 손가락 핀치 동작 시 캔버스 transform 적용 (스케일 0.5~5.0)
- [ ] 두 손가락 팬 동작 시 캔버스 이동
- [ ] 더블탭 시 Fit-to-screen 복귀 애니메이션
- [ ] 한 손가락 그리기는 기존과 동일하게 stroke 기록

#### GalleryPage (NEW)
- [ ] AppBar 타이틀에 작품 수 표시 ("내 작품 (N)")
- [ ] AppBar 우측에 삭제모드 토글 IconButton
- [ ] 작품 그리드: 2열, 정사각 썸네일, 작성일 텍스트
- [ ] 빈 상태: 일러스트 + 안내 텍스트 + "그리러 가기" 버튼
- [ ] 카드 길게 누름 → 삭제 모드 진입
- [ ] 삭제 모드: 카드 우상단 체크박스, 하단 액션 바(공유/삭제)
- [ ] 카드 탭(일반): `Get.toNamed(Routes.draw)` + 작품 로드
- [ ] 작품 100개 초과 시 상단에 경고 배너

#### HomePage (수정)
- [ ] "내 작품" 카드 추가, 작품 수 Rx 표시
- [ ] 카드 탭 시 `Get.toNamed(Routes.gallery)`

#### SettingsPage (수정)
- [ ] "흔들어 지우기" SwitchListTile (기본 OFF)
- [ ] 토글 아래 경고 문구 라인

---

## 6. Error Handling

### 6.1 Error Mapping

| Source | Failure | User-facing |
|--------|---------|-------------|
| `ExportFailure.permissionDenied` | gal 권한 거부 | toast warning + 액션 "설정" → `AppSettings.openAppSettings()` |
| `ExportFailure.ioError` | 디스크/SD 오류 | toast error "저장 실패" |
| `ExportFailure.encoderError` | 인코딩 실패 | toast error + 디버그 로그 |
| `ArtworkRepositorySaveError` | Hive write 실패 | toast error "작품 저장 실패" |
| `ArtworkLoadError` (썸네일/파일 missing) | 썸네일 unlink된 작품 | 카드 placeholder + 자동 self-heal (썸네일 재생성) |

### 6.2 Coordinate Mismatch (재오픈 시)

```dart
final scaleX = currentLogicalSize.width / drawing.canvasLogicalWidth;
final scaleY = currentLogicalSize.height / drawing.canvasLogicalHeight;
final scale = math.min(scaleX, scaleY); // letterbox 방식, 잘림 방지
```

가로↔세로 회전 등으로 비율이 크게 다른 경우(>20% gap): 토스트로 "원본 비율로 표시" 안내 1회.

---

## 7. Security / Privacy Considerations

- [ ] gal은 `WRITE_EXTERNAL_STORAGE` 대신 `MediaStore` 사용 → 추가 위험 없음.
- [ ] Android 13+ `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`는 사용자가 갤러리 저장 시점에만 요구.
- [ ] 사진 위 드로잉의 reference 이미지는 디스크 복사 없이 경로만 보관(개인정보 누수 방지). 작품 저장 시에도 경로 참조만, 원본 미복제.
- [ ] 작품 thumbnail은 앱 내부 디렉터리(other apps 접근 불가)에 저장.
- [ ] Hive 데이터에 PII 없음 — 별도 암호화 불필요.

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool | Phase |
|------|--------|------|-------|
| L1 (Unit) | `ExportService` 인코딩(encodeForTest), `ArtworkRepository` CRUD, `Drawing` adapter roundtrip | `flutter test` + Hive in-memory + fake gal | Do |
| L2 (Widget) | SaveOptionsSheet 인터랙션, GalleryPage 렌더, Shake 토글 | `flutter test` widget tester | Do |
| L3 (Regression) | DrawPage 한 손가락 stroke 무회귀 (기존 test 통과) | `flutter test` | Do/Check |
| L4 (Manual) | 실기기 gal 권한 / Android 13+ / OEM(MIUI) | 수기 체크리스트 | Check |

### 8.2 L1 Test Scenarios

| # | Target | Test | Expected |
|---|--------|------|----------|
| 1 | `Drawing` adapter | save → reopen box → load by id | 모든 필드 일치, stroke offsets 손실 0 |
| 2 | `ArtworkRepository.save` | save 호출 → thumbnail 파일 존재 | 파일 존재, Hive entry 1개 |
| 3 | `ArtworkRepository.delete` | save → delete → list | list empty, thumbnail 파일 없음 |
| 4 | `ExportService.encodeForTest` | PNG/JPEG 포맷별 인코딩 | PNG/JPEG 시그니처 bytes 반환 |
| 5 | `ExportService.putBytesForTest` (fake gal) | mock returns success | `ExportResult.success == true` |
| 6 | `ExportService.putBytesForTest` (fake gal denied) | mock throws permission | `failure == permissionDenied` |

### 8.3 L2 Test Scenarios

| # | Page | Action | Expected |
|---|------|--------|----------|
| 1 | DrawPage | Save 버튼 탭 (drawable 있음) | SaveOptionsSheet 표시 |
| 2 | DrawPage | Save 버튼 탭 (drawable 없음) | 비활성 — 버튼 onPressed null |
| 3 | SaveOptionsSheet | 해상도 선택 → 저장 | `ExportService.saveCanvasToGallery` 호출 + opts 전달 |
| 4 | SaveOptionsSheet | 마지막 선택 prefill | `SettingController.lastExport*` 기준 라디오 선택 |
| 5 | GalleryPage | 빈 박스 진입 | 빈 상태 위젯 표시 |
| 6 | GalleryPage | 카드 길게 누름 | 삭제 모드 토글 |
| 7 | SettingsPage | Shake 토글 ON | `shakeToClearEnabled.value == true`, Hive persist |

### 8.4 L3 Regression Scenarios

| # | Scenario | Pass Criteria |
|---|----------|---------------|
| 1 | 한 손가락 stroke 기록 | InteractiveViewer 도입 후에도 strokes.length 증가 |
| 2 | Undo/Redo | 기존 `doodle_controller_test.dart` 통과 |
| 3 | 휴지통 + 확인 다이얼로그 | 기존 동작 유지 |
| 4 | Share | 기존 share_plus 흐름 통과 |

### 8.5 Seed Data Requirements

| Entity | Min Count | Required Fields |
|--------|:--:|---|
| `Drawing` (위젯 테스트용) | 3 | id / strokes(≥1) / thumbnailPath(존재) / canvasLogicalSize |
| Settings | n/a | shakeToClearEnabled=false, lastExportResolution=2, lastExportFormat="png" |

> Do phase: `test/app/helpers/fake_artwork_repository.dart`, `fake_export_service.dart` 작성.

---

## 9. Clean Architecture Layering

본 프로젝트는 Web/Server가 아니므로 Flutter 컨텍스트로 매핑.

| Layer | 책임 | 위치 |
|-------|------|------|
| **Presentation** | Page, Widget, Sheet | `lib/app/pages/`, `lib/app/widgets/` |
| **Application** | Controller (GetX), Mixin | `lib/app/controllers/`, `lib/app/mixins/` |
| **Domain** | Entity, Enum, Value | `lib/app/data/models/`, `lib/app/data/brushes/` |
| **Infrastructure** | Service (외부 IO), Hive 어댑터, gal/sensors_plus 호출 | `lib/app/services/` |

### 9.1 Dependency Rules

- Page → Controller → Service → Domain (역방향 금지)
- Service는 Controller를 import하지 않는다.
- Domain(Drawing, BrushType, SerializableStroke)은 외부 패키지 의존 최소(`hive_ce`만 허용).

### 9.2 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| `DrawPage`, `GalleryPage`, `SaveOptionsSheet` | Presentation | `lib/app/pages/...` |
| `DoodleController` (+ ShakeDetectorMixin), `GalleryController` | Application | `lib/app/controllers/`, `lib/app/mixins/` |
| `Drawing`, `SerializableStroke` | Domain | `lib/app/data/models/` |
| `ExportService`, `ArtworkRepository` | Infrastructure | `lib/app/services/` |

---

## 10. Coding Convention Reference

CLAUDE.md 원칙 + 현 프로젝트 컨벤션 준수.

### 10.1 Naming

| Target | Rule | Example |
|--------|------|---------|
| Class | PascalCase | `ExportService`, `ArtworkRepository` |
| Method | camelCase | `saveCanvasToGallery`, `saveAsArtwork` |
| Const | lowerCamelCase (Dart convention) | `defaultThumbnailMaxDimension` |
| File (class) | snake_case.dart | `export_service.dart`, `artwork_repository.dart` |
| i18n key | snake_case with prefix | `save_resolution_1x`, `gallery_empty_title` |

### 10.2 Import Order (Dart)

```dart
// 1. dart:* core
import 'dart:io';
import 'dart:ui' as ui;

// 2. flutter
import 'package:flutter/material.dart';

// 3. external packages
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

// 4. project (절대 경로)
import 'package:doodle_pad/app/data/models/drawing.dart';

// 5. 같은 폴더 (상대 경로)
import 'fake_helper.dart';
```

### 10.3 Translate Key Prefixes

| Prefix | Scope | Example |
|--------|-------|---------|
| `save_*` | 갤러리 저장 흐름 | `save_to_gallery_title`, `save_success` |
| `resolution_*` | 해상도 라벨 | `resolution_1x`, `resolution_hd` |
| `gallery_*` | 작품 갤러리 | `gallery_title`, `gallery_empty_title` |
| `artwork_*` | 작품 액션 | `artwork_save_success`, `artwork_delete_confirm` |
| `shake_*` | Shake 토글 | `shake_to_clear_title`, `shake_warning` |

### 10.4 This Feature's Conventions

- 신규 Service는 싱글톤 인스턴스(`ExportService.instance`)로 노출, `Get.put` 등록 불필요.
- Controller는 `Get.lazyPut` (binding 패턴) 유지.
- Hive Adapter는 `dart run build_runner build --delete-conflicting-outputs`로 생성, `.g.dart`도 커밋.
- 모든 신규 IconButton에 `tooltip` 필수, 다국어 키 사용.

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/app/
├── controllers/
│   ├── doodle_controller.dart            [modify: zoom, save 위임, mixin 적용]
│   ├── setting_controller.dart           [modify: shake/lastExport 키 3개]
│   └── gallery_controller.dart           [NEW]
├── data/
│   └── models/
│       ├── drawing.dart                  [NEW @HiveType id=2,3]
│       └── drawing.g.dart                [GEN build_runner]
├── mixins/
│   └── shake_detector_mixin.dart         [NEW]
├── pages/
│   ├── draw/
│   │   ├── draw_page.dart                [modify: Save/Artwork 버튼, InteractiveViewer]
│   │   └── widgets/
│   │       └── save_options_sheet.dart   [NEW]
│   ├── gallery/
│   │   ├── gallery_page.dart             [NEW]
│   │   └── gallery_binding.dart          [NEW]
│   ├── home/                             [modify: 내 작품 카드 추가]
│   └── settings/                         [modify: Shake 토글]
├── services/
│   ├── export_service.dart               [NEW]
│   ├── artwork_repository.dart           [NEW]
│   └── hive_service.dart                 [modify: drawings box, adapter 등록]
├── routes/
│   ├── app_pages.dart                    [modify: gallery 라우트]
│   └── app_routes.dart                   [modify: Routes.gallery]
├── bindings/
│   └── app_binding.dart                  [modify: lazyPut ExportService/Repo 불요, mixin 등록]
└── translate/
    └── translate.dart                    [modify: 신규 키 ~25개 × 8개 언어]
```

신규: 7개 / 수정: 9개 (translate는 1파일이지만 다국어 분량 큼).

### 11.2 Implementation Order

1. **모델·어댑터·DI 준비**
   - `Drawing`, `SerializableStroke` 작성 → `build_runner` 실행
   - `HiveService`에 `drawings` 박스 + 어댑터 등록
   - `main.dart` 초기화 순서 확인
2. **ExportService 구현 + L1 단위 테스트**
3. **ArtworkRepository 구현 + L1 단위 테스트**
4. **SaveOptionsSheet + DoodleController.exportToGallery 위임** (Phase 1 완료)
5. **InteractiveViewer 통합 (panEnabled=false 기본 분리) + 회귀 테스트** (Phase 2 줌)
6. **ShakeDetectorMixin + Settings 토글** (Phase 2 Shake)
7. **GalleryController + GalleryPage + GalleryBinding + 라우트** (Phase 3)
8. **HomePage 진입점 카드**
9. **translate.dart 다국어 키 일괄 추가**
10. **L2/L3 위젯 테스트 보강**
11. **`flutter analyze` / `flutter test` 0 issue / 0 fail**

### 11.3 Session Guide

#### Module Map

| Module | Scope Key | Description | Estimated Turns |
|--------|-----------|-------------|:---:|
| 갤러리 저장 (F1·F2·F4·F7) | `module-save` | `Drawing` 모델·어댑터·ExportService·SaveOptionsSheet·DrawPage Save 버튼 | 25–35 |
| 줌·팬 + Shake (F3·F4·F5·F6) | `module-canvas` | InteractiveViewer 통합, ShakeDetectorMixin, Settings 토글 | 20–30 |
| 작품 갤러리 (F8·F9·F10·F11·F12) | `module-artwork` | ArtworkRepository·GalleryController·GalleryPage·HomePage 카드·DrawPage Artwork 버튼 | 35–50 |
| 다국어 + 테스트 마무리 | `module-polish` | translate.dart 키 추가, L2/L3 위젯 테스트, analyze/test 0 fail | 15–25 |

#### Recommended Session Plan

| Session | Phase | Scope | Turns |
|---------|-------|-------|:---:|
| 1 (현재) | Plan + Design | 전체 | 25 |
| 2 | Do | `--scope module-save` | 30 |
| 3 | Do | `--scope module-canvas` | 25 |
| 4 | Do | `--scope module-artwork` | 45 |
| 5 | Do | `--scope module-polish` | 20 |
| 6 | Check + Iterate + Report | 전체 | 30 |

> 큰 변경이라 4개 세션으로 분할 권장. 작품 갤러리(`module-artwork`)는 단독 세션으로 분리.

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-14 | 초기 작성 — Option C 선택 후 Pragmatic 아키텍처 상세 설계 | DangunDad |
