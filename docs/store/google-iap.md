# Doodle Pad Google Play 인앱 구매(IAP) 정의서 (정본)

이 문서는 Doodle Pad Google Play 인앱 구매 상품의 **정본(Source of Truth)**입니다.
Google Play Console > [수익 창출] > [인앱 상품] 메뉴에서 아래 표를 참고하여 상품을 등록하세요.

---

#### 3개의 후원 상품 등록 예시

**상품 1: Premium Coffee** ☕
| 항목         | 값                                                    |
| ------------ | ----------------------------------------------------- |
| 제품 ID      | `doodle_pad_premium_small`                            |
| 태그         | `premium`, `donation`, `coffee`, `small`              |
| 이름         | Premium - Coffee                                      |
| 설명         | Remove ads and unlock premium features.               |
| 구매 옵션 ID | `purchase-coffee`                                     |
| 구매 유형    | 구입 (영구 소유)                                      |
| 한국 가격    | 약 ₩4,400                                             |
| 미국 가격    | $2.99                                                 |
| 상태         | 활성화                                                |

**상품 2: Premium Lunch** 🍱 (추천)
| 항목         | 값                                                      |
| ------------ | ------------------------------------------------------- |
| 제품 ID      | `doodle_pad_premium_medium`                             |
| 태그         | `premium`, `donation`, `lunch`, `medium`, `recommended` |
| 이름         | Premium - Lunch                                         |
| 설명         | Remove ads and unlock premium features.                 |
| 구매 옵션 ID | `purchase-lunch`                                        |
| 구매 유형    | 구입 (영구 소유)                                        |
| 한국 가격    | 약 ₩8,800                                               |
| 미국 가격    | $5.99                                                   |
| 상태         | 활성화                                                  |

**상품 3: Premium Dinner** 🍽️
| 항목         | 값                                                     |
| ------------ | ------------------------------------------------------ |
| 제품 ID      | `doodle_pad_premium_large`                             |
| 태그         | `premium`, `donation`, `dinner`, `large`               |
| 이름         | Premium - Dinner                                       |
| 설명         | Remove ads and unlock premium features.                |
| 구매 옵션 ID | `purchase-dinner`                                      |
| 구매 유형    | 구입 (영구 소유)                                       |
| 한국 가격    | 약 ₩14,700                                             |
| 미국 가격    | $9.99                                                  |
| 상태         | 활성화                                                 |

---

#### [Google Play 11개국 다국어 현지화 참고표]

##### 1. Coffee Support ($2.99)
| 언어 (Locale) | 상품명 (Title) | 설명 (Description) |
|---|---|---|
| **영어 - 미국 (en-US)** (`en-US`) | `Coffee Support` | `Remove ads & unlock premium features.` |
| **한국어 (ko)** (`ko-KR`) | `커피 한 잔 후원 (Coffee)` | `광고 영구 제거 및 프리미엄 기능 해제` |
| **일본어 (ja)** (`ja-JP`) | `コーヒーで応援` | `広告を永久削除し、プレミアム機能を解放。` |
| **중국어 번체 (zh-Hant)** (`zh-TW`) | `一杯咖啡贊助` | `永久移除廣告並解鎖高級功能。` |
| **독일어 (de-DE)** (`de-DE`) | `Kaffee-Unterstützung` | `Werbung dauerhaft entfernen & Premium freischalten.` |
| **프랑스어 (fr-FR)** (`fr-FR`) | `Soutien Café` | `Supprime les pubs & débloque les fonctions premium.` |
| **스페인어 (es-ES)** (`es-ES`) | `Apoyo con un Café` | `Elimina anuncios y desbloquea funciones premium.` |
| **포르투갈어 - 브라질 (pt-BR)** (`pt-BR`) | `Apoio com um Café` | `Remova os anúncios e desbloqueie recursos premium.` |
| **러시아어 (ru)** (`ru-RU`) | `Поддержка: Чашка кофе` | `Убрать рекламу и открыть премиум-функции.` |
| **인도네시아어 (id)** (`id`) | `Dukungan Secangkir Kopi` | `Hapus iklan & buka fitur premium selamanya.` |
| **아랍어 (ar-SA)** (`ar`) | `دعم فنجان قهوة` | `إزالة الإعلانات وفتح الميزات المميزة.` |

