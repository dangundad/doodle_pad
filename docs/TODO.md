# Doodle Pad - TODO

## 구현 완료 기능

- [x] 5종 브러시 (펜, 마커, 지우개, 수채화, 에어브러시)
- [x] 브러시별 너비 배율 (펜 1x, 마커 2.5x, 지우개 4x, 수채화 2x, 에어브러시 1x)
- [x] 지우개: BlendMode.clear + canvas.saveLayer() 패턴
- [x] 수채화/에어브러시 보상형 광고 해금 (Hive 저장)
- [x] 16색 팔레트 (DoodleController.colorPalette)
- [x] 브러시 크기 조절
- [x] Undo/Redo (최대 20단계)
- [x] 캔버스 저장 (PNG, 앱 문서 디렉토리)
- [x] 갤러리 페이지 (저장된 그림 목록, 삭제)
- [x] 이미지 공유 (share_plus, RepaintBoundary 캡처)
- [x] Bezier 곡선 스무딩 (단일 점: drawCircle, 복수 점: quadratic bezier)
- [x] 에어브러시 고정 seed (리페인트 시 패턴 안정성)
- [x] 멀티터치 방어 (startStroke에서 기존 스트로크 제거)
- [x] 햅틱 피드백 (selection/light/medium/heavy)
- [x] GetX 상태 관리 + 라우팅
- [x] Hive_CE 로컬 저장
- [x] AdMob 광고 (배너 + 전면 + 보상형) + 미디에이션
- [x] 인앱 구매 (프리미엄 광고 제거)
- [x] 다국어 지원 (ko)
- [x] FlexColorScheme 테마 (pinkM3)
- [x] 설정 페이지
- [x] 통계 페이지
- [x] 활동 로그 서비스

## 출시 전 남은 작업

- [ ] AdMob 실제 광고 ID 교체 (현재 테스트 ID)
- [ ] 인앱 구매 상품 ID 등록 (Google Play Console)
- [ ] 앱 아이콘 제작 및 적용 (`dart run flutter_launcher_icons`)
- [ ] 스플래시 화면 제작 및 적용 (`dart run flutter_native_splash:create`)
- [ ] Google Play 스토어 등록 (스크린샷, 설명, 카테고리)
- [ ] Apple App Store 등록
- [ ] 다국어 확장 (en, ja 등)
- [ ] Privacy Policy 페이지 작성
- [ ] ProGuard 규칙 확인 (릴리스 빌드)
- [ ] Firebase Crashlytics 설정 확인
- [ ] 대량 스트로크 시 메모리 사용량 모니터링 (OOM 방지)
- [ ] 앱 백그라운드 진입 시 진행 중 드로잉 손실 방지 확인
- [ ] 저장 파일 손상/권한 거부 시 사용자 안내 강화
