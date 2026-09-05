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

/// The version the stores see, kept deliberately apart from the one people
/// read.
///
/// `versionCode` is the *only* thing Play orders by, so it must increase and
/// nothing else about it matters. `versionName` is free text and is the label
/// a human was given — `26w33a`, `26.1`. Deriving one from the other, as this
/// file used to (`major×10⁸ + minor×10⁶ + …`), welds them together: the label
/// can then never be restyled, reordered or renamed without the ordinal
/// moving with it, and a label that is not three integers cannot exist at all.
///
/// Both now come from `tool/release/version.sh` by way of CI, which is the one place
/// that decides. Locally, where neither is set, the build falls back to
/// Flutter's own numbers so `flutter run` keeps working.
/// Play's ordinal, straight from Flutter's `--build-number`.
///
/// One source, not two. It used to also read a `DPIP_CODE` environment
/// variable, which meant two ways to set the same field and no rule about
/// which won — and the two carry different numbers now that each store has its
/// own floor (`tool/release/version.sh`). Play's is deliberately the small one: it has
/// published nothing, and a code that turns out to be too low fails the
/// *upload*, before anything is served, which costs one line to fix.
val dpipVersionCode: Int = flutter.versionCode

val dpipVersionName: String =
    System.getenv("DPIP_LABEL")?.takeIf { it.isNotBlank() } ?: flutter.versionName

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
        versionCode = dpipVersionCode
        versionName = dpipVersionName

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
        debug {
            // defaultConfig keeps release artifacts arm64-only, but Android
            // emulators on Intel/AMD hosts need Flutter's x86_64 engine.
            ndk {
                abiFilters.add("x86_64")
            }
        }
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
    // Durable, queryable watchdog behind the geofence/alarm background-location
    // path. WorkManager persists its unique periodic work across process death
    // and reboot; it only repairs an overdue path and never takes a healthy
    // path's extra location fix.
    implementation("androidx.work:work-runtime:2.11.2")
    // Backports java.time/etc. for awesome_notifications (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
