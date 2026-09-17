## 구글 플레이 콘솔 인앱 구매 설정 (간단 그림판 앱 - 무료(광고 지원) + 광고 제거 후원)

### ⚠️ 중요: Doodle Pad는 무료(광고 지원) 앱입니다!

Doodle Pad 앱은 핵심 드로잉 기능과 기본 브러시 8종을 **무료**로 제공하며, 앱의 **광고를 영구적으로 제거**하고 Premium 브러시 2종을 잠금 해제하면서 개발자를 후원할 수 있는 **선택적 일회성 후원 옵션**을 제공합니다.

### 앱 수익 모델 (2026년 9월 업데이트)
- **기본: 무료 (광고 지원)**: 핵심 드로잉 기능과 기본 브러시 8종(펜 / 연필 / 마커 / 붓 / 형광펜 / 만년필 / 크레파스 / 지우개) 제공
- **프리미엄 혜택**: 일회성 후원 구매 시 앱 내 모든 광고 영구 제거 + Premium 브러시 2종(수채화 / 에어브러시) 잠금 해제
- **후원 옵션**: 개발자 후원 (일회성 구매, 3가지 가격대)
  - Small (커피): ₩2,900 ($2.99) - 부담 없는 후원
  - Medium (점심): ₩5,900 ($5.99) - 표준 후원 (추천)
  - Large (저녁): ₩9,900 ($9.99) - 프리미엄 후원
- **핵심 원칙**: 세 가지 옵션 모두 **동일한 혜택(광고 영구 제거 + Premium 브러시 2종)**을 제공하며, 가격 차이는 후원 금액의 차이일 뿐 기능 차이가 없습니다.

### 광고 시스템 현황 (활성)
- **Google AdMob**: 배너 / 보상형 광고 통합 완료 (전면 광고는 매니저만 준비, 앱 오픈·네이티브 광고는 미사용)
- **미디에이션**: AppLovin · Unity Ads · Pangle 중개 연동
- **UMP 동의**: `AdHelper.initializeConsentAndAds()`에서 GDPR/CCPA 동의를 먼저 처리하고 미디에이션 동의를 동기화한 뒤, `canRequestAds()`가 true일 때만 iOS ATT와 Mobile Ads SDK를 차례로 시작
- **광고 단위 ID**: `--dart-define` 주입 방식이며 미주입 시 광고를 건너뛴다 (`lib/app/admob/ads_helper.dart`)
- **광고 제거**: 후원 구매(프리미엄) 시 모든 광고 영구 비활성화

### 무료(광고 지원) + 후원 모델의 장점
1. **진입 장벽 없음**: 누구나 핵심 드로잉 기능과 기본 브러시 8종을 무료로 사용
2. **높은 다운로드 수**: 무료 앱은 유료 앱보다 다운로드율이 높음
3. **안정적 수익**: 광고 수익 + 선택적 후원의 이중 구조
4. **충분한 무료 선택지**: 기본 브러시 8종, 16색 팔레트, 커스텀 컬러, 작품 보관함 제공
5. **선택적 후원**: 광고 제거와 Premium 브러시 2종을 원하는 사용자가 후원 가능

### 현재 프리미엄(후원) 모델 (2026년 9월 구현 완료)

✅ **일회성 구매 (Non-Consumable)** - 3가지 가격대로 후원 선택

**구매 방식**: 세 가지 옵션 중 **하나만** 선택하여 구매 가능 (중복 구매 불필요)
- 모든 옵션이 동일한 혜택(광고 영구 제거 + Premium 브러시 2종) 제공
- 가격 차이는 후원 금액의 차이일 뿐, 기능 차이 없음
- 한 번 구매하면 영구 적용 (재설치 시 구매 복원 가능)

1. **Small - 커피 한 잔 후원** ☕
   - 기준 가격: $2.99 (원화 폴백 ₩2,900)
   - Android ID: `doodle_pad_premium_small`
   - iOS ID: `com.dangundad.doodlepad.premium.small`
   - 설명: 부담 없이 개발자 응원 + 광고 제거 + Premium 브러시 2종

2. **Medium - 점심 한 끼 후원** 🍱 (추천)
   - 기준 가격: $5.99 (원화 폴백 ₩5,900)
   - Android ID: `doodle_pad_premium_medium`
   - iOS ID: `com.dangundad.doodlepad.premium.medium`
   - 설명: 표준 후원 (가장 인기) + 광고 제거 + Premium 브러시 2종

