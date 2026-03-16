# Bottom Navigation & UI Improvement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** google_nav_bar를 도입해 하단 네비게이션바를 구성하고, 홈/히스토리 화면 UI를 개선한다.

**Architecture:**
- `MainShellPage`를 신규 생성해 HOME 라우트에 연결한다.
- `IndexedStack`으로 4개 탭( Home · Gallery · History · Stats )을 스위칭하며, Settings는 AppBar 우측 아이콘으로 유지한다.
- 기존 `home_page.dart`의 TopBar 네비게이션 버튼과 하단 설정 버튼을 제거하고, Feature chips/Saved Drawings 카드를 compact하게 리팩터한다.

**Tech Stack:** Flutter · GetX · google_nav_bar ^5.0.7 · flutter_screenutil

---

## Task 1: pubspec.yaml에 google_nav_bar 추가

**Files:**
- Modify: `pubspec.yaml`

**Step 1: pubspec.yaml 편집**

`dependencies:` 블록에 한 줄 추가:
```yaml
  google_nav_bar: ^5.0.7
```
(알파벳 순서상 `google_mobile_ads` 바로 뒤에 삽입)

**Step 2: 패키지 설치**
```bash
cd C:\Flutter_WorkSpace\doodle_pad
flutter pub get
```
Expected: "Got dependencies!" 출력

**Step 3: Commit**
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add google_nav_bar dependency"
```

---

## Task 2: MainShellPage 생성

**Files:**
- Create: `lib/app/pages/home/main_shell_page.dart`

**Step 1: MainShellPage 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/pages/gallery/gallery_page.dart';
import 'package:doodle_pad/app/pages/history/history_page.dart';
import 'package:doodle_pad/app/pages/home/home_page.dart';
import 'package:doodle_pad/app/pages/stats/stats_page.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = [
    const HomeContentPage(),
    const GalleryPage(),
    const HistoryPage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cs.surface.withValues(alpha: 0.9),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12.w,
                  right: 12.w,
                  top: 6.h,
                  bottom: 4.h,
                ),
                child: BannerAdWidget(
                  adUnitId: AdHelper.bannerAdUnitId,
                  type: AdHelper.banner,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: GNav(
                  gap: 6,
                  iconSize: 22.r,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  duration: const Duration(milliseconds: 300),
                  tabBackgroundColor: cs.primaryContainer,
                  color: cs.onSurfaceVariant,
                  activeColor: cs.primary,
                  tabs: [
                    GButton(
                      icon: LucideIcons.home,
                      text: 'nav_home'.tr,
                    ),
                    GButton(
                      icon: LucideIcons.image,
                      text: 'nav_gallery'.tr,
                    ),
                    GButton(
                      icon: LucideIcons.history,
                      text: 'nav_history'.tr,
                    ),
                    GButton(
                      icon: LucideIcons.chartBarBig,
                      text: 'nav_stats'.tr,
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/app/pages/home/main_shell_page.dart
git commit -m "feat: add MainShellPage with google_nav_bar bottom navigation"
```

---

## Task 3: app_pages.dart에서 HOME 라우트를 MainShellPage로 변경

**Files:**
- Modify: `lib/app/routes/app_pages.dart`

**Step 1: import 추가 및 HOME route 수정**

파일 상단 import에 추가:
```dart
import 'package:doodle_pad/app/pages/home/main_shell_page.dart';
```

HOME GetPage의 `page:` 수정:
```dart
GetPage(
  name: _Paths.HOME,
  page: () => const MainShellPage(),  // HomePage() → MainShellPage()
  binding: AppBinding(),
),
```

**Step 2: Commit**
```bash
git add lib/app/routes/app_pages.dart
git commit -m "feat: route HOME to MainShellPage"
```

---

## Task 4: home_page.dart 리팩터 — HomeContentPage로 분리 & UI 개선

**Files:**
- Modify: `lib/app/pages/home/home_page.dart`

**목표:**
1. 클래스명 `HomePage` → `HomeContentPage` 로 변경 (MainShellPage에서 내장용).
2. `_HomeTopActions` 위젯 제거 — 갤러리/히스토리/통계 버튼 모두 삭제. AppBar는 앱 이름 + 설정 버튼만 남긴다.
3. 하단 설정 버튼(InkWell + LucideIcons.settings 블록) 제거.
4. 배너 광고 `Container` 제거 (이제 MainShellPage bottomNavigationBar에 위치).
5. Feature chips Wrap → 더 작고 compact하게 조정.
6. `_SavedDrawingsCard` padding/size 축소.

