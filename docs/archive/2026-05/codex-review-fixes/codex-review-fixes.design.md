# Design: Codex 리뷰 후속 개선 (codex-review-fixes)

- 작성일: 2026-05-06
- 연결 Plan: `docs/01-plan/features/codex-review-fixes.plan.md`

## 1. 아키텍처 결정

세 가지 옵션을 비교하고 **Option C (Pragmatic Balance)**를 선택했다.

| 옵션 | 요약 | 트레이드오프 |
|---|---|---|
| A 최소 변경 | 광고 매니저 onInit에 `if (canRequestAds) loadAd()` 만 추가 | 동의가 늦게 떨어지면 영영 로드 안 됨 |
| B 클린 분리 | `AdConsentController` + `AdRegistry` 도입 | 파일 추가 많고 본 사이클 범위 초과 |
| **C 균형** | `AdHelper`에 `RxBool canRequestAds` 추가, 각 매니저는 GetX `ever()`로 가만히 기다리다 동의 시 로드 | 변경 최소, 기존 컨트롤러 흐름 보존, 테스트 가능 |

## 2. 변경 모듈

| 모듈 | 변경 |
|---|---|
| `android/app/proguard-rules.pro` | 신규 생성. AdMob/UMP/Mediation/Billing/Hive/Firebase keep 규칙 |
| `lib/app/admob/ads_helper.dart` | `static final RxBool canRequestAds`, 동의/초기화 성공 시 true |
| `lib/app/admob/ads_interstitial.dart` | `loadAd()` 진입 시 `canRequestAds` 가드, 미지정 시 `ever()`로 대기, `showAdIfAvailable`에서 프리미엄 가드 |
| `lib/app/admob/ads_rewarded.dart` | 동일 패턴의 `canRequestAds` 가드 + `ever()` 워커 |
| `lib/app/admob/ads_banner.dart` | `_loadBanner` 가드 + `ever()`로 동의 후 로드 |
| `lib/app/services/purchase_service.dart` | `_syncAdsForPremiumStatus`에서 `Get.delete<T>(force: true)`로 permanent 매니저 강제 삭제 |
| `lib/app/controllers/doodle_controller.dart` | `hasDrawableContent` getter, 동적 pixelRatio, `ui.Image.dispose` (`try/finally`), save/share 분기 |
| `lib/app/translate/translate.dart` | `supportedLocales` 를 en/ko로 제한 |
| `lib/app/pages/home/home_page.dart`, `lib/app/pages/gallery/gallery_page.dart` | "새 그림" 진입 시 `clearCanvas()` 사용 |
| 테스트 | consent gate 추가, hasDrawableContent + clearCanvas 테스트 추가 |

## 3. 핵심 흐름

### 3.1 광고 동의 게이트
1. 앱 시작 → `runApp` 후 `_initializeAds()` 비동기 시작.
2. `AdHelper.initializeConsentAndAds()`가 UMP + 미디에이션 동의 + `MobileAds.initialize()` 완료 시 `AdHelper.canRequestAds.value = true`.
3. 각 광고 매니저는 `onInit()`에서 `canRequestAds.value`가 false면 `ever()` 워커로 대기. true가 되면 워커 dispose 후 `loadAd()` 호출.
4. 모든 `loadAd()` 진입부에서도 다시 `canRequestAds`를 검증해 직접 호출이라도 안전하게 막힘.
5. 프리미엄 활성화 시 `Get.delete<...>(force: true)`로 permanent 매니저까지 정리.

### 3.2 캡처 메모리 안정화
- `_resolveCapturePixelRatio(size)`: `sqrt(maxPixels / (w*h))` 와 상한 3.0 중 작은 값 사용. 1.0 floor.
- `_savePng`/`shareCanvas` 모두 `try { ... } finally { image.dispose(); }`.

### 3.3 저장/공유 가능 조건
- `hasDrawableContent => strokes.isNotEmpty || referenceImagePath.value != null`.
- `saveCanvas`/`shareCanvas` 진입부 빈 상태 검사를 이 게터로 통일.

## 4. 테스트 계획

| L1: 정적 | `flutter analyze` 통과 |
| L2: 단위 |
| - | InterstitialAdManager: consent 전 plugin 호출 없음 (기존 + 신규) |
| - | RewardedAdManager: 동일 |
| - | BannerAdWidget: 동일 |
| - | DoodleController: hasDrawableContent / clearCanvas |
| L3: 위젯 | 기존 home/settings 위젯 테스트 회귀 확인 |

## 5. 위험 및 완화

| 위험 | 완화 |
|---|---|
| `ever()` 워커 누수 | onClose / dispose에서 `_consentWorker?.dispose()` 호출 |
| 캔버스 size가 0인 edge case | `_resolveCapturePixelRatio`에서 즉시 3.0 반환 |
| 기존 테스트가 consent 미설정에 의존 | tearDown에서 `resetInitializationStateForTest()`로 false 복원 |
