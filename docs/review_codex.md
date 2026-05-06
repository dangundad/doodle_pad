# Doodle Pad Codex 최종 리뷰

- 저장소: `C:\Github_WorkSpace\doodle_pad`
- 검토일: 2026-05-06
- 산출물: `docs/review_codex.md`
- 방식: Codex 본검토 + 병렬 에이전트 3개 역할 분담
- 검토 축: 핵심 드로잉 로직, 사용자 UI/UX, 설정 옵션, 광고/결제/릴리스 리스크, 테스트 공백

## 1. 결론

현재 앱은 자유 드로잉, 브러시, 저장/공유, 갤러리, 설정, 프리미엄 흐름의 기본 골격은 갖춰져 있습니다. 다만 **릴리스 준비 상태로 보기는 어렵습니다.** 특히 릴리스 빌드 설정, 광고 동의 게이트, 개인정보 처리방침, 구매 검증/상품 상태 UI는 출시 전에 먼저 막아야 합니다.

권장 판정:

- 기능 구현 상태: **MVP 동작 가능**
- 사용자 경험 상태: **핵심 흐름은 가능하지만 혼란/접근성 리스크 있음**
- 릴리스 상태: **Changes Required**
- 우선순위: **P0 3건, P1 13건, P2 6건**

## 2. 검토 팀 구성

| 역할 | 검토 범위 |
|---|---|
| Core Logic Review | `DoodleController`, `CanvasPainter`, 저장/공유/갤러리/히스토리 핵심 로직 |
| UI/UX & Settings Review | `DrawPage`, `Home/Gallery/History/Stats/Settings/Premium` 화면, 접근성, 옵션 구조 |
| Release/Ops Review | Android 설정, AdMob/UMP, IAP, Privacy Policy, 테스트/릴리스 차단 요소 |

## 3. P0 - 출시 전 즉시 조치

### P0-1. 릴리스 빌드가 없는 ProGuard 파일을 참조합니다

- 위치: `android/app/build.gradle.kts:66`, `android/app/build.gradle.kts:67`, `android/app/build.gradle.kts:71`
- 근거: `release` 빌드에서 `isMinifyEnabled = true`, `isShrinkResources = true`, `"proguard-rules.pro"`를 참조하지만 `android/app/proguard-rules.pro`가 없습니다.
- 영향: 릴리스 빌드 단계에서 실패할 가능성이 큽니다.
- 조치:
  - `android/app/proguard-rules.pro`를 추가합니다.
  - `google_mobile_ads`, IAP, Hive 관련 shrink/obfuscation 영향도 확인합니다.
  - 릴리스 빌드 자체는 프로젝트 지침상 일반 작업에서 실행하지 않되, 릴리스 담당 단계에서 필수 게이트로 확인합니다.

### P0-2. 광고 로드가 UMP 동의 및 `MobileAds.initialize()` 완료 전 시작될 수 있습니다

- 위치:
  - `lib/main.dart:56`-`62`
  - `lib/app/bindings/app_binding.dart:73`-`78`
  - `lib/app/admob/ads_interstitial.dart:18`-`22`
  - `lib/app/admob/ads_rewarded.dart:19`-`23`
  - `lib/app/pages/home/main_shell_page.dart:41`-`47`
  - `lib/app/admob/ads_banner.dart:28`-`30`
- 근거: `main.dart`는 `unawaited(_initializeAds())`로 광고 동의/초기화를 비동기로 시작합니다. 반면 `AppBinding`은 광고 매니저를 즉시 등록하고 각 매니저의 `onInit()`에서 바로 `loadAd()`를 호출합니다. 배너도 화면 의존성 생성 시 바로 `_loadBanner()`를 호출합니다.
- 영향: EU/UK 등 동의 필요 지역에서 동의 전 광고 요청 정책 위반 및 초기화 경합이 발생할 수 있습니다.
- 조치:
  - `AdService` 또는 `AdConsentController`를 만들고 `canRequestAds` 상태를 단일 source of truth로 둡니다.
  - `initializeConsentAndAds()` 완료 후에만 광고 매니저 등록, 배너 렌더링, `loadAd()` 호출을 허용합니다.
  - 동의 실패/오프라인/초기화 실패 상태에서는 광고 UI를 숨기고 재시도 상태만 유지합니다.

