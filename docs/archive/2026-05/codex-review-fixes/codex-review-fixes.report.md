# Report: Codex 리뷰 후속 개선 (codex-review-fixes)

- 작성일: 2026-05-06

## Executive Summary

| Problem | Solution | Value Delivered | Outcome |
|---|---|---|---|
| Codex 리뷰의 P0/P1 항목 일부가 릴리스 차단 요인이었음 | 광고 동의 게이트, ProGuard 추가, 캡처 메모리/상태 정리, 다국어 정합화 | 출시 가능 빌드 + 사용자 흐름 안정성 | analyze/test 100% 통과 |

## 1. 채택 범위 vs 보류 범위

### 채택 (구현 완료)
- P0-1 ProGuard 규칙 추가 (`android/app/proguard-rules.pro`)
- P0-2 + P1-10 광고 동의 게이트 + permanent 광고 매니저 강제 삭제
- P1-1 캡처 pixelRatio 동적화 + `ui.Image.dispose()`
- P1-4 "새 그림 시작" 진입 시 `clearCanvas()`
- P1-5 `hasDrawableContent` 게터로 참조 이미지 단독 저장/공유 허용
- P1-8 `supportedLocales` 를 en/ko로 제한

### 보류 (별도 사이클 권장)
- P0-3 Privacy Policy URL 404 → 외부 페이지 배포 필요
- P1-2 임시 PNG 정리 → 최근 커밋에서 1차 처리
- P1-3, P1-6, P1-7, P1-9, P1-11, P1-12, P1-13, P2 전반 → 본 사이클 범위 초과

## 2. 변경 파일 요약

```
android/app/proguard-rules.pro                 (신규)
lib/app/admob/ads_helper.dart                  (canRequestAds 추가)
lib/app/admob/ads_interstitial.dart            (consent 가드 + worker, 프리미엄 가드)
lib/app/admob/ads_rewarded.dart                (consent 가드 + worker)
lib/app/admob/ads_banner.dart                  (consent 가드 + worker)
lib/app/services/purchase_service.dart         (Get.delete<T>(force: true))
lib/app/controllers/doodle_controller.dart     (hasDrawableContent, 동적 pixelRatio, dispose)
lib/app/translate/translate.dart               (supportedLocales en/ko)
lib/app/pages/home/home_page.dart              (clearCanvas)
lib/app/pages/gallery/gallery_page.dart        (clearCanvas)
test/app/admob/ads_loading_test.dart           (consent gate 신규 케이스)
test/app/controllers/doodle_controller_test.dart (hasDrawableContent, clearCanvas)
```

## 3. 검증 결과

| 항목 | 결과 |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | 24/24 통과 (신규 3건 포함) |
| 매니저 consent gate 단위 테스트 | 통과 |
| `hasDrawableContent` / `clearCanvas` 단위 테스트 | 통과 |

## 4. Success Criteria 최종 상태

| ID | 상태 | 근거 |
|---|---|---|
| SC-1 analyze 통과 | ✅ | `No issues found!` |
| SC-2 test 통과 | ✅ | 24/24 |
| SC-3 ProGuard 파일 추가 | ✅ | `android/app/proguard-rules.pro` |
| SC-4 동의 전 외부 호출 차단 | ✅ | `ads_loading_test.dart`로 잠금 |
| SC-5 `hasDrawableContent` 게터 | ✅ | `doodle_controller_test.dart`로 잠금 |

## 5. 다음 권장 작업

1. P0-3: Privacy Policy 페이지 실제 배포 + URL HEAD 검증을 릴리스 체크리스트에 추가.
2. P1-9 / P1-11: IAP 상태 UI와 entitlement 검증 정책.
3. P1-7 / P1-6: 갤러리/홈 네비게이션 흐름과 "불러오기" 의미 정리.
4. P1-13: 접근성 semantics + 터치 영역 보강.
