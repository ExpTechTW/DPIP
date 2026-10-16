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

    // Robolectric inflates the Widget's real layouts and resolves its real
    // resources, so the unit-test run needs the merged resource table — which
    // is off by default for Android unit tests.
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }

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

        // The Widget's on-device suite (`src/androidTest`), which a JVM runner
        // cannot stand in for: the real `RemoteViews` inflater, the real SQLite,
        // and the real provider metadata the launcher reads. It runs from
        // android.yml on an emulator, which is the only place a device exists.
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Flutter ≥3.35 auto-sets release abiFilters to its 3 supported
        // architectures (union with whatever defaultConfig declares).
        // Keep only ARM64 devices and x86_64 emulators.
        // armeabi-v7a and x86 are intentionally unsupported.
        // This also drops unused libmaplibre.so copies (~18MB uncompressed).
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
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


// Robolectric reads the app's *merged assets* — the generated township
// resources are app assets, and the unit-test packaging task therefore consumes
// the directory the Flutter Gradle plugin writes into. AGP declares that edge
// for the app tasks but not for the unit-test packaging tasks, so Gradle's
// task-order validation fails the build with "uses this output ... without
// declaring an explicit or implicit dependency". Declaring it is the fix Gradle
// itself proposes; the alternative is dropping `isIncludeAndroidResources`,
// which is what makes `RemoteViews.apply` and the SQLite/resources tests
// possible at all.
tasks.matching { it.name == "packageDebugUnitTestForUnitTest" }.configureEach {
    dependsOn("copyFlutterAssetsDebug")
}
tasks.matching { it.name == "packageReleaseUnitTestForUnitTest" }.configureEach {
    dependsOn("copyFlutterAssetsRelease")
}

flutter {
    source = "../.."
}

dependencies {
    // Only the native widget picker uses MDC; Flutter and RemoteViews keep their themes.
    implementation("com.google.android.material:material:1.14.0")
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

    // The Widget's native unit tests.
    //
    // JUnit alone covers the pure policy (JSON, contracts, ordering,
    // presentation, solar time, the time protocols). The wiring that only exists
    // at runtime — `RemoteViews.apply` against the real layouts, the SQLite
    // store's SQL, WorkManager's scheduling, the configuration Activity and the
    // provider's restore path — needs an Android runtime, and there is no device
    // or emulator here or on the CI runner. Robolectric supplies one on the JVM,
    // so those tests run everywhere `tool/dev/test_android.sh` runs.
    //
    // `work-testing` provides the WorkManager test initializer, which is the
    // only way to inspect what was enqueued without a real scheduler.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16")
    testImplementation("androidx.test:core:1.6.1")
    testImplementation("androidx.work:work-testing:2.11.2")

    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test:rules:1.6.1")
}
