# Doodle Pad 배포 전 최종 점검 리뷰

> 작성: Claude Code (Opus 4.7)
> 작성일: 2026-05-16
> 대상 버전: `pubspec.yaml` 1.0.0+1
> 범위: `lib/` 전체, `android/` 빌드 구성, `test/` 커버리지
> 목적: 스토어 제출 직전 핵심 로직 / UI / 설정 / 수익화 / 빌드 전 영역 최종 감사

---

## 0. 요약 대시보드

| 영역 | 상태 | Blocker | Major | Minor |
|------|------|--------:|------:|------:|
| 핵심 드로잉 로직 | 🟢 출시 가능 | 0 | 2 | 4 |
| UI/UX | 🟡 수정 권장 | 2 | 6 | 15 |
| 서비스/수익화 | 🟠 수정 필요 | 2 | 4 | 3 |
| 빌드/설정/i18n | 🟡 수정 권장 | 1 | 2 | 2 |
| **합계** | **🟠 조치 필요** | **5** | **14** | **24** |

배포 차단 핵심 5건은 **iOS App Store ID 미입력**, **AdMob 환경 변수 미설정 시 테스트 ID 노출**, **홈 진입 다이얼로그 탈출 불가**, **설정 데이터 삭제 후 상태 불일치**, **local.properties 기본값 빌드 위험**입니다. 이 5건은 제출 전 반드시 해결을 권장합니다.

---

## 1. 핵심 드로잉 로직

### 1.1 DoodleController (`lib/app/controllers/doodle_controller.dart`)

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 586 | Major | `continueStroke()`에서 `strokes.refresh()` 호출. 손가락 이동 매 프레임마다 전체 옵저버 재트리거 → 저사양 기기에서 프레임 드랍 위험. 마지막 stroke만 부분 갱신하도록 별도 `RxList<List<Point>>` 또는 `ValueNotifier` 분리 권장 |
| 436 | Major | 다중 터치 환경에서 `_currentStroke` 단일 참조에 의존. 동시에 두 손가락이 닿으면 끊긴 선이 남거나 잘못된 stroke가 제거될 수 있음. 핀치 줌과의 경합은 `7a5af4e` 커밋에서 일부 완화되었으나 다중 펜 입력 케이스 회귀 테스트 필요 |
| 116, 649 | Minor | `_undoStack` 최대 20개로 관리. 정상이지만 redo 스택 비움 시점이 명시되지 않아 사용자 멘탈모델과 어긋날 수 있음 |
| 269 | Minor | `Vibration.hasVibrator()` 비동기 결과를 기다리지 않고 즉시 사용 가능 상태로 진입. 초기화 가드 보강 권장 |
| 705 | Minor | `_captureCanvas()` 실패(boundary null) 시 토스트 한 줄. 사용자에게 "잠시 후 다시 시도" 등 회복 안내가 없음 |

### 1.2 DrawPage / CanvasPainter

| 위치 | 심각도 | 발견 |
|------|--------|------|
| `draw_page.dart:240` | Minor | `controller.strokes.toList()` 매 빌드마다 새 리스트 생성. `List.unmodifiable()`로 감싸 캐싱 권장 |
| `canvas_painter.dart:21` | Minor | `strokes.any((s) => s.brushType == BrushType.eraser)` 매 paint 호출. 컨트롤러에 `hasEraser` boolean 캐시 권장 |
| `canvas_painter.dart:104` | Info | `shouldRepaint`가 항상 true 반환. Obx가 외부에서 필터링 중이라 안전하나, 의도 명확화 주석 권장 |

### 1.3 BrushPreset / 모델

| 위치 | 심각도 | 발견 |
|------|--------|------|
| `brush_preset.dart:150` | Minor | `type.index` 기반 Random seed. eraser 등 미등록 타입 호출 시 인덱스 오류 가능. `stableId` 사용 권장 |
| `drawing.dart:40` | Major | `pointsXY: List<double>` 짝수 길이 보장 미명시. 손상된 Hive 데이터 deserialize 시 IndexError 가능. `assert(pointsXY.length.isEven)` + 안전한 fallback 필요 |
| `drawing.dart:85` | Minor | `brushTypeIndex` 필드명은 실제로 `stableId`를 담음. 레거시 주석은 있으나 마이그레이션 또는 이름 변경 필요 |