### P0-3. 개인정보 처리방침 URL이 404입니다

- 위치:
  - `lib/app/utils/app_constants.dart:19`-`20`
  - `lib/app/controllers/setting_controller.dart:153`-`155`
- 확인 결과: `https://dangundad.github.io/privacy/doodle-pad` HEAD 요청이 `404`를 반환했습니다.
- 영향: 앱이 광고 ID, 광고 미디에이션, 인앱 결제, 로컬 이미지 저장/공유를 사용하므로 스토어 심사 차단 가능성이 큽니다.
- 조치:
  - 실제 Privacy Policy 페이지를 배포합니다.
  - AD_ID, Google Mobile Ads, AppLovin/Unity 미디에이션 동의, IAP, 로컬 저장 이미지, 공유 임시 파일 처리 방식을 명시합니다.
  - 릴리스 전 URL HTTP 상태를 CI 또는 수동 체크리스트에 넣습니다.

## 4. P1 - 핵심 로직/제품 흐름 개선

### P1-1. 저장/공유 캡처가 고정 `pixelRatio: 3`이고 `ui.Image`를 해제하지 않습니다

- 위치:
  - `lib/app/controllers/doodle_controller.dart:317`-`321`
  - `lib/app/controllers/doodle_controller.dart:325`-`340`
  - `lib/app/controllers/doodle_controller.dart:430`-`443`
- 영향: 고해상도 기기에서 풀스크린 캔버스를 3배로 캡처하면 메모리 사용량이 급증합니다. 반복 저장/공유 시 `ui.Image.dispose()` 누락도 누적 리스크가 됩니다.
- 조치:
  - 최대 픽셀 수 기준으로 동적 pixel ratio를 계산합니다.
  - `try/finally`에서 `image.dispose()`를 호출합니다.
  - 저장/공유 실패 시나리오를 테스트로 고정합니다.

### P1-2. 공유 성공 후 임시 PNG가 정리되지 않습니다

- 위치: `lib/app/controllers/doodle_controller.dart:437`-`453`
- 영향: 사용자가 공유한 그림이 앱 임시 디렉터리에 계속 남아 저장 공간과 프라이버시 리스크가 됩니다.
- 조치:
  - `ShareResult` 이후 지연 삭제를 시도합니다.
  - 앱 시작 시 `doodle_*.png` 임시 파일 정리 루틴을 추가합니다.

### P1-3. 긴 그림에서 전체 stroke repaint 비용이 커질 수 있습니다

- 위치:
  - `lib/app/controllers/doodle_controller.dart:263`-`273`
  - `lib/app/pages/draw/widgets/canvas_painter.dart:22`-`47`
  - `lib/app/pages/draw/widgets/canvas_painter.dart:171`-`226`
- 영향: 포인트가 추가될 때마다 전체 `strokes`를 다시 그리고, 에어브러시는 모든 포인트에 난수 점을 다시 계산합니다. 긴 그림이나 지우개가 포함된 그림에서 프레임 드롭이 발생할 수 있습니다.
- 조치:
  - 완료된 stroke는 `ui.Picture` 또는 bitmap cache로 누적하고 현재 stroke만 다시 그립니다.
  - 에어브러시 점 데이터는 stroke 생성 시 고정하거나 캐시합니다.
  - 지우개 레이어는 전체 캔버스 `saveLayer` 비용을 줄이는 방향으로 분리합니다.

### P1-4. “새 그림 시작”이 기존 unsaved strokes를 지우지 않습니다

- 위치:
  - `lib/app/pages/home/home_page.dart:260`-`264`
  - `lib/app/pages/gallery/gallery_page.dart:43`-`44`
  - `lib/app/pages/gallery/gallery_page.dart:299`-`300`
  - `lib/app/bindings/app_binding.dart:53`
