# Doodle Pad - TODO

> 마지막 갱신: 2026-05-16
> 정직성 정책: 코드에 없는 기능은 "구현 완료"로 적지 않는다. 의심되면 `lib/app/routes/app_pages.dart`와 `pubspec.yaml`을 확인.

## 컨셉

가볍게 그리고, 저장하고, 다시 열어 이어 그리는 캐주얼 드로잉 앱. 그린 결과는 기기 갤러리에 PNG/JPEG로 내보내거나 Android 공유 시트로 보낼 수 있고, **앱 내 작품 보관함**에 strokes·배경색·참조 사진과 함께 저장해 언제든 다시 열어 편집할 수 있다. 사용자 데이터는 모두 기기 로컬(Hive)에만 보관되며 서버로 업로드되지 않는다.

## 구현 완료 기능 (코드 기준)

- [x] 10종 브러시 (펜, 연필, 마커, 붓, 형광펜, 만년필, 크레파스, 수채화, 에어브러시, 지우개)
- [x] `perfect_freehand` 기반 가변 굵기 stroke 엔진 + `BrushPreset` 데이터 객체로 통일
- [x] BrushPreset 신규 brush 추가 비용 ≤ 30줄 (registry 항목 1개 추가)
- [x] 지우개: 필요한 경우에만 `saveLayer` + `BlendMode.clear` 적용 (성능 최적화)
- [x] 수채화/에어브러시 보상형 광고 해금 (Hive 저장)
- [x] 16색 팔레트 + 커스텀 컬러 피커 슬롯
- [x] 캔버스 배경 색상 6종 프리셋
- [x] 브러시 크기 조절 슬라이더
- [x] Undo/Redo (최대 20단계)
- [x] Bezier 곡선 스무딩 + 에어브러시 고정 seed
- [x] 멀티터치 방어 (`startStroke`에서 진행 중 stroke 정리)
- [x] 핀치 줌/팬 (InteractiveViewer) + 더블탭 Fit-to-screen
- [x] 캔버스 캡처 시 8MP 픽셀 예산으로 동적 ratio 조절 (OOM 방어)
- [x] 기기 갤러리 저장: PNG 또는 **실제 JPEG 인코딩**(image 패키지), 1x/2x/3x 해상도
- [x] PNG 임시 캡처 후 share_plus로 공유
- [x] 갤러리 사진을 참조 이미지로 불러와 그 위에 그리기
- [x] **앱 내 작품 보관함(GalleryPage)**: strokes·배경색·참조 사진과 함께 Hive 저장, 2열 그리드, 다중 선택 삭제, 100개 초과 경고
- [x] **참조 사진 영속 복사**: 저장 시 app support `references/` 디렉터리로 복사, 삭제 시 함께 정리
- [x] **작품 ID 충돌 방어**: timestamp + base36 random suffix
- [x] 갤러리에서 작품 열기 시 현재 작업물 손실 방어 다이얼로그
- [x] 그리기 화면 이탈 시 작업물 보존 확인 다이얼로그 (PopScope + 뒤로가기 버튼)
- [x] 홈 시작 버튼: 이전 그림이 있으면 이어 그리기/새로 시작 다이얼로그 (탈출 가능)
- [x] **흔들어 지우기**: 설정 토글, 가속도계 임계값 + 디바운스, 확인 다이얼로그 경유
- [x] 햅틱 피드백 (selection/light/medium/heavy)
- [x] GetX 상태 관리 + 라우팅 (home, draw, gallery, settings, premium)
- [x] Hive_CE 로컬 저장 (설정 / 해금 상태 / Premium 상태 / `Drawing` 작품)
- [x] AdMob 배너 + 보상형 + 미디에이션 (UMP 동의 후 로드)
- [x] **광고 매니저 Premium 가드**: `loadAd()` 진입부에 `PurchaseService.isPremiumActive` 체크 (race 방지)
- [x] **AdMob 환경변수 누락 경고**: 릴리스 빌드에서 `--dart-define` 누락 시 debugPrint 가시화
- [x] 1회 후원형 Premium (Small/Medium/Large) + 구매 복원
- [x] Premium 활성 시 배너/보상형 광고 매니저 정리
- [x] 11개 언어 다국어 (en, ko, ja, de, ru, fr, es, pt, id, zh, ar) + 키 일관성 자동 테스트
- [x] FlexColorScheme 기반 Material 3 테마
- [x] 종료 바텀시트
- [x] 컨트롤러/광고/구매/홈/갤러리/설정/테마/유틸/믹스인 단위 + 위젯 테스트 (94 passed)