---

## 2. UI / UX

### 2.1 HomePage (`lib/app/pages/home/home_page.dart`)

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 21–109 | **Blocker** | "이어 그리기 / 새로 시작" 다이얼로그가 `barrierDismissible: false`. 뒤로가기/바깥 탭으로 탈출 불가. 사용자가 결정을 보류할 수 없음 → 닫기(취소) 동작 추가 또는 barrier 허용 |
| 102 | Major | `continueExisting == null` 경로에서 아무 동작 없음. 다이얼로그 외부 입력 차단된 상태에서 상태 일관성 위험 |
| 171–180 | Minor | 헤더 아이콘 버튼 탭 타깃이 44.r 미만. Material 가이드라인 48.r로 확대 권장 |
| 313–330 | Minor | 이모지 장식이 Semantics label 없이 노출 |

### 2.2 GalleryPage

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 88–94 | Major | 2열 그리드 고정. 태블릿/폴더블에서 비효율. `SliverGridDelegateWithMaxCrossAxisExtent` 전환 권장 |
| 167–195 | Major | 공유 실패 시 토스트만 표시, 실패 원인(권한/파일 누락) 미설명 |
| 76–77 | Minor | 로딩 인디케이터만 노출, 비어 있을 때와 로딩 중 시각 구분 약함 |
| 139–151 | Minor | 단건 길게-눌러-삭제와 다중 선택 모드의 인터랙션 불일치 |

### 2.3 SettingsPage

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 178–217 | **Blocker** | "데이터 삭제" 실행 후 토스트만 띄우고 컨트롤러/바인딩 재초기화가 명확하지 않음. 갤러리/설정/프리미엄 상태가 분리 보존되므로 화면 잔존 상태로 인한 버그 가능 |
| 220–267 | Major | 언어 변경 시 즉시 반영되는지 검증 필요. `Get.updateLocale` 호출 후 일부 위젯(예: AppBar 타이틀)에서 캐시된 문자열 잔존 가능 |
| 236–267 | Minor | 좁은 화면에서 ChoiceChip Wrap이 잘릴 수 있음 |
| 376–379 | Minor | `_loc()` fallback 동작으로 누락 키가 영어로 표시. 누락 자체는 `translate_consistency_test.dart`로 방지 중이라 양호 |

### 2.4 PremiumPage / SaveOptionsSheet / ExitBottomSheet / Theme

| 위치 | 심각도 | 발견 |
|------|--------|------|
| `premium_page.dart:438–454` | Major | 구매 진행 중 버튼 높이 떨림. 고정 높이 + 로딩 인디케이터 권장 |
| `premium_page.dart:357–361` | Minor | 선택 체크/미선택 원이 색만 다름. 색맹 대응으로 형태 차이 추가 |
| `save_options_sheet.dart:19, 42` | Minor | 현재 해상도 미노출, `isScrollControlled: false` 고정 → 작은 화면에서 콘텐츠 잘림 |
| `exit_bottom_sheet.dart:99–129` | Major | 종료 시점 프리미엄 배너 노출은 침입적. 빈도 제한(예: 7일 1회) 권장 |
| `app_theme.dart` | Info | FlexColorScheme 사용 양호. 다크 모드 텍스트 대비 수동 검증 권장 |

---

## 3. 서비스 / 수익화 / 광고 / 결제

### 3.1 결제 보안 — `purchase_service.dart`

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 270–287 | **Major** | `_onPurchaseCompleted()`가 productId 매칭만으로 프리미엄 부여. **서명(signedData/signature) 검증 없음** → 디바이스 변조 시 우회 가능. 최소한 Google Play Billing의 `verifyPurchase` 호출 또는 백엔드 검증 권장 |
| 251–257 | Major | `completePurchase()` 실패 무시. 미완료 구매가 누적되어 다음 세션에 재트리거되는 부작용 가능 |
| 304–325, 205–227 | Minor | `_refreshPremiumStatusFromStore()` / `restorePurchases()`가 Android 우선. iOS 분기 미흐름 — 단, Android 우선 정책상 의도된 설계라면 iOS 진입점에서 UI 숨김 처리 필요 |

