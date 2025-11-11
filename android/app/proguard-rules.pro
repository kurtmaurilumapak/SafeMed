# Conservative keep rules for Flutter + pytorch_lite. Add more if needed after testing.
-keep class com.example.safemed.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class kotlin.Metadata { *; }
-keep class org.pytorch.** { *; }
-keep class com.github.am15h.** { *; }
-keep class com.github.am15h.pytorch_lite.** { *; }
-keep class com.facebook.** { *; }
-dontwarn com.facebook.jni.**
-dontwarn com.facebook.soloader.**
-dontwarn com.facebook.infer.**
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# R8 missing classes (Play Core deferred components references from Flutter engine)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task