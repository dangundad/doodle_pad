# Doodle Pad

자유 드로잉 캔버스 앱. 5종 브러시(펜/마커/지우개/수채화/에어브러시)로 그림을 그리고 저장/공유할 수 있는 Flutter 앱입니다.

## 주요 기능

- **5종 브러시**: 펜, 마커, 지우개, 수채화 (보상형 광고 해금), 에어브러시 (보상형 광고 해금)
- **16색 팔레트**: 다양한 색상 선택
- **브러시 크기 조절**: 슬라이더로 굵기 변경
- **Undo/Redo**: 최대 20단계 되돌리기/다시하기
- **캔버스 저장**: PNG 이미지로 앱 내 갤러리에 저장
- **공유**: 그린 그림을 이미지로 공유
- **갤러리**: 저장된 그림 목록 관리 및 삭제
- **햅틱 피드백**: 브러시 전환, 색상 선택 시 진동
- **프리미엄**: 인앱 구매로 광고 제거

## 기술 스택

- **Flutter** (Dart)
- **GetX** - 상태 관리, 라우팅, 다국어
- **Hive_CE** - 로컬 데이터 저장
- **CustomPainter** - 캔버스 렌더링 (`CanvasPainter`)
- **share_plus** - 이미지 공유
- **flex_color_scheme** - 테마 (`FlexScheme.pinkM3`)
- **flutter_screenutil** - 반응형 UI
- **google_mobile_ads** - AdMob 광고 (배너 + 전면 + 보상형)

## 설치 및 실행

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart
├── app/
│   ├── admob/              # AdMob 광고 관리
│   ├── bindings/           # GetX 바인딩
│   ├── controllers/        # DoodleController, SettingController 등
│   ├── pages/              # 화면별 UI (draw/ 하위에 CanvasPainter)
│   ├── routes/             # GetX 라우팅
│   ├── services/           # HiveService, PurchaseService 등
│   ├── theme/              # FlexColorScheme 테마
│   ├── translate/          # 다국어 (ko)
│   └── utils/              # 상수 정의
```

## 라이선스

Copyright 2026 DangunDad. All rights reserved.
