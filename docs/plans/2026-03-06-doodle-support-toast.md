# Doodle Pad Support Actions And Toast UX Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** `doodle_pad` 설정 화면 지원 액션을 실제 동작으로 연결하고, 공통 toast 레이어로 고빈도 피드백을 정리한다.

**Architecture:** `SettingController`에 support action을 모으고, `main.dart`에서 `ToastificationWrapper`를 한 번만 감싼다. `AppToast` 유틸을 통해 설정, 저장, 갤러리 피드백을 공통 API로 호출한다.

**Tech Stack:** Flutter, GetX, Hive_CE, `url_launcher`, `in_app_review`, `toastification`, Flutter widget/unit tests

---

### Task 1: 문서 체크포인트

**Files:**
- Create: `docs/plans/2026-03-06-doodle-support-toast-design.md`
- Create: `docs/plans/2026-03-06-doodle-support-toast.md`

**Step 1: 문서 작성**

- 설계와 구현 계획 문서를 저장한다.

**Step 2: 체크포인트 커밋**

Run:

```bash
git add docs/plans/2026-03-06-doodle-support-toast-design.md docs/plans/2026-03-06-doodle-support-toast.md
git commit -m "docs: add doodle support and toast plan"
```

### Task 2: Support Action 테스트 먼저 작성

**Files:**
- Create: `test/app/controllers/setting_controller_test.dart`
- Create: `test/app/pages/settings/settings_page_test.dart`
- Modify: `lib/app/controllers/setting_controller.dart`
- Modify: `lib/app/pages/settings/settings_page.dart`

**Step 1: Write the failing test**

- `SettingController`에 대해 아래 테스트를 작성한다.
  - `rateApp delegates to the app rating action`
  - `sendFeedback launches a mailto uri`
  - `openPrivacyPolicy launches the privacy policy externally`
  - `openMoreApps launches the developer page externally`
- `SettingsPage`에 대해 support tile 4개가 컨트롤러 메서드에 위임되는 테스트를 작성한다.

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/app/controllers/setting_controller_test.dart
flutter test test/app/pages/settings/settings_page_test.dart
```

Expected:

- `SettingController` 생성자, support action 메서드, support tile key, `PRIVACY_POLICY` 상수 부재로 실패

**Step 3: Write minimal implementation**

- `SettingController`에 테스트 가능한 생성자 주입 포인트 추가
- `AppRatingService`, `url_launcher` 위임 메서드 추가
- `settings_page.dart`에 support tile 4개 추가
- `app_constants.dart`와 `translate.dart`에 필요한 문자열/URL 추가

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/app/controllers/setting_controller_test.dart
flutter test test/app/pages/settings/settings_page_test.dart
```

Expected:

- 두 테스트 모두 PASS

**Step 5: Commit**

```bash
git add lib/app/controllers/setting_controller.dart lib/app/pages/settings/settings_page.dart lib/app/utils/app_constants.dart lib/app/translate/translate.dart test/app/controllers/setting_controller_test.dart test/app/pages/settings/settings_page_test.dart
git commit -m "feat: add doodle support actions"
```

### Task 3: Toastification 인프라 추가

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/main.dart`
- Create: `lib/app/utils/app_toast.dart`

**Step 1: Write the failing test**

- `AppToast`를 참조하는 최소 테스트 또는 wrapper를 포함한 smoke test를 추가한다.

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/app
```

Expected:

- `AppToast` 또는 `toastification` wrapper 부재로 실패

**Step 3: Write minimal implementation**

- `toastification` 의존성 추가
- `main.dart`의 `GetMaterialApp`을 `ToastificationWrapper`로 감싼다
- `lib/app/utils/app_toast.dart`에 `success`, `error`, `info` 정적 메서드 추가

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/app
```

Expected:

- 새 toast 관련 테스트 PASS

**Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/app/utils/app_toast.dart test/app
git commit -m "feat: add doodle toast layer"
```

### Task 4: 고빈도 Snackbar 치환

**Files:**
- Modify: `lib/app/controllers/doodle_controller.dart`
- Modify: `lib/app/pages/gallery/gallery_page.dart`
- Modify: `lib/app/pages/settings/settings_page.dart`

**Step 1: Write the failing test**

- 저장/불러오기/삭제/링크 실패 경로 중 핵심 한두 개에 대한 테스트를 추가한다.

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/app
```

Expected:

- 기존 `Get.snackbar` 경로 때문에 기대한 toast 호출이 일어나지 않아 실패

**Step 3: Write minimal implementation**

- 성공/실패 메시지를 `AppToast`로 교체한다.
- 예외 문자열 직접 출력 경로는 가능한 범위에서 정리한다.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/app
```

Expected:

- 관련 테스트 PASS

**Step 5: Commit**

```bash
git add lib/app/controllers/doodle_controller.dart lib/app/pages/gallery/gallery_page.dart lib/app/pages/settings/settings_page.dart test/app
git commit -m "feat: unify doodle feedback toasts"
```

### Task 5: 최종 검증과 문서 반영

**Files:**
- Modify: `C:/Flutter_WorkSpace/Flutter_Plan/docs/trending_packages_2026.md`

**Step 1: Run full verification**

Run:

```bash
flutter analyze
flutter test
```

Expected:

- analyze 0 issues
- test all pass

**Step 2: Update meta docs**

- `docs/trending_packages_2026.md`에 `doodle_pad` 완료와 `url_launcher`/`toastification` 집계를 반영한다.

**Step 3: Commit and push**

```bash
git add .
git commit -m "feat: roll out doodle support and toast ux"
git push
```

```bash
git -C C:/Flutter_WorkSpace/Flutter_Plan add docs/trending_packages_2026.md
git -C C:/Flutter_WorkSpace/Flutter_Plan commit -m "docs: record doodle pad rollout"
git -C C:/Flutter_WorkSpace/Flutter_Plan push
```
