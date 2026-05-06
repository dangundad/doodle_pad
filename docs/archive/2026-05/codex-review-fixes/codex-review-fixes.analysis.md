# Analysis: Codex 리뷰 후속 개선 (codex-review-fixes)

- 작성일: 2026-05-06

## 1. Match Rate (자가 평가)

설계 문서 기준 구현 항목 매칭.

| 항목 | 상태 | 근거 |
|---|---|---|
| ProGuard 파일 추가 (R-1) | ✅ | `android/app/proguard-rules.pro` 신규 |
| canRequestAds 게이트 (R-2) | ✅ | `ads_helper.dart`, 각 매니저 `onInit()`에 `ever()` 워커 |
| permanent 광고 매니저 force 삭제 (R-3) | ✅ | `purchase_service.dart` `Get.delete<T>(force: true)` |
| 캡처 pixelRatio 동적화 + dispose (R-4) | ✅ | `_resolveCapturePixelRatio`, `try/finally` dispose |
| 새 그림 진입 시 strokes clear (R-5) | ✅ | `home_page.dart`, `gallery_page.dart` `clearCanvas()` |
| 참조 이미지만으로 저장/공유 (R-6) | ✅ | `hasDrawableContent` 게터 + 빈 상태 검사 통일 |
| supportedLocales en/ko 제한 (R-7) | ✅ | `translate.dart` |
| analyze 통과 (SC-1) | ✅ | `No issues found!` |
| test 통과 (SC-2) | ✅ | 24/24 통과 (신규 3건 포함) |

Match Rate: 100% (선택한 범위 기준)

## 2. 주의 사항 / 한계

- 보류 항목(P0-3, P1-2, P1-3, P1-6, P1-7, P1-9, P1-11, P1-12, P1-13, P2 전체)은 본 사이클 범위 외.
- 광고 동의 흐름은 단위 테스트로 잠겼지만, 실제 EU/UK 환경 통합 테스트는 다음 회귀 단계에서 확인 필요.
- 캡처 pixelRatio 변경은 출력 이미지 해상도가 미세하게 낮아질 수 있음. 8MP 상한 안에서는 시각 차이 거의 없음.

## 3. 회귀 위험

| 영역 | 위험 | 평가 |
|---|---|---|
| 광고 표시 | consent 직후 잠깐 빈 배너 | 기존 `_isLoaded == false ? SizedBox.shrink()` 처리로 OK |
| 캡처 메모리 | 작은 캔버스에서 ratio 1.0 floor에 도달 | 사용자 시선 차이 미미 |
| 새 그림 진입 | 의도치 않은 strokes 손실 | 사용자가 "새 그림" 진입 의도이므로 합당 |
