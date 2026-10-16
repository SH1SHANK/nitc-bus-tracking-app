# ProGuard / R8 Rules for Tracklet (Flutter Android)

# --- Flutter Engine & Embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress Flutter Play Store deferred component warnings when Play Core is not bundled
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Preserve native JNI method bindings
-keepclasseswithmembers class * {
    native <methods>;
}

# Preserve Enum values() and valueOf() methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve standard debugging and reflection attributes
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses,SourceFile,LineNumberTable

# --- App Links & Deep Linking ---
-keep class com.llfbandit.app_links.** { *; }
-dontwarn com.llfbandit.app_links.**

# --- Geolocator ---
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**


# --- OkHttp, Okio & TLS Stacks ---
-dontwarn okio.**
-dontwarn okhttp3.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# --- Kotlin Coroutines ---
-dontwarn kotlinx.coroutines.**
