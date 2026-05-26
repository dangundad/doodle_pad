# =============================================================
# Doodle Pad - ProGuard / R8 Rules
# =============================================================
# 릴리스 빌드(`isMinifyEnabled = true`, `isShrinkResources = true`)에서
# Flutter, AdMob/UMP/Mediation, Google Play Billing, Hive,
# Firebase Crashlytics 사용 시 발생할 수 있는 클래스 제거/난독화
# 이슈를 방지한다.

# ----- Flutter / Dart embedding -----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ----- Google Play Core (deferred components) -----
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ----- AndroidX / Kotlin -----
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ----- Google Mobile Ads (AdMob) + UMP -----
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**

# ----- AdMob Mediation: AppLovin, Pangle, Unity -----
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**
-keep class com.bytedance.** { *; }
-dontwarn com.bytedance.**
-keep class com.unity3d.** { *; }
-dontwarn com.unity3d.**

# ----- Google Play Billing / In-App Purchase -----
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.api.**

# ----- Firebase / Crashlytics -----
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ----- Hive (hive_ce uses reflection only minimally; keep model adapters) -----
-keep class * extends hive_ce.TypeAdapter { *; }
-keep @hive_ce.HiveType class * { *; }

# ----- Misc reflection / annotations -----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ----- Suppress warnings for libraries we do not control directly -----
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
