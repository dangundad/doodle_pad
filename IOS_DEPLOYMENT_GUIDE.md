# Doodle Pad iOS 개발 및 배포 가이드라인

이 문서는 **Doodle Pad** 앱의 iOS 버전 배포를 위한 수정 사항, 설정 및 배포 절차를 설명합니다. (siren `IOS_DEPLOYMENT_GUIDE.md`를 기준으로 doodle_pad에 맞게 적용한 결과물입니다.)

> 기준 버전: `pubspec.yaml` → `version: 1.0.0+1` / 배포 타겟: **iOS 15.0+** (`ios/Podfile` `platform :ios, '15.0'`)
> Bundle ID: `com.dangundad.doodlepad` / IAP 상품: `com.dangundad.doodlepad.premium.{small,medium,large}`

**🚨 중요 원칙**
1. **Android 로직 보존:** iOS 대응 변경은 기존 Android 로직에 영향을 주지 않는다 (`TargetPlatform`/`Platform.isIOS` 분기).
2. **iOS UI/UX 최소 기준:** Safe Area, 스와이프 뒤로 가기(GetX popGesture 기본 활성), Cupertino 스타일 시스템 팝업(ATT 사전 설명) 준수.

---

## 1. 적용 완료된 iOS 대응 (2026-08-03)

### 1.1 ATT (App Tracking Transparency)
- **사전 설명(Pre-ATT Explainer):** 시스템 ATT 팝업 전에 `CupertinoAlertDialog`로 추적 필요성을 설명. 상태가 `notDetermined`일 때만 표시.
  - 코드: `lib/app/admob/ads_helper.dart` → `_requestTrackingAuthorizationIfNeeded` / `_showAttExplainerDialog`
  - 번역: `att_title` / `att_content` / `att_action` — **11개 언어** (`lib/app/translate/translate.dart`)
  - 흐름: `앱 실행` → `DoodlePadApp.initState` → `addPostFrameCallback` → `AdHelper.initializeConsentAndAds()` → ATT 사전 설명(`Get.context` 사용) → 시스템 ATT 팝업 → UMP 동의 → `MobileAds.initialize`
- **Info.plist:** `NSUserTrackingUsageDescription` 영어 기본값 + `*.lproj/InfoPlist.strings` 현지화.

### 1.2 광고 단위 ID (릴리스 주입)
- Debug/Profile: Google 샘플 ID. Release: `--dart-define` 주입 (미주입 시 광고 스킵 + 경고 로그).
  - `DOODLE_PAD_ADMOB_BANNER_IOS` / `DOODLE_PAD_ADMOB_INTERSTITIAL_IOS` / `DOODLE_PAD_ADMOB_REWARDED_IOS`
- AdMob **App ID**: `Info.plist` → `GADApplicationIdentifier = $(GAD_APPLICATION_IDENTIFIER)`.
  - `ios/Flutter/Debug.xcconfig`·`Profile.xcconfig`: Google 샘플 App ID
  - `ios/Flutter/Release.xcconfig`: `GAD_APPLICATION_IDENTIFIER=$(IOS_ADMOB_APP_ID)` → **빌드 시 `IOS_ADMOB_APP_ID` 주입 필요**
- `SKAdNetworkItems` 40종 등록됨 (Google + AppLovin/Pangle/Unity 미디에이션 포함).

### 1.3 앱 이름·권한 문구 다국어 (InfoPlist.strings)
- 위치: `ios/Runner/<lang>.lproj/InfoPlist.strings` — **11개 언어** (`en, ko, ja, de, ru, fr, es, pt, id, zh-Hans, ar`)
- 키: `CFBundleDisplayName`(translate.dart의 `app_name`과 동일 값), `NSPhotoLibraryAddUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSUserTrackingUsageDescription`
- `project.pbxproj`의 `knownRegions` / `PBXVariantGroup` / Resources 빌드 페이즈에 **등록 완료** → Xcode 수동 추가 불필요.
- 미지원 언어는 `Info.plist`의 영어 기본값으로 폴백.

