# 실기기/에뮬레이터 전 기능 QA — 2026-09-10

> 대상: `doodle_pad` 1.0.0+1 (debug build)
> 환경: Samsung SM-G781N (Android 13, 1080x2400 / 360dp) · Pixel 9 Pro AVD (Android 17, 1080x2400 / 360dp로 맞춤)
> 방법: `adb` 입력 주입 + 스크린샷 육안 검수 + `logcat` + MediaStore 직접 조회 + raw 픽셀 샘플링

## 요약

| 구분 | 건수 |
| --- | --- |
| 출시 차단(Critical) | 2 |
| 높음(High) | 3 |
| 보통(Medium) | 4 |
| 낮음(Low) | 3 |
| 이번 스프린트 수정 완료 | 11 |
| 보고만 (제품 판단 필요) | 1 |

정적 검증: `flutter analyze` 0 issue · `flutter test` **137개 통과** (기존 130 + 신규 회귀 7).

### 수정 후 재검증 결과

| 항목 | 검증 방법 | 결과 |
| --- | --- | --- |
| C-1 홈 버튼 | 시트 열었다 닫고 → 그리기 → 홈 → 확인 | 에뮬레이터·**실기기 모두 홈 화면 진입 성공** |
| C-2 debug 빌드 | `flutter build apk --debug` (key.properties 없음) | 성공 |
| H-1 상태바 | 갤러리 다녀온 뒤 `dumpsys window` | `LIGHT_STATUS_BARS` 유지, 아이콘 육안 확인 |
| H-2 파일명 | MediaStore `ls /sdcard/Pictures` | `doodle_…​.png` / `doodle_…​.jpg` (단일 확장자) |
| M-1 브러시 표시 | 앱 재시작 후 하단 툴바 | 마지막 브러시가 퀵 행 맨 앞에 선택 표시 |
| M-2 썸네일 | 보관함 스크린샷 | 그림 전체 노출 + 셀 확대로 크게 표시 |
| L-1 grain | 크레용·연필 획 스크린샷 | 떠 있던 점 사라짐 |
| L-3 다이얼로그 | 잠금 에어브러시 탭 | 앱 공통 스타일로 표시 |

---

## 1. Critical

### C-1. 홈 버튼 / 시스템 백이 동작하지 않음 → 설정·프리미엄 진입 불가 + 작업물 손실

**증상.** 그림을 그린 뒤 상단 홈 버튼을 누르면 "그림을 지울까요?" 확인 후
**캔버스만 비워지고 홈 화면으로 이동하지 않는다.** 시스템 백도 마찬가지로 종료 시트가
뜨지 않는다. 홈 화면이 설정/프리미엄/작품 보관함 허브의 유일한 입구이므로,
**한 번이라도 시트나 다이얼로그를 연 사용자는 설정 화면에 영영 도달할 수 없다.**

**재현.** 앱 실행 → 브러시 시트(`+`) 열었다 닫기 → 아무 획이나 긋기 → 홈 버튼 → "지우기"
(완전히 깨끗한 첫 실행에서 바로 홈을 누르면 정상 동작해 놓치기 쉽다.)

**원인.** `Get.previousRoute.isEmpty` 로 "DRAW가 루트인가"를 판별했는데, GetX의
`previousRoute` 는 bottomSheet/dialog 를 한 번 띄우면 그 이름으로 채워진 뒤 다시는
비지 않는다. 따라서 항상 `Get.back()` 분기를 타고, DRAW가 루트라 아무 일도 일어나지 않는다.

**수정.** `Navigator.of(context).canPop()` 으로 실제 스택을 직접 확인한다.
(`lib/app/pages/draw/draw_page.dart` — 홈 버튼 / `PopScope` 두 곳)

### C-2. `android/key.properties` 가 없으면 **debug 빌드까지** 실패

**증상.** `flutter build apk --debug` / `flutter run` 이
`Release signing requires android/key.properties` 로 실패. 키스토어가 없는 새 클론에서는
디버그 실행조차 불가능.

**원인.** 릴리스 서명 가드를 `buildTypes { getByName("release") { ... } }` 블록 안에서
`throw` 했는데, 이 블록은 Gradle **configuration 단계**에서 항상 평가된다.

