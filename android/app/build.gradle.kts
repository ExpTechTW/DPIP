import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (processes google-services.json).
    id("com.google.gms.google-services")
}

// Release signing is read from android/key.properties (kept out of version control;
// supplied locally or by CI). Falls back to debug signing when absent.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.exptech.dpip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by awesome_notifications (uses desugared java.time/etc.).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.exptech.dpip"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = 300909001
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
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
    // Lets MapSnapshotChannel use MapLibre's off-screen MapSnapshotter directly:
    // the maplibre_gl plugin's SDK dependency isn't on the app's compile
    // classpath. Keep the version in sync with maplibre_gl (android-sdk).
    implementation("org.maplibre.gl:android-sdk:12.3.1")
    // Lets the native background-location layer use the Fused Location Provider
    // and Geofencing API directly. Already in the APK transitively via
    // geolocator; this promotes it to the app's compile classpath (same reason
    // as the maplibre-gl line above). Keep in sync with geolocator_android.
    implementation("com.google.android.gms:play-services-location:21.2.0")
    // Backports java.time/etc. for awesome_notifications (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
