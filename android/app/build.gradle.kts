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
        targetSdk = flutterTargetSdkVersion.toInt()
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
            if (!hasReleaseKeystore) {
                throw GradleException("Release signing requires android/key.properties. Refusing to sign release with the debug key.")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("config")
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

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    testImplementation("junit:junit:4.13.2")
    implementation("androidx.work:work-runtime-ktx:2.7.1")
    implementation("com.google.android.gms:play-services-basement:18.4.0")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:2.1.20"))
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")

    // Android 15 SDK 35 대응 의존성 (androidx.core 1.17.0은 Kotlin 2.0+ 요구)
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.activity:activity-ktx:1.11.0")
    implementation("androidx.window:window:1.4.0")

    // AdMob Android 15 호환성을 위한 최신 의존성
    implementation("com.google.android.gms:play-services-ads:24.7.0")
    implementation("com.google.android.ump:user-messaging-platform:3.1.0")
}
