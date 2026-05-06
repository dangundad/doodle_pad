# Doodle Pad

간단한 드로잉 캔버스 앱입니다. 펜, 마커, 지우개, 수채화, 에어브러시로 그림을 그리고 PNG로 저장하거나 공유할 수 있습니다.

## 현재 상태

- 앱 패키지: `com.dangundad.doodlepad`
- 버전: `1.0.0+1`
- 플랫폼: Android 우선
- 상태 관리: GetX
- 로컬 저장: Hive_CE
- 수익화: AdMob + 1회 후원형 Premium
- 다국어: 11개 locale (`en`, `ko`, `ja`, `de`, `ru`, `fr`, `es`, `pt`, `id`, `zh`, `ar`)

## 주요 기능

- **5종 브러시**: 펜, 마커, 지우개, 수채화, 에어브러시
- **브러시 해금**: 수채화/에어브러시는 보상형 광고 또는 Premium으로 사용
- **16색 팔레트**: 기본 색상, 파스텔, 무채색 포함
- **브러시 크기 조절**: 슬라이더로 굵기 변경
- **Undo / Redo**: 드로잉 작업 되돌리기와 다시 실행
- **저장 / 갤러리**: PNG 저장, 앱 내 갤러리 관리, 다시 불러오기
- **공유**: Android share sheet로 그림 공유
- **기록 / 통계**: 앱 사용 기록과 활동 통계 확인
- **종료 바텀시트**: 물리 뒤로가기 버튼 입력 시 종료 확인
- **Premium**: Small / Medium / Large 3단계 후원으로 광고 제거 및 Premium 브러시 접근

## 기술 스택

- **Flutter / Dart**
- **GetX**: 상태 관리, 라우팅, 다국어
- **Hive_CE**: 로컬 설정과 앱 데이터 저장
- **CustomPainter**: 드로잉 캔버스 렌더링
- **flutter_screenutil**: 반응형 UI
- **flex_color_scheme**: Material 3 테마
- **lucide_icons_flutter**: 아이콘
- **share_plus**: 이미지 공유
- **google_mobile_ads**: 배너 / 보상형 광고
- **in_app_purchase**: Premium 구매 / 복원

## 실행

```bash
cd C:\Github_WorkSpace\doodle_pad
flutter pub get
flutter analyze
flutter test
flutter run
```

Hive 모델을 추가하거나 수정한 경우에만 코드 생성을 실행합니다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

릴리스 빌드는 일반 개발 작업에서 실행하지 않습니다.

## 광고와 구매

무료 버전은 메인 shell 하단 배너 광고와 특수 브러시 해금용 보상형 광고를 사용합니다. Premium 구매 시 광고를 숨기고 수채화/에어브러시 접근을 바로 허용합니다.

Premium 상품 ID:

| 옵션 | Android ID | 기본 가격 |
| --- | --- | --- |
| Small | `doodle_pad_premium_small` | ₩2,900 |
| Medium | `doodle_pad_premium_medium` | ₩5,900 |
| Large | `doodle_pad_premium_large` | ₩9,900 |

## 프로젝트 구조

```text
lib/
├── main.dart
└── app/
    ├── admob/          # AdMob 광고 관리
    ├── bindings/       # GetX 바인딩
    ├── controllers/    # Doodle, Premium, Settings 등
    ├── pages/          # home, draw, gallery, history, stats, premium
    ├── routes/         # GetX routes
    ├── services/       # Hive, purchase, rating, activity log
    ├── theme/          # FlexColorScheme 테마
    ├── translate/      # GetX 다국어
    ├── utils/          # 상수와 toast
    └── widgets/        # 공용 위젯
```

## 문서

- 스토어 메타데이터: `docs/store/google-store.md`
- 스크린샷 가이드: `docs/store/google-store-image.md`
- 앱 이름 / 스토어 제목: `docs/store/google-app-name.md`
- 광고 / Premium 설정: `docs/store/google-ads-subscription.md`

## 라이선스

Copyright 2026 DangunDad. All rights reserved.