**Step 1: _HomeTopActions → 간결한 AppBar로 교체**

기존 `_HomeTopActions()` 호출 부분을 삭제하고, Scaffold에 `appBar`를 추가한다:
```dart
appBar: AppBar(
  elevation: 0,
  backgroundColor: cs.surface.withValues(alpha: 0.85),
  title: Text(
    'app_name'.tr,
    style: TextStyle(
      fontSize: 20.sp,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(LucideIcons.settings, size: 20.r, color: cs.onSurface),
      tooltip: 'settings'.tr,
      onPressed: () => Get.toNamed(Routes.SETTINGS),
    ),
  ],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(3),
    child: Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
      ),
    ),
  ),
),
```

**Step 2: body 정리**

현재 `body`의 `SafeArea + Column`에서:
- `_HomeTopActions()` 줄 삭제
- 하단 배너 광고 `Container` 블록 삭제 (약 17줄, `Container(color: cs.surface...` 블록)
- `Scaffold.body` 최외각 `Container`는 그대로 유지

**Step 3: 하단 설정 버튼 블록 제거**

`SizedBox(height: 16.h)` 이후에 오는 설정 버튼 `Container` 전체 블록 삭제:
```dart
// 이 블록 전체 제거 (약 35줄)
Container(
  decoration: BoxDecoration(
    color: cs.surfaceContainerLow,
    ...
  ),
  child: Material(
    ...
    child: InkWell(
      onTap: () { ... Get.toNamed(Routes.SETTINGS); },
      child: ... Text('settings'.tr) ...
    ),
  ),
),
```

**Step 4: Feature Chips 박스를 compact하게**

기존 `Container`(padding: all(16.r))의 `Wrap` 안 chips를 더 촘촘하게:
```dart
Container(
  width: double.infinity,
  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),  // 16.r → 12/10
  decoration: BoxDecoration(
    color: cs.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16.r),  // 20.r → 16.r
    border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
  ),
  child: Wrap(
    spacing: 6.w,   // 8.w → 6.w
    runSpacing: 6.h, // 8.h → 6.h
    alignment: WrapAlignment.center,
    children: _features.asMap().entries.map(...).toList(),
  ),
),
```

`_FeatureChip` 위젯의 padding 축소:
```dart
padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),  // 12/7 → 10/5
```

**Step 5: _SavedDrawingsCard 축소**

`_SavedDrawingsCard`의 padding 축소:
```dart
padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),  // 20/16 → 16/12
```

아이콘 컨테이너 크기 축소:
```dart
width: 40.r,  // 48.r → 40.r
height: 40.r,
...
Icon(Icons.photo_library_rounded, size: 20.r, ...),  // 24.r → 20.r
```

숫자 폰트 크기 축소:
```dart
fontSize: 18.sp,  // 22.sp → 18.sp
```

**Step 6: 클래스명 변경**

`class HomePage` → `class HomeContentPage` (+State, StatefulWidget 모두)

참고로 기존 `app_pages.dart`에서 `HomePage` import가 남아있는데, Task 3에서 이미 제거했으므로 확인만 한다.

**Step 7: Commit**
```bash
git add lib/app/pages/home/home_page.dart
git commit -m "refactor: rename HomePage to HomeContentPage, remove top nav buttons and settings button, compact UI"
```

---

## Task 5: 히스토리 화면 UI 개선

**Files:**
- Modify: `lib/app/pages/history/history_page.dart`

**목표:**
- 히스토리 화면이 이제 탭으로 전환되므로 뒤로가기 버튼을 별도 추가하지 않는다.
- `_buildHeader`에 그라디언트 배경을 추가해 홈과 일관된 느낌을 준다.
- 이벤트 카드에 컬러 액센트(event-type별 컬러)를 추가해 가독성을 높인다.
- 전체 배경에 홈 화면과 동일한 `LinearGradient`를 적용한다.

**Step 1: 배경 그라디언트 추가**