3. **Large - 저녁 한 끼 후원** 🍽️
   - 기준 가격: $9.99 (원화 폴백 ₩9,900)
   - Android ID: `doodle_pad_premium_large`
   - iOS ID: `com.dangundad.doodlepad.premium.large`
   - 설명: 프리미엄 후원 (최고 지원) + 광고 제거 + Premium 브러시 2종

### 후원 구매 시 혜택
- ✅ **광고 영구 제거**: 홈 화면 하단 배너 광고 영구 비활성화
- ✅ **Premium 브러시 2종**: 수채화(Watercolor), 에어브러시(Airbrush)를 보상형 광고 없이 잠금 해제
- ✅ **개발자 후원**: 지속적인 앱 개선과 신규 기능 개발에 기여
- ✅ **영구 적용**: 한 번 구매하면 재설치해도 유지 (구매 복원 가능)

### 향후 확장 계획 (선택사항)

1. **후원자 전용 혜택 강화** (검토 중)
   - Premium 브러시 프리셋 추가
   - 후원자 전용 캔버스 배경 / 색상 프리셋
   - 백업/복원 기능 (작품 보관함 클라우드 동기화)

2. **광고 최적화** (진행 중)
   - Google AdMob 배너/보상형 전략적 배치
   - AppLovin · Unity · Pangle 미디에이션 eCPM 최적화
   - 후원 구매 시 광고 자동 영구 제거
   - ⚠️ 전면 광고는 `AppBinding`에 매니저가 등록되어 있으나 노출 지점이 없다. 노출 위치를 만들거나 등록을 제거해야 한다.

3. **정기 구독 모델 검토** (장기적, 현재 미구현)
   - ⚠️ 주의: 현재는 일회성 구매만 구현됨 (구독 없음)
   - 구독 가격·혜택·상품 ID는 모두 미정이며 현재 스토어 제출 대상이 아님

### 현재 권장사항 (2026년 9월)
- ✅ **무료(광고 지원) + 선택적 후원 모델로 구현 완료**
- ✅ **in_app_purchase 패키지 통합 완료**
- ✅ **PurchaseService 구현 완료 (GetxService)**
- ✅ **3가지 가격대 후원 옵션 구현 완료**
  - Small: ₩2,900 ($2.99)
  - Medium: ₩5,900 ($5.99)
  - Large: ₩9,900 ($9.99)
- ✅ **프리미엄 상태 관리 완료 (Hive 저장)**
- ✅ **광고 시스템 연동 완료 (후원 구매 시 광고 제거)**
- ✅ **AdMob + AppLovin/Unity/Pangle 미디에이션 연동 완료**
- 🔄 **Play Console / App Store Connect 상품 등록 필요**
- 🔄 **iOS App Store ID 실제 값으로 교체 필요 (현재 `RateMyAppConfig.APP_STORE_ID`는 `--dart-define` 미주입 시 빈 값)**
- 🔄 **전면 광고 노출 지점 결정 필요 (구현 또는 매니저 등록 제거)**
- 🔄 **사용자 피드백 수집 및 다운로드/후원율 추적**

---

## 구글 플레이 콘솔 인앱 구매 설정 가이드 (2024-2025 최신)

> **⚠️ 중요 변경사항**: Google Play Console에서 일회성 제품(이전 명칭: 인앱 상품) 생성 방식이 크게 변경되었습니다.
> - 기존 "관리형 제품"/"비소모형 제품" 용어가 **"일회성 제품(One-time products)"**으로 변경
> - 새로운 **구매 옵션(Purchase Options)** 및 **혜택(Offers)** 시스템 도입
> - **태그(Tags)** 기능 추가로 제품 분류 및 관리 개선
> - **지역별 가격** 및 **지역별 사용 가능 여부** 세밀하게 설정 가능

### A. 앱 등록 시 선택사항
1. 구글 플레이 콘솔 → 앱 → 앱 설정 → 앱 콘텐츠로 이동
2. "가격 및 배포"에서 "무료" 선택 (유료로 전환 불가능하니 신중히 선택)
3. 광고 포함 여부 선택 → **"광고 포함" 선택** (Doodle Pad는 AdMob 광고를 사용함)
4. "앱 내 구매" 항목이 자동으로 활성화됨 ✅

### B. 일회성 제품 만들기 (최신 방식 - 2024/2025)

#### 경로
**Play Console → Play를 통한 수익 창출 → 제품 → 일회성 제품**

#### 단계별 가이드

