# 앱 이름 ASO 현지화

확인일: 2026-09-17

## 적용 원칙

- Google Play 앱 이름은 로케일별 최대 30자이며, 현지 언어 제목을 각각 등록할 수 있다.
- 런처 이름은 홈 화면에서 잘리지 않도록 짧게 유지하고, 스토어 제목은 `그림판 + 현지 검색 범주어` 조합으로 구성한다.
- 경쟁 앱 이름을 그대로 복제하지 않고 앱의 실제 핵심 경험인 간단한 그림판, 빠른 스케치와 낙서를 정확히 설명한다.
- 같은 키워드의 과도한 반복, 순위·가격 표현, 다른 제품과의 관계를 오인하게 하는 표현은 사용하지 않는다.

런처 이름 정본: `lib/app/translate/translate.dart`의 `app_name`, `android/app/src/main/res/values*/strings.xml`
스토어 제목 정본: `android/fastlane/metadata/android/<locale>/title.txt`

공식 기준: [Google Play 앱 설정(제목 30자 및 로케일별 이름)](https://support.google.com/googleplay/android-developer/answer/9859152), [스토어 등록정보 권장사항](https://support.google.com/googleplay/android-developer/answer/13393723), [Google Play 검색 노출 권장사항](https://support.google.com/googleplay/android-developer/answer/4448378)

## 경쟁 앱에서 확인한 현지 범주어

| 시장 | 경쟁 앱 예시 | 확인한 범주어 | 반영 방향 |
|---|---|---|---|
| 글로벌 | [Doodle Pad - Sketch Draw](https://play.google.com/store/apps/details?id=com.doodlepad.app&hl=en), [SketchPad - Doodle Drawing Pad](https://play.google.com/store/apps/details?id=com.logicworklab.sketchpad.doodle.drawing.pad&hl=en), [Simple Drawing - Sketchbook](https://play.google.com/store/apps/details?id=com.simplemobiletools.draw&hl=en) | Doodle Pad, Drawing Pad, Sketch, Draw | 브랜드 `Doodle Pad`에 `Draw & Sketch`를 붙여 용도를 즉시 전달 |
| 한국 | [드로잉 패드](https://play.google.com/store/apps/details?id=jp.razuma.drawingbook&hl=ko), [간단한 그리기](https://play.google.com/store/apps/details?id=com.simplemobiletools.draw&hl=ko), [그림 그리기 - 스케치](https://play.google.com/store/apps/details?id=com.yys.drawingboard&hl=ko) | 그림판, 그리기, 스케치, 낙서 | 외래어 `드로잉 패드` 대신 검색량이 큰 `그림판`을 런처·제목에 사용 |
| 일본 | [おえかき帳](https://play.google.com/store/apps/details?id=jp.razuma.drawingbook&hl=ja), [Let's Draw お絵かき お絵描き 落書きアプリ](https://play.google.com/store/apps/details?id=com.urecy.tool.letsdraw&hl=ja) | お絵かき, 落書き, スケッチ | 한자 `描画`보다 친숙한 가나 표기 `お絵かき`를 사용 |
| 독일·러시아 | [Zeichenblock](https://play.google.com/store/apps/details?id=jp.razuma.drawingbook&hl=de), [Блокнот для рисования](https://play.google.com/store/apps/details?id=jp.razuma.drawingbook&hl=ru), [Простое рисование](https://play.google.com/store/apps/details?id=com.simplemobiletools.draw&hl=ru) | Zeichenblock, Skizzen, рисование, скетчи | 현지의 그림판 범주어를 그대로 런처 이름으로 채택 |
| 프랑스·스페인·포르투갈 | [Carnet à croquis - Dessin](https://play.google.com/store/apps/details?id=com.raed.drawing&hl=fr), [Bloc de bocetos - dibujos](https://play.google.com/store/apps/details?id=com.zxaeclub.codebyanju.project.drawingpadpro&hl=es), [Desenho Fácil Pintar Rabiscar](https://play.google.com/store/apps/details?id=com.desenho_facil&hl=pt) | Bloc dessin, Croquis, Bocetos, Esboços | 영어 고정 제목을 제거하고 현지 그림·스케치 용어 사용 |
| 인도네시아 | [Corat Coret](https://play.google.com/store/apps/details?id=com.corat.coret&hl=id), [Buku Gambar Dan Mewarnai](https://play.google.com/store/apps/details?id=com.hybrid.Menggambar_dan_mewarnai&hl=id) | Gambar, Sketsa, Coret | 런처와 제목 모두 현지어 `Gambar Mudah`로 통일 |
| 중국어 | [绘图板](https://play.google.com/store/apps/details?id=jp.razuma.drawingbook&hl=zh), [画板涂鸦](https://play.google.com/store/apps/details?id=com.thjh.drawing.board&hl=zh), [简单绘图](https://play.google.com/store/apps/details?id=com.simplemobiletools.draw&hl=zh) | 画板, 涂鸦, 绘画, 速写 | `简易画板`으로 간결함과 범주를 동시에 표현 |
| 아랍어 | [لوحة الرسم - تطبيق الرسم](https://play.google.com/store/apps/details?id=com.zxaeclub.codebyanju.project.drawingpadpro&hl=ar), [Drawing Desk:رسم, تلوين, خربشة](https://play.google.com/store/apps/details?id=com.axis.drawingdesk.v3&hl=ar) | الرسم, لوحة الرسم, اسكتشات | 현지 검색 범주어 `الرسم السهل`로 쉬운 그림판임을 명시 |

## 핸드폰에 표시될 앱 이름

```jsonc
{
  "app_name": {
    "en": "Doodle Pad",      // 기본 브랜드명
    "ko": "간단 그림판",        // 한국어 범주명
    "ja": "かんたんお絵かき",     // 일본어 범주명 (가나 표기)
    "de": "Zeichenblock",    // 독일어 합성어
    "ru": "Рисуй легко",     // 짧고 자연스러운 러시아어 표기
    "fr": "Bloc dessin",     // 프랑스어 어순
    "es": "Dibujo Fácil",    // 스페인어 어순
    "pt": "Tela Fácil",      // 포르투갈어 어순
    "id": "Gambar Mudah",    // 영어 Draw 대신 현지어 사용
    "zh": "简易画板",           // 간체 중국어 범주명
    "ar": "الرسم السهل"       // 아랍어 어순
  }
}
```

## 구글 스토어 타이틀 (최대 30자)

```jsonc
{
  "google_play_store_title": {
    "en": "Doodle Pad - Draw & Sketch",     // 26자
    "ko": "간단 그림판 - 그리기와 스케치",        // 17자
    "ja": "かんたんお絵かき - スケッチ",           // 15자
    "de": "Zeichenblock - Skizzen",         // 22자
    "ru": "Рисуй легко - Скетчи",           // 20자
    "fr": "Bloc dessin - Croquis",          // 21자
    "es": "Dibujo Fácil - Bocetos",         // 22자
    "pt": "Tela Fácil - Esboços",           // 20자
    "id": "Gambar Mudah - Sketsa",          // 21자
    "zh": "简易画板 - 绘画速写",                 // 11자
    "ar": "الرسم السهل - اسكتشات"            // 21자
  }
}
```