### 3.2 광고 정책 — `lib/app/admob/`

| 라인 | 심각도 | 발견 |
|------|--------|------|
| `ads_helper.dart:10–18, 231–269` | **Blocker** | AdMob 광고 단위 ID가 환경 변수(`DOODLE_PAD_ADMOB_*`)로 주입되며, **미설정 시 Google 공식 테스트 ID로 폴백**. 릴리스 빌드에서 환경 변수 누락 시 테스트 ID로 출시되어 정책 위반 + 노출 0 위험. 릴리스 빌드에서 `assert(kReleaseMode == false || envIdNotEmpty)` 추가 권장 |
| `main.dart:128–134` | Major | AdMob 초기화 try-catch 후 무시. 동의(UMP) 미확정 상태에서 광고 요청이 흘러갈 수 있음 |
| `ads_banner.dart:164–206` | Minor | `AdHelper.canRequestAds` 재확인 없이 로드 가능 경로 존재 |

### 3.3 데이터 / 저장 — `artwork_repository.dart`, `hive_service.dart`

| 라인 | 심각도 | 발견 |
|------|--------|------|
| `artwork_repository.dart:68–85` | Major | 참조 사진 복사 실패 시 null 반환 → 원본 경로 유지로 다음 열기 때 null 참조 가능. 트랜잭션(파일 쓰기 성공 후 Hive 커밋) 패턴 적용 권장 |
| `artwork_repository.dart:99–127` | Minor | PNG `flush: true` 작성은 양호. 다만 디스크 가득 차 있을 때 부분 작성 검증 없음 |
| `hive_service.dart:29–33` | Minor | 3개 box를 `Future.wait`로 병렬 오픈. 하나 손상 시 전체 실패 → 개별 try-catch로 partial recovery 권장 |

### 3.4 초기화 순서 — `main.dart`, `app_binding.dart`

| 라인 | 심각도 | 발견 |
|------|--------|------|
| `main.dart:82–134` | Major | Firebase·HiveService·광고 초기화 의존 관계가 `postFrameCallback` 위에 흩어져 있음. 광고 매니저가 동의/HiveService 완료 전 등록될 수 있음 → `_StartupFailureScreen` fallback 있지만 부분 실패 케이스가 사용자에게 보이지 않음 |
| `app_binding.dart:98–122` | Minor | `SettingController` 등록을 `DoodleController` 전 보장하는 `_ensureDependencyServices()` 호출이 여러 진입점에 분산. 단일 진입점 통합 권장 |

### 3.5 ID 하드코딩 — `app_constants.dart`

| 라인 | 심각도 | 발견 |
|------|--------|------|
| 55 | **Blocker** | `iosAppStoreId = '0000000000'` (TODO). 평점 요청·App Store 링크가 깨짐 → 입력 전 iOS 빌드 불가 처리 또는 Android 전용 명시 |
| 36–46 | Info | IAP 상품 ID 하드코딩. 상수 관리 양호 |

---

## 4. 빌드 / 설정 / i18n / 테스트

### 4.1 Android 빌드

| 항목 | 위치 | 심각도 | 상태 |
|------|------|--------|------|
| 서명 설정 | `android/app/build.gradle.kts:60–88` | OK | 릴리스 시 `key.properties` throw 검증 양호. R8/ProGuard 활성, Firebase/AdMob/Billing keep 규칙 완비 |
| 버전 동기화 | `pubspec.yaml:3` ↔ `android/local.properties` | **Blocker** | `local.properties` 누락/기본값(1, 1.0.0)으로 빌드 시 Play Console 버전 충돌 위험. CI/CD에서 `flutter.versionCode`/`Name` 명시 주입 권장 |
| 권한 | `AndroidManifest.xml` | Major | `VIBRATE`, `INTERNET`, `AD_ID`, `BILLING` 선언 OK. **`SENSOR` 또는 `HIGH_SAMPLING_RATE_SENSORS` 미선언** — `sensors_plus` + ShakeDetectorMixin 동작 위해 명시 권장(가속도계는 위험 권한 아니므로 런타임 prompt 불필요하나 정책 투명성) |
| key.properties | `.gitignore` | Minor | gitignore 포함 여부 확인 필요(보안) |