**1단계: 일회성 제품 기본 정보 입력**
1. "일회성 제품 만들기" 클릭
2. 다음 정보 입력:
   - **제품 ID**: 고유 식별자 (예: `doodle_pad_premium_small`)
   - **태그** (선택사항): 제품 분류용 라벨 (최대 20자, 여러 개 가능)
     - 예: `premium`, `donation`, `ad-free`
   - **이름**: 사용자에게 표시되는 제품 이름
   - **설명**: 제품에 대한 자세한 설명
   - **아이콘 이미지** (선택사항): 제품을 나타내는 이미지
3. "세금, 규정 준수, 프로그램" 섹션에서 세금 설정 구성
4. "다음" 클릭

**2단계: 구매 옵션 설정**
- **구매 옵션 ID**: 구매 방식 식별자 (예: `purchase-coffee`)
- **구매 유형**:
  - `구입`: 영구 소유 (비소모성 - 광고 제거/후원 업그레이드에 적합)
  - `대여`: 기간 한정 액세스 (미디어 콘텐츠용)
- **태그** (선택사항): 구매 옵션용 태그
- **고급 옵션**:
  - 수량 및 한도: 다중 수량 구매 허용 여부
  - 콘텐츠 유형: 디지털 콘텐츠 또는 서비스

**3단계: 지역별 사용 가능 여부 및 가격 설정**
- 기본적으로 모든 지역에서 사용 가능
- **지역별 가격 설정**:
  1. "가격 설정 > 가격 일괄 수정" 클릭
  2. 가격을 설정할 지역 선택
  3. 가격 및 통화 입력
  4. "적용" → "계속" 클릭
- 특정 지역에서 사용 불가로 설정하려면:
  - "사용 가능 여부 및 액세스 수정" → "사용 불가로 설정" 선택

**4단계: 활성화**
- "활성화" 클릭하여 제품 게시
- 제품이 일회성 제품 페이지에 표시됨

---

#### 3개의 후원 상품 등록 예시

> 로케일별 상품명·설명 현지화 문구는 `docs/store/google-iap.md`(11개 언어 정본)를 사용한다.

**상품 1: Premium Coffee** ☕
| 항목         | 값                                                    |
| ------------ | ----------------------------------------------------- |
| 제품 ID      | `doodle_pad_premium_small`                            |
| 태그         | `premium`, `donation`, `coffee`, `small`              |
| 이름         | Premium - Coffee                                      |
| 설명         | Remove ads and unlock two premium brushes.            |
| 구매 옵션 ID | `purchase-coffee`                                     |
| 구매 유형    | 구입 (영구 소유)                                      |
| 한국 가격    | ₩2,900                                                |
| 미국 가격    | $2.99                                                 |
| 상태         | 활성화                                                |

**상품 2: Premium Lunch** 🍱 (추천)
| 항목         | 값                                                      |
| ------------ | ------------------------------------------------------- |
| 제품 ID      | `doodle_pad_premium_medium`                             |
| 태그         | `premium`, `donation`, `lunch`, `medium`, `recommended` |
| 이름         | Premium - Lunch                                         |
| 설명         | Remove ads and unlock two premium brushes.              |
| 구매 옵션 ID | `purchase-lunch`                                        |
| 구매 유형    | 구입 (영구 소유)                                        |
| 한국 가격    | ₩5,900                                                  |
| 미국 가격    | $5.99                                                   |
| 상태         | 활성화                                                  |

**상품 3: Premium Dinner** 🍽️
| 항목         | 값                                                     |
| ------------ | ------------------------------------------------------ |
| 제품 ID      | `doodle_pad_premium_large`                             |
| 태그         | `premium`, `donation`, `dinner`, `large`               |
| 이름         | Premium - Dinner                                       |
| 설명         | Remove ads and unlock two premium brushes.             |
| 구매 옵션 ID | `purchase-dinner`                                      |
| 구매 유형    | 구입 (영구 소유)                                       |
| 한국 가격    | ₩9,900                                                 |
| 미국 가격    | $9.99                                                  |
| 상태         | 활성화                                                 |

> 앱 코드는 Small / Medium / Large product ID로 상품을 조회한다. 이미 구매한 사용자의 복원 호환성을 위해 **제품 ID는 변경하지 않는다.** 앱 표시명만 Coffee / Lunch / Dinner 후원으로 명확히 한다.

---

### C. 태그 활용 가이드 (신규 기능)

태그는 제품, 구매 옵션, 혜택을 분류하고 식별하는 데 사용됩니다.