### 1.4 Privacy Manifest (`ios/Runner/PrivacyInfo.xcprivacy`)
- `NSPrivacyAccessedAPITypes`: UserDefaults(`CA92.1`) — shared_preferences/rate_my_app 사용.
- `NSPrivacyCollectedDataTypes`: DeviceID (tracking=true, 제3자 광고 목적).
- `NSPrivacyTracking=true` + `NSPrivacyTrackingDomains`: `googleads.g.doubleclick.net`, `googleadservices.com`.
- pbxproj Resources에 등록 완료. 서드파티 SDK(GoogleMobileAds/Firebase/AppLovin 등)는 Pods에 자체 매니페스트 동봉.
- **검증:** Archive 후 Organizer → **Generate Privacy Report**.

### 1.5 iOS 동작 수정
- **앱 종료 버튼:** `ExitBottomSheet`의 종료 버튼이 iOS에서는 시트만 닫음 (`SystemNavigator.pop`은 iOS에서 무시되는 죽은 버튼이었음). Android 동작 유지.
- **앱 평가/스토어 열기:** `AppRatingService.openStoreListing` — App Store ID 미주입 시 인앱 리뷰로 폴백.
- **암호화 수출 규정:** `ITSAppUsesNonExemptEncryption = false` 설정됨.
- **프리미엄 복원:** `PremiumPage` AppBar에 복원 버튼(`restore`) 구현됨 (Guideline 3.1.1).

---

## 2. 배포 전 필수 점검 (Pre-Flight Checklist)

### ✅ 2.1 App Store ID 주입
- App Store Connect에서 앱 레코드 생성 후 발급되는 **숫자 App ID**를 릴리스 빌드에 주입:
  ```
  --dart-define=DOODLE_PAD_APP_STORE_ID=<숫자ID>
  ```
- 미주입 시 "앱 평가하기"는 인앱 리뷰(SKStoreReviewController)로만 동작.

### ✅ 2.2 AdMob 실제 ID 주입
- App Store Connect/AdMob 콘솔에서 iOS 앱 등록 후:
  - **App ID**: Xcode 빌드 설정 또는 아카이브 시 `IOS_ADMOB_APP_ID=ca-app-pub-…~…` 주입 (`Release.xcconfig`가 참조)
  - **광고 단위 ID 3종**: `--dart-define=DOODLE_PAD_ADMOB_{BANNER,INTERSTITIAL,REWARDED}_IOS=ca-app-pub-…/…`

### ✅ 2.3 IAP 상품 등록 (App Store Connect)
- **기능 → 인앱 구매**에서 아래 3개 상품(비소모성)을 동일 ID로 등록:
  - `com.dangundad.doodlepad.premium.small`
  - `com.dangundad.doodlepad.premium.medium`
  - `com.dangundad.doodlepad.premium.large`
- 등록 전에는 런타임 로그에 `Not found products: [...]`가 출력되고 구매가 동작하지 않음 (2026-08-03 실기기 로그로 확인됨).
- 샌드박스 계정으로 구매·복원 테스트 필수.

### ✅ 2.4 런치 스크린 확인
- Xcode에서 `ios/Runner.xcworkspace` 열고 `LaunchScreen.storyboard` 렌더링 확인.

### ✅ 2.5 실기기 릴리스 테스트
- `flutter run --release -d <기기>` + 위 dart-define 전체 주입 후:
  1. **ATT:** 최초 실행 시 사전 설명 → 시스템 ATT 팝업 순서 확인 (`notDetermined`일 때만).
  2. **광고:** 배너(홈)/전면/보상형(브러시 해금) 로드 확인.
  3. **UI:** 노치·홈 인디케이터 Safe Area, 캔버스 제스처(핀치 줌/더블탭) 확인.
  4. **IAP:** 샌드박스 구매·복원.
  5. **사진:** 갤러리 사진 불러오기(권한 팝업 문구 언어 확인) / 갤러리 저장.

