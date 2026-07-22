# Doodle Pad Design System

이 문서는 현재 Flutter 구현에서 추출한 디자인 계약이다. 새 시각 방향을 덧씌우지 않고, 이미 출시 후보에 적용된 Shadcn Orange 기반 Material 3 UI를 일관되게 유지·검증한다.

## 1. Atmosphere & Identity

Doodle Pad는 밝고 친근한 디지털 스케치북이다. 흰 캔버스와 차분한 중성 표면이 작업 공간을 만들고, 선명한 오렌지는 주요 행동과 선택 상태에만 사용한다. 시그니처는 “오렌지 도구와 넓은 종이”이며, 장식보다 그리기 동작과 작품이 먼저 보여야 한다.

## 2. Color

기본 소스는 `FlexScheme.shadOrange`와 활성 `ColorScheme`이다. 위젯에서는 원시 색상 대신 `Theme.of(context).colorScheme` 또는 `Get.theme.colorScheme`의 의미 토큰을 사용한다.

| Role | Flutter token | Light | Dark | Usage |
|---|---|---:|---:|---|
| Surface/primary | `surface` | `#FFFFFF` | `#0C0A09` | 페이지와 캔버스 주변 배경 |
| Surface/secondary | `surfaceContainerLow` / `secondaryContainer` | `#F5F5F4` 계열 | `#292524` 계열 | 카드, 도구 묶음, 선택 전 컨테이너 |
| Surface/elevated | `surfaceContainerHigh` | 밝은 stone 계열 | 어두운 stone 계열 | 시트, 다이얼로그, 고정 액션 바 |
| Text/primary | `onSurface` | `#0C0A09` | `#FAFAF9` | 제목, 본문, 핵심 값 |
| Text/secondary | `onSurfaceVariant` | `#78716C` 계열 | `#A8A29E` 계열 | 설명, 메타데이터, 힌트 |
| Border/default | `outlineVariant` | `#E7E5E4` | `#292524` | 카드와 선택 옵션의 조용한 경계 |
| Accent/primary | `primary` | `#F97316` | `#EA580C` | 주요 CTA, 선택, 포커스, 앱 바 |
| Accent/on-primary | `onPrimary` | `#FAFAF9` | `#FAFAF9` | 오렌지 표면 위 콘텐츠 |
| Status/error | `error` | `#EF4444` | `#DC2626` | 삭제·실패·파괴적 행동 |

규칙:

- 한 모바일 화면에서 포화된 오렌지 강조 영역은 원칙적으로 2개 이하로 유지한다.
- 상태색은 실제 상태 전달에만 사용하고 장식에 사용하지 않는다.
- 브러시 팔레트의 사용자 선택 색상은 창작 도구 데이터이므로 브랜드 색 예산에서 제외한다.
- 새 색이 필요하면 먼저 이 표에 의미 역할을 추가한다.

## 3. Typography

### Font stack

- iOS: San Francisco 시스템 폰트
- Android: Roboto 시스템 폰트
- 별도 표시용/모노 폰트는 사용하지 않는다.

### Scale

| Level | Logical size | Weight | Line height | Usage |
|---|---:|---:|---:|---|
| Display | 30–34sp | 800 | 1.25 | 제품명; Arabic 등 큰 글리프 스크립트는 30sp |
| H1 | 22sp | 700–800 | 1.25 | 화면의 주요 블록 제목 |
| H2 | 20sp | 700–800 | 1.3 | 시트·확인 화면 제목 |
| H3 | 18sp | 700 | 1.35 | 다이얼로그 제목, 섹션 제목 |
| Body/lg | 16sp | 500–700 | 1.4 | 주요 버튼, 빈 상태 제목 |
| Body | 14–15sp | 400–600 | 1.4 | 기본 본문과 행 제목 |
| Body/sm | 14sp | 400–500 | 1.35 | 보조 설명 |
| Caption | 14sp | 500–700 | 1.3 | 짧은 상태·도구 라벨 |

규칙:

- 핵심 설명과 설정 본문은 14sp 미만으로 내려가지 않는다.
- 사용자에게 노출되는 텍스트는 역할과 관계없이 14sp 이상을 유지한다.
- 번역 문자열은 임의로 잘라 의미를 숨기지 않는다. 공간이 부족하면 행 높이 또는 레이아웃이 늘어난다.
- 한국어·일본어·중국어의 한 글자 고아 줄과 잘린 글리프를 허용하지 않는다.

## 4. Spacing & Layout

### Base unit

논리 간격은 4dp를 기준으로 하며 `flutter_screenutil`의 `.w`, `.h`, `.r`, `.sp`는 앱 진입점과 동일한 375×812 설계 크기에서 반응형 변환만 담당한다.

| Token | Value | Usage |
|---|---:|---|
| `space-1` | 4dp | 아이콘 내부 미세 간격 |
| `space-2` | 8dp | 인라인 요소, 작은 그룹 |
| `space-3` | 12dp | 목록·도구 컨테이너 |
| `space-4` | 16dp | 표준 페이지/카드 간격 |
| `space-5` | 20dp | 시트와 카드 내부 여백 |
| `space-6` | 24dp | 다이얼로그 내부 여백 |
| `space-8` | 32dp | 주요 섹션 분리 |

### Radius scale

| Token | Value | Usage |
|---|---:|---|
| `radius-sm` | 10dp | 텍스트 버튼 |
| `radius-md` | 12dp | 기본 버튼·선택 옵션 |
| `radius-lg` | 14–16dp | 카드·툴바 |
| `radius-xl` | 18–20dp | 다이얼로그·바텀 시트 |
| `radius-2xl` | 24dp | 떠 있는 종료 시트 |
| `radius-pill` | full | 배지·칩 |

