# Release shrinking. Flutter's own rules ship with the engine;
# these keep plugins that look up classes by name.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
