# 간단 그림판: 그리기 iOS App Store 배포 자료

기준일: 2026-07-21  
준비 상태: **조건 확인 후 제출 가능**

그리기·사진 불러오기·저장·공유는 iOS 지원 범위입니다. 센서 기반 기능, 사진 권한, 고해상도 저장과 IAP를 실기기에서 확인합니다.

## 프로젝트 식별 정보

| 항목 | 값 |
|---|---|
| 저장소 | `doodle_pad` |
| Bundle ID | `com.dangundad.doodlepad` |
| 버전 | `1.0.0+1` |
| SKU 제안 | `ios-doodle-pad` |
| 지원 기기 설정 | iPhone, iPad |
| 기본 언어 제안 | 한국어 (`ko`) |
| 기본 카테고리 | Graphics & Design |
| 보조 카테고리 | Photo & Video |
| 기존 Google 자료 | `docs/store/google-store.md` |

## 문서 사용 순서

1. `metadata.md`의 한국어와 영어 등록정보를 App Store Connect에 입력합니다.
2. `privacy-review.md`의 개인정보, 권한, 연령 등급, 심사 메모를 실제 빌드와 대조합니다.
3. `assets.md`의 스토리보드로 iPhone과 필요한 iPad 스크린샷을 제작합니다.
4. TestFlight 실기기 검증 뒤 심사에 추가합니다.

## 계정에서 직접 확정할 값

- [ ] Apple Developer Team, 배포 인증서, 프로비저닝 프로파일
- [ ] Support URL: 실제 연락처가 표시되는 HTTPS 페이지
- [ ] Privacy Policy URL: 앱 내부에도 접근 링크 제공
- [ ] Marketing URL(선택), 저작권 표기, 가격, 국가/지역
- [ ] App Review 담당자 이름, 전화번호, 이메일
- [ ] EU DSA trader 상태와 공개 연락처
- [ ] 광고 단위, 인앱 구매 상품, 세금·은행 계약

## 2026 공통 게이트

- 2026-04-28 이후 제출 빌드는 **iOS 26 SDK 이상**으로 빌드해야 합니다.
- 이름 30자, 부제 30자, 프로모션 170자, 설명 4,000자, 키워드 100바이트 제한을 지킵니다.
- 개인정보 처리방침 URL과 App Privacy 응답은 필수입니다.
- iOS 26의 새 연령 등급 질문에 답하고, 접근성 영양성분표는 현재 자발적이지만 실제 지원만 표시합니다.
- 모든 URL과 인앱 구매는 심사 중 실제 동작해야 하며 placeholder를 제출하면 안 됩니다.

## Apple 공식 근거

- [2026 SDK 최소 요구사항](https://developer.apple.com/news/?id=ueeok6yw)
- [앱 이름·부제 제한](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [App Store 등록정보 필드](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [App Privacy 입력 방법](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [EU DSA trader 요구사항](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
