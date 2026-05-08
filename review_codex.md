# Doodle Pad 최종 코드베이스 리뷰

검토일: 2026-05-08  
검토 범위: `lib/`, `test/`, `android/`, `pubspec.yaml`, `README.md`, `docs/store/*`, `docs/TODO.md`  
검증 명령: `flutter analyze`, `flutter test`

## 한 줄 결론

현재 앱은 "가볍게 열어서 바로 그리고 공유하는 드로잉 앱"으로는 출시 가능한 수준에 가깝다. 다만 스토어/README 문서가 현재 코드에 없는 저장, 갤러리, 기록, 통계를 아직 설명하고 있어 출시 전 반드시 정리해야 한다. 경쟁앱 대비 가장 아쉬운 핵심 공백은 앱 내부 저장/재개, 사진 위에 그리기, 최소 레이어 기능이다.

## 검증 결과

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| 정적 분석 | 통과 | `flutter analyze` → `No issues found!` |
| 테스트 | 통과 | `flutter test` → `31 tests passed` |
| 작업 트리 | 깨끗함 | `git status --short` 출력 없음 |
| 핵심 화면 | 홈, 그리기, 설정, 프리미엄 | `lib/app/routes/app_pages.dart` |
| 실제 드로잉 기능 | 5종 브러시, 팔레트, 크기, undo/redo, 공유 | `lib/app/controllers/doodle_controller.dart`, `lib/app/pages/draw/draw_page.dart` |

## 출시 전 반드시 정리할 것

### P0. 스토어/문서와 실제 기능 불일치

현재 코드 기준으로 저장 갤러리, 히스토리, 통계 화면은 제거되어 있다. `lib/app/routes/app_pages.dart`에도 `/home`, `/draw`, `/settings`, `/premium`만 있다. 그런데 `README.md`, `docs/TODO.md`, `docs/store/google-ads-subscription.md`는 아직 PNG 저장, 앱 내 갤러리, 기록, 통계를 완료 기능처럼 설명한다.

출시 전에 둘 중 하나를 선택해야 한다.

1. 기능을 다시 넣는다: 최소 PNG 저장 + 앱 내 갤러리 + 다시 열기.
2. 기능을 넣지 않는다: 모든 스토어 문구와 README에서 저장/갤러리/기록/통계를 제거하고 "공유 중심"으로 정직하게 수정한다.

이건 단순 문서 문제가 아니라 Google Play 등록 문구, 스크린샷, 유저 기대치에 직접 영향을 준다. 현재 상태 그대로 출시하면 사용자가 "저장/갤러리가 있다더니 없다"고 느낄 가능성이 높다.

### P0. 그림 손실 방지 흐름

홈의 시작 버튼은 `DoodleController.to.clearCanvas()` 후 `/draw`로 이동한다. 그리기 화면에서 뒤로 나가면 현재 그림을 보존하거나 임시 저장하는 흐름이 없다. 현재 앱이 "빠른 낙서 후 공유"를 지향하더라도, 실수로 뒤로 가거나 앱이 백그라운드에서 종료될 때 그림이 사라지는 경험은 리뷰에 크게 악영향을 준다.

권장 최소안:

- 그리기 화면에서 `strokes.isNotEmpty`이면 뒤로가기 확인 바텀시트 표시.
- "계속 그리기", "버리고 나가기", "공유하기" 3개 행동 제공.
- 저장 기능을 넣는다면 "임시 저장 후 나가기"까지 제공.

### P0. 실제 출시 설정 확인

광고 ID는 `String.fromEnvironment`로 주입되고, 값이 비어 있으면 광고 로드를 건너뛰도록 되어 있다. 이 설계는 안전하지만 출시 빌드에서 `--dart-define`이 빠지면 광고가 조용히 비활성화된다.

출시 전 체크:

- `DOODLE_PAD_ADMOB_BANNER_ANDROID`
- `DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID`
- `DOODLE_PAD_ADMOB_REWARDED_ANDROID`
- Play Console 인앱 상품 3개 ID
- `android/app/src/main/AndroidManifest.xml`의 AdMob App ID
- 개인정보 처리방침 URL과 Play Data Safety 입력값
- 실제 기기에서 구매, 복원, 보상형 광고, 배너 숨김, 공유 플로우 확인

### P1. 구매 검증 수준