### 4.2 다국어 — `translate.dart`

- 11개 언어(en, ko, ja, de, ru, fr, es, pt, id, zh, ar) 키셋 완비.
- `test/translate_consistency_test.dart`가 키 일관성 자동 검증 → 누락 위험 매우 낮음. ✅
- 단, 동적 문자열(가격, 날짜, 갯수)의 복수형/포맷 미검증.

### 4.3 SettingController / Mixins

- 언어 코드 화이트리스트 + 손상값 정규화(`setting_controller.dart:124–198`) 견고.
- ShakeDetectorMixin 임계값·디바운스·구독 해제 모두 테스트됨(`test/app/mixins/shake_detector_mixin_test.dart`).

### 4.4 테스트 커버리지

`test/` 24개 파일 — controllers/services/admob/pages/widgets/mixins/theme/utils/translate 전반 커버. 누락 권장:
- `purchase_service` 영수증 검증 mock 시나리오
- `artwork_repository` 디스크 풀/권한 거부 케이스
- AdMob 환경 변수 미주입 → 폴백 차단 assert 테스트

---

## 5. 배포 직전 체크리스트

### 🔴 Blocker (제출 전 필수)
- [ ] `app_constants.dart:55` iOS App Store ID 입력 또는 iOS 출시 제외 명시
- [ ] `ads_helper.dart` 환경 변수 `DOODLE_PAD_ADMOB_*` 모두 주입 + 릴리스 빌드 폴백 차단 assert
- [ ] `android/local.properties` versionCode/versionName 명시 (CI/CD 권장)
- [ ] HomePage 진입 다이얼로그(`home_page.dart:21–109`)에 닫기/취소 동작 추가
- [ ] SettingsPage 데이터 삭제 후 컨트롤러 재초기화 흐름 명확화(`settings_page.dart:178–217`)

### 🟠 Major (가능하면 제출 전)
- [ ] Google Play Billing 영수증 서명 검증 도입
- [ ] AndroidManifest에 `<uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS"/>` 검토 추가
- [ ] DoodleController `continueStroke` 리페인트 최적화
- [ ] Drawing 모델 `pointsXY.length.isEven` 검증
- [ ] 종료 시트 프리미엄 배너 노출 빈도 제한
- [ ] PremiumPage 구매 버튼 높이 고정
- [ ] Gallery 그리드 maxCrossAxisExtent 적용

### 🟡 Minor (배포 후 백로그)
- [ ] 다중 터치 입력 회귀 테스트(`doodle_controller.dart:436`)
- [ ] BrushPreset `stableId` 마이그레이션 (`brush_preset.dart:150`, `drawing.dart:85`)
- [ ] HiveService partial recovery
- [ ] AppBinding 의존성 등록 단일 진입점 통합
- [ ] 접근성 Semantics label / 색맹 대응 보강
- [ ] AdMob UMP 동의 재확인 흐름 일원화

---

## 6. 종합 의견

코드 구조(`GetX` + `Hive_CE` + `perfect_freehand`)와 테스트 커버리지(24개 파일, 다국어 일관성 자동검증, ShakeDetector·SettingController·ShareFileCleanup 등 핵심 흐름 포함)는 1인 개발 Flutter 앱 기준 평균 이상으로 견고합니다. 핵심 드로잉 로직은 메모리 누수·null safety 측면에서 방어가 충실하여 **출시 가능 상태**로 판단됩니다.

다만 **수익화(영수증 검증·테스트 광고 ID 폴백)**, **버전 관리(local.properties 기본값)**, **iOS App Store ID TODO** 세 영역은 정책 위반 또는 운영 사고로 직결되는 위험이므로 위 Blocker 5건을 해결한 뒤 제출하시기 바랍니다. UI/UX Blocker 2건(홈 다이얼로그 탈출, 설정 삭제 후 상태)은 사용자 신뢰와 직결되므로 함께 처리 권장합니다.

Major 항목은 1.0.0 직후 1.0.1 핫픽스로 단계 분할이 가능합니다.