- 영향: `DoodleController`는 permanent로 유지되는데 홈/갤러리의 “그리기 시작” 경로는 `clearReferenceDrawing()`만 호출합니다. 이전에 저장하지 않은 선이 남아 있으면 새 그림처럼 진입해도 기존 그림 위에 이어 그릴 수 있습니다.
- 조치:
  - “새 그림”은 `clearCanvas()` 또는 확인 후 `clearStrokes()`를 호출합니다.
  - 이어 그리기는 “최근 그림 계속하기” 같은 별도 동작으로 분리합니다.

### P1-5. 참조 이미지가 있어도 stroke가 없으면 저장/공유가 빈 그림으로 처리됩니다

- 위치:
  - `lib/app/controllers/doodle_controller.dart:307`-`310`
  - `lib/app/controllers/doodle_controller.dart:344`-`353`
  - `lib/app/controllers/doodle_controller.dart:419`-`427`
  - `lib/app/pages/gallery/gallery_page.dart:204`-`214`
- 영향: 갤러리에서 저장 이미지를 불러오면 화면에는 참조 이미지가 보이지만, 새 stroke가 없으면 저장/공유가 막히고 `gallery_empty` 메시지가 표시됩니다.
- 조치:
  - `hasDrawableContent => strokes.isNotEmpty || referenceImagePath.value != null` 같은 기준을 추가합니다.
  - 저장/공유 버튼 활성화와 토스트 문구를 같은 기준으로 맞춥니다.

### P1-6. 갤러리 “불러오기”는 실제 편집 복원이 아닙니다

- 위치:
  - `lib/app/pages/gallery/gallery_page.dart:121`-`133`
  - `lib/app/pages/gallery/gallery_page.dart:204`-`214`
  - `lib/app/controllers/doodle_controller.dart:307`-`310`
- 영향: 사용자는 저장한 그림을 다시 편집한다고 기대할 수 있지만, 현재 구현은 PNG를 참조 배경으로 깔고 stroke는 복원하지 않습니다. Undo/Redo 가능한 편집 복원이 불가능합니다.
- 조치:
  - 현재 구조를 유지한다면 문구를 “참조로 열기”로 바꿉니다.
  - 편집 복원이 목표라면 `DrawingStroke`와 캔버스 metadata를 Hive 모델로 저장합니다.

### P1-7. 탭 화면과 독립 route가 섞여 이동/뒤로가기 흐름이 혼란스럽습니다

- 위치:
  - `lib/app/pages/home/main_shell_page.dart:25`-`30`
  - `lib/app/pages/home/main_shell_page.dart:64`-`86`
  - `lib/app/pages/gallery/gallery_page.dart:26`-`29`
  - `lib/app/pages/home/home_page.dart:317`-`318`
  - `lib/app/pages/settings/settings_page.dart:66`-`80`
- 영향: `GalleryPage`가 하단 탭 안에도 있고 `/gallery` route로도 열립니다. 탭 안의 back 버튼은 홈 탭 전환이 아니라 route pop처럼 동작할 수 있습니다.
- 조치:
  - shell 탭 전환을 `MainShellController` 같은 단일 상태로 관리합니다.
  - 탭 내부 화면에서는 back 버튼을 숨기거나 홈 탭 전환 동작으로 바꿉니다.

### P1-8. 지원 언어 선언과 실제 번역/설정 옵션이 불일치합니다

- 위치:
  - `lib/app/translate/translate.dart:5`-`17`
  - `lib/app/translate/translate.dart:20`
  - `lib/app/pages/settings/settings_page.dart:12`-`15`
  - `lib/app/controllers/setting_controller.dart:88`-`89`
  - `lib/main.dart:100`-`109`
