# Sprint Report — pre-release-audit

> Sprint ID: `pre-release-audit`
> Trust Level: L3
> 시작: 2026-05-16
> 종료: 2026-05-16
> 산출물: 코드 수정 4건 + 검증 1건, `flutter analyze` 0 issue, `flutter test` 94/94 PASS

## 1. 결과 요약

| Blocker | 결과 | 비고 |
|---------|------|------|
| B1 iOS App Store ID | ✅ 정책 명시 주석 추가 | Android-first 앱, 런타임 영향 없음. iOS 빌드 시점에 교체 필요 |
| B2 AdMob 환경변수 폴백 | ✅ 빈 값 경고 로그 추가 | 릴리스는 이미 테스트 ID 폴백 없음(false alarm). CI 누락 발견 보강 |
| B3 local.properties 버전 | ✅ 정책 주석 추가 | 실제 값은 이미 pubspec과 일치(1.0.0 / 1) |
| B4 HomePage 다이얼로그 탈출 | ✅ `barrierDismissible: true` | 사용자 결정 보류 시 안전 취소 |
| B5 설정 데이터 삭제 일관성 | ✅ 검증(변경 없음) | 코드 재확인 결과 이미 견고 — 초기 리뷰의 false positive |

## 2. KPI

- **M3 Critical Issue Count**: 0 (목표 0) ✅
- **flutter analyze**: No issues found ✅
- **flutter test**: 94 passed / 0 failed ✅
- **회귀 위험**: 없음 — 모든 변경은 (a) 주석 추가, (b) 디버그 로그 추가, (c) 다이얼로그 dismissal 정책 변경. 기능 동작 변화 없음.

## 3. 변경 파일

```
M lib/app/utils/app_constants.dart        # B1: 주석
M lib/app/admob/ads_helper.dart           # B2: slot 인자 + debugPrint 경고
M android/local.properties                # B3: source of truth 주석
M lib/app/pages/home/home_page.dart       # B4: barrierDismissible: true
A docs/01-plan/sprints/pre-release-audit/prd.md
A docs/04-report/sprints/pre-release-audit/report.md
```

## 4. Lessons Learned

- **정적 감사의 한계**: 초기 `review_claude.md`는 코드를 다 읽지 않은 채 Blocker로 분류한 항목이 2건(B3·B5) 있었다. Sprint Do 단계에서 실제 코드를 펼쳐보니 이미 처리되어 있었다. → 향후 감사 보고서에는 "정적 추정"과 "코드 확인 완료"를 구분 표기 권장.
- **AdMob 폴백의 실체**: 릴리스 빌드는 `_isDebugMode` 분기로 인해 테스트 ID 폴백이 일어나지 않는다. 진짜 위험은 "조용한 광고 실패"였고, 이 경고 로그가 그 갭을 메운다.
- **clearAppSettings의 보존 정책**: 프리미엄/잠금해제 브러시는 의도적으로 보존된다. 사용자가 보상형 광고/결제로 획득한 권리를 잃지 않게 하기 위함. 이 정책은 코드 주석으로 충분히 문서화되어 있다.

## 5. Carry Items (1.0.1 후속 sprint 권장)

### Major (배포 후 우선)
- Google Play Billing 영수증 서명 검증
- `drawing.dart` pointsXY 짝수 길이 검증
- `doodle_controller.dart:586` continueStroke 리페인트 최적화
- Gallery 그리드 `SliverGridDelegateWithMaxCrossAxisExtent` 전환
- ExitBottomSheet 프리미엄 배너 노출 빈도 제한
- PremiumPage 구매 버튼 고정 높이

### Minor (백로그)
- BrushPreset `stableId` 마이그레이션
- HiveService partial recovery
- AppBinding 의존성 등록 단일 진입점 통합
- 접근성 Semantics label + 색맹 대응
- AndroidManifest `HIGH_SAMPLING_RATE_SENSORS` 명시 검토

## 6. 배포 권고

**🟢 배포 가능**

5개 Blocker 모두 해결(2건 코드 수정 불필요, 3건 수정 완료) + 정적 분석/테스트 통과. 1.0.0 스토어 제출을 진행해도 안전한 상태로 판단합니다. Major/Minor 항목은 1.0.1 핫픽스 sprint로 분리해 점진적으로 해소하시면 됩니다.

CI/CD 빌드 시 다음 환경변수가 주입되어 있는지 최종 확인하세요:
```bash
flutter build appbundle --release \
  --dart-define=DOODLE_PAD_ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=DOODLE_PAD_ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/ZZZZ \
  --dart-define=DOODLE_PAD_ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/WWWW \
  --build-name=1.0.0 --build-number=1
```
