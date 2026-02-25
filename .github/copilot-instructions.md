# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

자유 드로잉 캔버스 앱. 펜/마커/지우개/Undo/Redo/공유 지원. Android 전용.

- 패키지명: `com.dangundad.doodlepad`
- 개발사: DangunDad (`dangundad@gmail.com`)
- 설계 크기: 375×812 (ScreenUtil 기준)
- 테마: `FlexScheme.blueWhale` (라이트/다크 모두)

## 빌드 명령어

```bash
# 의존성 설치
flutter pub get

# Hive 어댑터 재생성 (모델 변경 시)
dart run build_runner build --delete-conflicting-outputs

# 정적 분석 (변경 후 항상 실행)
flutter analyze

# 앱 실행
flutter run
```

## 아키텍처

### 서비스 초기화 흐름

`main()` → AdMob 동의 폼 초기화 → `AppBinding.initializeServices()` (Hive 초기화 + 서비스 등록) → `runApp()`

`AppBinding`은 두 가지 역할을 겸함:
1. `initializeServices()` (static) — `main()`에서 앱 시작 시 영구 서비스 등록
2. `dependencies()` — GetX 라우팅 시 HomePage에서 호출

### GetX 의존성 트리

**영구 서비스 (permanent: true)**
- `HiveService` — Hive 박스 관리 (`settings`, `app_data` 박스)
- `ActivityLogService` — 이벤트 로그 (`phase1_activity_log` 박스, 최대 300개)
- `PurchaseService` — IAP 관리, 프리미엄 상태에 따라 광고 매니저 동적 등록/해제
- `DoodleController` — 캔버스 상태 (스트로크 목록, 브러시 설정, Undo 스택)
- `SettingController` — 앱 설정 (`doodle_settings_v1` 박스)
- `InterstitialAdManager` — 전면 광고 (비프리미엄 시)
- `RewardedAdManager` — 보상형 광고 (비프리미엄 시)

**LazyPut (필요 시 생성)**
- `HistoryController` — ActivityLogService 이벤트 조회/필터
- `StatsController` — 이벤트 통계 집계
- `PremiumController` — 프리미엄 UI 상태

### 라우팅

| 경로        | 페이지         | 바인딩           |
| ----------- | -------------- | ---------------- |
| `/home`     | `HomePage`     | `AppBinding`     |
| `/draw`     | `DrawPage`     | —                |
| `/settings` | `SettingsPage` | —                |
| `/history`  | `HistoryPage`  | —                |
| `/stats`    | `StatsPage`    | —                |
| `/premium`  | `PremiumPage`  | `PremiumBinding` |

### 드로잉 핵심 구조

`DoodleController`가 `List<DrawingStroke>.obs`를 관리 (Hive 미저장, 인메모리).

`CanvasPainter`의 핵심 패턴:
- 지우개는 `BlendMode.clear`로 구현 → **반드시 `canvas.saveLayer()`로 감싸야 동작**
- 단일 점 입력 시 `drawCircle`, 복수 점은 quadratic bezier 곡선으로 부드럽게 처리
- `shouldRepaint`는 스트로크 수 또는 마지막 스트로크의 점 수 변화만 감지

브러시 타입별 동작:
- `pen`: `StrokeCap.round`, 기본 너비
- `marker`: `StrokeCap.square`, 너비 2.5배
- `eraser`: `BlendMode.clear`, 너비 4.0배

### 스토리지 구조

| Hive 박스             | 용도                               | 담당 서비스          |
| --------------------- | ---------------------------------- | -------------------- |
| `settings`            | 범용 설정 (key-value)              | `HiveService`        |
| `app_data`            | 범용 앱 데이터                     | `HiveService`        |
| `doodle_settings_v1`  | 앱 전용 설정 (haptic, language 등) | `SettingController`  |
| `phase1_activity_log` | 이벤트 로그                        | `ActivityLogService` |

`SettingController`와 `HiveService`는 별도 박스를 사용함에 주의. `HiveKeys.IS_PREMIUM`은 `settingsBox`에 저장됨.

### 광고 / 프리미엄

- `PurchaseService._syncAdsForPremiumStatus(true)` 호출 시 광고 매니저를 `Get.delete()`로 제거
- 프리미엄 해제 시 다시 `Get.put()`으로 등록
- 실제 AdMob ID는 `ads_helper.dart`의 TODO 항목으로 교체 필요 (현재 테스트 ID 사용 중)
- IAP 상품 ID 형식: `com.dangundad.doodlepad.premium_{weekly|monthly|yearly}`

### 다국어

현재 `ko` 키만 정의. 새 문자열은 `lib/app/translate/translate.dart`에 `ko` 섹션에만 추가.

## 주요 상수 위치

- `AppUrls.PACKAGE_NAME` — 패키지명
- `HiveKeys` — Hive 저장 키 상수
- `PurchaseConstants.ANDROID_PRODUCT_IDS` — IAP 상품 ID 목록
- `DoodleController.colorPalette` — 16색 팔레트 (ARGB int 배열)
- `DoodleController._maxUndo` — Undo 최대 20단계
