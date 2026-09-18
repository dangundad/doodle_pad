import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties =  Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Allow opting out of the strict release-signing requirement when explicitly
// generating a debug-signed APK (e.g. local smoke test). Default is strict.
val allowUnsignedRelease: Boolean = (project.findProperty("allowUnsignedRelease") as String?)?.toBoolean() ?: false


android {
    namespace = "com.dangundad.doodlepad"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.dangundad.doodlepad"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            isMinifyEnabled = true
            isShrinkResources = true
            // Use the upload keystore when present; otherwise fall back to debug
            // signing so non-release tasks (assembleDebug / flutter run) can still
            // configure without a keystore. A debug-signed release never lands on
            // Play because the taskGraph guard below hard-fails an actual release
            // assembly when the keystore is missing (unless -PallowUnsignedRelease
            // =true is explicitly passed for a local smoke test).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("config")
            } else {
                if (allowUnsignedRelease) {
                    logger.warn(
                        "WARNING: key.properties not found — release will be debug-signed " +
                        "because -PallowUnsignedRelease=true was passed. Do not upload to Play."
                    )
                }
                signingConfigs.getByName("debug")
            }
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

// Guard: hard-fail an actual release assembly/bundle when no upload keystore is
// available, unless a debug-signed release was explicitly requested via
// -PallowUnsignedRelease=true. This runs only for release tasks, so debug builds
// and `flutter run` are never blocked by a missing keystore.
gradle.taskGraph.whenReady {
    val assemblingRelease = allTasks.any { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") ||
                task.name.startsWith("bundle") ||
                task.name.startsWith("package"))
    }
    if (assemblingRelease && !keystorePropertiesFile.exists() && !allowUnsignedRelease) {
        throw GradleException(
            "Release signing keystore (android/key.properties) not found. " +
            "Provide it for the upload key, or pass -PallowUnsignedRelease=true " +
            "to generate a debug-signed release locally."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.work:work-runtime-ktx:2.11.2")
    implementation("com.google.android.gms:play-services-basement:18.10.0")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:2.3.20"))
    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")

    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.activity:activity-ktx:1.13.0")
    implementation("androidx.window:window:1.5.1")

    implementation("com.google.android.gms:play-services-ads:25.4.0")
    implementation("com.google.android.ump:user-messaging-platform:4.0.0")

    testImplementation("junit:junit:4.13.2")
}