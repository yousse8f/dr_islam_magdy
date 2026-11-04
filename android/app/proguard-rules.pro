# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# App models & serialization
-keep class com.example.dr_islam_magdy.** { *; }

# Flutter Plugins
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class com.google.flutter.plugins.webview.** { *; }
-keep class com.fivestars.flutterplugins.fluttertimezone.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep timezone data & notifications plugin
-keep class timezone.** { *; }
-keep class flutter_local_notifications.** { *; }

# Ignore missing Play Core classes referenced by Flutter embedding
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

-keepattributes *Annotation*,Signature,EnclosingMethod
