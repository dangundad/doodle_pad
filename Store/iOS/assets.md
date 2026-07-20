# App Store 이미지·접근성 계획

## 필수 이미지 규격

- iPhone: 1~10장, JPG/JPEG/PNG, 투명도 없음. 대표 세트는 6.9인치 세로 `1320 × 2868px` 또는 Apple이 허용하는 다른 6.9인치 규격을 사용합니다.
- iPad 13인치: 세로 `2064 × 2752px` 또는 `2048 × 2732px`.
- 현재 Xcode 설정이 iPad를 포함하므로 13인치 iPad 세트도 필수입니다. iPad를 지원하지 않을 계획이면 바이너리 지원 기기 설정을 먼저 변경하고 기능 QA를 다시 합니다.
- App Preview는 선택이며 로케일·기기 크기당 최대 3개입니다.
- 1024px 마케팅 아이콘은 Xcode asset catalog 또는 Icon Composer로 빌드에 포함하고 실제 Archive에서 확인합니다.

## 앱별 스크린샷 스토리보드

| 순서 | 한국어 오버레이 | 영어 오버레이 | 촬영 내용 |
|---|---|---|---|
| 1 | 펜·연필·마커·수채화 등 열 가지 브러시 | Draw with ten brush styles | 실제 앱 화면과 기능 결과 |
| 2 | 색상·크기·배경과 실행 취소·다시 실행 | Adjust color, size, background, undo, and redo | 실제 앱 화면과 기능 결과 |
| 3 | 사진 위에 그리기 | Sketch over a photo you choose | 실제 앱 화면과 기능 결과 |
| 4 | PNG·JPEG 저장, 공유, 다시 열기 | Save PNG or JPEG, share, and reopen artwork | 실제 앱 화면과 기능 결과 |

제작 원칙:

- 첫 3장이 핵심 가치, 사용 흐름, 결과를 설명하도록 배치합니다.
- Android 상태바, 내비게이션, 빠른 설정, Play 배지, Android 전용 위젯을 넣지 않습니다.
- 기능이 아직 iOS에서 동작하지 않으면 모형 화면을 올리지 말고 구현·실기기 QA 후 촬영합니다.
- 모든 로케일에서 실제 제공하는 기능만 설명하고 작은 글자도 읽을 수 있게 만듭니다.

## 접근성 영양성분표 QA

iOS 26에서는 제품 페이지에 접근성 섹션이 표시됩니다. 현재는 자발적 입력이지만 미응답도 “지원 정보 미제공”으로 보입니다.

- [ ] VoiceOver로 첫 실행, 핵심 기능, 설정, 구매를 완료
- [ ] Voice Control의 표시 이름과 접근성 라벨 일치
- [ ] Larger Text 200%에서 잘림·겹침 없음
- [ ] Dark Interface의 모든 주요 화면 확인
- [ ] 색상 외의 텍스트·모양으로 상태 구분
- [ ] 텍스트 4.5:1 수준 등 충분한 대비
- [ ] Reduce Motion 활성화 시 불필요한 동작 축소
- [ ] 광고가 핵심 작업의 접근성을 막지 않음

검증을 통과한 항목만 App Store Connect의 App Accessibility에 게시합니다.

## 공식 근거

- [스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