#### 태그 사용 시 장점
- 앱 내에서 특정 제품 그룹을 필터링 가능
- 비즈니스 로직에서 제품 카테고리 식별
- 혜택 태그는 구매 옵션 태그를 상속받음

#### 권장 태그 예시
```
- premium: 프리미엄(후원) 제품 표시
- donation: 후원 목적 제품
- ad-free: 광고 제거 포함
- coffee/lunch/dinner: 후원 티어 구분
- small/medium/large: 가격대 구분 (내부 tier, 코드 상품 ID와 일치)
- recommended: 추천 제품 표시
```

### D. 할인 혜택 추가 (선택사항)

일회성 제품에 할인 혜택을 추가할 수 있습니다:

1. 일회성 제품 수정 페이지 → "혜택 추가" → "할인" 클릭
2. 다음 정보 입력:
   - **혜택 ID**: 할인 식별자 (예: `launch_discount`)
   - **혜택 유형**: 비율 할인 또는 정액 할인
   - **시작/종료 날짜**: 할인 기간 설정
   - **태그**: 할인 관련 태그 (예: `launch-offer`)
   - **구매 한도**: 사용자당 최대 구매 수 (선택사항)
3. 지역별 할인율 설정
4. "저장" → "활성화"

---

### E. App Store Connect 인앱 구매 설정 (iOS)

> **참고**: iOS 코드는 `com.dangundad.doodlepad.premium.*` 상품 ID를 조회합니다. 배포 전 `--dart-define=DOODLE_PAD_APP_STORE_ID`로 실제 App Store ID를 주입하고 App Store Connect의 상품 상태를 확인해야 합니다.

1. App Store Connect → 앱 → 기능 → 앱 내 구매
2. "새로 만들기" → "비소모성" 선택
3. 3개의 후원 상품 등록:

**상품 1: Premium Coffee**
- 제품 ID: `com.dangundad.doodlepad.premium.small`
- 참조 이름: Premium Coffee
- 기준 국가/지역 가격: $2.99에 해당하는 가격 포인트

**상품 2: Premium Lunch** (추천)
- 제품 ID: `com.dangundad.doodlepad.premium.medium`
- 참조 이름: Premium Lunch
- 기준 국가/지역 가격: $5.99에 해당하는 가격 포인트

**상품 3: Premium Dinner**
- 제품 ID: `com.dangundad.doodlepad.premium.large`
- 참조 이름: Premium Dinner
- 기준 국가/지역 가격: $9.99에 해당하는 가격 포인트

Apple의 현재 가격 일정은 고정된 과거식 Tier 번호가 아니라 기준 국가/지역과 가격 포인트를 선택하고 다른 스토어프론트 가격을 자동 생성하는 방식입니다. 상품마다 표시 이름·설명 현지화, 판매 가능 지역, App Review Screenshot과 Review Notes를 채우고 첫 앱 버전과 함께 심사에 추가합니다.

### F. 앱 설명 작성
- "핵심 드로잉 기능과 기본 브러시 8종 무료" 명시
- "선택적 후원으로 광고 제거와 Premium 브러시 2종(수채화 / 에어브러시) 잠금 해제" 명시
- "3가지 가격대로 후원 가능" 설명
- "한 번 구매로 광고 영구 제거 + Premium 브러시 2종 + 영구 적용" 명시
- 세 옵션 모두 동일 혜택임을 안내
- 수채화 / 에어브러시는 후원 없이도 보상형 광고 시청으로 해금할 수 있음을 함께 안내
- 앱 내 작품 보관함은 기기 로컬에만 저장되며 클라우드 동기화가 없다는 점을 표기

### G. 리뷰 관리
- 무료 앱이므로 긍정적인 리뷰 유도
- 구매 여부와 관계없이 모든 사용자 피드백을 같은 지원 채널에서 검토
- 정기적인 업데이트로 신뢰 구축
- 후원 감사 메시지 표시
- 작품과 참조 사진이 서버로 업로드되지 않는다는 점을 문의 응대 시 명확히 안내

### H. 구매 복원 기능
- ✅ 앱에 "구매 복원" 버튼 구현 완료
- 재설치 시 사용자가 구매 내역 복원 가능
- 실제 복원 상품 검증 후에만 프리미엄 권한/복원 성공 확정
- iOS/Android 모두 지원

### I. 주요 변경사항 요약 (기존 → 신규)