**수정.** 가드를 `gradle.taskGraph.whenReady` 로 옮겨 `:app:(assemble|bundle|package|install)Release`
태스크가 실제로 그래프에 올라왔을 때만 실패시킨다. 릴리스 보호는 그대로 유지된다.
(`android/app/build.gradle.kts`)

---

## 2. High

### H-1. 상태바 아이콘이 보이지 않음

**증상.** 작품 보관함/설정/프리미엄(주황 AppBar)을 들렀다 그리기 화면으로 돌아오면
상태바 아이콘이 흰색으로 남아 **흰 캔버스 위에서 시계·배터리·신호가 통째로 사라진다.**
다크 테마에서는 처음부터 같은 문제가 발생한다(캔버스는 항상 밝음).

**검증.** `dumpsys window` 의 `mLastAppearance` 에 `LIGHT_STATUS_BARS` 플래그가 사라진 것을 확인.

**원인.** DrawPage에 AppBar가 없어 자체 `SystemUiOverlayStyle` 을 선언하지 않았고,
직전 화면 AppBar가 설정한 스타일이 그대로 남는다.

**수정.** DrawPage를 `AnnotatedRegion<SystemUiOverlayStyle>` 로 감싸고, **캔버스 색 휘도**로
아이콘 밝기를 정한다(밝은 캔버스 → 어두운 아이콘). 다크 테마·검정 캔버스 케이스까지 함께 해결된다.

### H-2. 갤러리 저장 파일명에 확장자가 두 번 붙음

**증상.** 저장된 파일이 `doodle_1789010363663.png.png`, `doodle_1789010384993.jpg.jpg`.
(에뮬레이터 MediaStore `content query` 로 실물 확인. 파일 내용 자체는 정상 PNG/JPEG.)

**원인.** `gal` 은 `name` 에 확장자를 넣지 말 것을 명시하고(`Do not include the extension`)
bytes에서 판별한 확장자를 스스로 붙이는데, `ExportService._defaultFileName` 이 확장자까지 넣었다.

**수정.** 기본 파일명을 `doodle_<ts>` 로 변경. 회귀 테스트 2건 추가(PNG/JPEG).

### H-3. Android 10 이하에서 갤러리 저장 불가 (권한 선언 누락)

**증상(코드/플러그인 계약 기준).** `minSdk = 24` 인데 `WRITE_EXTERNAL_STORAGE` 선언이 없다.
`gal` 은 `SDK_INT <= 29` 에서 legacy external storage 경로로 쓰기 때문에 이 권한이 필수이며,
미선언 상태에서는 권한 요청이 즉시 거부되어 `permissionDenied` → "저장 권한이 필요합니다"
토스트만 반복된다. **Android 7~10 사용자는 갤러리 저장을 성공시킬 방법이 없다.**

**수정.** `AndroidManifest.xml` 에 `WRITE_EXTERNAL_STORAGE (maxSdkVersion=29)` +
`requestLegacyExternalStorage="true"` 추가. API 30+ 에서는 무시된다.

> 보유 기기가 Android 13이라 실기기 재현은 불가. 플러그인 소스(`GalPlugin.java:207`
> `hasAccess()`)와 README 요구사항으로 확인했다.

---

## 3. Medium

### M-1. 재시작하면 "선택된 브러시" 표시가 사라짐

`brushType` 은 영속화하지 않아 항상 pen 으로 초기화되는데 `recentBrushes` 는 저장된다.
최근 목록에서 pen 이 밀려나 있으면 하단 퀵 행 어디에도 선택 표시가 없고,
전체 시트를 열어야만 현재 브러시를 알 수 있다.

**수정.** `last_brush_type` 키로 마지막 브러시를 저장/복원하고, 복원된 브러시가 퀵 행에
없으면 맨 앞에 자리를 확보한다. 잠긴 브러시가 저장돼 있으면 pen 으로 폴백. 회귀 테스트 2건 추가.

### M-2. 작품 썸네일이 과도하게 잘림

세로로 긴 캔버스(≈9:20)를 거의 정사각형 카드에 `BoxFit.cover` 로 넣어, 그림 대부분이
잘려 나가 작품을 식별할 수 없었다(획 2개 중 1개만 보임).

**수정.** `BoxFit.contain` + 카드 배경색으로 여백 처리. 다만 정사각형 셀에 세로 그림을
넣으면 좌우 여백이 셀의 2/3를 먹어 그림이 작아지므로, 그리드 `childAspectRatio` 를 `0.72` 로
낮춰 같은 폭에서 그림이 크게 보이도록 함께 조정했다.