기존 `DecoratedBox` decoration에 홈 화면과 동일한 그라디언트:
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cs.primary.withValues(alpha: 0.10),
      cs.surface,
      cs.secondaryContainer.withValues(alpha: 0.15),
    ],
  ),
),
```

**Step 2: _buildHeader 개선**

`Row` 안 타이틀 좌측에 컬러드 아이콘 추가:
```dart
Row(
  children: [
    Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: Icon(Icons.history_rounded, size: 18.r, color: cs.onPrimary),
    ),
    SizedBox(width: 10.w),
    Expanded(
      child: Text(
        'history'.tr,
        style: TextStyle(
          fontSize: 24.sp,  // 28.sp → 24.sp
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
    ),
    IconButton(
      onPressed: controller.clearAll,
      tooltip: 'clear_all'.tr,
      icon: Icon(Icons.delete_outline, size: 20.r, color: cs.error),
    ),
  ],
),
```

**Step 3: 이벤트 카드 event-type 컬러 적용**

`_eventColor` 메서드를 추가해 icon 컨테이너 배경색에 반영:
```dart
Color _eventColor(String eventName, ColorScheme cs) {
  final t = eventName.toLowerCase();
  if (t.contains('premium')) return cs.tertiaryContainer;
  if (t.contains('stats')) return cs.secondaryContainer;
  if (t.contains('draw') || t.contains('stroke') || t.contains('path')) {
    return cs.primaryContainer;
  }
  return cs.surfaceContainerHigh;
}

Color _eventIconColor(String eventName, ColorScheme cs) {
  final t = eventName.toLowerCase();
  if (t.contains('premium')) return cs.tertiary;
  if (t.contains('stats')) return cs.secondary;
  if (t.contains('draw') || t.contains('stroke') || t.contains('path')) {
    return cs.primary;
  }
  return cs.onSurfaceVariant;
}
```

아이콘 컨테이너 `color:` 를 `_eventColor(event, cs)` 로 교체, icon `color:` 를 `_eventIconColor(event, cs)` 로 교체.

**Step 4: 이벤트 이름 표시 개선**

event 문자열이 너무 기술적(raw)이므로, `_localizeEvent` 유틸 추가:
```dart
String _localizeEvent(String raw) {
  // 번역키가 있으면 번역, 없으면 snake_case → Title Case
  if (raw.startsWith('unknown')) return 'event_unknown'.tr;
  return raw.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
```

`itemBuilder` 내 `event` 변수 사용 시:
```dart
final event = _localizeEvent(item['event']?.toString() ?? '');
```

**Step 5: Commit**
```bash
git add lib/app/pages/history/history_page.dart
git commit -m "feat: improve history page UI with consistent theme and event type colors"
```

---

## Task 6: 번역 키 추가

**Files:**
- Modify: `lib/app/translate/translate.dart`

**Step 1: 하단 네비게이션바 번역 키 추가**

`'ko':` 맵에 추가:
```dart
'nav_home': '홈',
'nav_gallery': '갤러리',
'nav_history': '기록',
'nav_stats': '통계',
'event_unknown': '알 수 없는 이벤트',
```

**Step 2: Commit**
```bash
git add lib/app/translate/translate.dart
git commit -m "feat: add bottom nav translation keys"
```

---

## Task 7: flutter analyze 실행 및 오류 수정

**Step 1: 정적 분석 실행**
```bash
cd C:\Flutter_WorkSpace\doodle_pad
flutter analyze
```
Expected: "No issues found!" 또는 lint 경고 목록

**Step 2: 오류 수정**
- import 미사용 경고: 해당 줄 제거
- type error: 타입 명시 추가
- deprecated: 해당 API 교체

**Step 3: 최종 Commit**
```bash
git add -A
git commit -m "fix: resolve flutter analyze warnings"
```

---

## 접근 요약

| 번호 | 작업                             | 파일                                      |
| ---- | -------------------------------- | ----------------------------------------- |
| 1    | google_nav_bar 의존성 추가       | `pubspec.yaml`                            |
| 2    | MainShellPage 생성               | `lib/app/pages/home/main_shell_page.dart` |
| 3    | HOME 라우트 → MainShellPage      | `lib/app/routes/app_pages.dart`           |
| 4    | HomeContentPage 리팩터 + UI 개선 | `lib/app/pages/home/home_page.dart`       |
| 5    | HistoryPage UI 개선              | `lib/app/pages/history/history_page.dart` |
| 6    | 번역 키 추가                     | `lib/app/translate/translate.dart`        |
| 7    | flutter analyze 수행             | -                                         |
