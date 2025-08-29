# تحسينات ProGuard المتقدمة لتقليل حجم التطبيق
# Advanced ProGuard optimizations for app size reduction

# تفعيل جميع التحسينات
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# ضغط أقوى للكود
-repackageclasses ''
-allowaccessmodification

# إزالة السجلات في الإنتاج
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# إزالة print statements
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# ضغط أسماء الكلاسات والمتغيرات (استخدام الأسماء الافتراضية)
# تم إزالة dictionary.txt لتجنب مشاكل الملف المفقود

# Firebase rules - إخفاء تحذيرات الإهلاك
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# إخفاء تحذيرات Firebase Auth المحددة
-dontwarn com.google.firebase.auth.FirebaseAuth
-dontwarn com.google.firebase.auth.FirebaseUser
-dontwarn com.google.firebase.auth.ActionCodeSettings$Builder

# إخفاء تحذيرات الـ Deprecation
-dontnote **
-dontwarn **Deprecated**
-dontwarn **deprecated**

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Mobile Scanner rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.vision.**

# Image Picker rules
-keep class androidx.exifinterface.** { *; }
-dontwarn androidx.exifinterface.**

# Permission Handler rules
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Shared Preferences rules
-keep class androidx.preference.** { *; }
-dontwarn androidx.preference.**

# URL Launcher rules
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# General Android rules
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Keep all model classes (if using reflection)
-keep class com.example.kidsbus.models.** { *; }

# Keep all service classes
-keep class com.example.kidsbus.services.** { *; }

# Gson rules (if using Gson)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Retrofit rules (if using Retrofit)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# We want to keep methods in Activity that could be used in the XML attribute onClick
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}

# For enumeration classes, see http://proguard.sourceforge.net/manual/examples.html#enumerations
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}

-keepclassmembers class **.R$* {
    public static <fields>;
}

# The support library contains references to newer platform versions.
# Don't warn about those in case this app is linking against an older
# platform version.  We know about them, and they are safe.
-dontwarn android.support.**

# Understand the @Keep support annotation.
-keep class android.support.annotation.Keep

-keep @android.support.annotation.Keep class * {*;}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <methods>;
}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <fields>;
}

-keepclasseswithmembers class * {
    @android.support.annotation.Keep <init>(...);
}
