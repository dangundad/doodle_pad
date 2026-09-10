# Doodle Pad App Store Connect 신규 앱 등록 정보 (정본)

이 문서는 App Store Connect 웹 콘솔(https://appstoreconnect.apple.com/apps)에서 **[+] 신규 앱**을 생성하고 심사를 제출할 때 필요한 모든 필수 입력 정보의 **정본(Source of Truth)**입니다.

---

## 📋 1. 신규 앱 생성 모달 (App Creation Modal)

| 필드 (Field) | 입력값 (Value) | 비고 |
|---|---|---|
| **플랫폼 (Platform)** | `iOS` | [v] 체크 |
| **기본 언어 (Primary Language)** | `영어(미국)` (`English (U.S.)`) | **기본 기준 언어로 고정** |
| **앱 이름 (Name)** | `Doodle Pad - Draw & Sketch` | 최대 30자 |
| **번들 ID (Bundle ID)** | `com.dangundad.doodlepad` | 드롭다운에서 선택 |
| **SKU** | `com.dangundad.doodlepad` | 번들 ID와 동일하게 입력 |
| **사용자 접근 권한 (User Access)** | `전체 접근 권한 (Full Access)` | 기본값 |

---

## ⚙️ 2. 일반 정보 & 스토어 메타데이터 (General Information)

| 항목 | 권장 설정값 | 비고 |
|---|---|---|
| **첫 출시 버전 (Version)** | `1.0.0` | 세 자리 형식 (`1.0.0`) |
| **기본 카테고리 (Primary Category)** | `유틸리티 (Utilities)` | 또는 `생산성 (Productivity)` |
| **보조 카테고리 (Secondary)** | `라이프스타일 (Lifestyle)` | 선택 사항 |
| **연령 등급 (Age Rating)** | `4+` (만 4세 이상) | 모든 설문에서 **'없음 / 아니요'** 선택 |
| **EU DSA 거래자 상태 (Trader Status)** | `비거래자 (Non-Trader)` | 개인 개발자 계정 시 선택 (또는 Trader) |
| **저작권 (Copyright)** | `DangunDad Lab` | 개발자/조직명 |
| **가격 (Price)** | `무료 (₩0)` | 기본값 |
| **가용 국가/지역 (Availability)** | `175개국 전체 선택` | 기본값 |
| **지원 URL (Support URL)** | `https://dangundad.blogspot.com/p/support.html` | **필수** |
| **마케팅 URL (Marketing URL)** | *(비워둠)* | 필수 아님 |

---

## 🔒 3. [신뢰 및 안전] 앱이 수집하는 개인정보 (App Privacy)

> 👉 접속: App Store Connect > 좌측 메뉴 **[앱 개인정보 처리방침] (App Privacy)** > [시작하기]

- **개인정보처리방침 URL (Privacy Policy URL)**: `https://dangundad.blogspot.com/p/support.html`

### 📊 수집 데이터 항목 4종 설문 답변 가이드 (AdMob + Firebase 기준)

| 데이터 유형 (Data Type) | 수집 목적 (Purpose) | 사용자 신원 연결 | 추적(Tracking) 사용 |
|---|---|---|---|
| **1. 기기 ID (Device ID)**<br>*(식별자 > 기기 ID)* | • `타사 광고 (Third-Party Advertising)`<br>• `분석 (Analytics)` | **아니요 (No)** | **예 (Yes)**<br>*(ATT 프롬프트 연동)* |
| **2. 제품 상호작용 (Product Interaction)**<br>*(사용 내용 > 제품 상호작용)* | • `분석 (Analytics)`<br>• `타사 광고 (Third-Party Advertising)` | **아니요 (No)** | **아니요 (No)** |
| **3. 크래시 데이터 (Crash Data)**<br>*(진단 > 크래시 데이터)* | • `앱 기능 (App Functionality)`<br>• `분석 (Analytics)` | **아니요 (No)** | **아니요 (No)** |
| **4. 기타 진단 데이터 (Other Diagnostic Data)**<br>*(진단 > 기타 진단 데이터)* | • `앱 기능 (App Functionality)`<br>• `분석 (Analytics)` | **아니요 (No)** | **아니요 (No)** |

> ⚠️ 위 4개 항목을 모두 입력한 후 우측 상단의 **[게시(Publish)]** 버튼을 꼭 눌러야 심사 제출이 가능합니다.

---

## 🕵️ 4. 앱 심사 정보 & 심사 제출 규정 준수 (App Review & Compliance)

| 항목 | 입력값 / 선택값 | 비고 |
|---|---|---|
| **버전 번호 (Version)** | `1.0.0` | 세 자리 형식 (`1.0.0`) |
| **로그인 정보 (Sign-In Required)** | `체크 해제 (로그인 불필요)` | 계정 없이 모든 기능 사용 가능 |
| **연락처 성 (Last Name)** | `Oh` | 담당자 정보 |
| **연락처 이름 (First Name)** | `Yongjin` | 담당자 정보 |
| **전화번호 (Phone Number)** | `+82 1031115058` | 국가번호(+82) 포함 |
| **심사 메모 (Review Notes)** | `[Guideline 2.1 Compliance] 1. Sign-In: NO (No login/account required, fully functional upon launch). 2. IAPs: 3 optional tip tiers (Coffee/Lunch/Dinner) via StoreKit 2 which remove ads; all core features are 100% free. 3. SDKs: AdMob (standard ads for free users), Firebase Analytics/Crashlytics (anonymous stability only). 4. Tested Devices: iPhone 15 Pro, iPhone 13, iPad Pro (iOS 18/17). 5. Compliance: Consistent worldwide, no regulated industry, all code/assets proprietary by DangunDad Lab.` | 심사관 안내 (Guideline 2.1 표준 답변) |
| **광고 식별자 (IDFA)** | `예 (Yes)` - 타사 광고 게재 목적 | AdMob SDK 사용 |
| **수출 규정 준수 (Export Compliance)** | `면제 (Exempt)` | 표준 HTTPS만 사용 (`ITSAppUsesNonExemptEncryption=NO`) |
| **콘텐츠 권한 (Content Rights)** | `아니요 (No)` | 타사 지적재산권 포함 안 함 (자체 제작) |

---

## 🌐 5. 11개국 앱스토어 이름 (Store Title) & 홈 화면 이름 (CFBundleDisplayName)

| 언어 (Locale) | 앱스토어 표시 이름 (Store Title, 30자 이내) | 홈 화면 앱 이름 (CFBundleDisplayName, 6-10자 권장) |
|---|---|---|
| **영어 - 미국 (en-US)** (`en-US`) | `Doodle Pad - Draw & Sketch` | `Doodle Pad` |
| **한국어 (ko)** (`ko`) | `간단 그림판 - 그리기와 스케치` | `간단 그림판` |
| **일본어 (ja)** (`ja`) | `かんたんお絵かき - スケッチ` | `かんたんお絵かき` |
| **중국어 번체 (zh-Hant)** (`zh-Hant`) | `简易画板 - 绘画速写` | `简易画板` |
| **독일어 (de-DE)** (`de-DE`) | `Zeichenblock - Skizzen` | `Zeichenblock` |
| **프랑스어 (fr-FR)** (`fr-FR`) | `Bloc dessin - Croquis` | `Bloc dessin` |
| **스페인어 (es-ES)** (`es-ES`) | `Dibujo Fácil - Bocetos` | `Dibujo Fácil` |
| **포르투갈어 - 브라질 (pt-BR)** (`pt-BR`) | `Tela Fácil - Esboços` | `Tela Fácil` |
| **러시아어 (ru)** (`ru`) | `Рисуй легко - Скетчи` | `Рисуй легко` |
| **인도네시아어 (id)** (`id`) | `Gambar Mudah - Sketsa` | `Gambar Mudah` |
| **아랍어 (ar-SA)** (`ar-SA`) | `الرسم السهل - اسكتشات` | `الرسم السهل` |
