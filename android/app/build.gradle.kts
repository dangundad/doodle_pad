import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties =  Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterMinSdkVersion = localProperties.getProperty("flutter.flutterMinSdkVersion") ?: "24"
val flutterTargetSdkVersion = localProperties.getProperty("flutter.flutterTargetSdkVersion") ?: "36"
val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

android {
    namespace = "com.dangundad.doodlepad"
    compileSdk = Math.max(flutter.compileSdkVersion, 36)
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dangundad.doodlepad"
        minSdk = maxOf(flutterMinSdkVersion.toInt(), 24)
        targetSdk = maxOf(flutterTargetSdkVersion.toInt(), 36)
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName.toString()

        multiDexEnabled = true // 멀티덱스를 사용하도록 설정.
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("config") {
                keyAlias = keystoreProperties["keyAlias"] as? String ?: ""
                keyPassword = keystoreProperties["keyPassword"] as? String ?: ""
                storeFile = (keystoreProperties["storeFile"] as? String)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as? String ?: ""
            }
        }
    }

    buildTypes {
        getByName("release") {
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            isMinifyEnabled = true
            isShrinkResources = true
            // key.properties 가 없으면 서명 설정 자체가 존재하지 않는다.
            // 실제 차단은 아래 taskGraph 가드가 담당한다 (릴리스 태스크 요청 시에만).
            signingConfig = signingConfigs.findByName("config")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 릴리스 서명 가드.
//
// 예전에는 이 검사를 `buildTypes { getByName("release") { ... } }` 안에서 throw 했는데,
// 그 블록은 Gradle의 *configuration* 단계에서 항상 평가되므로 `assembleDebug` 처럼
// 릴리스와 무관한 빌드까지 함께 실패했다(= key.properties 없는 새 클론에서 디버그 실행 불가).
// 실제로 릴리스 산출물을 만들려는 태스크가 그래프에 올라왔을 때만 실패시킨다.
gradle.taskGraph.whenReady {
    if (hasReleaseKeystore) return@whenReady
    val releaseTaskPattern = Regex("^:app:(assemble|bundle|package|install)Release")
    val wantsRelease = allTasks.any { releaseTaskPattern.containsMatchIn(it.path) }
    if (wantsRelease) {
        throw GradleException(
            "Release signing requires android/key.properties. Refusing to sign release with the debug key."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    testImplementation("junit:junit:4.13.2")
    implementation("androidx.work:work-runtime-ktx:2.11.2")
    implementation("com.google.android.gms:play-services-basement:18.10.0")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:2.2.20"))
    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("androidx.multidex:multidex:2.0.1")

    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.activity:activity-ktx:1.13.0")
    implementation("androidx.window:window:1.5.1")

    implementation("com.google.android.gms:play-services-ads:25.1.0")
    implementation("com.google.android.ump:user-messaging-platform:4.0.0")
}
