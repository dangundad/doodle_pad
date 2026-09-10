# UI/UX 리뉴얼 — "종이 + 잉크" — 2026-09-10

> 대상: `doodle_pad` 1.0.0+1
> 범위: 테마 · 그리기 · 홈 · 보관함 · 설정 · 프리미엄 · 공통 시트/다이얼로그 (기능/상태/영속성/라우팅 변경 없음)
> 검증: `flutter analyze` 0 issue · `flutter test` 139개 통과 · Pixel AVD(Android 17, 1080×2400) 스크린샷 육안 검수

## 왜 밋밋했는가

- AppBar를 주황(primary)으로 칠하고, 그 아래에는 회색 카드가 같은 간격으로 반복됐다. 색은 많은데 위계가 없었다.
- 선택 상태를 primary 채움 + 글로우(boxShadow)로 표현해 "AI 템플릿" 느낌이 났다.
- 홈은 원형 아이콘 + 제목 + 칩 + 버튼의 전형적인 온보딩 구성이라 사용자의 그림이 어디에도 보이지 않았다.

## 디자인 방향

**종이 + 잉크.** 따뜻한 종이색 표면(`surface` #FBF9F4) 위에 잉크 블루(`primary` #2F4FBF) 하나만 강조색으로 쓴다.
앱 아이콘(노란 스케치북 + 크레용)에서 가져온 노랑은 `secondary`(프리미엄/후원/경고), 초록은 `tertiary`(혜택 체크)로만 제한한다.

규칙:
- **위계는 표면 단계와 헤어라인으로만.** 그림자 대신 1px `outlineVariant` 외곽선, `surfaceContainerLowest`(흰 종이) → `surfaceContainerLow`(연한 종이) → `surface`(바탕).
- **AppBar는 칠하지 않는다.** 표면색 + 잉크색 아이콘 + 왼쪽 정렬 제목.
- **선택 = 잉크 블루 채움 또는 잉크 블루 테두리.** 글로우·확대 효과 없음.
- **반경 3단계**: 10(작은 타일) / 14(카드·버튼) / 20(시트·다이얼로그·하단 툴바).
- `primaryContainer` 위 전경은 항상 `onPrimaryContainer` (기존 규칙 유지, 대비 테스트 추가).
- 그라데이션 금지(기존 `no_gradient_usage_test` 유지).

## 파일 변경

| 파일 | 변경 |
| --- | --- |
| `lib/app/theme/app_theme.dart` | `FlexScheme.shadOrange` → 수동 `ColorScheme`(light/dark) 주입. AppBar surface 배경, 반경 토큰(`radiusSm/Md/Lg`), 타이포 weight/letterSpacing, 슬라이더·스위치 테마. |
| `lib/app/widgets/app_ui.dart` (신규) | `AppPanel`(헤어라인 카드), `SectionLabel`, `IconBadge`(6톤), `AppConfirmDialog`, `AppSheetShell`(그립 핸들), `AppListRow`, `DirectionalChevron`. |
| `lib/app/pages/draw/draw_page.dart` | 상단 툴바를 그룹 구분선이 있는 한 줄 필로 정리, 하단 툴바에 굵기 수치 표시, 색상 선택을 "바깥 링"으로 변경(색 자체를 가리지 않음), 모든 다이얼로그/시트를 공통 위젯으로 교체. 1923 → 약 1500줄. |
| `lib/app/pages/home/home_page.dart` | 히어로를 **최근 작품 3장을 겹친 종이 묶음**으로 교체(작품 없으면 빈 종이). 제목 왼쪽 정렬, 칩 카드 제거, CTA에 화살표. |
| `lib/app/pages/gallery/gallery_page.dart` | 작품 카드를 종이(흰 표면 + 헤어라인 + 캔버스 배경색 여백)로, 날짜 행에 헤어라인 구분. 빈 상태를 빈 종이 일러스트로. 경고 배너를 error → secondary(노랑) 톤으로. |
| `lib/app/pages/settings/settings_page.dart` | 중복 소개 카드 제거, 섹션 라벨 + 헤어라인 목록, 스위치 행 전체 탭 가능, `ListView` → `SingleChildScrollView`. |
| `lib/app/pages/premium/premium_page.dart` | 히어로에 혜택 3줄 통합, 옵션 카드를 라디오 스타일로, 구매 바에서 플랜/가격 분리. |
| `lib/app/pages/draw/widgets/save_options_sheet.dart` | 공통 시트 껍데기 + 섹션 라벨 + 선택 타일 통일. |
| `lib/app/widgets/exit_bottom_sheet.dart` | 공통 패널/배지 사용, 프리미엄 안내를 secondary 톤으로. |
| `test/app/theme/app_theme_test.dart` | AppBar surface/좌측 정렬, 팔레트 고정, `primaryContainer` 대비 ≥ 4.5 검증으로 갱신. |

## 지키는 것 (테스트가 고정)

- 모든 `ValueKey`(`draw-brush-*`, `draw-color-*`, `canvas-color-*`, `settings-*-tile`, `home-*`, `premium_*`)와 툴팁 문자열 유지.
- 44dp 터치 타깃, Semantics(button/selected/label/hint) 유지.
- 320dp × 130% 텍스트 배율에서 11개 언어 오버플로 없음.
- 감소된 모션 설정 시 진입 애니메이션 즉시 완료.

## 남은 판단

- 전면광고 노출 지점 부재(이전 QA 보고)는 이번 범위 밖.
- 폰트: `google_fonts`가 의존성에 있으나 CJK/아랍어 폴백과 오프라인 첫 실행을 고려해 시스템 폰트를 유지했다. 라틴 전용 디스플레이 폰트를 원하면 별도 작업.