### Layout rules

- 모든 페이지는 `SafeArea`와 시스템 인셋을 존중한다.
- 최소 지원 폭 320dp, 기준 폭 375dp, iPhone 12 Pro Max 폭에서 가로 오버플로우가 없어야 한다.
- 고정 폭 Row는 긴 번역에서 `Expanded`, `Flexible`, `Wrap`, 수평 스크롤 중 의미에 맞는 방식을 사용한다.
- 주요 터치 대상은 최소 44×44dp이다.
- 앱 바, 캔버스, 하단 도구 영역의 스크롤 소유권을 분리하고 캔버스가 도구 영역을 밀어내지 않는다.

## 5. Components

### Page App Bar

- **Structure**: 중앙 제목 + 아이콘 액션
- **Variants**: 루트, 뒤로 가기, 선택 모드
- **Spacing**: `space-2`와 Material 기본 툴바 인셋
- **States**: default, pressed, focused, disabled
- **Accessibility**: 모든 아이콘 버튼에 현지화된 tooltip/semantic label 제공
- **Motion**: iOS는 Cupertino 전환, 그 외는 fade-up 전환

### Primary Action

- **Structure**: 아이콘 + 한 줄 라벨
- **Variants**: filled, outlined, text, destructive
- **Spacing**: 수직 12–16dp, 아이콘-라벨 8–10dp
- **States**: default, pressed, focused, disabled, loading
- **Accessibility**: 44dp 이상 높이, 색 외에도 아이콘·텍스트로 상태 전달
- **Motion**: 눌림 효과는 Material ink/interaction effect로 전달

### Surface Card

- **Structure**: 선택적 아이콘 블록 + 제목/설명 + 선택적 trailing
- **Variants**: navigation, setting section, artwork, status
- **Spacing**: 내부 12–20dp
- **States**: default, pressed, selected, disabled, empty, error
- **Accessibility**: 카드 전체가 동작하면 하나의 명확한 semantics action으로 노출
- **Depth**: 기본은 tonal surface와 얇은 outline, 그림자는 떠 있는 시트에만 사용

### Tool Selector

- **Structure**: 가로 스크롤 가능한 44dp 셀과 현지화 라벨
- **Variants**: brush, color, resolution, image format
- **States**: default, selected, pressed, focused, locked/disabled
- **Accessibility**: 선택 상태와 잠금 이유를 semantics로 전달
- **Layout**: 도구가 많을 때 잘라내지 않고 수평 스크롤 또는 Wrap 사용

### Modal Surface

- **Structure**: 아이콘/제목/설명/행동 그룹
- **Variants**: confirm, destructive confirm, option sheet, exit sheet
- **States**: default, loading, disabled, error
- **Accessibility**: focus 이동, 바깥 탭 닫기 정책 명시, 긴 번역에서 내부 스크롤 허용
- **Depth**: 18–24dp radius, 제한된 tinted shadow

### Settings Section

- **Structure**: 섹션 헤더 + `ListTile`/`SwitchListTile`/언어 선택 컨트롤
- **States**: default, pressed, toggled, disabled
- **Accessibility**: 제목과 설명을 자르지 않고 스위치 값이 읽히도록 구성
- **Layout**: 콘텐츠 높이에 따라 늘어나며 페이지 ListView가 스크롤 소유

## 6. Motion & Interaction

| Type | Duration | Curve | Usage |
|---|---:|---|---|
| Micro | 100–150ms | ease-out | 버튼·선택 피드백 |
| Standard | 300ms | ease-in-out | fade-in, 패널 상태 변경 |
| Page | 500ms | platform transition | 화면 전환 |

규칙:

- 애니메이션은 상태·상호작용을 설명할 때만 사용한다.
- 장식만을 위한 반복 애니메이션은 추가하지 않는다.
- 시스템의 모션 감소 설정에서 비필수 애니메이션을 줄인다.
- 진동/햅틱 설정이 꺼져 있으면 선택 피드백 진동을 발생시키지 않는다.

## 7. Depth & Surface

전략은 **mixed, tonal-first**이다. 페이지와 카드의 기본 계층은 `surfaceContainer*` tonal shift와 `outlineVariant`로 만들고, 화면에서 떠 있는 바텀 시트·다이얼로그에만 낮은 불투명도의 그림자를 사용한다. 그라데이션은 사용하지 않는다.

| Level | Treatment | Usage |
|---|---|---|
| Base | `surface` | 페이지 배경, 캔버스 주변 |
| Grouped | `surfaceContainerLow` + optional outline | 카드와 툴바 그룹 |
| Selected | `primaryContainer` + primary outline | 선택 옵션 |
| Floating | `surface` + outline + soft shadow | 종료 시트, 고정 구매 바 |

## 8. Accessibility Constraints & Accepted Debt

### Constraints

- 목표: WCAG 2.2 AA에 준하는 대비와 iOS HIG 44×44dp 터치 영역
- 텍스트 확대·긴 번역에서 RenderFlex overflow, 가로 스크롤, 의미 손실이 없어야 한다.
- 모든 화면은 영어, 한국어, 일본어, 독일어, 러시아어, 프랑스어, 스페인어, 포르투갈어, 인도네시아어, 중국어(`zh`), 아랍어를 지원한다.
- RTL 로케일은 방향성 아이콘·행 순서·텍스트 정렬이 자연스럽게 반전되어야 한다.
- 색상만으로 선택·오류·잠금을 전달하지 않는다.

### Accepted Debt

현재 승인된 디자인 부채는 없다. 감사에서 발견되는 44dp 미만 터치 대상, 14sp 미만 텍스트, 이모지 아이콘, 잘린 번역은 수정 후보로 취급하고 사용자 승인 없이 부채로 고정하지 않는다.