현재 `PurchaseService`는 구매 스트림과 과거 구매 조회 결과를 기준으로 바로 `isPremium.value = true`를 설정하고 Hive에 저장한다. `pendingCompletePurchase`가 있으면 `completePurchase()`도 호출한다. 앱 규모와 "후원형 1회 구매" 모델을 고려하면 MVP로는 이해 가능한 구조지만, 엄밀한 프로덕션 결제 검증은 아니다.

Google Play Billing 문서는 구매 혜택을 주기 전에 purchase token을 서버에서 검증하는 흐름을 권장한다. 백엔드 없이 출시한다면 적어도 리뷰 문서와 운영 체크리스트에 "클라이언트 검증 기반"이라는 리스크를 명시하는 편이 좋다.

참고: https://developer.android.com/google/play/billing/integrate, https://developer.android.com/google/play/billing/security

## 경쟁앱 대비 반드시 고려할 기능

조사 기준:

- Sketchbook: 레이어, 블렌드 모드, 커스터마이즈 브러시, 가이드/룰러, Predictive Stroke, symmetry, pressure/tilt를 강조한다.  
  https://play.google.com/store/apps/details?gl=US&hl=en&id=com.adsk.sketchbook
- ibis Paint X: 대량 브러시, 레이어 무제한, clipping, 사진 import, stroke stabilization, ruler/symmetry, 녹화, 벡터/애니메이션까지 제공한다.  
  https://play.google.com/store/apps/details?id=jp.ne.ibis.ibispaintx.app
- Concepts: infinite canvas, paper/grid, live smoothing, layers, reference image drag/drop, 다양한 export를 제공한다.  
  https://play.google.com/store/apps/details?id=com.tophatch.concepts
- Doodle Toy: 캐주얼/키즈 계열에서도 사진 위에 그리기, neon/rainbow/mirror effect, 저장/공유를 내세운다.  
  https://play.google.com/store/apps/details?hl=en&id=com.doodletoy
- Tayasui Sketches: realistic tools, layers, photo import, brush editor, color eyedropper, stylus support를 제공한다.  
  https://play.google.com/store/apps/details?hl=en&id=com.tayasui.sketches
- Drawing Desk: 학습형 드로잉 앱은 step-by-step lesson, fill bucket, shapes, symmetry, textures를 차별점으로 쓴다.  
  https://play.google.com/store/apps/details?hl=en-US&id=com.axis.drawingdesk.v3

| 기능 | 현재 Doodle Pad | 경쟁앱 기준 | 판단 |
| --- | --- | --- | --- |
| 빠른 자유 드로잉 | 있음 | 기본 기대 기능 | 충분 |
| 브러시 다양성 | 5종 | 상위 앱은 수십~수만 브러시 | MVP로 충분 |
| Undo/Redo | 있음, undo 20단계 | 기본 기대 기능 | 충분하지만 제한 문구 필요 |
| 직접 저장/갤러리 | 없음 | 캐주얼 앱도 저장/갤러리 제공 | 반드시 보강 또는 문구 제거 |
| 사진 위에 그리기 | 내부 상태 일부만 있음, UI 없음 | Doodle Toy/Tayasui/Concepts가 제공 | 강력 추천 |
| 레이어 | 없음 | Sketchbook/ibis/Concepts 핵심 기능 | P1 핵심 차별 보완 |
| 채우기/도형/대칭 | 없음 | Drawing Desk/Doodle Toy/Sketchbook이 제공 | P1~P2 |
| 스타일러스 pressure/tilt | 없음 | 전문 앱 핵심 | 태블릿 타겟이면 P1 |
| 캔버스 zoom/pan | 없음 | 드로잉 앱 기본 기대에 가까움 | P1 |
| 튜토리얼/템플릿 | 없음 | 학습형 앱 차별점 | P2 |

### 추천 우선순위

1. 앱 내부 저장/재개: 출시 전 가장 실사용 가치가 크다. 최소 구현은 "현재 캔버스를 PNG로 앱 내부에 저장하고 홈에서 최근 그림 3개를 보여주기"다.
2. 사진 위에 그리기: `referenceImagePath`와 `Image.file` 렌더링은 이미 일부 준비되어 있다. `image_picker` 또는 Android Photo Picker 진입점만 추가해도 경쟁앱 대비 체감 기능이 커진다.
3. 레이어 Lite: 전문 레이어 전체가 부담이면 `Background`, `Drawing`, `Sticker/Image` 정도의 2~3 레이어로 시작한다.
4. Fill bucket 또는 quick shapes: 어린이/캐주얼 유저에게는 브러시 수보다 "쉽게 예쁘게 완성되는 도구"가 더 잘 먹힌다.
5. 대칭/mirror 모드: 구현 난이도 대비 스토어 스크린샷에서 눈에 띄는 기능이다.

