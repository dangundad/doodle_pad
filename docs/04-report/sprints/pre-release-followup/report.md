# Sprint Report — pre-release-followup

> Sprint ID: `pre-release-followup`
> Trust Level: L3
> 시작/종료: 2026-05-16
> 출발점: `review_codex.md` (Codex의 Pre-Release Review)

## 1. Codex 리뷰 vs 현재 코드 상태

`review_codex.md`가 제기한 P0/P1 항목을 현재 코드와 직접 대조한 결과, 다수는 **이미 정밀하게 처리**되어 있어 추가 작업이 불필요했다. 진짜 남아 있던 작은 손실 방어 2건만 이번 sprint에서 처리했다.

| Codex 항목 | 현 상태 | 근거 |
|------------|---------|------|
| P0 `shake_to_clear` 바인딩 순서 | ✅ 이미 수정 | `app_binding.dart:99-104` SettingController를 DoodleController **전에** 등록, 명시 주석 포함 |
| P0 `gallery_page_test` hang | ✅ 통과 | `runAsync`로 FakeAsync 회피, 본 환경 94/94 통과 |
| P1 JPEG 인코딩 | ✅ 이미 수정 | `export_service.dart:166-181` `image` 패키지로 실제 JPEG 인코딩 |
| P1 Premium 광고 매니저 race | ✅ 이미 수정 | `ads_rewarded.dart:36-41`, `ads_interstitial.dart:35-40` `loadAd()` 진입 가드 |
| P1 참조 이미지 영속 복사 | ✅ 이미 수정 | `artwork_repository.dart:68-85` `_persistReferenceImage` + 삭제 시 함께 정리 |
| P1 README/스토어 문서 불일치 | ✅ 이미 수정 | README는 10종 브러시·갤러리·참조 사진 복사·history/stats 부재 명시 |
| P2 작품 저장 중복 클릭 | ✅ 이미 수정 | `draw_page.dart:431-448` `isSavingArtwork.value`로 disable |
| P2 iOS placeholder | ✅ 직전 sprint 처리 | `app_constants.dart:55-57` iOS-only 정책 주석 |
| **갤러리 진입 시 작품 손실 방어** | 🔧 본 sprint 수정 | F1 |
| **작품 ID timestamp 충돌** | 🔧 본 sprint 수정 | F2 |

## 2. 본 Sprint 변경

### F1 — 갤러리 작품 열기 손실 방어
`gallery_page.dart:_openArtwork` — 현재 캔버스에 작업물이 있으면(`hasDrawableContent`) 확인 다이얼로그를 거친 뒤에만 `loadArtwork()`로 교체. 기존 번역 키(`continue_or_new_*`, `cancel`, `confirm`)를 재사용해 11개 언어 추가 작업 회피. `context.mounted` 가드로 async gap 안전화.

### F2 — 작품 ID 충돌 강화
`doodle_controller.dart:saveAsArtwork` — `artwork_${ms}` 단독은 빠른 연속 저장 시 ms 단위 충돌 가능. `dart:math` Random으로 base36 4자리 suffix를 부여해 충돌 확률을 1M분의 1 수준으로 축소.

## 3. QA

- `flutter analyze`: **No issues found** ✅
- `flutter test`: **94/94 PASS** ✅
- 회귀 위험: 갤러리 손실 방어는 신규 경로만 추가, ID 변경은 신규 저장에만 적용 — 기존 작품 호환성 영향 없음.

## 4. 변경 파일

```
M lib/app/pages/gallery/gallery_page.dart      # F1
M lib/app/controllers/doodle_controller.dart   # F2
A docs/04-report/sprints/pre-release-followup/report.md
```

## 5. Lessons Learned

- **두 AI 리뷰의 시점 차이**: Codex 리뷰(2026-05-14) 이후 도메인 코드가 상당 부분 진화한 상태였다. 정적 리뷰는 항상 "리뷰 시점 코드"를 가리키므로, 후속 작업 전에 코드와의 차이를 먼저 확인하는 것이 효율적이다.
- **리뷰 교차 검증의 가치**: Claude 리뷰가 놓친 동적 동작 버그(shake_to_clear 바인딩 순서, JPEG 가짜 인코딩)를 Codex가 잡았고, 이를 검증하는 과정에서 코드 품질이 이미 매우 높음을 확인했다.
- **번역 키 재사용 우선**: 11개 언어 다국어 프로젝트에서 새 키 추가는 비용이 크다. 의미가 비슷한 기존 키 재사용이 유지보수에 유리하다.

## 6. 배포 판단

🟢 **1.0.0 출시 안전**. 두 리뷰의 모든 차단/주의 항목이 해결되었고 정적 분석/테스트가 모두 통과한다. 남은 Carry Items는 1.0.1 백로그로 분리한다.