### M-3. 첫 실행 언어가 기기 로케일을 따르지 않음

11개 언어를 지원하는데 저장된 설정이 없으면 무조건 `en` 으로 시작한다.
한국어/일본어 기기 사용자도 첫 화면이 영어.

**수정.** 저장값이 없을 때만 `Get.deviceLocale` 을 참고해 지원 언어면 그 언어로 시작.
`clearAppSettings()` 의 초기화 값도 같은 기준으로 맞춰, 초기화 직후와 다음 부팅의 언어가
어긋나지 않게 했다. `Get.deviceLocale` 은 실제 `PlatformDispatcher` 를 보므로
flutter_test 로 바꿀 수 없어, `SettingController(deviceLocaleFn: ...)` 주입점을 추가하고
회귀 테스트 3건(기기 로케일 채택 / 미지원 로케일 폴백 / 저장값 우선)을 붙였다.

### M-4. 전면광고가 로드되지만 노출 지점이 없음 — **보고만 (제품 판단 필요)**

logcat 에 `Interstitial ad loaded` 가 찍히지만 `InterstitialAdManager.show*` 를 호출하는
코드가 앱 전체에 없다. 매 실행마다 광고를 받아놓고 버리는 셈이라 트래픽·배터리 낭비이고,
AdMob 의 노출률(match/show rate) 지표에도 불리하다.

선택지는 두 가지이고 둘 다 제품 결정이라 코드는 건드리지 않았다.
1. 노출 지점을 만든다 (예: 작품 저장 N회마다, 홈 복귀 시)
2. `AppBinding._ensureDependencyServices` 에서 `InterstitialAdManager` 등록을 제거한다

---

## 4. Low (수정 완료)

- **L-1. 연필/크레용 결(grain) 점이 획 끝에서 분리되어 떠 보임.**
  outline 은 `perfect_freehand` 가 streamline 보정한 중심선을 쓰는데 grain 은 원본
  포인트를 써서 생긴 어긋남. 같은 보정을 grain 에도 적용.
- **L-2. 굵기 미리보기 점이 실제 굵기/농도와 다름.** 슬라이더 값만 반영해 marker(×2.0)와
  pencil(×0.7)이 같은 크기로 보이고, 형광펜(alpha 0.35)·수채화(0.28)도 불투명하게 보였다.
  `sizeMultiplier` 와 `alpha` 를 미리보기에 반영.
- **L-3. 잠금 브러시 다이얼로그만 스타일이 달랐다.** 여기만 `Get.defaultDialog` 라
  알약 버튼 + 아이콘 없는 형태가 튀어나왔다. 앱 공통 다이얼로그(원형 아이콘 + 좌우 버튼)로 통일.

---

## 5. 정상 확인된 항목

- 브러시 10종 렌더링(펜/연필/마커/붓/형광펜/만년필/크레파스/수채화/에어브러시) 및 지우개
- 실행취소/다시실행 활성화 상태 전이
- 캔버스 지우기 확인 다이얼로그, 캔버스 배경색 6종 + 커스텀
- 보상형 광고 시청 → 수채화 잠금 해제 → 재시작 후에도 유지
- 갤러리 저장(1x/2x/3x · PNG/JPEG) — 파일 시그니처 `89504E47` / `FFD8FFE0` 정상
- 작품 저장 → 보관함 → 열기(덮어쓰기 확인) → 좌표 복원 정확
- 설정 11개 언어 전환, 다크 모드, 종료 시트
- 프리미엄 화면(플랜 3종, 스크롤, 폴백 가격)
- 크래시 0건 (`logcat -b crash` 비어 있음)

## 6. 테스트 중 관찰된 환경 이슈 (앱 문제 아님)

실기기 `R3CN90X6EEZ` 를 다른 세션이 `adb`(uid 2000)로 동시에 조작 중이었다.
(`com.dangundad.voice.scribe` 실행, 예기치 않은 BACK 이벤트, 포커스 탈취)
초반 테스트 결과가 오염되어, 이후 전수 스윕은 동일한 360dp 화면 설정으로 맞춘
Pixel 9 Pro 에뮬레이터에서 진행했다.
