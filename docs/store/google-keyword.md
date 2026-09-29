# Doodle Pad 스토어 키워드 (ASO) 정의서 (정본)

이 문서는 Doodle Pad App Store 키워드의 **정본(Source of Truth)**입니다.
`./store.sh ios init-docs` 또는 `./store.sh ios create` 명령어를 실행할 때 이 문서를 참조하여 `apple-store.md`의 키워드를 자동으로 생성합니다.

### ⚠️ App Store 키워드 작성 규칙:
1. **글자수 제한**: 각 언어별 **최대 100자** (쉼표 포함, 공백 없이 쉼표로만 구분 권장)
2. **중복 금지**: 앱 이름(Title) 및 부제(Subtitle)에 이미 사용된 단어는 심사 시 자동 검색되므로 제외 (100자 공간 절약)
3. **쉼표 구분**: 단어 또는 구문 단위로 쉼표(`,`)로 구분 (공백 대신 쉼표만 쓰는 것이 글자수 절약에 유리)

{
  "keywords": {
    "en": "freehand,drawing,pen,pencil,marker,crayon,airbrush,watercolor,highlighter,whiteboard,scribble",  // 영어 - 미국 (en-US)
    "ko": "손그림,밧줄,펜,연필,마커,크레파스,에어브러시,수채화,형광펜,공책,낙서,캔버스,그림공부,일기,필기체,색칠하기,작품첩,메모",  // 한국어 (ko)
    "ja": "落書き,ペン,鉛筆,マーカー,クレヨン,エアブラシ,絵の具,蛍光ペン,手描き,落書き帳,線画,イラスト,メモ帳,色塗り,練習,無料,広告なし",  // 일본어 (ja)
    "zh": "涂鸦,画图,铅笔,马克笔,蜡笔,喷枪,水彩,荧光笔,手绘,画册,线稿,插画,记事本,上色,练习,免费,无广告,儿童绘画,涂色书,美术,安全",  // 중국어 번체 (zh-Hant)
    "de": "Malen,Malspiel,Stift,Bleistift,Marker,Kreide,Aquarell,Filzstift,Malbuch,Zeichnen,Finger,Farbe",  // 독일어 (de-DE)
    "fr": "Coloriage,Stylo,Crayon,Marqueur,Feutre,Aquarelle,Pinceau,Main,Colorier,Peinture,Cahier",  // 프랑스어 (fr-FR)
    "es": "Dibujar,Colorear,Lápiz,Marcador,Cera,Pincel,Acuarela,Pintura,Paleta,Cuaderno,Pintar,Arte",  // 스페인어 (es-ES)
    "pt": "Desenhar,Colorir,Lápis,Marcador,Cera,Pincel,Aquarela,Pintura,Paleta,Caderno,Desenho,Arte,Sketch",  // 포르투갈어 - 브라질 (pt-BR)
    "ru": "Рисование,Карандаш,Ручка,Маркер,Воск,Акварель,Фломастер,Кисть,Тетрадь,Альбом,Раскраска,Живопись",  // 러시아어 (ru)
    "id": "Menggambar,Mewarnai,Pensil,Spidol,Crayon,Kuas,Cat Air,Stabilo,Alat Tulis,Coretan,Kreatif,Anak",  // 인도네시아어 (id)
    "ar": "تلوين,قلم,ألوان,طباشير,فرشاة,مائية,دفتر,ألواح,مبتدئين,إبداع,فنون,ممحاة,ورق,تخطيط,أشكال"  // 아랍어 (ar-SA)
  }
}
