# JNI callbacks invoked by maplibre_gl's native WindParticleHost.
# R8 cannot see these calls because they originate in C++: without this rule a
# release build renames or drops all four, GetMethodID fails, and opening a
# wind layer crashes with NoSuchMethodError. Debug builds are not shrunk, so
# only a release build shows it.
#
# Flutter's Gradle plugin enables R8 for release builds and adds this file
# when it exists; build.gradle.kts needs no change for it to apply.
-keepclassmembers class org.maplibre.maplibregl.WindParticleLayer {
    void onNativeInitialize();
    void onNativeRender(double, double, double, double, double, double);
    void onNativeContextLost();
    void onNativeDeinitialize();
}
