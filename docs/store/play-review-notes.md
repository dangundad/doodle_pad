# Doodle Pad - Google Play Review Notes

> 기준일: 2026-09-17<br>
> 패키지명: `com.dangundad.doodlepad`<br>
> 용도: Play Console 심사 답변과 권한 재현 절차

## 현재 앱 범위

Doodle Pad는 자유 드로잉, 10종 브러시, 갤러리 사진 위 드로잉, 앱 내 작품 보관함, 선택형 일회성 후원을 제공하는 그림판 앱입니다.

- 레이어, 벡터 편집, 계정/로그인, 커뮤니티 피드, 클라우드 동기화 기능은 제공하지 않습니다.
- 앱은 알림을 생성하지 않으며 런타임에 `POST_NOTIFICATIONS` 권한을 요청하지 않습니다.
- 참조 사진은 `image_picker`가 여는 시스템 선택기에서 사용자가 직접 고른 한 장만 사용합니다.
- Android 13 이상에서는 Android Photo Picker를 사용하며, 앱 매니페스트는 광범위한 사진·미디어 읽기 권한을 직접 선언하지 않습니다.
- 앱은 사진 라이브러리를 스캔하거나 선택한 이미지를 서버에 업로드하지 않습니다. 선택한 사진은 작품 저장 시 앱 내부 저장소로 복사되어 로컬에만 보관됩니다.
- 작품(선 데이터·배경색·참조 사진)은 기기 로컬 Hive와 앱 내부 저장소에만 저장됩니다.

## 현재 권한과 사용 목적

| 권한 | 사용 목적 |
|---|---|
| `INTERNET` | 광고, Firebase Crashlytics, 스토어 구매 통신 |
| `AD_ID` | 무료 사용자 대상 AdMob 광고 측정 |
| `VIBRATE` | 브러시 선택과 지우기 동작의 햅틱 피드백 |
| `com.android.vending.BILLING` | 선택형 비소모성 일회성 후원 구매와 복원 |
| `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion="29"`) | Android 7~10에서 완성한 그림을 기기 갤러리에 저장(`gal`). API 30+ 에서는 무시됨 |

- `android:requestLegacyExternalStorage="true"`는 위 API ≤29 갤러리 저장 경로를 위해서만 선언되어 있습니다.
- 흔들어 지우기는 `sensors_plus` 가속도계를 사용하며 별도 권한이 필요하지 않습니다.
- 앱은 위치, 연락처, 마이크, 카메라, 포그라운드 서비스, 접근성 서비스 권한을 사용하지 않습니다.

## Play Console 제출용 답변

### 사용자 선택 참조 사진

```text
The app opens the system image picker only when the user chooses a reference photo to draw on.
It reads one image explicitly selected by the user and copies it into app-private storage so the saved artwork can be reopened and edited later.
The app does not request broad photo or media access, scan the photo library, upload photos, or access media in the background.
```

### 기기 갤러리 저장

```text
WRITE_EXTERNAL_STORAGE is declared with maxSdkVersion="29" only so that users on Android 7-10 can save their finished drawing to the device gallery through the legacy external storage path.
On Android 11 and above the declaration is ignored and the app writes through MediaStore.
The app never reads existing files from external storage with this permission.
```

### 인앱 결제

```text
Google Play Billing is used only for three optional one-time, non-consumable supporter products.
All three products provide the same permanent benefits: removal of all ads and access to the two premium brushes (watercolor and airbrush). The price only changes the support amount.
The core drawing features and eight brushes remain usable without purchase, the two premium brushes can also be unlocked by watching an optional rewarded ad, and eligible purchases can be restored after reinstalling the app or changing devices.
```

상품 ID:

- `doodle_pad_premium_small`
- `doodle_pad_premium_medium`
- `doodle_pad_premium_large`

### 보상형 광고

```text
Rewarded ads are never shown automatically. They appear only after the user taps a locked brush (watercolor or airbrush) and confirms in a dialog that they want to watch an ad to unlock it.
Purchasing any supporter product removes this step entirely.
```

### 광고 ID

```text
The advertising ID is used by Google Mobile Ads and configured mediation partners to serve and measure ads for free users, subject to the user's consent choices collected through the UMP SDK.
Purchasing any supporter product disables the banner ad and the rewarded-ad unlock flow.
```

### 데이터 저장

```text
Drawings, their background color and the user-selected reference photo are stored only in local Hive boxes and app-private storage on the device.
There is no account, no sign-in and no cloud sync, and drawings leave the device only when the user explicitly taps Share or Save to gallery.
```

## 리뷰어 재현 경로

1. 앱을 실행하면 바로 그리기 화면이 열립니다. 캔버스에 선을 그어 드로잉이 동작하는지 확인합니다.
2. 하단 툴바에서 브러시와 색상, 굵기를 바꿔 봅니다.
3. 잠긴 브러시(수채화 또는 에어브러시)를 눌러 해금 확인 다이얼로그와 보상형 광고 흐름을 확인합니다.
4. 상단 더보기(`···`) → 사진 불러오기에서 시스템 이미지 선택기를 열고 이미지 한 장을 선택한 뒤, 사진 위에 선이 그려지는지 확인합니다.
5. 저장 시트에서 PNG / JPEG 포맷과 1x / 2x / 3x 해상도를 선택해 기기 갤러리에 저장되는지 확인합니다.
6. 상단 "내 작품"에서 저장된 작품을 다시 열어 이어 그리기가 되는지 확인합니다. (길게 누르면 삭제)
7. 홈 버튼 → 프리미엄 화면에서 Small / Medium / Large 상품과 공통 혜택을 확인합니다.
8. 구매 복원 버튼을 확인합니다. 구매 이력이 없는 계정은 오류가 아니라 구매 내역 없음으로 처리됩니다.
9. 설정에서 흔들어 지우기를 켜고 기기를 흔들어 확인 다이얼로그가 뜨는지 확인합니다.

## 제출 전 체크리스트

- [ ] 최종 병합 매니페스트에 사진·미디어 읽기 권한(`READ_MEDIA_IMAGES`, `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE`)과 `POST_NOTIFICATIONS`가 없는지 확인
- [ ] `WRITE_EXTERNAL_STORAGE`에 `maxSdkVersion="29"`가 유지되는지 확인
- [ ] Data safety 응답을 Firebase Crashlytics, AdMob·미디에이션, 인앱 결제의 실제 처리와 일치시킴
- [ ] 세 상품의 유형을 비소모성 일회성 상품으로 등록하고 공통 혜택을 동일하게 기재
- [ ] 운영 AdMob App ID·광고 단위 ID를 적용하고 테스트 광고가 스토어 자료에 보이지 않게 함
- [ ] 사진 위 드로잉, 갤러리 저장(API 29 이하 포함), 구매·복원, 프리미엄 광고 제거, 보상형 해금을 실기기에서 확인
- [ ] 전면 광고 노출 지점이 없는 상태로 제출할지, 매니저 등록을 제거할지 결정
