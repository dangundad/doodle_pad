# Doodle Pad - TODO

> 마지막 갱신: 2026-05-08
> 정직성 정책: 코드에 없는 기능은 "구현 완료"로 적지 않는다. 의심되면 `lib/app/routes/app_pages.dart`와 `pubspec.yaml`을 확인.

## 컨셉

가볍게 그리고 바로 공유하는 캐주얼 드로잉 앱. 앱 내부 영구 저장이나 갤러리는 제공하지 않는다. 사용자가 공유 시트를 통해 자신이 원하는 앱(메신저, 사진앱 등)으로 직접 보내 보존한다.

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
- [x] 캔버스 캡처 시 8MP 픽셀 예산으로 동적 ratio 조절 (OOM 방어)
- [x] PNG 임시 캡처 후 share_plus로 공유
- [x] 갤러리 사진을 참조 이미지로 불러와 그 위에 그리기
- [x] 그리기 화면 이탈 시 작업물 보존 확인 다이얼로그 (PopScope + 뒤로가기 버튼)
- [x] 홈 시작 버튼: 이전 그림이 있으면 이어 그리기/새로 시작 다이얼로그
- [x] 햅틱 피드백 (selection/light/medium/heavy)
- [x] GetX 상태 관리 + 라우팅 (home, draw, settings, premium)
- [x] Hive_CE 로컬 저장 (설정과 해금 상태, Premium 상태만)
- [x] AdMob 배너 + 보상형 + 미디에이션 (UMP 동의 후 로드)
- [x] 1회 후원형 Premium (Small/Medium/Large) + 구매 복원
- [x] Premium 활성 시 배너/보상형 광고 매니저 정리
- [x] 11개 언어 다국어 (en, ko, ja, de, ru, fr, es, pt, id, zh, ar)
- [x] FlexColorScheme 기반 Material 3 테마
- [x] 종료 바텀시트
- [x] 컨트롤러/광고/구매/홈/설정/테마/유틸 단위 + 위젯 테스트

## 코드에 존재하지 않으므로 README/스토어 문구에서 제외 대상

- 앱 내부 PNG 영구 저장
- 앱 내 갤러리 / 다시 불러오기 화면
- 활동 기록 / 통계 화면
- 활동 로그 서비스
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

## 차기 검토 후보 (출시 차단 아님)

- 채우기 / 도형 / 대칭 모드 등 캐주얼 도구 추가
- 레이어 Lite (배경/그림/사진 3층)
- 캔버스 zoom/pan
- 작품 임시 저장 (앱 재진입 시 복원)
- DrawPage / CanvasPainter 위젯 / 골든 테스트