| 기존 방식                    | 신규 방식 (2024-2025)                                            |
| ---------------------------- | ---------------------------------------------------------------- |
| 관리형 제품 / 비소모형       | **일회성 제품 (One-time products)**                              |
| 단일 제품 생성               | **제품 → 구매 옵션 → 혜택** 3단계 구조                           |
| 기본 가격 설정               | **구매 옵션별 지역별 가격**                                      |
| 라벨 없음                    | **태그 (Tags)** 기능 추가                                        |
| 수익 창출 > 제품 > 인앱 상품 | **Play를 통한 수익 창출 > 제품 > 일회성 제품**                   |
| CSV 파일 가져오기/내보내기   | **Publishing API 또는 개별 관리** (2025년 5월부터 CSV 지원 중단) |

---

## 향후 계획 (2026년 9월 업데이트)
- **Phase 1**: 무료(광고 지원) + 선택적 후원으로 구현 ✅ (완료)
- **Phase 2**: Play Console / App Store 상품 등록 🔄 (진행중)
  - Android: doodle_pad_premium_small/medium/large 등록 필요
  - iOS: com.dangundad.doodlepad.premium.small/medium/large 등록 필요
  - 기준 가격: $2.99 / $5.99 / $9.99 (원화 폴백 ₩2,900 / ₩5,900 / ₩9,900)
- **Phase 3**: 광고 최적화 🔄 (진행중)
  - Google AdMob 배너/보상형 광고
  - AppLovin · Unity · Pangle 미디에이션 eCPM 최적화
  - 전면 광고 노출 지점 확정 또는 매니저 등록 제거
  - 후원 구매 시 광고 자동 제거
- **Phase 4**: 사용자 피드백 수집 및 기능 개선
- **Phase 5**: 다운로드 10,000+ 달성 목표
- **Phase 6**: 후원율 분석 및 최적화
- **Phase 7**: 후원자 전용 혜택 추가 검토

## 기술 구현 상세

### 상품 ID 상수 (lib/app/utils/app_constants.dart)
```dart
/// IAP 상품 ID
/// 같은 혜택(광고 제거 + Premium 브러시 2종), 다른 가격대 - 사용자가 원하는 금액으로 후원
abstract class PurchaseConstants {
  static const String PREMIUM_SMALL_ANDROID = 'doodle_pad_premium_small';
  static const String PREMIUM_MEDIUM_ANDROID = 'doodle_pad_premium_medium';
  static const String PREMIUM_LARGE_ANDROID = 'doodle_pad_premium_large';

  static const String PREMIUM_SMALL_IOS = 'com.dangundad.doodlepad.premium.small';
  static const String PREMIUM_MEDIUM_IOS = 'com.dangundad.doodlepad.premium.medium';
  static const String PREMIUM_LARGE_IOS = 'com.dangundad.doodlepad.premium.large';

  static const List<String> ANDROID_PRODUCT_IDS = [
    PREMIUM_SMALL_ANDROID, PREMIUM_MEDIUM_ANDROID, PREMIUM_LARGE_ANDROID,
  ];

  static const List<String> IOS_PRODUCT_IDS = [
    PREMIUM_SMALL_IOS, PREMIUM_MEDIUM_IOS, PREMIUM_LARGE_IOS,
  ];
}
```

### 후원 티어 정의 (lib/app/controllers/premium_controller.dart)
```dart
// 스토어 조회 가격이 우선이고, 조회 실패 시 아래 fallbackPrice를 표시한다.
// 스토어 콘솔에는 USD 기준가($2.99/$5.99/$9.99)로 등록하고 현지 가격은 자동 환산을 쓴다.
PremiumPlan(fallbackPrice: '￦2,900')  // ☕ Small  $2.99
PremiumPlan(fallbackPrice: '￦5,900')  // 🍱 Medium $5.99 (추천, 기본 선택)
PremiumPlan(fallbackPrice: '￦9,900')  // 🍽️ Large  $9.99
```

### 주요 기능 (PurchaseService, GetxService)
- ✅ 3개의 일회성 구매 상품 관리 (Small/Medium/Large)
- ✅ 구매 상태 실시간 업데이트 (RxBool isPremium)
- ✅ 구매 스트림을 초기화 전에 구독하고 순차 처리
- ✅ 실제 복원 상품 검증 후에만 프리미엄 권한/복원 성공 확정
- ✅ 등록되지 않은 product ID는 권한 부여 및 구매 완료 처리에서 제외
- ✅ Hive를 통한 프리미엄 상태 영구 저장 (`HiveKeys.IS_PREMIUM`)
- ✅ 구매 복원 기능 (재설치 시)
- ✅ 로케일별 가격 표시 (스토어 조회 실패 시 `fallbackPrice`)
- ✅ 광고 시스템·Premium 브러시 연동 (후원 구매 시 배너 제거 + 수채화/에어브러시 잠금 해제)