- 영향: `supportedLocales`에는 `ja/de/ru/fr/es/pt/id/zh/ar`가 포함되어 있지만 GetX 번역 map은 `en/ko`만 있습니다. 기기 언어에 따라 fallback 또는 raw key 노출 가능성이 있고, 설정 옵션도 `en/ko`만 제공합니다.
- 조치:
  - 실제 번역을 추가하기 전까지 `supportedLocales`를 `en/ko`로 제한합니다.
  - 다국어 출시가 목표라면 각 locale의 GetX key를 완성하고 설정 옵션도 동기화합니다.

### P1-9. 프리미엄/구매 상태 UI가 실제 상품 로딩과 구매 불가 상태를 충분히 반영하지 않습니다

- 위치:
  - `lib/app/services/purchase_service.dart:94`-`103`
  - `lib/app/services/purchase_service.dart:129`-`154`
  - `lib/app/pages/premium/premium_page.dart:62`-`85`
  - `lib/app/pages/premium/premium_page.dart:372`-`380`
- 영향: 상품 미등록/미조회 시 `notFoundIDs`를 로그만 남기고, UI는 fallback 가격과 구매 버튼을 계속 보여줄 수 있습니다.
- 조치:
  - 상품 조회 성공 전에는 구매 버튼을 비활성화합니다.
  - `available`, `statusMessage`, `errorMessage`, `products`를 프리미엄 화면에 명시적으로 반영합니다.
  - Play Console 상품 ID 등록 상태를 릴리스 체크리스트에 추가합니다.

### P1-10. 프리미엄 전환 후 광고 매니저가 남을 수 있습니다

- 위치:
  - `lib/app/bindings/app_binding.dart:73`-`78`
  - `lib/app/services/purchase_service.dart:337`-`344`
- 영향: 광고 매니저를 `permanent: true`로 등록한 뒤 `Get.delete()`를 `force: true` 없이 호출합니다. GetX permanent 인스턴스는 기본 삭제가 제한되므로 프리미엄 이후에도 광고 객체가 남을 수 있습니다.
- 조치:
  - 광고 매니저는 permanent 등록을 피하거나 `Get.delete<T>(force: true)`를 사용합니다.
  - `showAdIfAvailable()`에서도 프리미엄 상태를 재확인합니다.

### P1-11. 구매 권한 검증이 로컬 플래그와 미검증 purchase stream에 크게 의존합니다

- 위치:
  - `lib/app/services/purchase_service.dart:239`-`244`
  - `lib/app/services/purchase_service.dart:258`-`267`
  - `lib/app/services/purchase_service.dart:273`-`293`
- 영향: `verificationData` 검증 없이 `productID`만 맞으면 프리미엄을 부여하고, 저장된 `is_premium`도 먼저 신뢰합니다. 스토어 조회 실패, 오프라인, 로컬 변조 시 stale entitlement가 유지될 수 있습니다.
- 조치:
  - 서버 검증 또는 Play Developer API 기반 검증을 추가합니다.
  - 로컬 캐시는 임시 표시 용도로만 사용하고 만료/재검증 정책을 둡니다.

### P1-12. 핵심 drawing 액션 기록이 부족하고 이벤트 저장은 동시성에 약합니다

- 위치:
  - `lib/app/controllers/doodle_controller.dart:344`
  - `lib/app/controllers/doodle_controller.dart:393`
  - `lib/app/controllers/doodle_controller.dart:419`
  - `lib/app/services/activity_log_service.dart:53`-`89`
  - `lib/app/controllers/setting_controller.dart:189`-`205`
- 영향: save/share/delete/load/undo/redo 같은 핵심 액션이 히스토리에 충분히 남지 않습니다. 이벤트 기록도 Hive 리스트 read-modify-write 방식이고 호출부가 `unawaited`라 동시 기록 시 유실 가능성이 있습니다.
- 조치:
  - 성공한 핵심 액션마다 명시적인 log event를 남깁니다.
  - `ActivityLogService` 내부에 직렬 큐/락을 두어 기록 순서를 보장합니다.

### P1-13. 커스텀 컨트롤 접근성과 터치 영역이 부족합니다

- 위치:
  - `lib/app/pages/draw/draw_page.dart:430`-`487`
  - `lib/app/pages/draw/draw_page.dart:603`-`636`
  - `lib/app/pages/gallery/gallery_page.dart:328`-`384`
  - `lib/app/pages/premium/premium_page.dart:320`-`385`
