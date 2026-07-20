# 개인정보·심사 입력안

이 문서는 코드 의존성과 iOS 설정을 바탕으로 만든 **제출 전 후보 답변**입니다. 최종 Archive의 Xcode Privacy Report, 실제 광고·분석 설정, 서버 로그와 대조한 뒤 App Store Connect에 확정합니다.

## App Privacy 후보

- 광고 SDK: 기기 ID, 광고 데이터, 대략적 위치, 제품 상호작용, 진단 데이터의 수집·추적 여부를 광고 및 미디에이션 설정과 대조합니다.
- Firebase Analytics/Crashlytics: 제품 상호작용, 충돌, 성능 및 기타 진단 데이터의 수집 목적과 사용자 연결 여부를 확인합니다.
- ATT: IDFA 기반 추적이 실제 활성화될 때만 권한을 요청하고 App Privacy의 Tracking 답변과 일치시킵니다.
- 사진·카메라 입력: 기기 밖으로 전송하지 않는다면 로컬 처리임을 명시하고, 업로드가 있으면 사용자 콘텐츠 수집을 선언합니다.
- 센서 값: 기기 밖으로 전송·보관되는지 확인하고 분석/광고 SDK 이벤트에 원시 센서 값을 넣지 않습니다.

- Privacy Policy URL: `[필수 입력: 공개 HTTPS URL]`
- Privacy Choices URL: `[선택: 삭제·동의 철회 페이지]`
- 개인정보 처리방침 링크를 앱 내부 설정/정보 화면에도 제공합니다.

## 감지된 iOS 권한 문구

- `NSPhotoLibraryAddUsageDescription`: 실제 기능 사용 시점과 문구 확인
- `NSPhotoLibraryUsageDescription`: 실제 기능 사용 시점과 문구 확인
- `NSUserTrackingUsageDescription`: 실제 기능 사용 시점과 문구 확인

권한은 기능을 누르는 시점에 요청하고, 사용하지 않는 키는 `Info.plist`에서 제거합니다. 카메라·마이크·화면 기록은 사용자가 알 수 있는 표시와 명시적 동의가 필요합니다.

## Privacy Manifest·SDK

- 앱 자체 `PrivacyInfo.xcprivacy`: **감지되지 않음 — Archive Privacy Report로 필요 여부 확인**
- 개인정보 영향 의존성: `app_tracking_transparency`, `firebase_core`, `firebase_crashlytics`, `google_mobile_ads`, `image_picker`, `in_app_purchase`, `sensors_plus`, `share_plus`, `shared_preferences`, `url_launcher`
- Apple 목록의 SDK는 유효한 privacy manifest와 서명이 포함된 최신 버전을 사용합니다.
- Required Reason API 경고가 있으면 승인된 이유를 앱 또는 해당 SDK manifest에 선언합니다.

## iOS 인앱 구매 상품 ID 후보

- `com.dangundad.doodlepad.premium.large`
- `com.dangundad.doodlepad.premium.medium`
- `com.dangundad.doodlepad.premium.small`

위 값은 코드에서 `com.`으로 시작하고 `premium` 또는 `remove_ads`를 포함한 문자열만 자동 탐지한 후보입니다. 실제 판매 상품과 대조하고, App Store Connect에서 Product ID, 표시명, 설명, 가격, 국가, 심사용 스크린샷을 별도로 등록해 첫 버전과 함께 심사에 추가합니다.

## 연령 등급·규제

- 권장 시작점: 4+ 예상
- 연령 등급 메모: 아동 전용으로 지정하지 않는 일반 창작 앱 기준
- Made for Kids: **선택하지 않음**. 아동 전용 앱으로 확정할 때만 별도 정책 감사 후 선택합니다.
- 규제 의료기기 선언: 해당 없음
- 콘텐츠 권리: 포함 브러시·아이콘·예시 이미지 라이선스 확인

## App Review Notes 초안

로그인 없이 빈 캔버스 또는 사용자가 선택한 사진 위에 그림을 그리고 기기 갤러리와 앱 내 보관함에 저장합니다.

테스트 계정: 로그인 없음

## 수출 규정·지역 규정

- HTTPS, Apple OS 암호화만 사용하는지 확인하고 App Store Connect의 수출 규정 질문에 사실대로 답합니다.
- 면제 대상이면 빌드 설정의 `ITSAppUsesNonExemptEncryption` 값을 실제 사용과 일치시킵니다.
- EU 배포 여부와 무관하게 DSA trader 상태를 선언합니다. 광고 또는 IAP 수익화 앱은 trader 가능성이 높으므로 계정 법적 상태를 확인합니다.
- 한국·중국·베트남 등 선택 지역에서 추가 허가나 등급 번호가 필요한지 카테고리와 콘텐츠 기준으로 확인합니다.

## 공식 근거

- [App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)
- [연령 등급 설정](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)
- [수출 규정 개요](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