### 가격 정책
| 옵션   | 한국 가격 | 해외 가격 | 설명                   |
| ------ | --------- | --------- | ---------------------- |
| Small  | ₩2,900    | $2.99     | 커피 한 잔 후원        |
| Medium | ₩5,900    | $5.99     | 점심 한 끼 후원 (추천) |
| Large  | ₩9,900    | $9.99     | 저녁 한 끼 후원        |

**중요**: 세 가지 옵션 모두 동일한 혜택(광고 영구 제거 + Premium 브러시 2종 + 개발자 후원)을 제공합니다. 가격 차이는 후원 금액의 차이일 뿐입니다.

### 앱 내 프리미엄 화면 (lib/app/pages/premium/)
- `premium_page.dart`: 프리미엄 여부에 따라 구매(`_UpgradeContent`)/활성화(`_OwnedPremiumView`) 상태 라우팅
- `_HeroPanel`: 혜택 히어로 영역
- `_SupportOptionTile`: 세 후원 선택 카드 (Medium 기본 선택 + 인기 배지)
- `_PurchaseBar`: 하단 고정 구매 CTA와 구매 복원 버튼
- `premium_binding.dart`: `PremiumController` 주입

### 광고 정책
| 광고 유형      | 무료 사용자                          | 프리미엄 사용자 |
| -------------- | ------------------------------------ | --------------- |
| 홈 배너        | 표시 (홈 화면 하단)                  | 숨김            |
| 그리기 화면 배너 | 미사용                             | 미사용          |
| 앱 오프닝 광고 | 미사용                               | 미사용          |
| 전면 광고      | 매니저만 등록, 노출 지점 없음        | 숨김            |
| 네이티브 광고  | 미사용 (종료 시트에 넣지 않음)       | 미사용          |
| 보상형 광고    | 수채화 / 에어브러시 해금 시 사용자 선택으로 표시 | 불필요 (이미 해금) |

광고는 캔버스 위에 표시하지 않으며, 그리기 흐름을 방해하지 않도록 홈 화면으로 제한합니다. 보상형 광고는 잠금 브러시를 눌렀을 때 확인 다이얼로그를 거쳐 사용자가 선택한 경우에만 재생됩니다.

### 광고 단위 ID 주입 (--dart-define)
```bash
flutter run ^
  --dart-define=DOODLE_PAD_ADMOB_BANNER_ANDROID=ca-app-pub-xxx/banner ^
  --dart-define=DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/interstitial ^
  --dart-define=DOODLE_PAD_ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/rewarded
```

> iOS는 `DOODLE_PAD_ADMOB_{BANNER,INTERSTITIAL,REWARDED}_IOS`를 사용한다.
> 릴리스 빌드는 별도 요청 없이 실행하지 않는다. 위 명령은 로컬 확인용 예시다.

## 출시 전 체크리스트

- [ ] Play Console 일회성 제품 3개 등록 (제품 ID가 `PurchaseConstants`와 완전히 일치)
- [ ] 세 상품의 유형을 비소모성 일회성 상품으로 등록하고 공통 혜택을 동일하게 기재
- [ ] 운영 AdMob App ID·광고 단위 ID를 적용하고 테스트 광고가 스토어 자료에 보이지 않게 함
- [ ] Premium 구매 / 복원 플로우 실제 기기 테스트
- [ ] Premium 상태에서 홈 배너와 보상형 해금 요구가 사라지는지 확인
- [ ] 무료 상태에서 수채화 / 에어브러시 보상형 광고 흐름 확인
- [ ] 전면 광고 노출 지점 결정 (구현 또는 `AppBinding` 등록 제거)
- [ ] Data safety 응답을 Firebase Crashlytics, AdMob·미디에이션, 인앱 결제의 실제 처리와 일치시킴
- [ ] 개인정보처리방침 최신화

## 공식 참고 문서
- [Google Play Console: Overview of one-time products](https://support.google.com/googleplay/android-developer/answer/16430488?hl=en)
- [Android Developers: One-time products](https://developer.android.com/google/play/billing/one-time-products)
- [Android Developers: One-time purchase lifecycle](https://developer.android.com/google/play/billing/lifecycle/one-time)
