## 구글 플레이 콘솔 광고/결제 설정 (Doodle Pad - 무료 + 후원형 Premium)

### ⚠️ 중요: Doodle Pad는 기본 무료 앱입니다

Doodle Pad는 핵심 드로잉 기능을 무료로 제공하며, 사용자가 원할 경우 **1회 후원형 Premium**을 구매해 광고를 제거하고 Premium 브러시 접근을 열 수 있습니다.

### 앱 수익 모델 (2026년 5월)
- **기본: 무료 드로잉 앱**
  - 펜 / 마커 / 지우개 기본 제공
  - 16색 팔레트 + 커스텀 컬러 피커, 캔버스 배경 색상 프리셋
  - 브러시 크기 슬라이더, Undo / Redo (최대 20단계)
  - 갤러리 사진을 참조로 깔고 그 위에 그리기 (사진 위 드로잉)
  - 그린 결과를 PNG로 캡처해 Android 공유 시트로 전달
  - 그리기 이탈 시 작업물 보존 확인, 홈 재진입 시 이어 그리기 선택
  - 11개 언어 지원
  - 앱은 그림을 영구 저장하지 않음 (공유 시 임시 PNG로만 노출)
- **광고 포함**
  - 홈 화면 하단 배너 광고
  - 수채화 / 에어브러시 해금을 위한 보상형 광고
  - 전면 광고 매니저는 코드에 준비되어 있으나, 현재 사용자 동작 트리거에는 연결하지 않음
  - 종료 바텀시트에는 현재 네이티브 광고를 넣지 않음
- **Premium 구매**
  - 광고 제거
  - Premium 브러시 접근
  - 구매 복원 지원
  - Small / Medium / Large 3개 후원 옵션 제공
  - 세 옵션은 기능 차이가 없고 후원 금액만 다름

---

## 현재 Premium 모델

✅ **일회성 구매 (Non-Consumable) - 3단계 후원**

**구매 방식**
- 한 번 구매하면 영구 적용
- 재설치 후 구매 복원 가능
- Android 중심 운영

**Premium 상품**

| 옵션   | Android ID                    | 한국 가격 | 해외 가격 | 설명        |
| ------ | ----------------------------- | --------- | --------- | ----------- |
| Small  | `doodle_pad_premium_small`    | ₩2,900    | $2.99     | 가벼운 후원 |
| Medium | `doodle_pad_premium_medium`   | ₩5,900    | $5.99     | 기본 추천   |
| Large  | `doodle_pad_premium_large`    | ₩9,900    | $9.99     | 큰 응원     |

> 코드 source of truth: `lib/app/utils/app_constants.dart`의 `PurchaseConstants`

### Premium 구매 시 혜택
- ✅ **광고 제거**: 메인 shell 하단 배너 광고 제거
- ✅ **브러시 접근**: 수채화 / 에어브러시를 광고 없이 사용
- ✅ **구매 복원**: 재설치 후 Play 계정 기준 복원 가능
- ✅ **개발자 지원**: 유지보수와 개선에 기여

### 앱 내 Premium 페이지 구성
- Small / Medium / Large 3개 후원 카드
- Medium 옵션 기본 선택
- Medium 옵션에 인기 배지
- 광고 제거 / 무제한 그리기 / 상세 통계 혜택 영역
- 구매 복원 버튼
- 하단 고정 구매 CTA

---

## Google Play Console 설정 가이드

### A. 앱 등록 시 선택사항
1. Google Play Console → 앱 → 가격 및 배포로 이동
2. `무료` 선택
3. 광고 포함 여부 선택: `광고 포함` 체크 ✅
4. 앱 내 구매 사용: `앱 내 구매` 체크 ✅

### B. 인앱 상품 등록 (Android)
1. Google Play Console → 앱 → 수익 창출 → 제품 → 인앱 상품
2. `관리형 제품 만들기` 클릭
3. 아래 상품 3개 등록

**상품 1: Doodle Pad Premium Small**
- 상품 ID: `doodle_pad_premium_small`
- 태그: `premium`, `small`
- 이름(영어): `Premium - Coffee Support`
- 설명(영어): `Removes ads and unlocks premium brush access.`
- 구매 옵션 ID: `doodle-pad-premium-small`
- 가격: ₩2,900 ($2.99)
- 상태: 활성화

**상품 2: Doodle Pad Premium Medium**
- 상품 ID: `doodle_pad_premium_medium`
- 태그: `premium`, `medium`
- 이름(영어): `Premium - Lunch Support`
- 설명(영어): `Removes ads and unlocks premium brush access.`
- 구매 옵션 ID: `doodle-pad-premium-medium`
- 가격: ₩5,900 ($5.99)
- 상태: 활성화