- 영향: 브러시, 색상, 잠금 상태, 갤러리 카드, 요금제 선택이 스크린 리더에서 의미 있게 전달되지 않습니다. 색상 swatch는 30-36dp라 권장 터치 크기보다 작습니다.
- 조치:
  - `Semantics(button: true, selected: ..., label: ...)`를 추가합니다.
  - `Tooltip`, `InkWell`/`IconButton` 기반 48dp 이상 hit area를 적용합니다.

## 5. P2 - 품질/사용성 후속 개선

### P2-1. 캔버스가 툴바 아래까지 입력되고 저장됩니다

- 위치: `lib/app/pages/draw/draw_page.dart:20`-`26`, `lib/app/pages/draw/draw_page.dart:68`-`102`
- 영향: 상단/하단 툴바가 캔버스를 덮어 사용자가 보지 못한 영역에 선이 생길 수 있습니다.
- 조치: 캔버스 입력 영역을 툴바 높이만큼 inset 처리하거나 툴바 자동 숨김/접기 옵션을 제공합니다.

### P2-2. 저장 경로 검증과 갤러리 카드에서 동기 파일 IO를 사용합니다

- 위치:
  - `lib/app/controllers/doodle_controller.dart:134`-`141`
  - `lib/app/controllers/doodle_controller.dart:396`-`397`
  - `lib/app/pages/gallery/gallery_page.dart:325`-`349`
- 영향: 저장 이미지가 많아지면 앱 시작 및 갤러리 스크롤에서 jank가 발생할 수 있습니다.
- 조치: 파일 존재 여부와 metadata를 비동기 캐시하고, 갤러리는 저장 시점 metadata 모델을 표시합니다.

### P2-3. History/Stats에 loading/error 상태가 없습니다

- 위치:
  - `lib/app/controllers/history_controller.dart:20`-`21`
  - `lib/app/pages/history/history_page.dart:36`-`39`
  - `lib/app/controllers/stats_controller.dart:26`-`27`
  - `lib/app/pages/stats/stats_page.dart:67`-`99`
- 영향: Hive 로딩 중/실패 상태와 실제 기록 없음 상태를 구분할 수 없습니다.
- 조치: controller에 `isLoading`, `errorMessage`를 추가하고 loading, empty, error, retry 상태를 분리합니다.

### P2-4. History/Stats가 내부 이벤트명과 route를 사용자에게 노출합니다

- 위치:
  - `lib/app/pages/history/history_page.dart:78`-`83`
  - `lib/app/pages/history/history_page.dart:237`-`244`
  - `lib/app/pages/stats/stats_page.dart:120`-`129`
  - `lib/app/pages/stats/stats_page.dart:295`-`298`
- 영향: `home_open`, `open_stats`, `/home` 같은 개발자용 문자열은 일반 사용자에게 의미가 약합니다.
- 조치: 이벤트 이름과 route를 localized display map으로 변환하거나 route 노출을 숨깁니다.

### P2-5. 설정 옵션이 드로잉 앱 사용 흐름에 비해 부족합니다

- 위치:
  - `lib/app/pages/settings/settings_page.dart:98`-`145`
  - `lib/app/controllers/setting_controller.dart:34`-`43`
- 영향: 사용자는 기본 브러시/색상/굵기, 캔버스 배경, 내보내기 품질, 자동 저장, 모션 줄이기, 저장 그림 전체 삭제 같은 옵션을 기대할 수 있습니다.
- 조치 우선순위:
  - 기본 브러시/색상/굵기
  - 내보내기 품질
  - 자동 저장 또는 종료 전 확인
  - 모션 줄이기
  - 저장 그림 전체 삭제

### P2-6. 일부 상수 파일 주석에 인코딩 손상 흔적이 있습니다

