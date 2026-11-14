# ──────────────────────────────────────────────────────────────
#  Wooberly Driver – High Performance ProGuard / R8 Rules
#  Configured for maximum obfuscation (>85-95%), dead-code
#  shrinking, and reduced DEX memory footprint.
# ──────────────────────────────────────────────────────────────

# ---------- R8 Optimizations ----------------------------------
-allowaccessmodification

# Optimization passes for deeper dead-code elimination & inlining
-optimizationpasses 5

# ---------- Preserve Essential Attributes ---------------------
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ---------- Flutter Engine & Plugin Registrant ----------------
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-dontwarn io.flutter.**

# ---------- AndroidX @Keep Annotations ------------------------
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

# ---------- Jetpack / AndroidX Lifecycle & ViewModel ----------
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}

# ---------- AndroidX WorkManager, Room & App Startup ----------
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer {
    public <init>();
}
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class androidx.work.Worker {
    public <init>(...);
}
-keep class androidx.work.ListenableWorker {
    public <init>(...);
}
-keep class androidx.work.impl.model.** { *; }
-dontwarn androidx.**

# ---------- Apollo GraphQL ------------------------------------
-keepclassmembers class * implements com.apollographql.apollo.api.Executable {
    public <init>(...);
}
-keepclassmembers class * implements com.apollographql.apollo3.api.Executable {
    public <init>(...);
}
-dontwarn com.apollographql.apollo.**
-dontwarn com.apollographql.apollo3.**

# ---------- Gson / JSON Serialization ------------------------
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-dontwarn com.google.gson.**

# ---------- Parcelable ----------------------------------------
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ---------- Enums ---------------------------------------------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---------- JNI / Native Methods ------------------------------
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---------- WebKit JavascriptInterface -----------------------
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ---------- Google Play Services & Firebase ------------------
# Firebase and Play Services AARs supply their own consumer rules.
# Only suppress benign build-time warnings here.
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# ---------- AndroidX Credentials ------------------------------
-dontwarn androidx.credentials.**
-dontwarn com.google.android.libraries.identity.googleid.**

# ---------- Socket.IO / OkHttp / Coroutines -------------------
-dontwarn com.github.nkzawa.**
-dontwarn io.socket.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.**

# ---------- Misc Third-Party Warnings -------------------------
-dontwarn javax.annotation.**
-dontwarn sun.misc.**
-dontwarn org.codehaus.**
-dontwarn android.**