### ✅ 2.6 2026 최신 필수 요건
- [x] **Privacy Manifest** 존재 + 추적/요구사유 API 선언 (1.4절)
- [ ] **Xcode 26 / iOS 26 SDK 빌드** (2026-04-28부터 업로드 필수 — 현재 Mac의 Xcode 버전 확인)
  - SDK 버전과 **배포 타겟(15.0)은 별개** → 배포 타겟 올릴 필요 없음.
- [ ] **EU DSA 거래자(Trader) 정보** App Store Connect 등록 (광고 수익 앱은 해당됨. 미등록 시 EU 스토어 제거)
- [ ] **Privacy Nutrition Label**: App Store Connect "앱 개인정보 보호" 섹션을 실제 수집(AdMob/Firebase: 기기 ID, 진단)과 일치시키기.

---

## 3. 빌드 및 배포 방법

### 3.1 클린 빌드 준비
```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ios --release \
  --dart-define=DOODLE_PAD_ADMOB_BANNER_IOS=ca-app-pub-XXXX/YYYY \
  --dart-define=DOODLE_PAD_ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXX/YYYY \
  --dart-define=DOODLE_PAD_ADMOB_REWARDED_IOS=ca-app-pub-XXXX/YYYY \
  --dart-define=DOODLE_PAD_APP_STORE_ID=0000000000
```
> `IOS_ADMOB_APP_ID`는 Xcode 빌드 설정(User-Defined) 또는 CI 환경변수로 주입. Android 릴리스와 동일하게 `DOODLE_PAD_ADMOB_*_ANDROID`도 함께 주입하면 하나의 명령으로 양 플랫폼 관리 가능.

### 3.2 아카이브 및 업로드
1. Xcode에서 `ios/Runner.xcworkspace` 열기.
2. 타겟 **Any iOS Device (arm64)** 선택.
3. `Runner > Signing & Capabilities`에서 유료 Apple Developer Program 팀 + 자동 서명 확인 (현재 팀: `Q2FYC9F82W`).
4. **Product > Archive** → **Validate App** → **Distribute App** (TestFlight).
5. Organizer → **Generate Privacy Report**로 매니페스트 검증.

---

## 4. 트러블슈팅

### CocoaPods 잠금 충돌 (`could not find compatible versions`)
플러그인 버전 업그레이드 후 `Podfile.lock`이 옛 네이티브 SDK에 고정된 경우:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```
(2026-08-03 `google_mobile_ads` 9.0.0 ↔ `Google-Mobile-Ads-SDK 13.3` 충돌을 이 방법으로 해결.)

### 실기기 "개발자를 신뢰할 수 없음"
설정 → 일반 → VPN 및 기기 관리에서 개발자 신뢰. iOS 16+는 **개발자 모드** 활성화(재시작) 필요.

### SwiftPM 미지원 경고
`gma_mediation_{applovin,pangle,unity}`가 SwiftPM 미지원 경고를 출력하지만 CocoaPods 경로로 정상 빌드됨(현재 무해).

---

## 5. App Store 심사 거절 방지 요약

- **5.1.1 (개인정보):** ATT 사전 설명 + 명확한 혜택 문구 ✓ / 권한 문구 11개 언어 현지화 ✓ / 로그인 없음 → 계정 삭제 요건 해당 없음 / Nutrition Label 일치 필요 (2.6절).
- **2.1 (완성도):** 실기기 검증 완료(2026-08-03, iPhone 12 Pro Max). 플레이스홀더 전수 제거(가짜 App Store ID → env 주입, 테스트 광고 ID → env 주입).
- **4.0 (디자인):** GetX popGesture 스와이프 뒤로 가기 기본 활성 / ATT 팝업 Cupertino 스타일 / iOS에서 앱 자체 종료 금지 처리 ✓.
- **3.1.1 (결제):** `in_app_purchase` 기반 Apple IAP + 복원 버튼 ✓. 상품 등록만 남음 (2.3절).