- 위치: `lib/app/utils/app_constants.dart:13`, `lib/app/utils/app_constants.dart:33`
- 영향: 실행 영향은 작지만 유지보수 품질이 떨어지고 다국어 파일 수정 시 인코딩 관리가 필요합니다.
- 조치: UTF-8로 주석을 복구하고, 한글 포함 파일 수정 시 저장 인코딩을 확인합니다.

## 6. 테스트/검증 공백

현재 테스트는 설정 컨트롤러, 일부 설정 화면, 홈/배너, 구매 캐시 일부, 광고 빈 ID 스킵, 토스트 일부를 다룹니다. 다음 리스크는 테스트 또는 CI 검증으로 고정되어 있지 않습니다.

- 릴리스 `proguard-rules.pro` 존재 여부
- UMP 동의 전 광고 요청 차단
- 프리미엄 전환 후 permanent 광고 매니저 삭제
- Privacy Policy URL HTTP 상태
- Play Console 상품 미조회 시 구매 UI 비활성화
- 저장/공유 `pixelRatio` OOM 방지
- 공유 임시 파일 정리
- 참조 이미지만 있는 상태의 저장/공유 정책
- 새 그림 진입 시 기존 stroke 처리
- 지원 locale과 실제 translation key 일치

## 7. 권장 작업 순서

1. `android/app/proguard-rules.pro` 추가 및 릴리스 빌드 설정 정합성 확인
2. 광고 동의/초기화 게이트를 `AdService`로 분리
3. Privacy Policy 페이지 배포 및 URL 상태 검증
4. IAP 상품 조회 실패 UI, 상품 등록 체크, entitlement 검증 정책 정리
5. 저장/공유 메모리 및 임시 파일 정리
6. 새 그림/이어 그리기/참조로 열기 UX 문구와 상태 전환 정리
7. locale 선언을 실제 번역 범위와 맞춤
8. 접근성 semantics와 터치 영역 보강
9. History/Stats의 사용자 친화 문구와 loading/error 상태 추가
10. 위 항목을 회귀 테스트 또는 CI 체크로 고정

## 8. 확인한 긍정 요소

- `CanvasPainter`는 1점/2점/다점 stroke smoothing 분기를 갖추고 있습니다.
- 에어브러시는 seed를 stroke에 고정해 repaint 시 spray 패턴 flicker를 줄이려는 설계가 있습니다.
- undo/redo/clear 기본 스택 동작은 단순하고 이해하기 쉽습니다.
- 빈 release 광고 unit ID일 때 광고 로드를 스킵하는 테스트가 있습니다.
- 설정/피드백/외부 링크 일부 동작은 테스트로 고정되어 있습니다.

## 9. 최종 판정

이 저장소는 “기능 구현 완료” 단계로는 볼 수 있지만, 광고/결제/개인정보/릴리스 설정이 포함된 앱 기준으로는 아직 최종 출시 전 리뷰를 통과하기 어렵습니다. 코드 수정의 첫 대상은 UI polish보다 **릴리스 차단 항목(P0)** 이어야 하며, 그 다음 저장/공유 메모리 안정성, 새 그림 상태 전환, 참조 이미지 UX, IAP 상태 UI를 순서대로 처리하는 것이 좋습니다.

## 10. 실행 검증

문서 작성 후 아래 검증을 실행했습니다.

| 명령 | 결과 |
|---|---|
| `flutter analyze` | 통과: `No issues found!` |
| `flutter test` | 통과: `All tests passed!` |
| `Test-Path android\app\proguard-rules.pro` | 실패 근거 확인: `False` |
| `Invoke-WebRequest -Method Head https://dangundad.github.io/privacy/doodle-pad` | 실패 근거 확인: `STATUS 404` |

주의: `flutter analyze`와 `flutter test` 통과는 현재 코드의 정적 오류와 기존 테스트 범위 통과만 의미합니다. 이 문서의 P0/P1 항목 중 광고 동의 게이트, 릴리스 ProGuard, Privacy Policy URL, IAP entitlement 검증, 저장/공유 메모리 안정성은 기존 테스트가 충분히 막고 있지 않습니다.
