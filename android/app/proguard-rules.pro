# Keep the Flutter embedding intact when R8 shrinks the release build.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
