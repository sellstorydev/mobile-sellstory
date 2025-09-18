# ProGuard / R8 rules for Sellstory
# Keep Flutter embedding & plugin classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase (reflection / annotations)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Services / GMS
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep AndroidX core (avoid over-shrinking resources used reflectively)
-keep class androidx.core.** { *; }

# Apple sign-in plugin (may use reflection)
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# Keep model classes that might be (de)serialized dynamically (add more as needed)
# -keep class me.sellstory.app.** { *; }

# Keep basic enum methods (fix invalid previous pattern)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Retain annotations
-keepattributes *Annotation*

# (Optional) If using Gson / reflection based JSON, uncomment:
# -keep class * implements com.google.gson.TypeAdapterFactory { *; }
# -keep class * implements com.google.gson.JsonSerializer { *; }
# -keep class * implements com.google.gson.JsonDeserializer { *; }

# Suppress warnings for Kotlin metadata
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }

# Retain generic signatures & inner classes for reflection
-keepattributes Signature,InnerClasses,EnclosingMethod
