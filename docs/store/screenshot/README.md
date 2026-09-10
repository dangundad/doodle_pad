# Google Play 스토어 스크린샷 (영어 로케일)

> 촬영일: 2026-09-10
> 기기: Samsung SM-G781N (Android 13, 1080×2400, 480dpi) 실기기, `adb` 입력 주입
> 빌드: debug, `--dart-define=DOODLE_PAD_QA_LOCALE=en --dart-define=DOODLE_PAD_QA_SEED_ARTWORKS=true`
> 상태: 광고 배너를 숨기려고 촬영 중 Wi-Fi/모바일 데이터를 껐다(배너는 로드 실패 시 `SizedBox.shrink`). 촬영 후 복원.

Play Console 요구사항(9:16 이상, 최소 320px, 최대 3840px)을 만족하는 원본 1080×2400 PNG다. 그대로 업로드하거나 프레임/캡션을 얹어 쓰면 된다.

## 파일 목록

| 파일 | 화면 | 시나리오 (더미 데이터) | 스토어 캡션 제안 |
| --- | --- | --- | --- |
| `01_draw_canvas.png` | 그리기 화면 | 보관함에서 "Sunset Lake" 작품(수채화 하늘 + 마커 태양 + 만년필 산 + 붓 물결 + 형광펜 반사)을 열고 최근 색상 선택 상태 | Draw with 10 realistic brushes |
| `02_brushes.png` | 브러시 시트 | 위 작품 위에서 브러시 10종 시트(마커 선택, 워터컬러/에어브러시 잠금 배지) | Pen, pencil, marker, watercolor, airbrush & more |
| `03_color_palette.png` | 색상 시트 | 기본 팔레트 16색 + 커스텀 피커 진입 버튼 | Pick any color |
| `03b_color_wheel.png` | 리치 컬러 피커 | Custom 탭: 컬러휠 + 명암 단계 + HEX(`#3B82C4`) + 최근 색상 | Color wheel, shades and HEX |
| `04_gallery.png` | 내 작품 보관함 | 작품 8점 그리드(날짜 2026.09.03~09.10로 분산, 다크 캔버스 1점 포함) | Keep every doodle in your gallery |
| `05_save_options.png` | 갤러리 저장 시트 | 해상도 1x/2x/3x + PNG/JPEG 선택 | Export up to 3x Ultra HD |
| `06_more_actions.png` | 더보기 시트 | 캔버스 색상 / 사진 불러오기 | Draw over your photos |
| `07_canvas_color.png` | 캔버스 색상 시트 | 프리셋 7종 + 커스텀 피커 | Choose your paper |
| `08_home.png` | 홈 허브 | 최근 작품 3장 종이 묶음 히어로 + 기능 칩 + 보관함 카운트 8 | — |
| `09_premium.png` | 프리미엄 | 후원 옵션 3종(Lunch 선택, Popular 배지) + 혜택 목록 | Go ad-free, unlock premium brushes |
| `10_settings.png` | 설정 | 토글 4종 + 11개 언어 칩 | Available in 11 languages |
| `11_gallery_select.png` | 보관함 선택 모드 | 2점 선택, 공유/삭제 액션 바 | Share or delete in bulk |
| `12_draw_dark_canvas.png` | 그리기 화면(다크 캔버스) | "City Lights" 작품(남색 캔버스 + 흰 펜 건물 + 형광펜 창 + 에어브러시 은하수) — 상태바 아이콘 밝기 반전 확인 | Dark canvases too |

권장 업로드 순서: 01 → 02 → 12 → 04 → 03b → 06 → 05 → 09 (최대 8장).

## 더미 데이터 생성 방식

작품은 손으로 그리지 않고 `lib/app/utils/store_screenshot_seed.dart`가 앱 시작 시 프로그램으로 생성한다.

- `--dart-define=DOODLE_PAD_QA_SEED_ARTWORKS=true`일 때만 동작하며, 상수 폴딩으로 일반 빌드에서는 코드가 제거된다.
- 보관함(`drawings` Hive box)을 비운 뒤 8점을 `ArtworkRepository.save`(실제 저장 경로)로 넣고, 썸네일은 앱과 같은 `CanvasPainter`로 3x 렌더한다. 따라서 보관함에서 열면 실제 stroke가 캔버스에 복원되어 그대로 편집 가능하다.
- 작품 설계 캔버스는 360×800dp(DrawPage 전체 화면). 상/하단 툴바에 가리지 않도록 중심 기준 0.88배 축소 + 30dp 상향 보정한다.
- 생성일은 하루 간격으로 과거로 분산하고(보관함 날짜 표시), 최근 브러시(마커/붓/크레용/펜)와 최근 색상 5종도 함께 심어 하단 툴바가 채워져 보이게 한다.
- 작품 8점: Sunset Lake, Spring Bloom, After the Rain(무지개), City Lights(다크 캔버스), Balloons(수채화 하트), Mochi the Cat(연필 스케치), Swirl Study(크림 캔버스 + 에어브러시), My Home(크레용 어린이 낙서).

## 재촬영 절차

```bash
# 1) 실행 (영어 + 시드)
flutter run -d <serial> --dart-define=DOODLE_PAD_QA_LOCALE=en --dart-define=DOODLE_PAD_QA_SEED_ARTWORKS=true

# 2) 광고 배너 숨김 (촬영 후 반드시 enable로 복원)
adb shell svc wifi disable && adb shell svc data disable

# 3) 캡처
adb exec-out screencap -p > docs/store/screenshot/<name>.png
```

주의: `flutter run`을 다시 띄워도 이미 실행 중인 프로세스는 재시작되지 않아(`am start`가 기존 액티비티를 앞으로만 가져옴) 옛 코드가 그대로 도는 경우가 있었다. 시드 코드를 바꿨다면 `adb shell am force-stop com.dangundad.doodlepad` 후 `am start -n com.dangundad.doodlepad/.MainActivity`로 새 프로세스를 띄우고 logcat에서 `[StoreScreenshotSeed] seeded 8 artworks`를 확인한다.

## 촬영 중 발견한 UI 메모

- 그리기 화면 "Discard drawing?" 다이얼로그의 취소 버튼 라벨 `keep_drawing`('Keep drawing')이 360dp 폭에서 `Keep drawi…`로 잘린다. 스토어 스크린샷에는 포함하지 않았지만 출시 전 라벨 단축(예: 'Keep') 또는 버튼 폭 조정이 필요하다.
