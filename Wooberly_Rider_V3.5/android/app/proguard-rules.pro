# ──────────────────────────────────────────────────────────────
#  Wooberly Driver – ProGuard / R8 rules
#  Enables full shrinking + obfuscation while keeping classes
#  required by Flutter, Firebase, Play Services, Apollo, etc.
# ──────────────────────────────────────────────────────────────

# ---------- Flutter -------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ---------- App classes ---------------------------------------
-keep class com.radicalstart.wooberlydriver.** { *; }
-keepnames class com.radicalstart.wooberlydriver.** { *; }

# ---------- Firebase ------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics – preserve source line numbers in crash reports
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# ---------- Google Maps / Location ----------------------------
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# ---------- Apollo GraphQL ------------------------------------
-keep class com.apollographql.apollo.** { *; }
-keep class com.apollographql.apollo3.** { *; }
-keepclassmembers class * implements com.apollographql.apollo3.api.Executable {
    public <init>(...);
}
-dontwarn com.apollographql.apollo.**
-dontwarn com.apollographql.apollo3.**

# ---------- Socket.IO -----------------------------------------
-keep class com.github.nkzawa.** { *; }
-keep class io.socket.** { *; }
-dontwarn com.github.nkzawa.**
-dontwarn io.socket.**

# ---------- Gson / JSON ---------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# ---------- AndroidX Credentials (Restore Credentials API) ---
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn androidx.credentials.**
-dontwarn com.google.android.libraries.identity.googleid.**

# ---------- AndroidX / Jetpack --------------------------------
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.**

# ---------- OkHttp / Okio (transitive deps) ------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ---------- Kotlin --------------------------------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ---------- Coroutines ----------------------------------------
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-dontwarn kotlinx.coroutines.**

# ---------- Serialization / Reflection -----------------------
-keepattributes RuntimeVisibleAnnotations
-keepattributes AnnotationDefault
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ---------- Parcelable ----------------------------------------
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ---------- Enum classes --------------------------------------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---------- R8 / General Android -----------------------------
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers class **.R$* {
    public static <fields>;
}
-dontwarn android.**

# ---------- Suppress misc library warnings -------------------
-dontwarn javax.annotation.**
-dontwarn sun.misc.**
-dontwarn org.codehaus.**

# ---------- Stripe / React Native Stripe SDK -------------------
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Push provisioning is an optional Stripe module (Google Pay push
# provisioning). If you haven't added the pushProvisioning artifact,
# these classes won't exist — tell R8 to ignore them instead of erroring.
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**