## 코드에 존재하지 않으므로 README/스토어 문구에서 제외 대상

- 활동 기록 / 통계 화면
- 활동 로그 서비스
- 하단 내비게이션
- 클라우드 동기화
- iOS 전용 추가 기능 (Android 우선 정책)

## 출시 전 남은 작업

- [ ] AdMob 운영 광고 단위 ID를 `--dart-define`으로 주입한 빌드 검증
- [ ] Play Console 인앱 상품 3개 등록 (`doodle_pad_premium_small/medium/large`)
- [ ] AndroidManifest의 AdMob App ID 운영값 확인
- [ ] 앱 아이콘 / 스플래시 최종본 적용 (`flutter_launcher_icons`, `flutter_native_splash`)
- [ ] Privacy Policy URL 확정 + Play Data Safety 입력
- [ ] 실제 Android 13~15 기기에서 공유, 사진 불러오기, 광고, 구매 복원 흐름 확인
- [ ] 한국어/영어/아랍어 RTL UI 오버플로 확인
- [ ] 결제 검증 정책 메모: 현재는 클라이언트 측 검증 기반 (서버 검증 없음). 운영 위험 한계를 README와 docs/store/google-ads-subscription.md에 명시 유지
- [ ] 대량 stroke 환경에서의 메모리 사용량 모니터링
- [ ] ProGuard 규칙 확인 (릴리스 빌드 시점)

## 1.0.1 Carry Items (review_claude.md / review_codex.md 결과)

### Major
- [ ] Google Play Billing 영수증 서명 검증 도입 (서버 또는 클라이언트 BillingClient)
- [ ] `drawing.dart` `pointsXY.length.isEven` 검증 + 손상 데이터 복구
- [ ] `doodle_controller.dart` `continueStroke` 리페인트 최적화 (옵저버 분리)
- [ ] Gallery 그리드 `SliverGridDelegateWithMaxCrossAxisExtent` 전환 (태블릿/폴더블 대응)
- [ ] ExitBottomSheet 프리미엄 배너 노출 빈도 제한
- [ ] PremiumPage 구매 버튼 고정 높이 (레이아웃 떨림 방지)

### Minor
- [ ] BrushPreset `stableId` 마이그레이션 완료 (enum index 의존 제거)
- [ ] HiveService partial recovery (3개 box 중 하나 손상 시 개별 복구)
- [ ] AppBinding 의존성 등록 단일 진입점 통합
- [ ] 접근성 Semantics label + 색맹 대응(아이콘 형태 차이)
- [ ] AndroidManifest `HIGH_SAMPLING_RATE_SENSORS` 명시 검토
- [ ] Gallery 삭제 버튼 label을 `clear` 재사용에서 별도 `delete` 키로 분리

## 차기 검토 후보 (출시 차단 아님)

- 채우기 / 도형 / 대칭 모드 등 캐주얼 도구 추가
- 레이어 Lite (배경/그림/사진 3층)
- 작품 임시 저장 (앱 재진입 시 복원)
- DrawPage / CanvasPainter 위젯 / 골든 테스트
- iOS App Store 출시 시 App Store ID 입력 + iOS Restore 흐름 구현
