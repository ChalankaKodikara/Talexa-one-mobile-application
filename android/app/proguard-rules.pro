# Flutter deferred components / old Play Core references
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep Flutter basics
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin metadata / annotations
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*