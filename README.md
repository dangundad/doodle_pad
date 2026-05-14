# Doodle Pad

가볍게 그리고, 저장하고, 다시 열어 이어 그리는 캐주얼 드로잉 앱입니다. 10종 브러시로 즉석 낙서를 만들어 기기 갤러리에 저장하거나 Android 공유 시트로 보낼 수 있고, 앱 내 작품 보관함(갤러리)에서 저장한 그림을 다시 열어 편집할 수 있습니다.

## 현재 상태

- 앱 패키지: `com.dangundad.doodlepad`
- 버전: `1.0.0+1`
- 플랫폼: Android 우선
- 상태 관리: GetX
- 로컬 저장: Hive_CE (설정/해금 상태/Premium 상태 + 앱 내 작품(`Drawing`) 영속화)
- 수익화: AdMob + 1회 후원형 Premium
- 다국어: 11개 locale (`en`, `ko`, `ja`, `de`, `ru`, `fr`, `es`, `pt`, `id`, `zh`, `ar`)

## 주요 기능

- **10종 브러시**: 펜, 연필, 마커, 붓, 형광펜, 만년필, 크레파스, 수채화, 에어브러시, 지우개. stroke 엔진은 `perfect_freehand` 기반으로 가변 굵기/taper를 지원
- **브러시 해금**: 수채화/에어브러시는 보상형 광고 또는 Premium으로 사용. 그 외 브러시는 모두 무료
- **16색 팔레트 + 커스텀 컬러 피커**: 기본 색상과 사용자 색상 슬롯
- **캔버스 배경 색상**: 6종 프리셋
- **브러시 크기 조절**: 슬라이더로 굵기 변경
- **Undo / Redo**: 최대 20단계 되돌리기와 다시 실행
- **사진 위에 그리기**: 갤러리에서 사진을 불러와 참조로 깔고 그 위에 그리기
- **기기 갤러리 저장**: 그린 결과를 PNG 또는 JPEG로, 1x/2x/3x 해상도를 골라 기기 갤러리에 저장
- **앱 내 작품 보관함**: 그림을 strokes·배경색·참조 사진과 함께 앱 내부에 저장하고, 갤러리 화면에서 다시 열어 편집 (참조 사진은 앱 내부로 복사되어 원본이 사라져도 유지됨)
- **공유**: 그린 결과를 PNG로 캡처해 Android share sheet로 전달
- **흔들어 지우기**: 설정에서 켜면 기기를 흔들어 캔버스를 지우기 (항상 확인 다이얼로그 경유)
- **그림 손실 방지**: 그리기 화면 이탈 시 작업물이 있으면 확인 다이얼로그 표시
- **이어 그리기**: 홈에서 다시 들어올 때 이전 그림이 있으면 이어 그리기/새로 시작 선택
- **종료 바텀시트**: 물리 뒤로가기 버튼 입력 시 종료 확인
- **Premium**: Small / Medium / Large 3단계 후원으로 광고 제거 및 Premium 브러시 접근

## 기술 스택

- **Flutter / Dart**
- **GetX**: 상태 관리, 라우팅, 다국어
- **Hive_CE**: 로컬 설정과 앱 데이터 저장
- **CustomPainter + perfect_freehand**: 드로잉 캔버스 렌더링과 stroke outline 생성
- **flutter_screenutil**: 반응형 UI
- **flex_color_scheme**: Material 3 테마
- **lucide_icons_flutter**: 아이콘
- **gal**: 기기 갤러리 저장
- **image**: JPEG 인코딩
- **image_picker**: 참조 사진 선택
- **sensors_plus**: 흔들어 지우기 감지
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
    ├── controllers/    # doodle, gallery, premium, setting
    ├── data/           # brushes/ (BrushPreset 정의 + registry), models/ (Drawing)
    ├── mixins/         # shake_detector_mixin
    ├── pages/          # home, draw, gallery, settings, premium
    ├── routes/         # GetX routes
    ├── services/       # Hive, artwork_repository, export, purchase, rating
    ├── theme/          # FlexColorScheme 테마
    ├── translate/      # GetX 다국어
    ├── utils/          # 상수와 toast
    └── widgets/        # 공용 위젯
```

> 코드에 `history`, `stats` 페이지나 활동 로그 서비스, 하단 내비게이션은 포함되어 있지 않습니다. 과거 문서/주석에 남아 있다면 모두 제거 대상입니다.

## 문서

- 스토어 메타데이터: `docs/store/google-store.md`
- 스크린샷 가이드: `docs/store/google-store-image.md`
- 앱 이름 / 스토어 제목: `docs/store/google-app-name.md`
- 광고 / Premium 설정: `docs/store/google-ads-subscription.md`

## 라이선스

Copyright 2026 DangunDad. All rights reserved.