## 코드 품질 관찰

### 좋은 점

- `CanvasPainter`는 eraser가 있을 때만 `saveLayer`를 사용해 비용을 줄였다.
- 에어브러시 seed를 stroke에 고정해 repaint flicker를 막았다.
- 캔버스 캡처 시 8MP 제한으로 pixel ratio를 낮춰 OOM 리스크를 줄였다.
- AdMob은 UMP 동의 이후 `canRequestAds`가 true일 때만 로드하도록 되어 있다.
- Premium 활성 시 배너/보상형 광고 매니저를 정리하는 흐름이 있다.
- 테스트가 컨트롤러, 광고 초기화, 구매 복원, 홈/설정 일부 UI를 커버한다.

### 아쉬운 점

- `referenceImagePath`는 컨트롤러와 렌더러에 있지만 사용자 진입점이 없다. 경쟁앱 대비 바로 살릴 수 있는 기능인데 숨겨져 있다.
- `DrawPage` 위젯 테스트와 `CanvasPainter` 렌더링 테스트가 없다. 브러시, 지우개, share button enable/disable, toolbar overflow는 회귀 위험이 있다.
- `HiveService`의 `settings` box와 `SettingController`의 `doodle_settings_v1` box가 나뉘어 있다. 의도한 분리라면 문서화가 필요하고, 아니면 출시 전 단일화하거나 마이그레이션 규칙을 명확히 하는 것이 좋다.
- `README.md`, `docs/TODO.md`, `docs/store/google-ads-subscription.md`가 실제 코드와 많이 드리프트됐다.
- `RateMyAppConfig.APP_STORE_ID = '0000000000'`가 남아 있다. Android 우선이라 큰 문제는 아니지만, iOS 파일이 존재하는 저장소라 장기적으로는 오해 포인트다.

## 출시 전 QA 체크리스트

- 새 그림 시작 → 그리기 → 뒤로가기 → 그림 손실 안내 확인
- 빈 캔버스 공유 → 토스트 확인
- 긴 스트로크 100개 이상 → undo/redo, 지우개, 공유 성능 확인
- 수채화/에어브러시 무료 상태 → 광고 미준비/준비/보상 완료 상태 확인
- Premium 구매 후 → 배너 숨김, 특수 브러시 바로 선택, 구매 복원 확인
- 네트워크 오프라인 → 광고/구매/피드백/개인정보 링크 실패 안내 확인
- 한국어/영어/아랍어 → 홈, 설정, 프리미엄, 그리기 툴바 overflow 확인
- Android 13~15 실제 기기 → 공유 시트, 진동 권한, Ad ID, Billing 동작 확인

## 권장 마무리 순서

1. `README.md`, `docs/TODO.md`, `docs/store/google-ads-subscription.md`를 현재 코드 기준으로 정리한다.
2. 저장/갤러리를 넣을지, 공유 전용으로 갈지 결정한다. 출시 안정성 기준으로는 최소 저장 기능을 권장한다.
3. 그리기 화면 이탈 확인 또는 자동 임시 저장을 추가한다.
4. 사진 불러오기 버튼을 추가해 `referenceImagePath` 흐름을 실제 기능으로 연결한다.
5. DrawPage/CanvasPainter 회귀 테스트를 추가한다.
6. 실제 기기에서 광고, 구매, 공유, 다국어 UI를 확인한다.
7. Play Console 문구와 스크린샷을 실제 기능만 기준으로 최종 수정한다.

## 최종 판단

기능 구현 자체는 안정적으로 정리되어 있고 analyzer/test도 통과한다. 지금 가장 큰 리스크는 코드 품질보다 "사용자가 기대하는 드로잉 앱의 기본 저장 경험"과 "문서/스토어 문구 불일치"다. 출시를 서두른다면 저장/갤러리를 빼고 공유 전용으로 문구를 낮춰야 하고, 경쟁앱 대비 후회 없는 출시를 목표로 한다면 최소 저장/최근 그림/사진 위에 그리기까지는 넣는 편이 좋다.
