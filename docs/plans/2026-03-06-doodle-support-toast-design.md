# Doodle Pad Support Actions And Toast UX Design

**Date:** 2026-03-06

## Goal

`doodle_pad` 설정 화면의 지원 액션을 실제 동작으로 연결하고, 저장/불러오기/삭제/링크 실패 피드백을 `toastification` 기반 공통 레이어로 정리한다.

## Context

- 현재 설정 화면에는 `Send Feedback`만 placeholder로 남아 있다.
- `AppRatingService`와 `url_launcher`는 이미 프로젝트에 준비되어 있다.
- 피드백 메시지는 `Get.snackbar`가 분산되어 있어 스타일과 실패 처리 기준이 일관되지 않다.
- 이번 범위는 Android 우선이며, 기존 GetX/Hive 패턴과 라우팅 구조는 유지한다.

## Options

### Option 1: Feedback 링크만 연결

- `Send Feedback`만 실제 메일 링크로 교체
- 장점: 변경 범위가 매우 작다
- 단점: `Rate App`, `Privacy Policy`, `More Apps`와 toast 일관성이 그대로 남는다

### Option 2: Support Actions만 완결

- 설정에 `Rate App`, `Send Feedback`, `Privacy Policy`, `More Apps`를 모두 연결
- 기존 `Get.snackbar`는 유지
- 장점: 구현이 단순하다
- 단점: 이번 배치의 `toastification` 도입 가치를 거의 살리지 못한다

### Option 3: Support Actions + Toastification 정리

- 설정 지원 액션 4개를 모두 실제 연결
- `toastification` 전역 wrapper와 `AppToast` 유틸 추가
- 저장/불러오기/삭제/링크 실패 경로를 공통 toast 레이어로 정리
- 장점: 사용자 체감 개선이 가장 크고, 후속 앱 확장 패턴으로 재사용 가능하다
- 단점: 파일 영향 범위가 Option 2보다 넓다

## Chosen Approach

Option 3을 채택한다.

## Architecture

- `SettingController`가 support action을 소유한다.
- `AppRatingService`는 기존대로 유지하고, `SettingController`에서 `rateApp()`으로 위임한다.
- 외부 링크는 `url_launcher`로 열고 실패 시 `AppToast.error(...)`를 호출한다.
- `AppToast`는 `toastification`을 감싼 얇은 유틸로 두고, 전역 진입점은 `main.dart`에서 한 번만 `ToastificationWrapper`를 적용한다.

## Files In Scope

- `lib/main.dart`
- `lib/app/controllers/setting_controller.dart`
- `lib/app/pages/settings/settings_page.dart`
- `lib/app/controllers/doodle_controller.dart`
- `lib/app/pages/gallery/gallery_page.dart`
- `lib/app/utils/app_constants.dart`
- `lib/app/translate/translate.dart`
- `lib/app/utils/app_toast.dart` 신규
- `test/app/controllers/setting_controller_test.dart` 신규
- `test/app/pages/settings/settings_page_test.dart` 신규
- 필요 시 `test/app/utils/app_toast_test.dart` 신규

## Error Handling

- 링크 실행 불가 또는 launch 실패 시 `AppToast.error`로 짧은 안내를 노출한다.
- 저장/삭제/불러오기 성공은 success/info toast로 통일한다.
- 예외 문자열 그대로 노출하던 경로는 가능하면 번역 키 기반 메시지로 정리한다.

## Testing

- `SettingController` 단위 테스트
  - `rateApp` 위임
  - `sendFeedback` mailto URI
  - `openPrivacyPolicy` 외부 링크
  - `openMoreApps` 외부 링크
- `SettingsPage` 위젯 테스트
  - support tile 탭이 컨트롤러 메서드로 위임되는지 확인
- toast 관련 테스트
  - 최소 범위로 `AppToast` 호출 지점 또는 wrapper 존재 확인

## Constraints

- iOS 전용 구현은 넣지 않는다.
- 기존 구매 흐름 `PurchaseService`는 이번 범위에서 수정하지 않는다.
- Hive 모델 변경은 없으므로 `build_runner`는 실행하지 않는다.
