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
        versionCode = 300909009
        versionName = flutter.versionName

        // Flutter ≥3.35 auto-sets release abiFilters to its 3 supported
        // architectures (union with whatever defaultConfig declares), so the
        // map SDK's libmaplibre.so gets copied for ABI-less engines too. Clear
        // and pin to arm64-v8a: minSdk 26 means no armv7-era devices, and
        // x86_64 is emulator-only (debug builds, which keep all ABIs). This
        // drops the dead libmaplibre.so copies (~18MB uncompressed).
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a"))
        }
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
    // Lets MapSnapshotChannel / MapCacheChannel use MapLibre APIs directly:
    // the maplibre_gl plugin's SDK isn't on the app's compile classpath.
    // maplibre_gl ≥0.26 switched to the OpenGL artifact and excludes the
    // unsuffixed `android-sdk` — keep this in sync or mergeReleaseNativeLibs
    // dies on duplicate `lib/arm64-v8a/libmaplibre.so`.
    implementation("org.maplibre.gl:android-sdk-opengl:13.3.0")
    // Lets the native background-location layer use the Fused Location Provider
    // and Geofencing API directly. Already in the APK transitively via
    // geolocator / maplibre_gl; this promotes it to the app's compile
    // classpath. Keep ≥ maplibre_gl's pin (21.3.0).
    implementation("com.google.android.gms:play-services-location:21.3.0")
    // PackageManagerCompat.getUnusedAppRestrictionsStatus / IntentCompat's
    // manage-unused-app-restrictions intent, for UnusedAppRestrictionsChannel.
    // Already in the APK transitively through the Flutter embedding, but a
    // transitive version is not a contract — pin it explicitly rather than
    // compile against whatever the dependency graph happens to resolve.
    implementation("androidx.core:core-ktx:1.13.1")
    // getUnusedAppRestrictionsStatus returns a ListenableFuture, which lives in
    // guava's listenablefuture artifact — androidx.core declares it but does not
    // put it on a consumer's compile classpath, so calling addListener/get needs
    // this explicitly.
    implementation("androidx.concurrent:concurrent-futures:1.2.0")
    // Backports java.time/etc. for awesome_notifications (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