**상품 3: Doodle Pad Premium Large**
- 상품 ID: `doodle_pad_premium_large`
- 태그: `premium`, `large`
- 이름(영어): `Premium - Dinner Support`
- 설명(영어): `Removes ads and unlocks premium brush access.`
- 구매 옵션 ID: `doodle-pad-premium-large`
- 가격: ₩9,900 ($9.99)
- 상태: 활성화

### C. AdMob 설정
- 광고 단위 ID 정의 위치: `lib/app/admob/ads_helper.dart`
- Android 광고 ID는 빌드 시 `--dart-define`으로 주입

```bash
flutter run ^
  --dart-define=DOODLE_PAD_ADMOB_BANNER_ANDROID=ca-app-pub-xxx/banner ^
  --dart-define=DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/interstitial ^
  --dart-define=DOODLE_PAD_ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/rewarded
```

> 릴리스 빌드는 별도 요청 없이 실행하지 않습니다. 위 명령은 로컬 확인용 예시입니다.

### D. 앱 설명 작성
- `가볍게 그리고 바로 공유`, `5종 브러시`, `16색 팔레트 + 커스텀 컬러`, `사진 위 드로잉`, `Android 공유` 흐름을 앞부분에 배치
- 수채화 / 에어브러시는 보상형 광고 또는 Premium으로 접근 가능하다고 명시
- 무료 버전 광고 포함 안내
- Premium은 1회 후원형 구매이며 Small / Medium / Large 모두 같은 혜택임을 명확히 표기
- 구매 복원 지원 문구 포함
- 앱은 그림을 영구 저장하지 않으며 사용자가 공유로 보존해야 한다는 점을 명확히 표기

### E. 리뷰 관리
- 사용자가 만든 그림은 공유 시 임시 PNG로만 노출되며 앱은 영구 저장본을 보관하지 않는다는 점 안내
- 공유는 Android 공유 시트를 통해 사용자가 직접 선택한 앱으로만 진행됨
- 광고는 무료 사용자를 위한 수익 모델이며, 구매 시 제거됨을 명확히 안내
- 결제 검증은 현재 클라이언트 측 검증 기반이며, 향후 백엔드 검증 도입 시 사용자 안내 업데이트
- 특수 권한 앱이 아니므로 접근성 / 포그라운드 서비스 심사 문구를 사용하지 않음

---

## 출시 전 체크리스트

- [ ] Play Console 인앱 상품 3개 등록
- [ ] 상품 ID가 `PurchaseConstants`와 완전히 일치하는지 확인
- [ ] AdMob 앱 ID와 광고 단위 ID 최종 확인
- [ ] 테스트 광고로 QA 후 운영 광고 ID 전환
- [ ] Premium 구매 / 복원 플로우 실제 기기 테스트
- [ ] Premium 상태에서 배너 광고와 보상형 해금 요구가 사라지는지 확인
- [ ] 무료 상태에서 수채화 / 에어브러시 보상형 광고 흐름 확인
- [ ] 데이터 보안 양식과 개인정보처리방침 최신화

---

## 기술 구현 메모

### PurchaseConstants
```dart
abstract class PurchaseConstants {
  static const String PREMIUM_SMALL_ANDROID = 'doodle_pad_premium_small';
  static const String PREMIUM_MEDIUM_ANDROID = 'doodle_pad_premium_medium';
  static const String PREMIUM_LARGE_ANDROID = 'doodle_pad_premium_large';
}
```

### 주요 구현 상태
- ✅ `PurchaseService` 기반 상품 조회 / 구매 / 복원
- ✅ Hive 기반 Premium 상태 저장
- ✅ Premium 활성 시 광고 매니저 정리
- ✅ Premium 화면 3단계 후원 UI
- ✅ 종료 바텀시트 연동
- ✅ 보상형 광고 기반 특수 브러시 해금
- 🔄 실제 Play Console 상품 등록 필요
- 🔄 운영 AdMob ID 최종 검증 필요

### 광고 정책
| 광고 유형 | 적용 여부 | 현재 동작 |
| --- | --- | --- |
| 배너 | ✅ 적용 | 메인 shell 하단, Premium 시 숨김 |
| 보상형 | ✅ 적용 | 수채화 / 에어브러시 해금 |
| 전면 | ⚙️ 준비 | 매니저는 있으나 사용자 트리거 미연결 |
| 앱 오프닝 | ❌ 미적용 | 현재 코드 기준 없음 |
| 네이티브 | ❌ 미적용 | 종료 바텀시트에는 사용하지 않음 |