##### 2. Lunch Support ($5.99)
| 언어 (Locale) | 상품명 (Title) | 설명 (Description) |
|---|---|---|
| **영어 - 미국 (en-US)** (`en-US`) | `Lunch Support` | `Remove ads & unlock premium features.` |
| **한국어 (ko)** (`ko-KR`) | `식사 한 끼 후원 (Lunch)` | `광고 영구 제거 및 프리미엄 기능 해제` |
| **일본어 (ja)** (`ja-JP`) | `ランチで応援` | `広告を永久削除し、プレミアム機能を解放。` |
| **중국어 번체 (zh-Hant)** (`zh-TW`) | `一頓午餐贊助` | `永久移除廣告並解鎖高級功能。` |
| **독일어 (de-DE)** (`de-DE`) | `Mittagessen-Unterstützung` | `Werbung dauerhaft entfernen & Premium freischalten.` |
| **프랑스어 (fr-FR)** (`fr-FR`) | `Soutien Déjeuner` | `Supprime les pubs & débloque les fonctions premium.` |
| **스페인어 (es-ES)** (`es-ES`) | `Apoyo con un Almuerzo` | `Elimina anuncios y desbloquea funciones premium.` |
| **포르투갈어 - 브라질 (pt-BR)** (`pt-BR`) | `Apoio com um Almoço` | `Remova os anúncios e desbloqueie recursos premium.` |
| **러시아어 (ru)** (`ru-RU`) | `Поддержка: Обед` | `Убрать рекламу и открыть премиум-функции.` |
| **인도네시아어 (id)** (`id`) | `Dukungan Makan Siang` | `Hapus iklan & buka fitur premium selamanya.` |
| **아랍어 (ar-SA)** (`ar`) | `دعم وجبة غداء` | `إزالة الإعلانات وفتح الميزات المميزة.` |

##### 3. Dinner Support ($9.99)
| 언어 (Locale) | 상품명 (Title) | 설명 (Description) |
|---|---|---|
| **영어 - 미국 (en-US)** (`en-US`) | `Dinner Support` | `Remove ads & unlock premium features.` |
| **한국어 (ko)** (`ko-KR`) | `근사한 저녁 후원 (Dinner)` | `광고 영구 제거 및 프리미엄 기능 해제` |
| **일본어 (ja)** (`ja-JP`) | `ディナーで応援` | `広告を永久削除し、プレミアム機能を解放。` |
| **중국어 번체 (zh-Hant)** (`zh-TW`) | `豐盛晚餐贊助` | `永久移除廣告並解鎖高級功能。` |
| **독일어 (de-DE)** (`de-DE`) | `Abendessen-Unterstützung` | `Werbung dauerhaft entfernen & Premium freischalten.` |
| **프랑스어 (fr-FR)** (`fr-FR`) | `Soutien Dîner` | `Supprime les pubs & débloque les fonctions premium.` |
| **스페인어 (es-ES)** (`es-ES`) | `Apoyo con una Cena` | `Elimina anuncios y desbloquea funciones premium.` |
| **포르투갈어 - 브라질 (pt-BR)** (`pt-BR`) | `Apoio com um Jantar` | `Remova os anúncios e desbloqueie recursos premium.` |
| **러시아어 (ru)** (`ru-RU`) | `Поддержка: Ужин` | `Убрать рекламу и открыть премиум-функции.` |
| **인도네시아어 (id)** (`id`) | `Dukungan Makan Malam` | `Hapus iklan & buka fitur premium selamanya.` |
| **아랍어 (ar-SA)** (`ar`) | `دعم وجبة عشاء` | `إزالة الإعلانات وفتح الميزات المميزة.` |
