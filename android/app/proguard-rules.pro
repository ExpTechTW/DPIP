# JNI callbacks invoked by maplibre_gl's native WindParticleHost.
# R8 cannot see these calls because they originate in C++.
-keepclassmembers class org.maplibre.maplibregl.WindParticleLayer {
    void onNativeInitialize();
    void onNativeRender(double, double, double, double, double, double);
    void onNativeContextLost();
    void onNativeDeinitialize();
}
